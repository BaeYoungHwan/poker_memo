import { initializeApp } from "firebase-admin/app";
import { onCall, HttpsError } from "firebase-functions/v2/https";

import { callGeminiFlash, FLASH_MODEL_NAME } from "./ai/geminiClient";
import { logAgentExecution } from "./utils/agentExecutionLogger";

initializeApp();

interface AnalyzeLeakRequest {
  /** 사용자가 기록한 핸드 메모 원문 (분석 대상) */
  handMemoText: string;
}

/**
 * 핸드 메모 최대 허용 길이(자) — Vertex AI 토큰 비용이 입력 길이에 비례해 늘어나므로
 * GCP/Firebase 비용을 $300 평가판 한도 내로 제한하기 위한 안전장치로 둔다.
 * (한 핸드를 설명하는 메모는 보통 수백 자 내외이므로 2,000자면 충분히 여유 있는 상한선)
 */
const MAX_HAND_MEMO_LENGTH = 2000;

/**
 * 핸드 메모를 받아 Gemini Flash로 리크(약점)를 분석하는 최소 골격 (Pro 티어 핵심 기능의 출발점).
 *
 * 흐름: 인증 확인 → 입력 검증 → `logAgentExecution`으로 감싼 Vertex AI 호출 →
 *       성공/실패 관계없이 `agent_execution_logs`에 자동 기록 → 결과 반환
 *
 * 실제 운영에서는 프롬프트에 누적 핸드 데이터·포지션별 통계 등을 더 정교하게 반영하도록 확장한다.
 */
export const analyzeLeak = onCall<AnalyzeLeakRequest>(async (request) => {
  // 인증되지 않은 호출은 차단 (CLAUDE.md 보안 규칙: 본인 데이터만 접근 가능)
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "로그인이 필요한 기능입니다.");
  }

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

  const userId = request.auth.uid;
  const prompt = [
    "당신은 포커 코칭 전문가입니다. 아래 핸드 메모를 읽고,",
    "플레이어의 의사결정에서 드러나는 리크(약점)를 한국어로 1~3문장으로 짧게 분석해 주세요.",
    "",
    `핸드 메모: ${handMemoText}`,
  ].join("\n");

  try {
    const analysisText = await logAgentExecution({
      userId,
      agentTask: "leak_analysis",
      modelName: FLASH_MODEL_NAME,
      fn: async () => {
        const { text, inputTokenCount, outputTokenCount } = await callGeminiFlash(prompt);
        return {
          output: text,
          // XPRIZE 증빙용 판단 근거 — 입력 데이터와 산출 결과를 한글로 요약
          reasoningSummary: `사용자가 입력한 핸드 메모를 바탕으로 Gemini Flash가 리크 분석 결과를 생성함 (입력 길이 ${handMemoText.length}자)`,
          inputTokenCount,
          outputTokenCount,
        };
      },
    });

    return { analysis: analysisText };
  } catch (error) {
    // logAgentExecution이 이미 실패 로그를 기록했으므로, 여기서는 클라이언트에 안전한 에러만 전달
    console.error("리크 분석 실패:", error);
    throw new HttpsError("internal", "리크 분석 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.");
  }
});
