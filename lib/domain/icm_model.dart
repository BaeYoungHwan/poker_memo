// ICM(Independent Chip Model) 도메인 모델
// 토너먼트 포커에서 칩 스택을 실제 상금 가치($)로 환산하는 데 필요한 데이터 구조

// ---------------------------------------------------------------------------
// TournamentPlayer -- 토너먼트 참가 플레이어 한 명
// ---------------------------------------------------------------------------

/// 토너먼트에 참여한 단일 플레이어의 이름과 칩 스택을 보유하는 불변 모델
class TournamentPlayer {
  const TournamentPlayer({
    required this.name,
    required this.chipStack,
  });

  /// 플레이어 식별자 (표시 이름, IcmResult.equities Map 키로도 사용)
  final String name;

  /// 현재 보유 칩 수 (정수, 반드시 > 0)
  final int chipStack;

  /// 불변 복사 -- 지정한 필드만 교체해 새 인스턴스 반환
  TournamentPlayer copyWith({
    String? name,
    int? chipStack,
  }) {
    return TournamentPlayer(
      name: name ?? this.name,
      chipStack: chipStack ?? this.chipStack,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentPlayer &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          chipStack == other.chipStack;

  @override
  int get hashCode => name.hashCode ^ chipStack.hashCode;

  @override
  String toString() => 'TournamentPlayer(name: $name, chips: $chipStack)';
}

// ---------------------------------------------------------------------------
// IcmResult -- ICM 계산 결과
// ---------------------------------------------------------------------------

/// ICM 계산 완료 후 각 플레이어의 상금 에퀴티를 담는 불변 결과 객체
class IcmResult {
  const IcmResult({
    required this.equities,
    required this.totalPrizePool,
  });

  /// 플레이어명 -> 상금 에퀴티($) 매핑
  /// 예: {'A': 618.37, 'B': 449.88, 'C': 331.75}
  final Map<String, double> equities;

  /// 전체 프라이즈 풀 합계($) -- equities 값의 합과 반드시 일치
  final double totalPrizePool;

  /// 불변 복사
  IcmResult copyWith({
    Map<String, double>? equities,
    double? totalPrizePool,
  }) {
    return IcmResult(
      equities: equities ?? this.equities,
      totalPrizePool: totalPrizePool ?? this.totalPrizePool,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IcmResult &&
          runtimeType == other.runtimeType &&
          totalPrizePool == other.totalPrizePool;

  @override
  int get hashCode => equities.hashCode ^ totalPrizePool.hashCode;

  @override
  String toString() =>
      'IcmResult(totalPrizePool: $totalPrizePool, equities: $equities)';
}

// ---------------------------------------------------------------------------
// IcmInputState -- ICM 계산기 화면 전체 UI 상태
// ---------------------------------------------------------------------------

/// ICM 계산기 화면 전체 상태를 담는 불변 상태 객체
/// Riverpod StateNotifier 또는 Notifier 클래스와 함께 사용
class IcmInputState {
  const IcmInputState({
    this.players = const [],
    this.prizes = const [],
    this.result,
    this.isCalculating = false,
    this.errorMessage,
  });

  /// 입력된 플레이어 목록
  final List<TournamentPlayer> players;

  /// 입력된 상금 구조 (인덱스 0 = 1등 상금, 1 = 2등 상금 ...)
  final List<double> prizes;

  /// ICM 계산 결과 -- null 이면 아직 계산 전 또는 에러 상태
  final IcmResult? result;

  /// 계산 진행 중 여부 (UI 로딩 스피너 제어)
  final bool isCalculating;

  /// 에러 메시지 -- null 이면 정상
  final String? errorMessage;

  /// 불변 복사
  /// clearResult / clearError 플래그로 명시적 null 세팅 가능
  IcmInputState copyWith({
    List<TournamentPlayer>? players,
    List<double>? prizes,
    IcmResult? result,
    bool? isCalculating,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return IcmInputState(
      players: players ?? this.players,
      prizes: prizes ?? this.prizes,
      // clearResult=true 이면 명시적으로 null 세팅
      result: clearResult ? null : (result ?? this.result),
      isCalculating: isCalculating ?? this.isCalculating,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IcmInputState &&
          runtimeType == other.runtimeType &&
          players == other.players &&
          prizes == other.prizes &&
          result == other.result &&
          isCalculating == other.isCalculating &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      players.hashCode ^
      prizes.hashCode ^
      result.hashCode ^
      isCalculating.hashCode ^
      errorMessage.hashCode;
}
