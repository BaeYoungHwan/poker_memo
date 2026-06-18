import { VertexAI, Part } from "@google-cloud/vertexai";

/**
 * 비용 효율을 위해 기본적으로 Gemini Flash 계열을 사용한다 (CLAUDE.md 기술 스택 규칙).
 * 품질이 부족한 영역이 확인되면 이 상수를 Pro 계열로 부분 전환 검토.
 */
export const FLASH_MODEL_NAME = "gemini-2.5-flash";

/** Vertex AI 호출 결과 — 응답 텍스트와 토큰 사용량을 함께 담는다 (로깅 유틸리티가 그대로 사용) */
export interface GeminiCallResult {
  text: string;
  inputTokenCount: number;
  outputTokenCount: number;
}

let vertexAi: VertexAI | null = null;

/** VertexAI 클라이언트는 최초 호출 시 1회만 생성해 재사용한다 (콜드 스타트 비용 절감) */
function getVertexAi(): VertexAI {
  if (!vertexAi) {
    vertexAi = new VertexAI({
      project: process.env.GCLOUD_PROJECT,
      // Firestore와 동일한 리전으로 맞춰 지연 시간을 최소화한다
      location: "asia-northeast3",
    });
  }
  return vertexAi;
}

/**
 * Gemini Flash 모델에 멀티모달 `parts`(텍스트/이미지 등)를 보내고
 * 응답 텍스트·토큰 사용량을 추출하는 공통 내부 헬퍼.
 *
 * `callGeminiFlash`(텍스트 전용)와 `callGeminiFlashVision`(텍스트+이미지)이
 * 이 함수를 공유해 응답 파싱 로직 중복을 없앤다.
 */
async function generateContentInternal(parts: Part[]): Promise<GeminiCallResult> {
  const model = getVertexAi().getGenerativeModel({ model: FLASH_MODEL_NAME });

  const response = await model.generateContent({
    contents: [{ role: "user", parts }],
  });

  const candidate = response.response.candidates?.[0];
  const text = candidate?.content?.parts?.map((part) => part.text ?? "").join("") ?? "";

  // 토큰 사용량은 응답의 usageMetadata에서 추출한다 (비용 계산의 기준값)
  const usage = response.response.usageMetadata;
  const inputTokenCount = usage?.promptTokenCount ?? 0;
  const outputTokenCount = usage?.candidatesTokenCount ?? 0;

  if (!text) {
    throw new Error("Gemini 응답에서 텍스트를 추출하지 못했습니다.");
  }

  return { text, inputTokenCount, outputTokenCount };
}

/**
 * Gemini Flash 모델에 단일 프롬프트를 보내고 응답 텍스트·토큰 사용량을 반환하는 최소 골격.
 *
 * 실제 리크 분석·주간 리포트·포스터 스캔 등은 이 함수를 기반으로 프롬프트만 바꿔 확장한다.
 * 호출 실패(타임아웃, 응답 형식 오류 등) 시 예외를 그대로 던지며,
 * 호출부(`logAgentExecution`)에서 일괄적으로 try-catch 및 로깅을 담당한다.
 */
export async function callGeminiFlash(prompt: string): Promise<GeminiCallResult> {
  try {
    return await generateContentInternal([{ text: prompt }]);
  } catch (error) {
    // 호출부에서 상태(failed)와 에러 메시지를 일괄 기록하므로 여기서는 그대로 재전파한다
    throw error instanceof Error ? error : new Error(String(error));
  }
}

/**
 * Gemini Flash 모델에 텍스트 프롬프트 + 이미지(base64)를 함께 보내는 멀티모달 호출 함수.
 * 토너먼트 포스터 스캔처럼 이미지 인식이 필요한 기능에서 사용한다.
 *
 * @param prompt 이미지와 함께 전달할 지시문(텍스트)
 * @param imageBase64 순수 base64 인코딩 이미지 데이터 (data URI 접두사 제외)
 * @param mimeType 이미지 MIME 타입 (예: "image/jpeg")
 */
export async function callGeminiFlashVision(
  prompt: string,
  imageBase64: string,
  mimeType: string,
): Promise<GeminiCallResult> {
  try {
    return await generateContentInternal([
      { text: prompt },
      { inlineData: { mimeType, data: imageBase64 } },
    ]);
  } catch (error) {
    // 호출부에서 상태(failed)와 에러 메시지를 일괄 기록하므로 여기서는 그대로 재전파한다
    throw error instanceof Error ? error : new Error(String(error));
  }
}
