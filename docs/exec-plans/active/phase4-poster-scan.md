# Phase 4 — 대회 포스터 스캔 기능 (Plus Tier)

> 출처: `.claude/plans/steady-wiggling-fog.md`
> 생성: 2026-06-18
> 완료: 2026-06-18
> BASE_COMMIT: `b90b700cc459beb0ad7f2eec35009ecf05890590`

## 목표

대회 포스터/공지 이미지를 업로드하면 Gemini 2.5 Flash Vision으로 토너먼트명·날짜·바이인을
추출해 `AddTournamentScreen` 입력 폼에 자동 채워주는 기능 구현. 이미지는 Base64로 Cloud
Function에 직접 전달(Firebase Storage 미사용 — GCP $300 한도 보호).

## 태스크

- [x] `functions/src/ai/geminiClient.ts` — `callGeminiFlashVision` 추가 (멀티모달, 기존 `callGeminiFlash` 유지)
- [x] `functions/src/scanPoster.ts` (신규) — 인증/검증/일일한도(5회)/JSON 방어적 파싱/`logAgentExecution`
- [x] `functions/src/index.ts` — `scanPoster` export 추가
- [x] `firestore.rules` — `users/{userId}/poster_scan_usage/{date}` 쓰기 차단 규칙 추가
- [x] `pubspec.yaml` — `image_picker` 패키지 추가
- [x] `lib/services/poster_scan_service.dart` (신규) — `PosterScanService`/`PosterScanResult`
- [x] `lib/screens/add_tournament_screen.dart` — "포스터로 채우기" 버튼/바텀시트/로딩/필드 자동 채움 통합
- [x] `test/screens/add_tournament_screen_test.dart` — 성공/부분인식/실패 시나리오 추가
      (image_picker 플랫폼 채널까지 가짜로 교체해 실제 이미지 선택 → 스캔 → 폼 채움 전체 흐름을
      위젯 테스트로 검증 — `ImagePickerPlatform.instance`를 `_FakeImagePickerPlatform`으로 교체)
- [x] `flutter analyze` / `flutter test` / `tsc --noEmit` 검증
- [x] `TODO.md` 해당 항목 `[x]` 처리

## 검증 기준

| 항목 | Pass 기준 | 결과 |
|------|-----------|------|
| TypeScript 컴파일 | `cd functions && npx tsc --noEmit` 0 errors | ✅ 0 errors |
| Flutter 정적 분석 | `flutter analyze lib/ test/` 0 issues | ✅ 0 issues |
| Flutter 테스트 | `flutter test test/` 전체 pass | ✅ 48/48 pass (기존 45 + 신규 3) |
| 실기기/에뮬레이터 검증 | 실제 포스터 이미지로 `scanPoster` 호출 → 응답 확인 + `agent_execution_logs`에 `poster_scan` 기록 확인 | 🔄 보류 (Android 기기/에뮬레이터 필요, Phase 2/3과 동일하게 사용자 환경에서 직접 진행) |
| 일일 한도 동작 | 6회째 호출 시 `resource-exhausted` 에러 정상 발생 확인 | 🔄 보류 (실기기 검증과 함께 진행) |

## 참고 사항

- `firestore.rules`의 `gto_advice_usage` 경로에도 `poster_scan_usage`와 동일한 보호 누락(클라이언트
  직접 쓰기로 한도 우회 가능)이 있음을 step-validator 리뷰에서 확인. 이번 작업 범위 밖이라 손대지
  않았으며, 필요시 별도 작업으로 분리 권장.
