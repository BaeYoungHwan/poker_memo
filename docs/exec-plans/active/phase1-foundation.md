# Phase 1 — 기반 구축 (Foundation)

> 출처: `.claude/plans/polished-yawning-willow.md`
> 생성: 2026-06-08

## 목표
TODO.md P0 항목 완료: Flutter+Firebase 셋업, 다크모드 디자인 시스템,
Provider/Riverpod 상태관리 구조, Vertex AI 연동 초안 + 로깅 스키마, CI/CD 초안
(architecture-v1.md의 4계층 구조를 실제 코드로 구현하는 단계)

## 작업 목록

### 1. Flutter 프로젝트 초기화
- [x] `flutter create` 로 프로젝트 생성 (최신 stable 기준)
      → `flutter create --org com.pokermemoai --project-name poker_memo_ai --platforms=android,ios .`
- [x] architecture-v1.md 레이어 구조에 맞춰 `lib/core·domain·services·providers·screens` 폴더 생성
- [x] Hello World 빌드/실행 확인 (`flutter analyze` 통과, `flutter test` 통과 — Android SDK 미설치로
      실제 에뮬레이터 실행/APK 빌드는 보류, Android Studio 설치 후 별도 확인 필요)

### 2. Firebase 프로젝트 연결
- [x] Firebase 프로젝트 생성 (`poker-memo-ai`, asia-northeast3) + `flutterfire configure` 연동
      → Android 앱 패키지명은 `com.pokermemoai.poker_memo_ai`로 최초 등록 시도했으나
      서버에 고아(orphan) 등록 충돌(409 ALREADY_EXISTS)이 남아있어 `com.pokermemoai.pokermemo`로
      변경 등록 (App ID: android `1:997874796160:android:cc7e1d65833e1ec5a48865`,
      ios `1:997874796160:ios:012b499b4e37abffa48865`)
- [x] Auth, Firestore, Cloud Functions 활성화
      → Firestore 활성화 완료 (Standard, asia-northeast3, Native 모드, 프로덕션 모드) — API로 확인됨
      → Auth(이메일/비밀번호) 활성화 완료 — `signIn.email.enabled: true` API로 확인됨
      → Blaze 플랜 전환 + 예산 알림 설정 완료 — `billingEnabled: true`,
      `billingAccounts/0163A4-C297BC-6A0361` 연결 API로 확인됨 ($300 평가판 크레딧 계정)
      → Cloud Functions — Blaze 전환 완료로 사용 가능 상태, 골격 코드는 추후 작업에서 작성 예정
- [x] Firestore 보안 규칙 초안 작성 (사용자별 데이터 격리) — `firestore.rules`, `firestore.indexes.json`
      작성 및 `firebase deploy --only firestore:rules,firestore:indexes`로 배포 완료

