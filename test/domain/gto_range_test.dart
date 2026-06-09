/// GTO 레인지 테이블 & 서비스 단위 테스트
///
/// 검증 항목:
/// 1. BTN 레인지 비율이 40~50% 사이인지
/// 2. UTG 레인지 비율이 10~18% 사이인지
/// 3. UTG 레인지가 BTN 레인지보다 좁은지
/// 4. AA가 BTN/CO/HJ/UTG/SB 모두에서 오픈 레인지에 포함되는지
/// 5. BB의 오픈 레인지가 비어있는지
/// 6. allHands()가 정확히 169개 핸드를 반환하는지

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_memo_ai/domain/hand_memo.dart';
import 'package:poker_memo_ai/domain/gto_range_table.dart';
import 'package:poker_memo_ai/services/gto_range_service.dart';

void main() {
  group('GtoRangeService - 레인지 비율 검증', () {
    // BTN 레인지 비율이 40~50% 사이여야 함 (6-max 기준 약 44%)
    test('BTN 레인지 비율이 40% 이상 50% 이하', () {
      final double pct = GtoRangeService.rangePercentage(PokerPosition.btn);
      expect(pct, greaterThanOrEqualTo(40.0),
          reason: 'BTN 레인지는 최소 40%여야 합니다. 실제: ${pct}%');
      expect(pct, lessThanOrEqualTo(50.0),
          reason: 'BTN 레인지는 최대 50%여야 합니다. 실제: ${pct}%');
    });

    // UTG 레인지 비율이 10~18% 사이여야 함 (6-max 기준 약 13%)
    test('UTG 레인지 비율이 10% 이상 18% 이하', () {
      final double pct = GtoRangeService.rangePercentage(PokerPosition.utg);
      expect(pct, greaterThanOrEqualTo(10.0),
          reason: 'UTG 레인지는 최소 10%여야 합니다. 실제: ${pct}%');
      expect(pct, lessThanOrEqualTo(18.0),
          reason: 'UTG 레인지는 최대 18%여야 합니다. 실제: ${pct}%');
    });
  });

  group('GtoRangeService - 레인지 포함 관계 검증', () {
    // UTG 레인지는 BTN 레인지보다 좁아야 함 (핸드 수 비교)
    test('UTG 레인지 핸드 수가 BTN 레인지 핸드 수보다 적음', () {
      final int utg = GtoRangeService.getOpenRange(PokerPosition.utg).length;
      final int btn = GtoRangeService.getOpenRange(PokerPosition.btn).length;
      expect(utg, lessThan(btn),
          reason: 'UTG(${utg}핸드)는 BTN(${btn}핸드)보다 좁아야 합니다');
    });

    // AA는 모든 오픈 포지션에서 레인지에 포함되어야 함
    test('AA가 BTN/CO/HJ/UTG/SB 모두에서 오픈 레인지에 포함', () {
      // 오픈 레인지가 있는 포지션 목록 (BB 제외)
      const List<PokerPosition> openPositions = [
        PokerPosition.btn,
        PokerPosition.co,
        PokerPosition.hj,
        PokerPosition.utg,
        PokerPosition.sb,
      ];

      for (final pos in openPositions) {
        expect(
          GtoRangeService.isInOpenRange(pos, 'AA'),
          isTrue,
          reason: 'AA는 ${pos.name} 레인지에 포함되어야 합니다',
        );
      }
    });

    // BB의 오픈 레인지는 비어있어야 함
    test('BB 오픈 레인지가 비어있음', () {
      final Set<String> bbRange = GtoRangeService.getOpenRange(PokerPosition.bb);
      expect(bbRange, isEmpty,
          reason: 'BB는 오픈 레인지가 없어야 합니다');
    });
  });

  group('GtoRangeService - allHands() 검증', () {
    // 전체 고유 핸드 카테고리는 정확히 169개여야 함
    // (쌍패 13 + 수티드 78 + 오프수트 78 = 169)
    test('allHands()가 정확히 169개 핸드 반환', () {
      final List<String> hands = GtoRangeService.allHands();
      expect(hands.length, equals(169),
          reason: '전체 고유 핸드 카테고리는 169개여야 합니다. 실제: ${hands.length}개');
    });

    // 중복 핸드가 없어야 함 (Set 변환 후 크기가 동일해야 함)
    test('allHands()에 중복 핸드 없음', () {
      final List<String> hands = GtoRangeService.allHands();
      final Set<String> uniqueHands = hands.toSet();
      expect(uniqueHands.length, equals(hands.length),
          reason: '중복 핸드가 있습니다. 총 ${hands.length}개 중 고유: ${uniqueHands.length}개');
    });
  });

  group('kGtoOpenRaiseRange - 상수 테이블 직접 검증', () {
    // 테이블에 모든 8개 포지션 키가 존재해야 함
    test('모든 포지션 키가 테이블에 존재', () {
      for (final pos in PokerPosition.values) {
        expect(kGtoOpenRaiseRange.containsKey(pos), isTrue,
            reason: '${pos.name} 포지션이 테이블에 없습니다');
      }
    });

    // 포지션별 레인지 크기 출력 (디버그 보조)
    test('포지션별 레인지 핸드 수 확인', () {
      for (final pos in PokerPosition.values) {
        final int count = kGtoOpenRaiseRange[pos]?.length ?? 0;
        final double pct = (count / 169) * 100;
        // ignore: avoid_print
        print('${pos.name.toUpperCase()}: ${count}핸드 (${pct.toStringAsFixed(1)}%)');
      }
      expect(kGtoOpenRaiseRange, isNotEmpty);
    });
  });
}
