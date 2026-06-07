# PokerMemo AI ARD v1

> 버전: v1 | 작성일: 2026-06-08 | 상태: Draft
> 참조 PRD: `docs/product-specs/PRD-v1.md`

---

## 1. 품질 속성 목표 (Quality Attributes)

| 속성 | 목표 | 측정 방법 | 우선순위 |
|------|------|-----------|----------|
| 단순성/직관성 | 1인 개발 + 비전문가도 유지보수 가능한 Firebase 중심 단순 구조 | 레이어 구조 리뷰, 코드 복잡도 점검 | High |
| AI 운영 증빙 | 주간 리포트 발행 시 분석 시작 시간·판단 근거·토큰 수·결과 상태를 `agent_execution_logs`에 100% 기록 | Firestore 컬렉션 기록 누락률 점검 | High |
| 다국어 지원 | 영어/한국어 2개 국어 완전 지원 | 로컬라이징 키 커버리지 점검 | Medium |
| 보안 | Firebase Auth 기반 인증, 결제는 외부 Stripe 링크로 위임(PG 직접 처리 없음) | OWASP 체크리스트, Firestore 보안 규칙 검토 | High |
| 정확성(도메인) | 포지션 약어(SB/BB/UTG/HJ/CO/BTN), ICM 변수명 등 포커 도메인 데이터 정확히 구분 | 도메인 글로서리 대조 검수 (`agents/poker-agent.md`) | High |
| 가용성 | Firebase/GCP 매니지드 서비스 활용으로 1인 운영 부담 최소화 | Firebase 콘솔 가동률 모니터링 | Medium |

---

## 2. 아키텍처 제약사항

### 기술적 제약
- Frontend: Flutter (Dart) 고정 — 다른 크로스플랫폼 프레임워크 도입 금지
- Backend & DB: Firebase (Auth, Firestore, Cloud Functions) 중심 — 별도 서버 인프라 구축 지양
- AI: Google Cloud Vertex AI / Gemini API — XPRIZE 요건상 Google Cloud 제품 필수 사용
- GTO/ICM: 1차 내부 로직 시도 → 일정 내 불가 시 외부 포커 API로 즉시 전환 가능한 구조로 설계

### 조직적 제약
- 1인 개발(Claude Code CLI + Codex 활용)이므로 운영 복잡도를 최소화하고, 의사결정 지연 없이 빠르게 반복 가능한 구조를 우선
- 앱 개발 경험 부재 — 직관적이고 단순한 패턴(Provider/Riverpod 등)으로 통일, 상태관리·UI 분리 강제

### 예산/인프라 제약
- 해커톤 기간 마케팅/CAC 비용은 0원이라도 투명하게 기록 (의사결정에 영향 없음, 증빙 목적)
- Firebase/GCP 무료 티어 및 종량제 범위 내에서 운영 — 비용 급증 가능 컴포넌트(Vertex AI 호출량 등) 모니터링 필요

---

## 3. 주요 아키텍처 결정 (초안)

> 상세 결정 기록은 `docs/design-docs/adr/` 에 ADR로 작성합니다.

| 결정 영역 | 선택 | 근거 |
|-----------|------|------|
| 레이어 구조 | Flutter UI / Provider·Riverpod 상태관리 / Firebase 서비스 레이어로 3분리 | 상태관리-UI 분리 강제 요건 충족, 비전문가도 추적 가능한 단순 구조 |
| 인증 방식 | Firebase Authentication | Firebase 생태계 통합, 1인 개발 운영 부담 최소화 |
| 데이터 저장 | Firestore (NoSQL 문서 기반) | 핸드 메모·티어·로그 등 비정형/반정형 데이터에 적합, 실시간 동기화 |
| AI 연동 | Vertex AI / Gemini API + Cloud Functions 트리거 | 주간 리포트·이미지 스캔 등 서버사이드 AI 처리, 실행 로그 자동 기록과 자연 결합 |
| 결제 처리 | Stripe 외부 결제 링크 (인앱 결제 미사용) | 자체 PG 구축 공수 제거, MVP 범위 제한과 일치 |
| 배포 전략 | Firebase Hosting + 앱스토어/플레이스토어 빌드, GCP 기반 백엔드 | 양식 4번 배포 환경 기반, Firebase·GCP 통합 운영 |

---

## 4. 리스크

| 리스크 | 영향도 | 발생 가능성 | 완화 전략 |
|--------|--------|-------------|-----------|
| GTO/ICM 내부 로직 구현이 일정 내 어려움 | High | Medium | 외부 전문 포커 API 연동으로 즉시 전환 가능한 추상화 레이어를 P0에서 미리 설계 |
| 1인 개발로 인한 일정 지연 (2026-06-30 MVP 마감) | High | Medium | Phase별 범위를 MVP 핵심 기능으로 엄격히 제한 (PRD 8번 제외 사항 준수), Claude/Codex 병렬 활용 |
| Vertex AI 호출 비용 급증 | Medium | Medium | 호출량 모니터링 + `agent_execution_logs`로 토큰 사용량 추적, 캐싱/배치 처리 검토 |
| 포커 도메인 용어/수식 오역으로 잘못된 데이터 구조 생성 | Medium | Medium | `agents/poker-agent.md` 도메인 에이전트로 용어·수식 검증 강제 |
| XPRIZE 증빙(로그/매출/고객 데이터) 누락으로 심사 불이익 | High | Low | 개발 초기부터 `agent_execution_logs` 자동 기록 및 Stripe 매출 증빙 체계를 P0~P1에 내장 |

---

## 5. 검증 기준

아키텍처가 이 ARD를 만족하는지 확인하는 방법:

- [ ] 품질 속성 목표 달성 여부 — Firestore 로그 기록률, 로컬라이징 커버리지, 도메인 글로서리 대조 검수
- [ ] 제약사항 위반 없음 — `architecture-guard.sh` 훅 통과 (경고 모드)
- [ ] 주요 결정사항 ADR 작성 완료 (`docs/design-docs/adr/`)
- [ ] XPRIZE 증빙 요건(로그/매출/고객 데이터) 자동 수집 파이프라인 동작 확인
