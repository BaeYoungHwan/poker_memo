# Phase 3 — 토너먼트 상세 기능 (Plus Tier)

> 상태: ✅ 코드 구현/정적 검증 완료 — 실기기 검증만 보류
> 생성일: 2026-06-17
> 완료일: 2026-06-17
> 플랜 파일: `C:\Users\.claude\plans\rustling-moseying-crab.md`

---

## 목표

TODO.md P1 Plus Tier "토너먼트 상세 기능" 구현. 핸드 메모와 연결되는 토너먼트 컨테이너를
추가하고, 동시에 기존에 라우팅이 누락돼 있던 ICM 계산기/GTO 레인지 화면 진입점도 함께 연결한다.

## 범위 결정 (사용자 승인)

- 토너먼트는 핸드 메모와 연결되는 컨테이너 (`tournamentId` nullable, 애디티브 변경)
- 입력 필드는 최소: 이름/장소, 날짜, 바이인
- `HomeScreen` AppBar에 토너먼트/ICM/GTO 3개 진입점 아이콘 한번에 추가

전체 설계 근거는 플랜 파일 참조.

---

## 작업 목록

- [x] `lib/domain/tournament.dart` (신규) — Tournament 모델
- [x] `lib/domain/hand_memo.dart` (수정) — `tournamentId` 필드 추가
- [x] `lib/services/tournament_service.dart` (신규)
- [x] `lib/providers/tournament_list_provider.dart` (신규)
- [x] `lib/providers/hand_memo_list_provider.dart` (수정) — `addMemo`에 `tournamentId` 파라미터
- [x] `lib/screens/add_hand_memo_screen.dart` (수정) — 토너먼트 선택 칩 추가
- [x] `lib/screens/tournament_list_screen.dart` (신규)
- [x] `lib/screens/add_tournament_screen.dart` (신규)
- [x] `lib/screens/tournament_detail_screen.dart` (신규)
- [x] `lib/screens/home_screen.dart` (수정) — AppBar 진입점 3개 (토너먼트/ICM/GTO)
- [x] `test/domain/tournament_test.dart` (신규)
- [x] `flutter analyze` / `flutter test` 검증

## 검증 (2026-06-17 추가)

실기기/에뮬레이터가 없는 환경 제약상, Firebase 의존성을 `ProviderScope.overrides`로
가짜 Notifier 치환하는 기존 `widget_test.dart` 패턴을 그대로 활용해 **실제 화면 렌더링·
상호작용까지 위젯 테스트로 검증**함 (도메인 모델 라운드트립보다 한 단계 더 깊은 검증):

| 파일 | 검증 내용 |
|------|-----------|
| `test/screens/tournament_list_screen_test.dart` | 빈 상태/카드 렌더링, FAB → AddTournamentScreen 이동 |
| `test/screens/add_tournament_screen_test.dart` | 이름 미입력 시 저장 버튼 비활성화, 저장 시 `addTournament` 인자 정확히 전달 |
| `test/screens/tournament_detail_screen_test.dart` | 헤더 정보 표시, **`tournamentId` 일치 메모만 필터링되는 핵심 로직 검증** |
| `test/screens/add_hand_memo_screen_test.dart` | 토너먼트 선택 칩 렌더링, 선택/미선택 시 `addMemo`에 전달되는 `tournamentId` 검증 |
| `test/screens/home_screen_nav_test.dart` | AppBar 3개 아이콘 존재 및 각각 올바른 화면으로 네비게이션 |

## 검증 기준

| 항목 | Pass 기준 | 결과 |
|------|-----------|------|
| 정적 분석 | `flutter analyze lib/ test/` 0 issues | ✅ 0 issues |
| 단위/위젯 테스트 | `flutter test test/` 전체 pass | ✅ 45/45 pass (기존 30 + 위젯 테스트 15) |
| 실기기 검증 | - | 🔄 보류 (사용자가 개발 추가 진행 후 직접 진행하기로 합의) |
