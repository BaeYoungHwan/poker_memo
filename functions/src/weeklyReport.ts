import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { callGeminiFlash, FLASH_MODEL_NAME } from "./ai/geminiClient";
import { logAgentExecution } from "./utils/agentExecutionLogger";

/** 분석 대상 기간(일) */
const ANALYSIS_WINDOW_DAYS = 7;

/** 유저당 최대 분석 핸드 수 — Vertex AI 비용 제어 */
const MAX_MEMOS_PER_USER = 50;

interface WeeklyReportResult {
  reportId: string;
  handsAnalyzed: number;
  topLeaks: string[];
  reportText: string;
}

/**
 * 단일 유저의 주간 리포트를 생성하고 Firestore에 저장한다.
 * weeklyReport(스케줄)와 generateWeeklyReportForUser(callable) 양쪽에서 공유.
 */
async function buildReportForUser(userId: string): Promise<WeeklyReportResult> {
  const db = getFirestore();

  const weekStart = new Date();
  weekStart.setDate(weekStart.getDate() - ANALYSIS_WINDOW_DAYS);
  weekStart.setHours(0, 0, 0, 0);

  const memosSnap = await db
    .collection("users")
    .doc(userId)
    .collection("hand_memos")
    .where("createdAt", ">=", Timestamp.fromDate(weekStart))
    .orderBy("createdAt", "desc")
    .limit(MAX_MEMOS_PER_USER)
    .get();

  if (memosSnap.empty) {
    throw new Error("분석할 핸드 메모가 없습니다.");
  }

  const memos = memosSnap.docs.map((d) => d.data());

  // 포지션별 빈도 집계
  const positionCounts: Record<string, number> = {};
  const memoLines: string[] = [];

  for (const memo of memos) {
    const pos = (memo["position"] as string | undefined)?.toUpperCase() ?? "?";
    positionCounts[pos] = (positionCounts[pos] ?? 0) + 1;
    if (memo["noteText"]) {
      memoLines.push(`[${pos}] ${memo["noteText"]}`);
    }
  }

  const positionSummary = Object.entries(positionCounts)
    .sort(([, a], [, b]) => b - a)
    .map(([pos, cnt]) => `${pos}: ${cnt}핸드`)
    .join(", ");

  const prompt = [
    "당신은 포커 코칭 전문가입니다.",
    `아래는 플레이어가 최근 ${ANALYSIS_WINDOW_DAYS}일간 기록한 핸드 메모 ${memos.length}건입니다.`,
    "",
    `포지션별 플레이 빈도: ${positionSummary}`,
    "",
    "핸드 메모 (최대 20건):",
    ...memoLines.slice(0, 20).map((t, i) => `${i + 1}. ${t}`),
    "",
    "위 데이터를 분석하여 다음 형식으로 한국어 주간 리포트를 작성해주세요:",
    "1. 이번 주 요약 (2~3문장)",
    "2. 상위 약점(Leak) 3가지 (각 항목은 '-'로 시작, 1~2문장)",
    "3. 다음 주 개선 포인트 (1~2문장)",
  ].join("\n");

  const reportRef = db
    .collection("users")
    .doc(userId)
    .collection("weekly_reports")
    .doc();

  const reportText = await logAgentExecution({
    userId,
    agentTask: "weekly_report",
    modelName: FLASH_MODEL_NAME,
    fn: async () => {
      const { text, inputTokenCount, outputTokenCount } = await callGeminiFlash(prompt);
      const topLeaks = extractTopLeaks(text);

      await reportRef.set({
        generatedAt: FieldValue.serverTimestamp(),
        weekStart: Timestamp.fromDate(weekStart),
        handsAnalyzed: memos.length,
        topLeaks,
        reportText: text,
        status: "success",
        createdAt: FieldValue.serverTimestamp(),
      });

      return {
        output: text,
        reasoningSummary:
          `${memos.length}건 핸드 메모(${positionSummary})를 분석해 ` +
          `Gemini Flash가 주간 Leak 리포트 생성. 상위 약점 ${topLeaks.length}개 추출.`,
        inputTokenCount,
        outputTokenCount,
        resultRef: reportRef,
      };
    },
  });

  const savedSnap = await reportRef.get();
  const savedData = savedSnap.data() ?? {};

  return {
    reportId: reportRef.id,
    handsAnalyzed: memos.length,
    topLeaks: (savedData["topLeaks"] as string[] | undefined) ?? [],
    reportText,
  };
}

