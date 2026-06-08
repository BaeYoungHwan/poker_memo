import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/hand_memo_stats.dart';

/// 핸드 메모 통계 상태를 관리하는 Notifier
///
/// 화면(`lib/screens/`)은 이 클래스를 직접 참조하지 않고,
/// 아래 [handMemoStatsProvider]와 공유 모델 [HandMemoStats]를 통해서만 접근한다.
/// (CLAUDE.md 규칙: 상태 관리 파일과 UI 화면 파일을 철저히 분리)
class HandMemoStatsNotifier extends Notifier<HandMemoStats> {
  @override
  HandMemoStats build() {
    // TODO: Firestore `users/{uid}/hand_memos` 컬렉션 카운트 연동 (추후 services/ 계층에서 주입)
    return HandMemoStats.initial();
  }

  /// 핸드 메모가 새로 기록되었을 때 호출 — 총 개수를 1 증가시킨다
  ///
  /// copyWith는 순수 데이터 복사라 예외가 날 수 없으므로 try-catch를 두지 않는다.
  /// (CLAUDE.md의 try-catch 규칙은 API 호출·데이터 파싱 등 실패 가능한 외부 연동 대상이며,
  ///  Firestore 연동이 들어가는 시점에 그 호출부에서 처리한다)
  void recordNewMemo() {
    state = state.copyWith(totalCount: state.totalCount + 1);
  }
}

/// 화면이 의존하는 공개 인터페이스 — 상태(HandMemoStats)와 이 Provider 핸들만 노출
final handMemoStatsProvider = NotifierProvider<HandMemoStatsNotifier, HandMemoStats>(
  HandMemoStatsNotifier.new,
);
