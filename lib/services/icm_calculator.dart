import 'dart:math' as math;

import 'package:poker_memo_ai/domain/icm_model.dart';

/// ICM(Independent Chip Model) 계산기 -- Malmuth-Harville 알고리즘
///
/// [알고리즘 개요]
/// 1등 확률:  P(i=1등) = chips_i / totalChips
/// k등 확률:  P(i=k등) = 재귀적으로, 다른 플레이어 j가 먼저 순위를 결정한 뒤
///            나머지 중 i가 k-1등이 될 확률의 가중합
/// 에퀴티:    Equity(i) = Σ_k [ P(i=k등) * Prize(k) ]
///
/// 메모이제이션으로 중복 재귀 호출을 방지한다.
class IcmCalculator {
  // 외부에서 인스턴스화 불필요 -- 모든 메서드가 static
  IcmCalculator._();

  // ---------------------------------------------------------------------------
  // 공개 API
  // ---------------------------------------------------------------------------

  /// ICM 에퀴티를 계산하여 [IcmResult]로 반환
  ///
  /// [players] 토너먼트 플레이어 목록 (2~9명)
  /// [prizes]  상금 구조, prizes[0]=1등, prizes[1]=2등 ... (길이 <= players 수)
  static IcmResult calculate(
    List<TournamentPlayer> players,
    List<double> prizes,
  ) {
    // ---- 입력 검증 ----
    if (players.length < 2) {
      throw ArgumentError(
          '플레이어 수는 최소 2명 이상이어야 합니다. 현재: ${players.length}');
    }
    if (players.length > 9) {
      throw ArgumentError(
          '플레이어 수는 최대 9명 이하여야 합니다. 현재: ${players.length}');
    }
    if (prizes.isEmpty) {
      throw ArgumentError('상금 배열이 비어 있습니다.');
    }
    if (prizes.length > players.length) {
      throw ArgumentError(
          '상금 개수(${prizes.length})가 플레이어 수(${players.length})를 초과합니다.');
    }
    for (final p in players) {
      if (p.chipStack <= 0) {
        throw ArgumentError(
            '모든 플레이어의 칩 스택은 0보다 커야 합니다. ${p.name}: ${p.chipStack}');
      }
    }

    // ---- 계산 준비 ----
    // 칩 스택 정수 배열 (인덱스 기반 재귀 처리를 위해)
    final chips = players.map((p) => p.chipStack).toList();

    // 전체 플레이어 인덱스 리스트
    final allIndices = List<int>.generate(players.length, (i) => i);

    // 메모이제이션 캐시:
    //   key   : 남은 플레이어 인덱스를 정렬 후 '_' 로 join
    //   value : Map<플레이어인덱스, 1등이 될 확률>
    final Map<String, Map<int, double>> memo = {};

    // ---- 각 플레이어의 에퀴티 계산 ----
    final Map<String, double> equities = {};

    for (int i = 0; i < players.length; i++) {
      double equity = 0.0;

      // k등 확률 x 상금(k) 의 합산
      // prizes.length 까지만 반복 (상금 없는 등수는 기여 0)
      for (int k = 0; k < prizes.length; k++) {
        final prob = _rankProbability(
          targetIndex: i,
          rank: k,
          remaining: allIndices,
          chips: chips,
          memo: memo,
        );
        equity += prob * prizes[k];
      }

      // 부동소수점 누적 오차 방지: 소수점 6자리에서 반올림
      equities[players[i].name] = _roundTo6(equity);
    }

    // 전체 프라이즈 풀 = 상금 배열 합산
    final totalPrizePool = prizes.fold(0.0, (sum, p) => sum + p);

    return IcmResult(
      equities: Map.unmodifiable(equities),
      totalPrizePool: _roundTo6(totalPrizePool),
    );
  }

  // ---------------------------------------------------------------------------
  // 내부 재귀 헬퍼
  // ---------------------------------------------------------------------------

  /// [targetIndex] 플레이어가 [remaining] 그룹에서 정확히 [rank]등 (0-indexed) 이 될 확률
  ///
  /// rank=0 : 1등 확률 → _finishFirstProbability 직접 호출
  /// rank=k : 다른 플레이어 j 가 먼저 확정된 후,
  ///          나머지 그룹에서 targetIndex 가 k-1등 될 확률의 가중합
  ///          P(i=k등 | remaining) =
  ///            Σ_{j != i} [ P(j=1등 | remaining) * P(i=k-1등 | remaining\{j}) ]
  static double _rankProbability({
    required int targetIndex,
    required int rank,
    required List<int> remaining,
    required List<int> chips,
    required Map<String, Map<int, double>> memo,
  }) {
    // 기저 사례: 1등 확률
    if (rank == 0) {
      return _finishFirstProbability(targetIndex, remaining, chips, memo);
    }

    // rank >= 1 : 다른 플레이어 j 가 먼저 확정되는 모든 경우 합산
    double prob = 0.0;

    for (final j in remaining) {
      if (j == targetIndex) continue; // 자기 자신 제외

      // j 가 현재 그룹에서 1등이 될 확률 (Malmuth-Harville)
      final jFirstProb =
          _finishFirstProbability(j, remaining, chips, memo);

      // j 제외 후 남은 그룹에서 targetIndex 가 rank-1등이 될 확률 (재귀)
      final remainingWithoutJ = remaining.where((x) => x != j).toList();
      final conditionalProb = _rankProbability(
        targetIndex: targetIndex,
        rank: rank - 1,
        remaining: remainingWithoutJ,
        chips: chips,
        memo: memo,
      );

      prob += jFirstProb * conditionalProb;
    }

    return prob;
  }

  /// [targetIndex] 가 [remaining] 플레이어들 중 1등이 될 확률
  ///
  /// Malmuth-Harville 공식:
  ///   P(i=1등 | remaining) = chips[i] / Σ_{j in remaining} chips[j]
  ///
  /// 메모이제이션 키: remaining 을 오름차순 정렬 후 '_' join
  static double _finishFirstProbability(
    int targetIndex,
    List<int> remaining,
    List<int> chips,
    Map<String, Map<int, double>> memo,
  ) {
    // 캐시 키 생성 -- 정렬해야 순서가 달라도 같은 집합을 동일 키로 인식
    final sortedRemaining = [...remaining]..sort();
    final cacheKey = sortedRemaining.join('_');

    // 캐시 히트 확인
    if (memo.containsKey(cacheKey) &&
        memo[cacheKey]!.containsKey(targetIndex)) {
      return memo[cacheKey]![targetIndex]!;
    }

    // 남은 플레이어들의 전체 칩 합산
    final totalChips =
        remaining.fold(0, (sum, idx) => sum + chips[idx]);

    // 방어 코드: 전체 칩이 0이면 확률 0 (정상 입력에서는 발생 안 함)
    if (totalChips == 0) return 0.0;

    // Malmuth-Harville 1등 확률 계산
    final prob = chips[targetIndex] / totalChips;

    // 캐시에 저장 (같은 remaining 집합에서 다른 targetIndex 재계산 방지)
    memo.putIfAbsent(cacheKey, () => {})[targetIndex] = prob;

    return prob;
  }

  // ---------------------------------------------------------------------------
  // 유틸리티
  // ---------------------------------------------------------------------------

  /// 부동소수점 누적 오차 방지용 반올림 -- 소수점 6자리 기준
  static double _roundTo6(double value) {
    final factor = math.pow(10, 6).toDouble();
    return (value * factor).round() / factor;
  }
}
