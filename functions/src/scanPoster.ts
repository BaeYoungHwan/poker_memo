import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";

import { callGeminiFlashVision, FLASH_MODEL_NAME } from "./ai/geminiClient";
import { logAgentExecution } from "./utils/agentExecutionLogger";

/** 포스터 스캔 요청 인터페이스 */
interface ScanPosterRequest {
  /** 순수 base64 인코딩 이미지 데이터 (data URI 접두사 제외) */
  imageBase64: string;
  /** 이미지 MIME 타입 (예: "image/jpeg") */
  mimeType: string;
}

/** 포스터 스캔 응답 인터페이스 */
interface ScanPosterResponse {
  /** 토너먼트명 또는 행사명 - 인식 불가 시 null */
  name: string | null;
  /** 토너먼트 개최 날짜 ("YYYY-MM-DD") - 인식 불가 시 null */
  date: string | null;
  /** 바이인 금액(숫자) - 인식 불가 시 null */
  buyIn: number | null;
  /** 부분/전체 인식 실패 시 사용자 안내 메시지, 완전 인식 성공 시 null */
  warning: string | null;
}

/** Gemini가 추출한 포스터 정보를 안전하게 담는 내부 구조체 */
interface ParsedPosterInfo {
  name: string | null;
  date: string | null;
  buyIn: number | null;
}

/** 업로드를 허용하는 이미지 MIME 타입 목록 */
const ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"];

/**
 * base64 이미지 문자열 최대 허용 길이.
 * raw 약 4MB 이미지를 base64로 인코딩하면 약 33% 늘어나므로, 안전 마진을 둔 상한선이다.
 */
const MAX_IMAGE_BASE64_LENGTH = 5_600_000;

/** 사용자별 포스터 스캔 일일 호출 상한 - 이미지 입력 토큰 비용이 높고 토너먼트 등록당 1회면 충분한 보조 기능이므로 gtoAdvice보다 엄격하게 설정 */
const DAILY_CALL_LIMIT_POSTER_SCAN = 5;

/** 날짜 형식("YYYY-MM-DD") 검증용 정규식 */
const DATE_FORMAT_REGEX = /^\d{4}-\d{2}-\d{2}$/;

/**
 * 오늘 날짜를 "YYYY-MM-DD" 형식으로 반환하는 헬퍼.
 * Firestore 문서 ID로 사용해 날짜별 카운터를 관리한다.
 */
function getTodayDateString(): string {
  return new Date().toISOString().split("T")[0];
}

/**
 * 사용자의 오늘 포스터 스캔 호출 횟수를 확인하고 한도를 초과하면 예외를 던진다.
 * 한도 이내면 카운터를 1 증가시킨 후 반환한다.
 *
 * Firestore 경로: users/{userId}/poster_scan_usage/{YYYY-MM-DD}
 * 필드: count (숫자)
 */
