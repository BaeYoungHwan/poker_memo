# 브랜치 전략 — develop + PR 기반 (1인 개발 권장)

1인 또는 소규모 개발에서 "단순함"과 "안전망(PR 리뷰 게이트)"을 동시에 가져가기 위한
브랜치 운영 가이드입니다. `/init-project`의 SCALE=1(개인) 기본값인 "main 직접 커밋"보다
한 단계 더 안전하면서도, SCALE=2의 `feature/*` 다중 브랜치보다 단순한 **중간 지점**입니다.

---

## 기본 구조

```
main (배포 기준 — 직접 푸시 금지)
  └── develop (일상 작업 — 모든 변경은 여기서 진행)
```

- 브랜치는 **develop 하나만** 추가 운영한다 (feature/* 분기 없음 — 1인 개발에서는 병렬 작업 충돌이 드물어 오버헤드만 늘어남)
- 일상적인 코드 변경·문서 작성·설계 산출물은 모두 `develop`에서 직접 진행하고 커밋한다
- 작업 단위가 안정화되면(기능 완성, Phase 완료 등) `develop` → `main` PR을 생성해 병합한다
- `main`은 "배포 가능한 상태"만 유지 — 직접 커밋·푸시 금지 (`permissions.deny`로 차단)

---

## 작업 흐름

1. `develop` 브랜치에서 작업 (커밋은 `docs/ref/commit-convention.md` 컨벤션 따름)
2. 작업 단위가 완결되면 `git push origin develop`
3. `/PR` 스킬로 `develop` → `main` PR 생성
4. PR 리뷰(셀프 리뷰 또는 sub-agent-review) 통과 후 머지
5. 머지 후 `develop`을 `main`과 동기화 (`git pull origin main` 또는 `git merge main`)

---

## 왜 이 구조인가

| 대안 | 문제 | 이 구조의 장점 |
|------|------|----------------|
| main 직접 커밋 (SCALE=1 기본) | 실수한 커밋이 곧바로 배포 기준에 반영됨 — 되돌리기 번거로움 | PR 단계에서 한 번 더 점검 가능, main은 항상 안정 상태 유지 |
| `feature/*` 다중 브랜치 (SCALE=2) | 1인 개발에서는 브랜치 전환·머지 충돌 관리 자체가 오버헤드 | 브랜치가 1개뿐이라 컨텍스트 전환 비용 없음, 그러면서도 PR 게이트는 확보 |

---

## 적용 시점

- 새 프로젝트 시작 시 `/init-project`에서 SCALE=1(개인)을 선택했더라도, 사용자가 "PR 기반으로 관리하고 싶다"고
  명시하면 이 전략을 적용한다 (자동 적용 금지 — 브랜치 생성은 항상 사용자 명시 지시 필요, CLAUDE.md 참조)
- 적용 결정 시 `permissions.deny`에 아래 항목이 있는지 확인 — 없으면 추가 권장:
  ```
  "Bash(git push origin main)"
  ```
- 최초 분기는 사용자가 직접 실행 (`git checkout -b develop && git push -u origin develop`) —
  Claude는 `git checkout -b` 자율 실행이 차단되어 있음
