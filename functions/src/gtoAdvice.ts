import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";

import { callGeminiFlash, FLASH_MODEL_NAME } from "./ai/geminiClient";
import { logAgentExecution } from "./utils/agentExecutionLogger";

/** GTO 조언 요청 인터페이스 */
interface GtoAdviceRequest {
  /** 사용자가 기록한 핸드 메모 원문 (최대 2000자) */
  handMemoText: string;
  /** 테이블에서 플레이어의 포지션 (예: "BTN", "CO") */
  position: string;
  /** 현재 스택 사이즈 (BB 단위, 예: 30 = 30BB) */
  stackSize: number;
  /** 현재 블라인드 레벨 (예: "500/1000") */
  blindLevel: string;
}

/** GTO 조언 응답 인터페이스 */
interface GtoAdviceResponse {
  /** AI가 생성한 GTO 기반 핸드 코칭 내용 */
  advice: string;
  /** 프롬프트에 주입된 GTO 레인지 요약 (프론트 표시용) */
  gtoContext: string;
}

/**
 * 포지션별 표준 GTO 오픈 레인지 요약 (100자 이내 핵심 카테고리)
 * — 이 정적 데이터를 프롬프트에 주입해 AI가 GTO 기준선을 명확히 인식하도록 한다.
 */
const GTO_RANGE_SUMMARY: Record<string, string> = {
  BTN: "22+, A2s+, K5s+, Q8s+, J8s+, T8s+, 수트커넥터(87s~54s), ATo+, KTo+, QTo+ (~44%)",
  CO:  "44+, A5s+, K9s+, Q9s+, J9s+, T9s, AJo+, KJo+, QJo (~27%)",
  HJ:  "55+, A9s+, KTs+, QTs+, JTs, AJo+, KQo (~20%)",
  UTG: "77+, ATs+, KQs, QJs, JTs, AJo+, KQo (~13%)",
  SB:  "22+, A2s+, K8s+, Q9s+, ATo+, KTo+ (~40%)",
  BB:  "오픈 레인지 없음 (3벳/콜/폴드 대응만)",
};

/** 핸드 메모 최대 허용 길이 — analyzeLeak와 동일하게 2000자로 통일 */
const MAX_HAND_MEMO_LENGTH = 2000;

/** 블라인드 레벨 최대 허용 길이 (예: "10000/20000/20000") */
const MAX_BLIND_LEVEL_LENGTH = 20;

/** 사용자별 GTO 조언 일일 호출 상한 — GCP $300 평가판 비용 제어 */
const DAILY_CALL_LIMIT = 10;

/**
 * 오늘 날짜를 "YYYY-MM-DD" 형식으로 반환하는 헬퍼.
 * Firestore 문서 ID로 사용해 날짜별 카운터를 관리한다.
 */
function getTodayDateString(): string {
  return new Date().toISOString().split("T")[0];
}

/**
 * 사용자의 오늘 호출 횟수를 확인하고 한도를 초과하면 예외를 던진다.
 * 한도 이내면 카운터를 1 증가시킨 후 반환한다.
 *
 * Firestore 경로: `users/{userId}/gto_advice_usage/{YYYY-MM-DD}`
 * 필드: `count` (숫자)
 */