async function checkAndIncrementDailyUsage(userId: string): Promise<void> {
  const db = getFirestore();
  const today = getTodayDateString();
  const usageRef = db.doc(`users/${userId}/poster_scan_usage/${today}`);

  await db.runTransaction(async (txn) => {
    const snapshot = await txn.get(usageRef);
    const currentCount: number = snapshot.exists ? (snapshot.data()?.count ?? 0) : 0;

    if (currentCount >= DAILY_CALL_LIMIT_POSTER_SCAN) {
      throw new HttpsError(
        "resource-exhausted",
        `일일 포스터 스캔 한도(${DAILY_CALL_LIMIT_POSTER_SCAN}회)에 도달했습니다.`,
      );
    }

    txn.set(
      usageRef,
      { count: FieldValue.increment(1), updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  });
}

const POSTER_SCAN_PROMPT = [
  "당신은 포커 토너먼트 포스터/공지 이미지를 분석하는 AI입니다.",
  "이미지에서 다음 3가지 정보를 추출해 순수 JSON 형식으로만 응답하세요.",
  "다른 설명 텍스트, 마크다운 코드블록을 절대 포함하지 마세요.",
  "",
  "추출 항목:",
  "- name: 토너먼트명 또는 행사명 (문자열, 인식 불가 시 null)",
  "- date: 토너먼트 개최 날짜 (YYYY-MM-DD 형식 문자열, 인식 불가 시 null)",
  "- buyIn: 바이인 금액 (숫자만, 화폐 기호/콤마 제외, 인식 불가 시 null)",
  "",
  "응답 예시: {\"name\": \"WSOP Main Event\", \"date\": \"2026-07-15\", \"buyIn\": 10000}",
  "정보가 이미지에 없으면 추측하지 말고 반드시 null로 응답하세요.",
].join("\n");

// 마크다운 코드블록 펜스(백틱 3개)를 안전하게 표현 - 정규식 문자열 안에 직접 적지 않기 위함
const MARKDOWN_FENCE = String.fromCharCode(96, 96, 96);
// Gemini 응답이 코드블록으로 감싸져 오는 경우를 벗겨내는 정규식 (json 라벨 유무 모두 매칭)
const CODE_BLOCK_REGEX = new RegExp(MARKDOWN_FENCE + "(?:json)?\\s*([\\s\\S]*?)\\s*" + MARKDOWN_FENCE, "i");

/**
 * Gemini 응답 원문에서 포스터 정보 JSON을 안전하게 파싱하는 순수 함수.
 * 코드블록을 벗기고 첫 중괄호~마지막 중괄호 구간만 추출해 JSON.parse 시도,
 * 실패 시 예외 대신 전부 null인 결과를 반환해 graceful degradation 한다.
 */
export function parsePosterScanJson(rawText: string): ParsedPosterInfo {
  const fallback: ParsedPosterInfo = { name: null, date: null, buyIn: null };

  const codeBlockMatch = rawText.match(CODE_BLOCK_REGEX);
  const withoutCodeBlock = codeBlockMatch ? codeBlockMatch[1] : rawText;

  const firstBrace = withoutCodeBlock.indexOf("{");
  const lastBrace = withoutCodeBlock.lastIndexOf("}");
  if (firstBrace === -1 || lastBrace === -1 || firstBrace > lastBrace) {
    return fallback;
  }
  const jsonCandidate = withoutCodeBlock.slice(firstBrace, lastBrace + 1);

  let parsed: unknown;
  try {
    parsed = JSON.parse(jsonCandidate);
  } catch {
    return fallback;
  }

  if (typeof parsed !== "object" || parsed === null) {
    return fallback;
  }
  const record = parsed as Record<string, unknown>;

  const name = typeof record.name === "string" && record.name.trim() !== "" ? record.name : null;

  const date =
    typeof record.date === "string" && DATE_FORMAT_REGEX.test(record.date) ? record.date : null;

  const buyIn =
    typeof record.buyIn === "number" && isFinite(record.buyIn) ? record.buyIn : null;

  return { name, date, buyIn };
}

/** 인식 결과를 바탕으로 사용자 안내 warning 메시지를 결정 (3개 인식: null, 0개: 전체 실패, 그 외: 부분 인식) */
function buildWarningMessage(info: ParsedPosterInfo): string | null {
  const recognizedCount = [info.name, info.date, info.buyIn].filter((v) => v !== null).length;

  if (recognizedCount === 3) {
    return null;
  }
  if (recognizedCount === 0) {
    return "이미지에서 정보를 추출하지 못했습니다. 직접 입력해 주세요.";
  }
  return "일부 정보만 인식되었습니다. 나머지는 직접 입력해 주세요.";
}

/**
 * 포스터 이미지를 받아 Gemini Flash Vision으로 토너먼트명/날짜/바이인을 추출하는 Cloud Function.
 * 인증 확인 -> 입력 검증 -> 일일 한도 확인 -> Gemini 호출 -> JSON 파싱 -> 결과 반환 순으로 처리한다.
 */
export const scanPoster = onCall<ScanPosterRequest>(async (request) => {
  // 인증되지 않은 호출 차단 (CLAUDE.md 보안 규칙)
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "로그인이 필요한 기능입니다.");
  }

  // -- 입력 검증 --------------------------------------------------
  const imageBase64 = request.data?.imageBase64;
  if (!imageBase64 || typeof imageBase64 !== "string" || imageBase64.trim() === "") {
    throw new HttpsError("invalid-argument", "분석할 이미지 데이터가 비어 있습니다.");
  }

  if (imageBase64.length > MAX_IMAGE_BASE64_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      "이미지 용량이 너무 큽니다. 더 작은 이미지로 다시 시도해 주세요.",
    );
  }

  // mimeType이 허용 목록에 없으면 거부 (Vertex AI가 지원하지 않는 형식 사전 차단)
  const mimeType = request.data?.mimeType;
  if (!mimeType || !ALLOWED_MIME_TYPES.includes(mimeType)) {
    throw new HttpsError(
      "invalid-argument",
      `지원하지 않는 이미지 형식입니다. 허용값: ${ALLOWED_MIME_TYPES.join(", ")}`,
    );
  }

  // -- 일일 호출 한도 확인 (HttpsError resource-exhausted 발생 시 그대로 상위로 전파) --
  await checkAndIncrementDailyUsage(request.auth.uid);

  // -- Gemini Flash Vision 호출 (logAgentExecution으로 감싸 XPRIZE 증빙 자동 기록) --
  try {
    const response = await logAgentExecution({
      userId: request.auth.uid,
      agentTask: "poster_scan",
      modelName: FLASH_MODEL_NAME,
      fn: async () => {
        const { text, inputTokenCount, outputTokenCount } = await callGeminiFlashVision(
          POSTER_SCAN_PROMPT,
          imageBase64,
          mimeType,
        );

        const { name, date, buyIn } = parsePosterScanJson(text);
        const warning = buildWarningMessage({ name, date, buyIn });
        const output: ScanPosterResponse = { name, date, buyIn, warning };

        return {
          output,
          reasoningSummary: `이미지에서 토너먼트명/날짜/바이인 추출 시도 - 인식 결과: name=${name !== null}, date=${date !== null}, buyIn=${buyIn !== null}`,
          inputTokenCount,
          outputTokenCount,
        };
      },
    });

    return response;
  } catch (error) {
    // logAgentExecution이 이미 실패 로그를 agent_execution_logs에 기록하므로 여기서는 안전한 메시지만 전달
    console.error("포스터 스캔 실패:", error);
    throw new HttpsError(
      "internal",
      "포스터 분석 중 오류가 발생했습니다. 잠시 후 다시 시도하거나 직접 입력해 주세요.",
    );
  }
});