/** 리포트 텍스트에서 '-'로 시작하는 약점 항목을 최대 3개 추출 */
function extractTopLeaks(reportText: string): string[] {
  const lines = reportText.split("\n").map((l) => l.trim());
  const leaks: string[] = [];

  for (const line of lines) {
    if (line.startsWith("-") && line.length > 2) {
      leaks.push(line.replace(/^-\s*/, "").trim());
      if (leaks.length >= 3) break;
    }
  }

  // '-' 패턴 없으면 비어 있지 않은 첫 3줄 반환
  if (leaks.length === 0) {
    return lines.filter(Boolean).slice(0, 3);
  }
  return leaks;
}

/**
 * 주간 리포트 스케줄 함수 — 매주 월요일 09:00 KST (00:00 UTC).
 * 최근 7일간 핸드 메모를 남긴 모든 활성 유저의 리포트를 일괄 생성.
 */
export const weeklyReport = onSchedule(
  { schedule: "0 0 * * 1", timeZone: "UTC" },
  async (_event) => {
    const db = getFirestore();
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - ANALYSIS_WINDOW_DAYS);

    // collectionGroup으로 활성 유저 UID 수집
    const memosSnap = await db
      .collectionGroup("hand_memos")
      .where("createdAt", ">=", Timestamp.fromDate(weekAgo))
      .select("userId")
      .get();

    const userIds = [...new Set(
      memosSnap.docs
        .map((d) => d.data()["userId"] as string | undefined)
        .filter((uid): uid is string => !!uid),
    )];

    console.log(`주간 리포트 생성 대상 유저: ${userIds.length}명`);

    for (const userId of userIds) {
      try {
        await buildReportForUser(userId);
        console.log(`리포트 생성 완료: ${userId}`);
      } catch (err) {
        // 개별 유저 실패가 전체 스케줄을 멈추지 않도록 continue
        console.error(`리포트 생성 실패 (${userId}):`, err);
      }
    }
  },
);

/**
 * 수동 리포트 생성 callable — Pro 유저가 앱에서 직접 요청.
 * 오늘 이미 생성된 리포트가 있으면 재생성 없이 기존 리포트를 반환한다.
 */
export const generateWeeklyReportForUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "로그인이 필요한 기능입니다.");
  }

  const userId = request.auth.uid;
  const db = getFirestore();

  // 오늘 이미 생성된 리포트 확인
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const existingSnap = await db
    .collection("users")
    .doc(userId)
    .collection("weekly_reports")
    .where("generatedAt", ">=", Timestamp.fromDate(todayStart))
    .orderBy("generatedAt", "desc")
    .limit(1)
    .get();

  if (!existingSnap.empty) {
    const d = existingSnap.docs[0].data();
    return {
      reportId: existingSnap.docs[0].id,
      handsAnalyzed: d["handsAnalyzed"] as number ?? 0,
      topLeaks: d["topLeaks"] as string[] ?? [],
      reportText: d["reportText"] as string ?? "",
    };
  }

  try {
    return await buildReportForUser(userId);
  } catch (err) {
    if (err instanceof Error && err.message.includes("분석할 핸드 메모가 없습니다")) {
      throw new HttpsError(
        "failed-precondition",
        "최근 7일간 기록된 핸드 메모가 없습니다. 핸드를 기록한 후 다시 시도해 주세요.",
      );
    }
    console.error("주간 리포트 생성 실패:", err);
    throw new HttpsError("internal", "리포트 생성 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.");
  }
});
