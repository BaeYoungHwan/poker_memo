# Phase 2 — GTO/ICM 내부 로직 프로토타입

> 상태: ✅ 내부 구현 확정 (Go) / gtoAdvice 연동 검증은 보류
> 생성일: 2026-06-09
> Go/No-Go 결정일: **2026-06-25** (검증 통과 → 내부 구현 확정, 실패 → 외부 API 전환)
> 검증 완료일: 2026-06-11

---

## 목표

2026-06-25 Go/No-Go 결정을 위한 내부 GTO/ICM 로직 프로토타입 완성 및 검증.

---

## 완료된 작업 ✅

| 파일 | 내용 |
|------|------|
| `lib/domain/icm_model.dart` | TournamentPlayer, IcmResult, IcmInputState 모델 |
| `lib/domain/gto_range_table.dart` | 6개 포지션 오픈레인지 const 테이블 (BTN 44%, UTG 11%) |
| `lib/services/icm_calculator.dart` | Malmuth-Harville 알고리즘 (메모이제이션, 9명 이하) |
| `lib/services/gto_range_service.dart` | GTO 레인지 조회/계산 서비스 |
| `lib/providers/icm_provider.dart` | ICM Riverpod 상태 관리 |
| `lib/providers/gto_provider.dart` | GTO Riverpod 상태 관리 |
| `lib/screens/icm_calculator_screen.dart` | ICM 계산기 Flutter UI |
| `lib/screens/gto_range_screen.dart` | GTO 핸드그리드 + AI 조언 Flutter UI |
| `functions/src/gtoAdvice.ts` | AI GTO 코칭 Cloud Function (Gemini Flash, 일 10회 한도) |
| `test/domain/icm_calculator_test.dart` | ICM 황금 케이스 유닛 테스트 13개 |
| `test/domain/gto_range_test.dart` | GTO 레인지 검증 유닛 테스트 13개 |

**테스트 결과**: `flutter test test/domain/` → 26/26 All passed  
**정적 분석**: `flutter analyze lib/` → No issues found  
**TypeScript**: `npx tsc --noEmit` → 0 errors  
**커밋**: `3d26648` / **Push**: `origin/develop` 완료

---

## 검증 결과 (2026-06-10 ~ 2026-06-11)

**1. ICM 수치 외부 비교** — 사용자 수동 작업 (별도 진행)

**2. Flutter UI 실행 (`flutter run`)** — ✅ PASS
- [x] ICM 계산기: 플레이어 입력 → 계산 → 에퀴티 표 정상 출력 (A=$701.79, B=$552.50, C=$445.71)
- [x] GTO 그리드: BTN 선택(44.4% neonGreen) / UTG 선택(11.2% neonGreen) 정상 렌더링, BTN > UTG 순서 확인
- [x] 에러 케이스: 최소 2명 입력이 UI에서 강제되어 "1명 계산" 자체가 불가 — 설계상 도달 불가능한 케이스로 확인 (버그 아님)

**3. gtoAdvice Cloud Function 호출** — 🔄 보류 (Flutter 연동 시 검증)
- [x] `gtoAdvice` 운영 환경(`poker-memo-ai`, us-central1) 배포 완료
- [ ] 함수 단독 호출 검증 — Firebase Auth ID 토큰 발급에 `iam.serviceAccounts.signBlob` 권한 필요,
      현재 계정에 권한 없음 (CLI 단독 검증 중단)
- [ ] **다음 단계에서 Flutter 화면 실제 연동 시, 앱의 익명 로그인(`lib/main.dart`)을 통해
      자연스럽게 호출 → Gemini 응답 + `agent_execution_logs` `hand_coaching` 로그 기록 함께 검증**

---

## Go/No-Go 결론

내부 GTO/ICM 로직(ICM 계산, 레인지 데이터, Flutter UI)은 화면단까지 정상 동작 확인 → **Go, 내부 구현 확정**.
`gtoAdvice` AI 연동(Cloud Function ↔ Flutter)은 별도 작업으로 다음 단계에서 진행 + 검증.

---

## 다음 단계

1. `gtoAdvice` Flutter 화면 실제 연동 (더미 → 실제 Cloud Function 호출)
   - 검증 가이드: 별도 인증 우회 불필요 — `flutter run`으로 앱 실행 시
     자동 익명 로그인을 그대로 사용해 GTO 레인지 화면에서 버튼 클릭 →
     응답 텍스트 + Firestore `agent_execution_logs`(`hand_coaching`) 기록 확인
2. Plus Tier 토너먼트 상세 기능
3. 포스터 스캔 (Vertex AI Vision)
4. 주간 리포트 자동 발행 (Pro Tier 핵심)

---

## 판단 기준

| 항목 | Pass | Fail → 조치 |
|------|------|------------|
| ICM 수치 | 외부 도구 ±$1 이내 | 알고리즘 재검토 또는 외부 API |
| GTO 레인지 | BTN > CO > HJ > UTG 순서 | 레인지 데이터 수정 |
| gtoAdvice 응답 | GTO 컨텍스트 반영된 한국어 조언 | 프롬프트 개선 |
| Flutter UI | 계산·그리드 정상 동작 | 화면 버그 수정 |
