# Firestore 스키마 — `agent_execution_logs`

> 작성일: 2026-06-08 | 버전: v1 | 상태: Draft
> 참조: `docs/design-docs/architecture-v1.md` (5번 데이터 흐름), CLAUDE.md (XPRIZE 증빙 요건)
> 관련 작업: `docs/exec-plans/active/phase1-foundation.md` — 작업그룹 5

---

## 1. 목적

XPRIZE 해커톤은 "AI 에이전트가 프로덕션에서 핵심 의사결정을 수행하는 실제 비즈니스" 증빙을 요구한다.
이 컬렉션은 **Vertex AI/Gemini 호출이 발생할 때마다 자동으로 기록되는 운영 로그**로,
다음 두 가지 역할을 동시에 수행한다.

1. **XPRIZE 증빙**: 분석 시작 시간·판단 근거·토큰 수·발행 결과 상태를 누적해 "AI가 실제로
   주간 리포트를 자동 발행했다"는 사실을 객관적으로 입증
2. **운영 모니터링**: 실패율·평균 토큰 사용량·비용 추정치를 추적해 Gemini Flash → Pro 전환
   판단(품질 부족 시 부분 전환 검토, 2026-06-08 결정)의 근거 데이터로 활용

**호출 시점**: Cloud Functions가 Vertex AI/Gemini API를 호출하는 모든 지점
(포스터 스캔, 리크 분석, 주간 리포트 생성)에서 호출 직후 — 성공/실패 여부와 무관하게 — 1건씩 기록한다.

---

## 2. 컬렉션 경로 및 문서 구조

```
agent_execution_logs/{logId}
```

- `logId`: Firestore 자동 생성 문서 ID (UUID 형태) — 별도 규칙 부여하지 않음
- 최상위 컬렉션으로 둔다 (특정 유저 서브컬렉션이 아님) — 운영자 관점에서 전체 실행 이력을
  시간순/상태별로 가로질러 조회해야 하므로 (예: "이번 주 실패한 리포트 발행 전체 조회")

---

## 3. 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `userId` | `string` | ✅ | 분석 대상 사용자의 UID (Firebase Auth UID, `users` 컬렉션 참조). 시스템 점검성 호출(유저 무관)인 경우 `"system"` |
| `agentTask` | `string` | ✅ | 실행된 작업 종류 — 아래 4번 "작업 종류 Enum" 참조 |
| `modelName` | `string` | ✅ | 호출에 사용된 모델 식별자 (예: `"gemini-2.5-flash"`). Flash→Pro 전환 추적의 핵심 필드 |
| `startedAt` | `Timestamp` | ✅ | **분석 시작 시간** — Vertex AI 호출 직전 기록 (XPRIZE 증빙 핵심 필드) |
| `completedAt` | `Timestamp \| null` | — | 분석 종료 시간 — 호출 완료(성공/실패 무관) 직후 기록. 타임아웃 등으로 콜백이 누락되면 `null`로 남을 수 있음 |
| `durationMs` | `number \| null` | — | `completedAt - startedAt` (밀리초). 응답 지연 모니터링용 |
| `reasoningSummary` | `string` | ✅ | **판단 근거** — AI가 어떤 입력 데이터를 바탕으로 어떤 결론/출력을 생성했는지 1~3문장 요약 (XPRIZE 증빙 핵심 필드, 한글로 기록) |
| `inputTokenCount` | `number` | ✅ | 입력 토큰 수 |
| `outputTokenCount` | `number` | ✅ | 출력 토큰 수 |
| `totalTokenCount` | `number` | ✅ | **토큰 수** — `inputTokenCount + outputTokenCount` (XPRIZE 증빙 핵심 필드, 비용 추적의 기준값) |
| `estimatedCostUsd` | `number \| null` | — | 토큰 수 × 모델별 단가로 산출한 추정 비용(USD). 모델별 단가표는 Cloud Functions 내 상수로 관리 |
| `status` | `string` | ✅ | **발행 결과 상태** — `"success"` \| `"failed"` \| `"partial"` (XPRIZE 증빙 핵심 필드) |
| `resultRef` | `DocumentReference \| null` | — | 생성된 결과물(주간 리포트, 스캔 결과 등)의 Firestore 문서 참조. 실패 시 `null` |
| `errorMessage` | `string \| null` | — | 실패(`status: "failed"`) 또는 부분 성공(`"partial"`) 시 캡처된 에러 메시지 (try-catch 블록에서 기록) |
| `createdAt` | `Timestamp` | ✅ | 로그 문서 생성 시각 — Firestore 서버 타임스탬프(`FieldValue.serverTimestamp()`) 사용 |

---

## 4. 작업 종류 Enum (`agentTask`)

| 값 | 설명 | 관련 Tier |
|----|------|-----------|
| `"poster_scan"` | 대회 포스터/정보 이미지 업로드 → AI 스캔 | Plus |
| `"leak_analysis"` | 누적 핸드 데이터 기반 유저 약점(Leak) 분석 | Pro |
| `"weekly_report"` | 주간 리포트 자동 생성·발행 | Pro |
| `"hand_coaching"` | 개인 맞춤형 핸드레인지·솔루션 코칭 | Pro |

