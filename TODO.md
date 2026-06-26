# TODO — PokerMemo AI

> 워크플로우: `[ ]` 대기 → `[🔄]` 진행 중 → `[x]` 완료
> 재시작 시: `docs/ref/session-state.md` 확인 후 `[🔄]` 항목부터 재개

---

## 시작 전

- [x] `/init-project` 실행 완료
- [ ] `docs/design-docs/architecture-v1.md` 검토 및 확정
- [ ] `docs/design-docs/ARD-v1.md` 비기능 요건 확정
- [x] Phase 분할 후 `docs/exec-plans/active/`에 실행 계획 생성 (`phase1-foundation.md`)

---

## 베타 모객 (개발과 병행 — CAC 0원 채널, 지금부터 시작)

> 개발 완료를 기다리지 않고 지금부터 가동 — 7/31 런칭 시점에 초기 유저 풀을 만들기 위함

- [ ] 베타 신청 랜딩 페이지 1장 제작 (Firebase Hosting)
- [ ] 포커 커뮤니티(Reddit r/poker, 2+2 Forums, 국내 포커 커뮤니티) 베타 테스터 모집 게시
- [ ] 오프라인 토너먼트 현장 접촉 계획 수립 (명함/QR코드, 참가자 인터뷰)
- [ ] 웜 아웃리치 — 지인 포커 플레이어 대상 1:1 베타 요청 (첫 "실제 고객 증빙" 확보)
- [ ] 2026-07-15 점검: 베타 신청자 수 확인 → 목표 미달 시 채널 전략 재조정

---

## P0 — 기반 구축

- [x] Flutter 프로젝트 초기화 + Firebase 프로젝트 연결 (Auth, Firestore, Cloud Functions)
- [x] 다크 모드 기반 디자인 시스템 (Jet Black + Neon Green/Gold, Material 3) 구축
- [x] Provider/Riverpod 상태 관리 구조 셋업 (상태 관리 ↔ UI 화면 분리)
- [x] Vertex AI / Gemini API 연동 초안 + `agent_execution_logs` Firestore 컬렉션 스키마 설계
      → 스키마 설계, Cloud Functions 호출 골격(`analyzeLeak`), 공통 로깅 유틸리티(`agentExecutionLogger`)
      작성·배포·1회 호출 테스트까지 완료 (HTTP 200, `agent_execution_logs`에 자동 기록 확인,
      예상 비용 $0.00003 — $300 한도 영향 없음). 상세 내용 `phase1-foundation.md` 참조
- [x] CI/CD 파이프라인 초안 구성 (GCP / Firebase Hosting)
      → `.github/workflows/ci.yml`: flutter-check + functions-build + deploy-firebase(master only) 3-job 구조
- [x] **GTO/ICM Go/No-Go 트리거**: 2026-06-11 검증 완료 → ICM 계산/Flutter UI PASS, 내부 구현 확정 (Go).
      gtoAdvice Cloud Function은 운영 환경 배포 완료, 단독 호출 검증은 보류 →
      Flutter 화면 실제 연동 시 함께 검증 (`docs/exec-plans/active/phase2-gto-icm-prototype.md` 참조)

---

## P1 — MVP 핵심 기능

### Free Tier
- [x] 기본 오프라인 핸드 메모 기능 (포지션: SB/BB/UTG/HJ/CO/BTN 등 정확히 구분)
      → 목록/작성/삭제(스와이프) + 상세 보기 + 편집 기능 구현 완료 (2026-06-27).
      HandMemoDetailScreen (읽기모드: 포지션·날짜·토너먼트·메모 표시,
      편집모드: 포지션/토너먼트/메모 수정 → Firestore 업데이트).
      flutter analyze 0 issues, flutter test 48/48 pass
- [x] 정적 데이터 기반 핸드레인지(Handrange) / 에퀴티(Equity) 조회
      → GTO 정적 레인지 테이블 6개 포지션 구현 완료 (BTN 44%, CO 22%, HJ 15%, UTG 11%)

### Plus Tier
- [x] ICM 계산기 (칩 가치 ↔ 상금 가치 변환 — 변수명 명확히 분리)
      → Malmuth-Harville 알고리즘 + Flutter UI 구현 및 검증 완료 (2026-06-11)