### 3. 다크 모드 디자인 시스템
- [x] Material 3 `ThemeData` — Jet Black(#000000) 배경 + Neon Green(#39FF14)/Gold(#FFD700) 포인트 컬러
      → `lib/core/theme/app_colors.dart`, `app_theme.dart` 작성, `ThemeMode.dark` 고정
- [x] 공통 위젯(버튼/입력폼) — 한 손 조작 가능한 하단 배치 기준으로 설계
      → `ElevatedButtonTheme`(최소 높이 52, 둥근 모서리), `InputDecorationTheme`(카드형 배경) 정의,
      `HomeScreen`에 `bottomNavigationBar` 패턴으로 주요 액션 버튼 하단 배치 예시 구현
- [x] `lib/core/theme/` 에 다크모드 테마 모듈화 — 완료, `flutter analyze`/`flutter test` 통과 확인

### 4. Provider/Riverpod 상태 관리 구조
- [x] Riverpod(`flutter_riverpod`) 패키지 추가 및 기본 Provider 골격 구성
      → `lib/providers/hand_memo_stats_provider.dart` (NotifierProvider) 작성, `main.dart`를
      `ProviderScope`로 감쌈
- [x] `lib/providers/`(상태) ↔ `lib/screens/`(UI) 간 직접 참조 금지 — 인터페이스로만 연결되는 샘플 구조 1개 구현
      → 공유 모델 `lib/domain/hand_memo_stats.dart` (순수 Dart, Flutter/Riverpod 비의존)를
      인터페이스 삼아 `HomeScreen`(ConsumerWidget)이 `handMemoStatsProvider`와 `HandMemoStats`만
      참조하고 `HandMemoStatsNotifier` 내부 구현은 알지 못하도록 분리. 버튼 탭 → 카운트 증가
      흐름을 `flutter test`로 검증 완료

### 5. Vertex AI/Gemini 연동 초안 + 로깅 스키마
- [x] Cloud Functions에서 Vertex AI/Gemini Flash API 호출하는 최소 골격 구현 (try-catch 필수)
      → `firebase init functions`로 TypeScript 코드베이스 셋업 (`functions/`, Node 22),
      `functions/src/ai/geminiClient.ts`에 `callGeminiFlash()` 골격(model: gemini-2.5-flash,
      asia-northeast3) 작성, `functions/src/index.ts`에 인증·입력 검증·try-catch를 갖춘
      `analyzeLeak` 콜러블 함수(Pro 티어 리크 분석 출발점) 구현. `npx tsc` 빌드/타입체크 통과
- [x] Firestore `agent_execution_logs` 컬렉션 스키마 설계
      (분석 시작 시간·판단 근거·토큰 수·발행 결과 상태 필드)
      → `docs/design-docs/firestore-schema-agent-execution-logs.md` (필드 정의·인덱스·보안 규칙·로깅 유틸 설계까지 포함)
- [x] AI 호출 직후 자동 기록하는 공통 로깅 유틸리티 작성
      (스키마 문서 8번 섹션 설계 방향 참조 — `agentExecutionLogger` 가칭)
      → `functions/src/utils/agentExecutionLogger.ts`: 성공/실패 무관하게 `agent_execution_logs`에
      자동 기록(judgement reasoningSummary·토큰 수·추정 비용·status 등 스키마 필드 모두 채움),
      로깅 자체 실패도 별도 try-catch로 격리해 본 흐름을 막지 않도록 처리
- [x] `analyzeLeak` Cloud Functions 배포 + 1회 호출 테스트로 전체 체인 동작 검증
      → 배포 완료 (us-central1, Node 22 2nd Gen), 컨테이너 이미지 cleanup 정책 설정(1일 이상 자동 삭제)
      → 진단 과정에서 2단계 이슈 발견·해결: ① IAM 미설정으로 401 (Cloud Run invoker +
      Cloud Functions invoker 둘 다 `allUsers`에 부여해야 `*.cloudfunctions.net` 라우팅 통과),
      ② Vertex AI API(`aiplatform.googleapis.com`) 미활성화로 403 SERVICE_DISABLED → API 활성화로 해결
      → 최종 테스트: 임시 계정으로 `analyzeLeak` 호출 → HTTP 200, Gemini Flash 분석 결과 정상 반환,
      `agent_execution_logs`에 성공 기록 자동 저장 확인 (status: success, 토큰 92+78,
      추정 비용 $0.00003 수준 — $300 평가판 한도에 영향 없음). 진단 중 발생한 실패 호출 2건도
      status: failed로 정확히 기록되어 로깅 유틸리티가 성공/실패 모두에서 정상 동작함을 함께 확인

### 6. CI/CD 파이프라인 초안
- [ ] GitHub Actions(또는 Firebase) 기반 빌드 검증 워크플로 초안 구성

## 완료 기준
- [x] Flutter 앱이 Firebase(Auth/Firestore)에 연결된 상태로 실행됨
- [x] 다크모드 테마 + Riverpod 상태관리 구조가 화면 1개 이상에 적용됨
- [x] Cloud Functions → Vertex AI 호출 → `agent_execution_logs` 자동 기록까지 1회 이상 동작 확인
- [ ] CI 파이프라인이 푸시 시 빌드를 검증함
