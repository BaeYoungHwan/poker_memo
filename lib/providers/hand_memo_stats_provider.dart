import 'package:flutter/foundation.dart';
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
  void recordNewMemo() {
    try {
      state = state.copyWith(totalCount: state.totalCount + 1);
    } catch (e) {
      // 상태 갱신 중 예외가 나도 앱이 죽지 않도록 방어
      // (CLAUDE.md 행동 지침: 주요 기능에 try-catch 필수)
      debugPrint('핸드 메모 통계 갱신 실패: $e');
    }
  }
}

/// 화면이 의존하는 공개 인터페이스 — 상태(HandMemoStats)와 이 Provider 핸들만 노출
final handMemoStatsProvider = NotifierProvider<HandMemoStatsNotifier, HandMemoStats>(
  HandMemoStatsNotifier.new,
);
