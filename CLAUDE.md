# PokerMemo AI — 지침 지도

> PokerMemo AI (오프라인 토너먼트 포커 트래커): 글로벌 오프라인 토너먼트 포커 플레이어가 기록한 핸드 메모를 바탕으로,
> AI 에이전트가 리크 분석 리포트 및 맞춤형 GTO/ICM 솔루션을 제공하는 서비스.
> XPRIZE 해커톤(Deadline 2026-08-18) 제출 프로젝트 — 실제 매출/유저/AI 운영 증빙 필수.
>
> 이 파일은 ~100줄 지도입니다. 세부 규칙은 `docs/`에 있습니다.

---

## 핵심 규칙 (항상 적용)

- 코드·변수명: **영어** / 주석·커밋·소통: **한국어**
- 민감정보(API 키 등): `.env` 관리, 절대 커밋 금지
- CLAUDE.md는 핵심 규칙만 유지 — 특정 상황 규칙은 `docs/ref/`에 배치
- AI 행동 원칙 (코딩 전 사고, 단순함, 수술적 변경, 목표 중심) → [`docs/ref/behavioral-principles.md`](docs/ref/behavioral-principles.md)
- 브랜치 생성 금지: 사용자 명시 지시 없이 `git checkout -b`, `git switch -c` 실행 불가

---

## 모델 사용 규칙

| 작업 유형 | 모델 |
|-----------|------|
| 탐색 / grep / 파일 검색 | Haiku |
| 개발 (코딩, 디버깅, 리팩터링) | Sonnet |
| 설계 / 계획 (Plan 모드) | Opus |

자세한 기준 → [`docs/ref/agent-model-routing.md`](docs/ref/agent-model-routing.md)

---

## 보안 규칙

- `--no-verify`, `curl | sh`, 자격증명 직접 입력 금지 (훅이 차단)
- 모든 Bash 명령은 `logs/claude-audit.log`에 자동 기록됨
- 자세한 보안 정책 → [`docs/SECURITY.md`](docs/SECURITY.md)

---

## 에이전트 사용 규칙

- `agents/` 폴더 에이전트: **병렬 처리 서브태스크** 전용
- Plan 모드로 설계 후 독립적으로 분리 가능한 작업은 반드시 에이전트로 병렬 실행
- 에이전트 분류 기준 → [`agents/LANES.md`](agents/LANES.md)

**Plan 모드 실행 흐름**:
- 독립 태스크 3개+ → `/ultrawork`
- 독립 태스크 1~2개 → `/ralph`
- 단순 작업 → 직접 실행

**Plan 모드 실행 규칙** → [`docs/ref/plan-mode-workflow.md`](docs/ref/plan-mode-workflow.md):
- ExitPlanMode 승인 = 플랜 전체 일괄 승인 → 실행 단계 파일별 재확인 없음
- ExitPlanMode 직후 `docs/exec-plans/active/` Phase 문서 없으면 자동 생성
- Phase 2 설계 출력: 섹션형 리포트 형식 (코드 블록 아님)

---

## 작업 흐름

| 상황 | 참조 문서 |
|------|-----------|
| 새 프로젝트 시작 | [`docs/ref/project-setup.md`](docs/ref/project-setup.md) → `/init-project` |
| TODO 작업 진행 | [`docs/ref/todo-workflow.md`](docs/ref/todo-workflow.md) |
| git 브랜치 운영 | [`docs/ref/branch-strategy.md`](docs/ref/branch-strategy.md) (develop + PR 기반, 1인 개발 권장) |
| 커밋 작성 | [`docs/ref/commit-convention.md`](docs/ref/commit-convention.md) |
| 테스트 전략 | [`docs/ref/testing-patterns.md`](docs/ref/testing-patterns.md) |
| 검증 전략 | [`docs/ref/verification-protocol.md`](docs/ref/verification-protocol.md) |
| PRD / 설계 문서 | [`docs/ref/PRD-template.md`](docs/ref/PRD-template.md) |
| Spec-driven 개발 | [`docs/ref/spec-driven-workflow.md`](docs/ref/spec-driven-workflow.md) |

---

## 컨텍스트 재시작 시 ("다음 작업 하자")