async function checkAndIncrementDailyUsage(userId: string): Promise<void> {
  const db = getFirestore();
  const today = getTodayDateString();
  const usageRef = db.doc(`users/${userId}/gto_advice_usage/${today}`);

  // 트랜잭션으로 읽기+증가를 원자적으로 처리해 경쟁 조건(race condition) 방지
  await db.runTransaction(async (txn) => {
    const snapshot = await txn.get(usageRef);
    const currentCount: number = snapshot.exists ? (snapshot.data()?.count ?? 0) : 0;

    if (currentCount >= DAILY_CALL_LIMIT) {
      throw new HttpsError(
        "resource-exhausted",
        `일일 GTO 조언 한도(${DAILY_CALL_LIMIT}회)에 도달했습니다.`,
      );
    }

    // 문서가 없으면 생성, 있으면 count만 1 증가
    txn.set(
      usageRef,
      { count: FieldValue.increment(1), updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  });
}

/**
 * 포지션·스택·블라인드 레벨을 바탕으로 GTO 레인지 데이터를 주입해
 * Gemini Flash에게 핸드 코칭 분석을 요청하는 Cloud Function.
 *
 * 흐름: 인증 확인 → 입력 검증 → 일일 호출 한도 확인 → logAgentExecution 래핑
 *       → Gemini Flash 호출 → 결과 반환
 *
 * XPRIZE 운영 증빙: 모든 호출은 `agent_execution_logs`에 자동 기록된다.
 */
export const gtoAdvice = onCall<GtoAdviceRequest>(async (request) => {
  // 인증되지 않은 호출 차단 (CLAUDE.md 보안 규칙)
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "로그인이 필요한 기능입니다.");
  }

  // ── 입력 검증 ──────────────────────────────────────────────────

  const handMemoText = request.data?.handMemoText?.trim();
  if (!handMemoText) {
    throw new HttpsError("invalid-argument", "분석할 핸드 메모 내용이 비어 있습니다.");
  }
  if (handMemoText.length > MAX_HAND_MEMO_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `핸드 메모는 최대 ${MAX_HAND_MEMO_LENGTH}자까지 분석할 수 있습니다. (입력 길이: ${handMemoText.length}자)`,
    );
  }

  const position = request.data?.position?.trim();
  if (!position || !(position in GTO_RANGE_SUMMARY)) {
    throw new HttpsError(
      "invalid-argument",
      `올바른 포지션을 입력하세요. 허용값: ${Object.keys(GTO_RANGE_SUMMARY).join(", ")}`,
    );
  }

  const stackSize = request.data?.stackSize;
  if (typeof stackSize !== "number" || !isFinite(stackSize) || stackSize < 1) {
    throw new HttpsError(
      "invalid-argument",
      "스택 사이즈는 1BB 이상의 숫자여야 합니다.",
    );
  }

  const blindLevel = request.data?.blindLevel?.trim();
  if (!blindLevel) {
    throw new HttpsError("invalid-argument", "블라인드 레벨을 입력해 주세요.");
  }
  if (blindLevel.length > MAX_BLIND_LEVEL_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `블라인드 레벨은 최대 ${MAX_BLIND_LEVEL_LENGTH}자까지 입력할 수 있습니다.`,
    );
  }

  // ── 일일 호출 한도 확인 ────────────────────────────────────────
  // HttpsError("resource-exhausted") 발생 시 그대로 상위로 전파
  await checkAndIncrementDailyUsage(request.auth.uid);

  // ── GTO 레인지 조회 및 프롬프트 구성 ──────────────────────────
  const gtoContext = GTO_RANGE_SUMMARY[position];

  const prompt = [
    "당신은 포커 GTO(Game Theory Optimal) 전문 코칭 AI입니다.",
    "",
    "=== 기준 GTO 데이터 ===",
    `포지션: ${position}`,
    `표준 GTO 오픈 레인지: ${gtoContext}`,
    `현재 스택: ${stackSize}BB`,
    `블라인드: ${blindLevel}`,
    "",
    "=== 사용자 핸드 상황 ===",
    handMemoText,
    "",
    "위 GTO 기준과 실제 핸드를 비교해,",
    "1) GTO 관점의 최적 플레이가 무엇인지",
    "2) 이 상황에서 주의해야 할 ICM 또는 스택 사이즈 고려 사항",
    "을 한국어로 3~5문장으로 분석해 주세요.",
  ].join("\n");

  // ── Gemini Flash 호출 (logAgentExecution으로 감싸 XPRIZE 증빙 자동 기록) ──
  try {
    const adviceText = await logAgentExecution({
      userId: request.auth.uid,
      agentTask: "hand_coaching",
      modelName: FLASH_MODEL_NAME,
      fn: async () => {
        const { text, inputTokenCount, outputTokenCount } = await callGeminiFlash(prompt);
        return {
          output: text,
          // XPRIZE 증빙: AI 판단 근거를 한글로 간결하게 요약
          reasoningSummary: `포지션 ${position}, 스택 ${stackSize}BB 상황에서 GTO 레인지 데이터를 근거로 핸드 코칭 분석 수행`,
          inputTokenCount,
          outputTokenCount,
        };
      },
    });

    const response: GtoAdviceResponse = {
      advice: adviceText,
      gtoContext,
    };
    return response;
  } catch (error) {
    // logAgentExecution이 이미 실패 로그를 agent_execution_logs에 기록하므로
    // 여기서는 클라이언트에 안전한 에러 메시지만 전달한다
    console.error("GTO 조언 생성 실패:", error);
    throw new HttpsError("internal", "GTO 조언 생성 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.");
  }
});
