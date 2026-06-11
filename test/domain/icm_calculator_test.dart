import 'package:flutter_test/flutter_test.dart';
import 'package:poker_memo_ai/domain/icm_model.dart';
import 'package:poker_memo_ai/services/icm_calculator.dart';

void main() {
  // ---------------------------------------------------------------------------
  // 황금 케이스 1: icmizer.com 검증값과 비교
  // ---------------------------------------------------------------------------
  group('황금 케이스 1 -- A=50000, B=30000, C=20000 / 상금 1000/500/200', () {
    late IcmResult result;

    setUpAll(() {
      final players = [
        const TournamentPlayer(name: 'A', chipStack: 50000),
        const TournamentPlayer(name: 'B', chipStack: 30000),
        const TournamentPlayer(name: 'C', chipStack: 20000),
      ];
      final prizes = [1000.0, 500.0, 200.0];
      result = IcmCalculator.calculate(players, prizes);
    });

    // 에퀴티 합 = 프라이즈 풀 (불변 조건)
    test('에퀴티 합계가 정확히 프라이즈 풀 1700과 일치해야 한다', () {
      final total = result.equities.values.fold(0.0, (a, b) => a + b);
      // 부동소수점 허용 오차 0.01
      expect(total, closeTo(1700.0, 0.01));
    });

    // Malmuth-Harville 수식 직접 계산값 A≈701.79, B≈552.5, C≈445.71
    test('A 에퀴티 ≈ 701.79 (±1)', () {
      expect(result.equities['A']!, closeTo(701.79, 1.0));
    });

    test('B 에퀴티 ≈ 552.50 (±1)', () {
      expect(result.equities['B']!, closeTo(552.5, 1.0));
    });

    test('C 에퀴티 ≈ 445.71 (±1)', () {
      expect(result.equities['C']!, closeTo(445.71, 1.0));
    });

    test('totalPrizePool == 1700', () {
      expect(result.totalPrizePool, closeTo(1700.0, 0.001));
    });
  });

  // ---------------------------------------------------------------------------
  // 황금 케이스 2: 동일 칩 -- 세 플레이어 에퀴티 거의 동일
  // ---------------------------------------------------------------------------
  group('황금 케이스 2 -- 동일 칩 A=33333, B=33333, C=33334 / 상금 600/300/100', () {
    late IcmResult result;

    setUpAll(() {
      final players = [
        const TournamentPlayer(name: 'A', chipStack: 33333),
        const TournamentPlayer(name: 'B', chipStack: 33333),
        const TournamentPlayer(name: 'C', chipStack: 33334),
      ];
      final prizes = [600.0, 300.0, 100.0];
      result = IcmCalculator.calculate(players, prizes);
    });

    // 칩이 거의 동일하므로 각 에퀴티는 333 부근 (+-10 허용)
    test('A 에퀴티가 333 근방이어야 한다 (±10)', () {
      expect(result.equities['A']!, closeTo(333.0, 10.0));
    });

    test('B 에퀴티가 333 근방이어야 한다 (±10)', () {
      expect(result.equities['B']!, closeTo(333.0, 10.0));
    });

    test('C 에퀴티가 333 근방이어야 한다 (±10)', () {
      expect(result.equities['C']!, closeTo(333.0, 10.0));
    });

    test('에퀴티 합이 1000과 일치해야 한다', () {
      final total = result.equities.values.fold(0.0, (a, b) => a + b);
      expect(total, closeTo(1000.0, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // 황금 케이스 3: 극단 케이스 -- A=99999, B=1
  // ---------------------------------------------------------------------------
  group('황금 케이스 3 -- 극단 A=99999, B=1 / 상금 1000/200', () {
    late IcmResult result;

    setUpAll(() {
      final players = [
        const TournamentPlayer(name: 'A', chipStack: 99999),
        const TournamentPlayer(name: 'B', chipStack: 1),
      ];
      final prizes = [1000.0, 200.0];
      result = IcmCalculator.calculate(players, prizes);
    });

    test('에퀴티 합 = 1200 (불변 조건)', () {
      final total = result.equities.values.fold(0.0, (a, b) => a + b);
      expect(total, closeTo(1200.0, 0.01));
    });

    // A는 칩이 거의 전부이므로 에퀴티가 1등 상금인 1000에 매우 가까워야 함
    test('A 에퀴티가 B보다 훨씬 높아야 한다', () {
      expect(result.equities['A']! > result.equities['B']!, isTrue);
    });

    test('B 에퀴티가 양수여야 한다', () {
      expect(result.equities['B']!, greaterThan(0.0));
    });
  });

  // ---------------------------------------------------------------------------
  // 잘못된 입력 테스트
  // ---------------------------------------------------------------------------
  group('잘못된 입력 -- ArgumentError / AssertionError 발생 확인', () {
    test('플레이어 1명 -> ArgumentError', () {
      final players = [const TournamentPlayer(name: 'A', chipStack: 1000)];
      final prizes = [1000.0];
      expect(
        () => IcmCalculator.calculate(players, prizes),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('플레이어 10명 -> ArgumentError', () {
      final players = List.generate(
        10,
        (i) => TournamentPlayer(name: 'P$i', chipStack: 1000),
      );
      final prizes = [1000.0];
      expect(
        () => IcmCalculator.calculate(players, prizes),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('칩 스택 0인 플레이어 -> ArgumentError', () {
      final players = [
        const TournamentPlayer(name: 'A', chipStack: 1000),
        const TournamentPlayer(name: 'B', chipStack: 0),
      ];
      final prizes = [1000.0, 200.0];
      expect(
        () => IcmCalculator.calculate(players, prizes),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('빈 상금 배열 -> ArgumentError', () {
      final players = [
        const TournamentPlayer(name: 'A', chipStack: 1000),
        const TournamentPlayer(name: 'B', chipStack: 1000),
      ];
      expect(
        () => IcmCalculator.calculate(players, []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('상금 개수가 플레이어 수 초과 -> ArgumentError', () {
      final players = [
        const TournamentPlayer(name: 'A', chipStack: 1000),
        const TournamentPlayer(name: 'B', chipStack: 1000),
      ];
      final prizes = [1000.0, 500.0, 200.0]; // 3개이지만 플레이어는 2명
      expect(
        () => IcmCalculator.calculate(players, prizes),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
