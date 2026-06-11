# PokerMemo AI

> 오프라인 토너먼트 포커 플레이어를 위한 AI 기반 핸드 메모 & 리크 분석 / GTO·ICM 코칭 앱
> XPRIZE 해커톤 제출 프로젝트 (Deadline: 2026-08-18) — 실제 매출/유저/AI 운영 증빙 필수

---

## 주요 기능 (티어별 진행 현황)

### Free Tier
- [ ] 오프라인 핸드 메모 CRUD (포지션: SB/BB/UTG/HJ/CO/BTN 정확히 구분) — 진행 중
- [x] GTO 정적 핸드레인지 / 에퀴티 조회 — 6개 포지션 구현 완료 (BTN 44%, CO 22%, HJ 15%, UTG 11% 등)

### Plus Tier
- [🔄] ICM 계산기 (칩 가치 ↔ 상금 가치 변환, Malmuth-Harville 알고리즘) — 프로토타입 구현 완료, 외부 도구 비교 검증 예정
- [ ] 토너먼트 상세 기능
- [ ] 대회 포스터/정보 이미지 업로드 → AI 스캔 (Vertex AI/Gemini)

### Pro Tier (핵심 AI 에이전트)
- [🔄] LLM 기반 포커 AI 코칭 — `gtoAdvice` Cloud Function 구현 완료(포지션별 GTO 컨텍스트 + Gemini Flash), Flutter 화면 연동 미완
- [ ] 개인 맞춤형 핸드레인지 설정 및 솔루션 제공
- [ ] 누적 데이터 기반 유저 약점(Leak) 분석 → 주간 리포트 자동 발행

> 진행 상황의 전체 목록은 [TODO.md](TODO.md) 참고.

---

## 기술 스택

- **Frontend**: Flutter (Dart, SDK ^3.12.1) — 다크 모드(Jet Black + Neon Green/Gold), Material 3, Riverpod 상태 관리
- **Backend & DB**: Firebase (Auth, Firestore, Cloud Functions)
- **AI**: Google Cloud Vertex AI / Gemini API — Gemini 2.5 Flash 기반 (`functions/src/ai/geminiClient.ts`)
- **CI/CD**: GitHub Actions (`.github/workflows/`) — Flutter 테스트, Cloud Functions 빌드, Firebase 배포

---

## 개발 현황

| Phase | 목표 | 상태 | 일정 |
|-------|------|------|------|
| P0 | 기반 구축 (Flutter+Firebase, Vertex AI 연동, CI/CD) | 🔄 GTO/ICM Go/No-Go 결정 대기 | 2026-06-25 |
| P1 | MVP 핵심 기능 (Free/Plus/Pro 티어) | 🔄 진행 중 | 2026-06-30 마감 |
| P2 | 검증 및 배포 | 예정 | 2026-07-31 런칭 |
| 해커톤 | XPRIZE 최종 제출 | 예정 | 2026-08-18 |

---

## 문서

- 프로젝트 지침: [CLAUDE.md](CLAUDE.md)
- 작업 목록: [TODO.md](TODO.md)
- 설계 문서: [docs/design-docs/](docs/design-docs/)
- 진행 중인 실행 계획: [docs/exec-plans/active/](docs/exec-plans/active/)
- 참조 문서: [docs/ref/](docs/ref/)

---

## 로컬 개발

### 요구사항
- Flutter SDK ^3.12.1
- Node.js (Cloud Functions 빌드용)
- Firebase CLI
- GCP 서비스 계정 (Vertex AI 호출용)

### 앱 실행
```bash
flutter pub get
flutter run
```

### 테스트
```bash
flutter test
```

### Cloud Functions
```bash
cd functions
npm install
npx tsc --noEmit   # 타입 체크
npm run deploy     # 배포
```
