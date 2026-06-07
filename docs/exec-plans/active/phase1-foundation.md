# Phase 1 — 기반 구축 (Foundation)

> 출처: `.claude/plans/polished-yawning-willow.md`
> 생성: 2026-06-08

## 목표
TODO.md P0 항목 완료: Flutter+Firebase 셋업, 다크모드 디자인 시스템,
Provider/Riverpod 상태관리 구조, Vertex AI 연동 초안 + 로깅 스키마, CI/CD 초안
(architecture-v1.md의 4계층 구조를 실제 코드로 구현하는 단계)

## 작업 목록

### 1. Flutter 프로젝트 초기화
- [ ] `flutter create` 로 프로젝트 생성 (최신 stable 기준)
- [ ] architecture-v1.md 레이어 구조에 맞춰 `lib/core·domain·services·providers·screens` 폴더 생성
- [ ] Hello World 빌드/실행 확인 (Android/iOS 시뮬레이터 또는 에뮬레이터)

### 2. Firebase 프로젝트 연결
- [ ] Firebase 프로젝트 생성 + `flutterfire configure` 연동
- [ ] Auth, Firestore, Cloud Functions 활성화
- [ ] Firestore 보안 규칙 초안 작성 (사용자별 데이터 격리)

### 3. 다크 모드 디자인 시스템
- [ ] Material 3 `ThemeData` — Jet Black(#000000) 배경 + Neon Green/Gold 포인트 컬러
- [ ] 공통 위젯(버튼/입력폼) — 한 손 조작 가능한 하단 배치 기준으로 설계
- [ ] `lib/core/theme/` 에 다크모드 테마 모듈화

### 4. Provider/Riverpod 상태 관리 구조
- [ ] Riverpod(또는 Provider) 패키지 추가 및 기본 Provider 골격 구성
- [ ] `lib/providers/`(상태) ↔ `lib/screens/`(UI) 간 직접 참조 금지 — 인터페이스로만 연결되는 샘플 구조 1개 구현

### 5. Vertex AI/Gemini 연동 초안 + 로깅 스키마
- [ ] Cloud Functions에서 Vertex AI/Gemini Flash API 호출하는 최소 골격 구현 (try-catch 필수)
- [x] Firestore `agent_execution_logs` 컬렉션 스키마 설계
      (분석 시작 시간·판단 근거·토큰 수·발행 결과 상태 필드)
      → `docs/design-docs/firestore-schema-agent-execution-logs.md` (필드 정의·인덱스·보안 규칙·로깅 유틸 설계까지 포함)
- [ ] AI 호출 직후 자동 기록하는 공통 로깅 유틸리티 작성
      (스키마 문서 8번 섹션 설계 방향 참조 — `agentExecutionLogger` 가칭)

### 6. CI/CD 파이프라인 초안
- [ ] GitHub Actions(또는 Firebase) 기반 빌드 검증 워크플로 초안 구성

## 완료 기준
- Flutter 앱이 Firebase(Auth/Firestore)에 연결된 상태로 실행됨
- 다크모드 테마 + Riverpod 상태관리 구조가 화면 1개 이상에 적용됨
- Cloud Functions → Vertex AI 호출 → `agent_execution_logs` 자동 기록까지 1회 이상 동작 확인
- CI 파이프라인이 푸시 시 빌드를 검증함
