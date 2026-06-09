// GTO 프리플롭 레인지 서비스
//
// kGtoOpenRaiseRange 테이블을 기반으로 레인지 조회·계산 메서드를 제공.
// 모든 메서드는 static으로 선언 — 인스턴스 생성 없이 바로 사용 가능.

import 'package:poker_memo_ai/domain/hand_memo.dart';
import 'package:poker_memo_ai/domain/gto_range_table.dart';

/// GTO 레인지 조회 및 계산 유틸리티
class GtoRangeService {
  // 외부 인스턴스화 방지 (유틸리티 클래스)
  const GtoRangeService._();

  // ------------------------------------------------------------------
  // 레인지 조회
  // ------------------------------------------------------------------

  /// 특정 포지션에서 해당 핸드가 오픈 레이즈 레인지에 포함되는지 반환
  ///
  /// [position] 체크할 포커 포지션
  /// [hand] 체크할 핸드 (예: 'AA', 'AKs', 'AKo')
  static bool isInOpenRange(PokerPosition position, String hand) {
    // kGtoOpenRaiseRange에 포지션 키가 없으면 false 반환 (안전 처리)
    return kGtoOpenRaiseRange[position]?.contains(hand) ?? false;
  }

  /// 특정 포지션의 전체 오픈 레이즈 레인지 Set 반환
  ///
  /// [position] 조회할 포커 포지션
  /// 포지션 데이터가 없으면 빈 Set 반환
  static Set<String> getOpenRange(PokerPosition position) {
    return kGtoOpenRaiseRange[position] ?? const <String>{};
  }

  // ------------------------------------------------------------------
  // 레인지 통계
  // ------------------------------------------------------------------

  /// 포지션의 레인지 비율 반환 (%)
  ///
  /// 계산식: 레인지에 포함된 핸드 수 / 169(전체 고유 핸드 카테고리 수) * 100
  /// 169 = 쌍패 13개 + 수티드 78개 + 오프수트 78개
  static double rangePercentage(PokerPosition position) {
    // 전체 고유 핸드 카테고리 수 (169가지)
    const int totalHandCategories = 169;
    final int rangeCount = getOpenRange(position).length;
    return (rangeCount / totalHandCategories) * 100;
  }

  // ------------------------------------------------------------------
  // 핸드 그리드 생성
  // ------------------------------------------------------------------

  /// 포커 핸드 그리드용 169개 핸드 카테고리 리스트 반환
  ///
  /// 순서 (표준 핸드 매트릭스 좌상단->우하단):
  /// AA, AKs, AQs, ..., A2s, AKo, KK, KQs, ..., K2s, AQo, KQo, QQ, ..., 22
  ///
  /// 카드 랭크 순서: A > K > Q > J > T > 9 > 8 > 7 > 6 > 5 > 4 > 3 > 2
  static List<String> allHands() {
    // 포커 카드 랭크 순서 (높은 것부터 낮은 것 순)
    const List<String> ranks = [
      'A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'
    ];

    final List<String> hands = [];

    // 13x13 핸드 매트릭스를 순서대로 순회
    // 대각선: 포켓 페어 (예: AA, KK, ...)
    // 대각선 위(j > i): 수티드 핸드 (높은 랭크 앞, 낮은 랭크 뒤, s 접미사)
    // 대각선 아래(j < i): 오프수트 핸드 (높은 랭크 앞, 낮은 랭크 뒤, o 접미사)
    for (int i = 0; i < ranks.length; i++) {
      for (int j = 0; j < ranks.length; j++) {
        if (i == j) {
          // 대각선: 포켓 페어
          hands.add(ranks[i] + ranks[j]);
        } else if (j > i) {
          // 대각선 위: 수티드 핸드
          hands.add('${ranks[i]}${ranks[j]}s');
        } else {
          // 대각선 아래: 오프수트 핸드 (col 랭크가 더 높으므로 앞에 위치)
          hands.add('${ranks[j]}${ranks[i]}o');
        }
      }
    }

    return hands;
  }
}