- [x] 토너먼트 상세 기능
      → Tournament 모델/서비스/Provider + 토너먼트 목록·작성·상세 화면 구현 완료 (2026-06-17).
      핸드 메모는 `tournamentId`(nullable)로 토너먼트와 선택적 연결. HomeScreen AppBar에
      토너먼트/ICM/GTO 진입점 3개 함께 연결 (기존 ICM/GTO 라우팅 누락 해소).
      `flutter analyze`/`flutter test` 30/30 pass, 실기기 검증은 보류 (`phase3-tournament-detail.md` 참조)
- [x] 대회 포스터/정보 이미지 업로드 → AI 스캔 기능 (Vertex AI/Gemini)
      → scanPoster Cloud Function(Gemini Flash Vision, Base64 직접 전달 - Storage 미사용) +
      Flutter AddTournamentScreen "포스터로 채우기" 통합 구현 완료 (2026-06-18).
      `flutter analyze`/`flutter test` 48/48 pass, `tsc --noEmit` 0 errors,
      실기기 검증은 보류 (`phase4-poster-scan.md` 참조)

### Pro Tier (핵심 AI 에이전트)
- [🔄] LLM 기반 포커 AI 코칭
      → gtoAdvice Cloud Function 구현 + 운영 환경 배포 완료 (포지션별 GTO 컨텍스트 + Gemini Flash),
      Flutter 화면 연동(`gto_range_screen.dart` 더미 → 실제 호출) 코드 완료 (2026-06-17).
      실기기/에뮬레이터 종단 검증(응답 확인 + `agent_execution_logs` 기록 확인)은
      사용자가 개발 더 진행한 후 직행 예정 — 보류
- [ ] 개인 맞춤형 핸드레인지 설정 및 솔루션 제공
- [ ] 누적 데이터 기반 유저 약점(Leak) 분석 → 주간 리포트 자동 발행 (+ 실행 로그 자동 기록)

### AI 운영 자동화 (Free→유료 전환 퍼널)
- [ ] Free 유저 행동 패턴 기반 Plus/Pro 전환 후보 감지 (규칙 기반 트리거: 메모 건수, 조회 패턴 등)
- [ ] AI 개인화 업그레이드 제안 메시지 생성 (Gemini Flash, 가격 앵커링 문구 자동 삽입)
- [ ] 발송 단계 확장: AI 생성 → 검토 후 발송 → (베타 안정화 후) 자동 발송 (`agent_execution_logs` 기록)

### 매출 증빙
- [ ] Stripe 결제 페이지 연동 (외부 결제 링크 방식)
      — 정가/파운딩 멤버가 이원 구조 + KRW 로컬 가격 적용
      (Plus $29.99→$14.99 / ₩39,900→₩19,900, Pro $99.99→$49.99 / ₩149,900→₩74,900)

### 다국어
- [ ] 영어/한국어 2개 국어 로컬라이징

---

## P2 — 검증 및 배포

- [ ] MVP 완성도 점검 (2026-06-27): Free/Plus 핵심 플로우 E2E 동작 여부 확인 →
      미달 시 Pro 일부 기능을 P2로 이연 (GTO/ICM Go/No-Go 트리거는 P0로 이동, 위 참조)
- [ ] E2E 테스트 작성
- [ ] Google Cloud Platform (GCP) / Firebase 호스팅·스토어 배포
- [ ] KPI 측정 기준 설정 (유료 구독 매출 발생, 주간 리포트 자동 발행/운영 로그 연속 기록)
- [ ] CAC(고객 획득 비용) 0원이라도 명확히 기록 및 공개 (해커톤 증빙용)
- [x] `web/` 폴더 처리 — Flutter 웹 검증 시 자동 생성된 플랫폼 폴더로 확인,
      `.gitignore`에 `web/` 추가하여 커밋 대상에서 제외 (로컬에는 유지 — 웹 검증 계속 가능)

---

## 마일스톤

- [ ] 2026-06-30: MVP 개발 마감 (Free 및 기본 기능 배포)
- [ ] 2026-07-31: Plus/Pro 티어 순차 배포, 공식 런칭 및 매출 확보 시작
- [ ] 2026-08-18 05:00 AM: XPRIZE 해커톤 최종 Deadline 및 제출