1. `docs/ref/session-state.md` 읽기 (git 상태)
2. `docs/exec-plans/active/` 읽기 (진행 중 작업 목록)
3. `[🔄]` 항목부터 이어서 진행

---

## 알림

- 1차: PC 토스트 알림 (`global-setup/` 설치 시 자동 동작)
- 세션 종료 시 git 상태 자동 저장 → `docs/ref/session-state.md`

---

## 프로젝트 구조

```
[프로젝트명]/
├── CLAUDE.md                  # 이 파일 (지침 지도)
├── TODO.md                    # 작업 목록
├── .claude/
│   ├── settings.json          # 권한 + 훅 등록
│   ├── hooks/                 # 보안·감사·세션 훅
│   ├── commands/              # 슬래시 스킬
│   └── skills/                # 하네스 내부 실행 스크립트 (score.py, analyze_sessions.py 등)
├── .claude-plugin/            # 마켓플레이스 플러그인 메타데이터
├── skills/                    # 마켓플레이스 배포용 — 다른 프로젝트가 설치 가능한 SKILL.md
├── agents/                    # 병렬 에이전트
├── docs/
│   ├── ref/                   # 참조 문서 (필요할 때만 로드)
│   ├── design-docs/           # 설계 문서
│   ├── exec-plans/            # 실행 계획 (active/completed)
│   └── product-specs/         # PRD / 기획 문서
├── src/
├── tests/
├── logs/                      # gitignore 대상
└── .env                       # gitignore 대상
```

---

## 프로젝트 맞춤 규칙

> /init-project 에서 자동 생성됨. 이 프로젝트에만 적용됩니다.

### Claude 행동 지침

- 무조건 다크 모드(Dark Mode) 기반의 심플하고 직관적인 UI — Flutter 컴포넌트 구조 사용
- 복잡한 포커 수학 수식·AI 프롬프트 로직 작성 시 초보자도 이해할 수 있도록 **한글 주석**을 상세히 달 것
- 기존에 작동하던 코드 수정 시 구조를 깨뜨리지 말고 단계별로 리팩토링할 것
- 모든 주요 기능(API 호출, 데이터 파싱 등)에 try-catch 예외 처리 코드를 반드시 포함할 것
- UI/UX: Material 3 스펙 준수, 배경 Jet Black(#000000) + 포인트 컬러 Neon Green/Gold, 입력 폼·버튼은 한 손 조작 가능한 하단 배치 우선
- 포커 도메인 용어(SB/BB/UTG/HJ/CO/BTN 등 포지션, ICM 변수명)는 정확히 구분해 데이터화 — 자세한 규칙 → [`agents/poker-agent.md`](agents/poker-agent.md)
- XPRIZE 증빙: AI 에이전트(Vertex AI)가 주간 리포트를 발행할 때마다 분석 시작 시간·판단 근거·토큰 수·발행 결과 상태를 Firestore `agent_execution_logs` 컬렉션에 무조건 자동 기록
- 상태 관리는 Provider 또는 Riverpod로 통일, 상태 관리 파일과 UI 화면 파일을 철저히 분리할 것

### MVP 범위 제한

> 아래 항목은 명시적 요청 없이 절대 구현하지 않습니다.

- 자체 결제 모듈 시스템 구축 (Stripe 등 외부 PG사 구독 결제 링크로 대체)
- 실시간 멀티플레이어 기능 (유저 간 핸드 공유, 소셜 피드, 커뮤니티)
- 실시간 족보 계산기 (인게임 중 실시간 확률 표시 UI)

### 기술 스택 고정

- Frontend: Flutter (Dart) — 최신 안정판(stable) 기준, 특정 버전 고정 없음
- Backend & DB: Firebase (Auth, Firestore, Cloud Functions)
- AI & Infrastructure: Google Cloud Vertex AI / Gemini API — **Gemini Flash 계열**(비용 효율 우선)을
  포스터 스캔·리크 분석·주간 리포트 생성에 기본 사용. 품질이 부족하면 Pro 계열로 부분 전환 검토
- 결제 증빙: Stripe 결제 페이지 연동 (외부 링크 방식)
- 다른 라이브러리/프레임워크 임의 도입 금지 — 변경 필요 시 항상 사용자에게 먼저 확인
