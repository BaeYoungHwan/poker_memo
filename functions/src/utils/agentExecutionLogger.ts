import { getFirestore, FieldValue, DocumentReference } from "firebase-admin/firestore";

/**
 * AI 에이전트가 수행하는 작업 종류
 * (docs/design-docs/firestore-schema-agent-execution-logs.md §4 Enum과 동일하게 유지)
 * 새 작업이 추가되면 이 타입과 스키마 문서를 함께 갱신한다.
 */
export type AgentTask =
  | "poster_scan"
  | "leak_analysis"
  | "weekly_report"
  | "hand_coaching";

/** 에이전트 실행 결과 상태 — 스키마 문서 §3 `status` 정의와 동일 */
export type AgentExecutionStatus = "success" | "failed" | "partial";

/**
 * 모델별 1,000 토큰당 단가(USD) — Vertex AI 가격 정책 변경 시 갱신 필요
 * (스키마 문서 §9 "향후 검토 사항"에 따라, 추후 Firestore `config` 문서 등 외부 설정으로 분리 검토)
 */
const MODEL_PRICING_USD_PER_1K_TOKENS: Record<string, { input: number; output: number }> = {
  "gemini-2.5-flash": { input: 0.000_075, output: 0.0003 },
};

/**
 * 토큰 사용량으로 추정 비용(USD)을 계산한다.
 * 단가표에 없는 모델이면 비용을 추정할 수 없으므로 null을 반환한다.
 */
function estimateCostUsd(
  modelName: string,
  inputTokenCount: number,
  outputTokenCount: number,
): number | null {
  const pricing = MODEL_PRICING_USD_PER_1K_TOKENS[modelName];
  if (!pricing) {
    return null;
  }
  const inputCost = (inputTokenCount / 1000) * pricing.input;
  const outputCost = (outputTokenCount / 1000) * pricing.output;
  return inputCost + outputCost;
}

/** 실제 Vertex AI 호출 함수가 반환해야 하는 형태 — 로깅에 필요한 정보를 함께 담는다 */
export interface AgentExecutionOutcome<T> {
  /** 호출 결과로 화면/후속 로직에 전달할 실제 데이터 */
  output: T;
  /** 판단 근거 — AI가 어떤 입력을 바탕으로 어떤 결론을 냈는지 1~3문장 한글 요약 (XPRIZE 증빙 핵심 필드) */
  reasoningSummary: string;
  inputTokenCount: number;
  outputTokenCount: number;
  /** 생성된 결과물(주간 리포트 등)의 Firestore 문서 참조 — 없으면 생략 */
  resultRef?: DocumentReference;
}

interface LogAgentExecutionParams<T> {
  /** 분석 대상 사용자 UID. 유저와 무관한 시스템 점검성 호출이면 "system" */
  userId: string;
  agentTask: AgentTask;
  /** 호출에 사용한 모델 식별자 (예: "gemini-2.5-flash") */
  modelName: string;
  /** 실제 Vertex AI 호출을 수행하고 [AgentExecutionOutcome]을 반환하는 함수 */
  fn: () => Promise<AgentExecutionOutcome<T>>;
}

/**
 * Vertex AI(Gemini) 호출을 감싸 실행 시작/종료/결과를 `agent_execution_logs`에
 * 무조건 자동 기록하는 공통 유틸리티.
 *
 * - 성공/실패 관계없이 항상 로그 1건을 남긴다 (XPRIZE 운영 증빙 요구사항).
 * - 호출 자체가 실패해도 로그 기록 실패가 상위 흐름을 막지 않도록 별도로 try-catch한다.
 *
 * 사용 예:
 * ```ts
 * const memo = await logAgentExecution({
 *   userId,
 *   agentTask: "leak_analysis",
 *   modelName: "gemini-2.5-flash",
 *   fn: async () => {
 *     const { text, inputTokenCount, outputTokenCount } = await callGeminiFlash(prompt);
 *     return { output: text, reasoningSummary: "...", inputTokenCount, outputTokenCount };
 *   },
 * });
 * ```
 */
export async function logAgentExecution<T>({
  userId,
  agentTask,
  modelName,
  fn,
}: LogAgentExecutionParams<T>): Promise<T> {
  const db = getFirestore();
  const startedAt = new Date();

  let status: AgentExecutionStatus;
  let outcome: AgentExecutionOutcome<T> | null = null;
  let errorMessage: string | null = null;

  try {
    // 실제 Vertex AI 호출 — 실패하면 catch에서 failed로 기록한다
    outcome = await fn();
    status = "success";
  } catch (error) {
    status = "failed";
    errorMessage = error instanceof Error ? error.message : String(error);
  }

  const completedAt = new Date();
  const durationMs = completedAt.getTime() - startedAt.getTime();
  const inputTokenCount = outcome?.inputTokenCount ?? 0;
  const outputTokenCount = outcome?.outputTokenCount ?? 0;
  const totalTokenCount = inputTokenCount + outputTokenCount;

  try {
    // 로그 기록 자체가 실패해도 본 호출 흐름(성공/실패 반환)에는 영향을 주지 않도록 별도 처리
    await db.collection("agent_execution_logs").add({
      userId,
      agentTask,
      modelName,
      startedAt,
      completedAt,
      durationMs,
      reasoningSummary: outcome?.reasoningSummary ?? "호출 실패로 판단 근거를 생성하지 못함",
      inputTokenCount,
      outputTokenCount,
      totalTokenCount,
      estimatedCostUsd:
        status === "success" ? estimateCostUsd(modelName, inputTokenCount, outputTokenCount) : null,
      status,
      resultRef: outcome?.resultRef ?? null,
      errorMessage,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (logError) {
    // 로깅 실패는 콘솔에만 남기고 무시 — 운영 로그 누락이 사용자 응답을 막아서는 안 됨
    console.error("agent_execution_logs 기록 실패:", logError);
  }

  if (status === "failed" || !outcome) {
    throw new Error(errorMessage ?? "AI 에이전트 호출에 실패했습니다.");
  }

  return outcome.output;
}