> 새 작업 종류가 추가되면 이 Enum 표와 Cloud Functions 내 상수를 함께 갱신한다 (값 누락 방지).

---

## 5. 작성 예시 (JSON)

**성공 케이스 (주간 리포트 발행)**
```json
{
  "userId": "uid_abc123",
  "agentTask": "weekly_report",
  "modelName": "gemini-2.5-flash",
  "startedAt": "2026-06-08T19:00:00Z",
  "completedAt": "2026-06-08T19:00:42Z",
  "durationMs": 42000,
  "reasoningSummary": "최근 4주간 BTN 포지션 3-bet 빈도가 GTO 권장치 대비 35% 낮게 나타나 해당 리크를 핵심 개선 포인트로 선정함",
  "inputTokenCount": 8200,
  "outputTokenCount": 1450,
  "totalTokenCount": 9650,
  "estimatedCostUsd": 0.0021,
  "status": "success",
  "resultRef": "/weekly_reports/report_xyz789",
  "errorMessage": null,
  "createdAt": "2026-06-08T19:00:42Z"
}
```

**실패 케이스 (포스터 스캔 — API 타임아웃)**
```json
{
  "userId": "uid_def456",
  "agentTask": "poster_scan",
  "modelName": "gemini-2.5-flash",
  "startedAt": "2026-06-08T10:15:00Z",
  "completedAt": "2026-06-08T10:15:30Z",
  "durationMs": 30000,
  "reasoningSummary": "이미지 업로드는 수신했으나 Vertex AI 응답 타임아웃으로 분석 미완료",
  "inputTokenCount": 0,
  "outputTokenCount": 0,
  "totalTokenCount": 0,
  "estimatedCostUsd": null,
  "status": "failed",
  "resultRef": null,
  "errorMessage": "DeadlineExceeded: Vertex AI 응답 시간 초과 (30s)",
  "createdAt": "2026-06-08T10:15:30Z"
}
```

---

## 6. 인덱스 설계 (Firestore 복합 인덱스)

운영 모니터링 및 유저별 이력 조회를 위해 아래 복합 인덱스를 등록한다 (`firestore.indexes.json`):

| 용도 | 필드 조합 |
|------|-----------|
| 특정 유저의 실행 이력을 최신순 조회 | `userId` (asc) + `startedAt` (desc) |
| 실패 건만 모아 모니터링 | `status` (asc) + `startedAt` (desc) |
| 작업 종류별 운영 통계 집계 | `agentTask` (asc) + `startedAt` (desc) |

---

## 7. 보안 규칙 (Firestore Security Rules) 방향

- **클라이언트(Flutter 앱)에서는 쓰기 금지** — 이 컬렉션은 Cloud Functions(서버 환경)에서만 기록한다.
  앱은 자신의 `userId`에 해당하는 문서만 **읽기** 가능하도록 제한 (마이페이지 등에서 "내 분석 이력" 노출 시).
- 운영자(관리자) 전용 대시보드가 생기기 전까지는 전체 컬렉션 읽기를 일반 유저에게 허용하지 않는다.

```
match /agent_execution_logs/{logId} {
  allow read: if request.auth != null && request.auth.uid == resource.data.userId;
  allow write: if false; // Cloud Functions(Admin SDK)만 기록 — 클라이언트 쓰기 전면 차단
}
```

---

## 8. 공통 로깅 유틸리티 설계 방향

Cloud Functions 내 `functions/src/utils/agentExecutionLogger.ts`(가칭) 형태의 공통 함수로 구현해
모든 Vertex AI 호출 지점에서 재사용한다 (CLAUDE.md "모든 외부 API 호출에 try-catch 필수" 준수).

```
async function logAgentExecution({ userId, agentTask, modelName, fn }):
  startedAt = now()
  try:
    result = await fn()  // 실제 Vertex AI 호출
    완료 시각·토큰 수·판단 근거를 결과에서 추출
    status = "success"
  catch (error):
    status = "failed"
    errorMessage = error.message
  finally:
    agent_execution_logs 컬렉션에 1건 기록 (성공/실패 모두)
    return result (또는 에러 재전파)
```

> 한글 주석 예시 — "// Vertex AI 호출 결과에서 토큰 사용량을 추출해 비용을 계산한다 (Flash 단가 기준)"
> 처럼, 포커 도메인 외에도 AI 호출·과금 로직에는 초보자가 이해할 수 있도록 한글 주석을 상세히 단다.

---

## 9. 향후 검토 사항

- `estimatedCostUsd` 산출에 사용할 모델별 단가표는 Vertex AI 가격 정책 변경 시 갱신 필요 — 단가표 자체는
  코드 상수가 아닌 별도 설정값(Remote Config 또는 Firestore `config` 문서)으로 분리하는 것을 P1에서 검토
- Pro 계열로 부분 전환 시 `modelName` 값에 `"gemini-2.5-pro"`가 혼재하게 되므로, 운영 대시보드에서
  모델별 비용·정확도 비교 리포트를 P2(검증 단계)에서 구성
