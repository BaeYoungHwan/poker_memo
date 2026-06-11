// ICM 계산기 상태 관리 Provider
// UI 화면(icm_calculator_screen.dart)은 이 파일을 통해서만 상태에 접근한다.
// (CLAUDE.md 규칙: 상태 관리 파일과 UI 화면 파일을 철저히 분리)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/icm_model.dart';
import '../services/icm_calculator.dart';

// ---------------------------------------------------------------------------
// IcmNotifier -- ICM 계산기 화면 전체 상태를 관리하는 Notifier
// ---------------------------------------------------------------------------

/// IcmInputState를 직접 상태 타입으로 사용하는 Notifier
/// IcmInputState 자체가 화면 전체 상태를 담고 있으므로 별도 래퍼 클래스 불필요
class IcmNotifier extends Notifier<IcmInputState> {
  @override
  IcmInputState build() {
    // 기본 상태: 빈 플레이어 목록, 빈 상금 배열, 결과 없음
    return const IcmInputState();
  }

  // ---------------------------------------------------------------------------
  // 플레이어 관리 메서드
  // ---------------------------------------------------------------------------

  /// 플레이어 추가 -- 최대 9명 제한 (초과 시 무시)
  void addPlayer(TournamentPlayer player) {
    // 최대 9명 제한 (IcmCalculator 입력 검증과 동일 기준)
    if (state.players.length >= 9) return;

    state = state.copyWith(
      players: [...state.players, player],
      clearResult: true, // 플레이어 변경 시 이전 결과 초기화
      clearError: true,
    );
  }

  /// 플레이어 제거 -- 인덱스 기반, 범위 초과 시 무시
  void removePlayer(int index) {
    if (index < 0 || index >= state.players.length) return;

    final updatedPlayers = [...state.players]..removeAt(index);
    state = state.copyWith(
      players: updatedPlayers,
      clearResult: true,
      clearError: true,
    );
  }

  /// 플레이어 정보 수정 -- 특정 인덱스의 플레이어를 교체
  void updatePlayer(int index, TournamentPlayer updated) {
    if (index < 0 || index >= state.players.length) return;

    final updatedPlayers = [...state.players];
    updatedPlayers[index] = updated;
    state = state.copyWith(
      players: updatedPlayers,
      clearResult: true,
      clearError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // 상금 관리 메서드
  // ---------------------------------------------------------------------------

  /// 상금 구조 업데이트 -- 1등/2등/3등 상금 배열 전체 교체
  void updatePrizes(List<double> prizes) {
    state = state.copyWith(
      prizes: prizes,
      clearResult: true,
      clearError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // ICM 계산 메서드
  // ---------------------------------------------------------------------------

  /// ICM 에퀴티 계산 실행
  /// IcmCalculator.calculate() 를 호출하고 결과 또는 에러를 상태에 반영한다.
  /// 계산 중에는 isCalculating=true 로 로딩 스피너를 표시한다.
  Future<void> calculate() async {
    // 계산 중복 실행 방지
    if (state.isCalculating) return;

    // 계산 시작 -- 이전 에러 초기화, 로딩 시작
    state = state.copyWith(
      isCalculating: true,
      clearError: true,
      clearResult: true,
    );

    try {
      // ICM 계산은 CPU 연산만 하므로 synchronous지만,
      // 추후 비동기 확장(9명 이상 대규모 시뮬레이션 등) 대비해 await 패턴 유지
      final result = await Future(() {
        return IcmCalculator.calculate(state.players, state.prizes);
      });

      // 계산 성공 -- 결과 반영
      state = state.copyWith(
        result: result,
        isCalculating: false,
      );
    } on ArgumentError catch (e) {
      // ArgumentError: 입력 검증 실패 (플레이어 수, 상금 범위, 칩 스택 등)
      state = state.copyWith(
        isCalculating: false,
        errorMessage: e.message.toString(),
        clearResult: true,
      );
    } catch (e) {
      // 그 외 예외 처리 (예측 불가한 런타임 오류 방어)
      state = state.copyWith(
        isCalculating: false,
        errorMessage: '계산 중 오류가 발생했습니다: $e',
        clearResult: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 초기화
  // ---------------------------------------------------------------------------

  /// 모든 상태를 초기값으로 되돌린다
  void reset() {
    state = const IcmInputState();
  }
}

// ---------------------------------------------------------------------------
// 공개 Provider -- 화면에서 이 Provider만 참조한다
// ---------------------------------------------------------------------------

/// ICM 계산기 화면이 의존하는 공개 인터페이스
final icmProvider = NotifierProvider<IcmNotifier, IcmInputState>(
  IcmNotifier.new,
);
