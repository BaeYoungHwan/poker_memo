# Phase 2 — GTO/ICM 내부 로직 프로토타입

> 상태: 🔄 구현 완료 / 검증 대기
> 생성일: 2026-06-09
> Go/No-Go 결정일: **2026-06-25** (검증 통과 → 내부 구현 확정, 실패 → 외부 API 전환)

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

## 대기 중인 작업 🔄

### 내일 (2026-06-10) 검증 체크리스트

**1. ICM 수치 외부 비교**
- [ ] icmizer.com 또는 holdemresources.net에서 A=50,000 / B=30,000 / C=20,000 / 상금 1000/500/200 입력
- [ ] 우리 앱 결과(A≈701.79, B≈552.5, C≈445.71)와 ±$1 이내 일치 확인

**2. Flutter UI 실행 (`flutter run`)**
- [ ] ICM 계산기: 플레이어 입력 → 계산 → 에퀴티 표 정상 출력
- [ ] GTO 그리드: BTN 선택(44% neonGreen) / UTG 선택(11% neonGreen) 정상 렌더링
- [ ] 에러 케이스: 플레이어 1명 계산 시도 → 에러 메시지 표시

**3. gtoAdvice Cloud Function 호출**
- [ ] `firebase emulators:start --only functions` 실행
- [ ] 포지션/스택/핸드메모 입력 → Gemini Flash 응답 확인
- [ ] Firestore `agent_execution_logs`에 `hand_coaching` 로그 기록 확인

---

## 다음 단계 (검증 통과 후)

1. `gtoAdvice` Flutter 화면 실제 연동 (더미 → 실제 Cloud Function 호출)
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
