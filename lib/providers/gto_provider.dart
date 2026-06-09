import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/hand_memo.dart';

/// GTO 화면 상태 모델 — 포지션 선택 + AI 조언 입출력 상태를 보유
///
/// UI(screens/)는 이 모델을 통해서만 GTO 상태를 읽는다.
/// (CLAUDE.md 규칙: 상태 관리 파일과 UI 화면 파일을 철저히 분리)
class GtoState {
  const GtoState({
    required this.selectedPosition,
    required this.handMemoInput,
    this.gtoAdviceResult,
    required this.isLoadingAdvice,
    this.errorMessage,
  });

  /// 현재 선택된 포커 포지션 — 기본값 BTN (레인지 가장 넓음)
  final PokerPosition selectedPosition;

  /// AI 조언 요청 시 전달할 핸드 상황 텍스트
  final String handMemoInput;

  /// AI(Cloud Function)로부터 받은 조언 결과 — null이면 아직 결과 없음
  final String? gtoAdviceResult;

  /// Cloud Function 호출 진행 중 플래그
  final bool isLoadingAdvice;

  /// 오류 메시지 — null이면 오류 없음
  final String? errorMessage;

  /// 기본 초기 상태 팩토리
  factory GtoState.initial() {
    return const GtoState(
      selectedPosition: PokerPosition.btn,
      handMemoInput: '',
      gtoAdviceResult: null,
      isLoadingAdvice: false,
      errorMessage: null,
    );
  }

  /// 불변 상태를 부분 갱신하는 copyWith
  ///
  /// gtoAdviceResult, errorMessage는 null 초기화와 "변경 없음"을 구분하기 위해
  /// sentinel 패턴을 사용한다.
  GtoState copyWith({
    PokerPosition? selectedPosition,
    String? handMemoInput,
    Object? gtoAdviceResult = _sentinel,
    bool? isLoadingAdvice,
    Object? errorMessage = _sentinel,
  }) {
    return GtoState(
      selectedPosition: selectedPosition ?? this.selectedPosition,
      handMemoInput: handMemoInput ?? this.handMemoInput,
      gtoAdviceResult: gtoAdviceResult == _sentinel
          ? this.gtoAdviceResult
          : gtoAdviceResult as String?,
      isLoadingAdvice: isLoadingAdvice ?? this.isLoadingAdvice,
      errorMessage:
          errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
    );
  }
}

/// copyWith에서 null 초기화와 "변경 없음"을 구분하기 위한 sentinel 값
const _sentinel = Object();

// ---------------------------------------------------------------------------
// Notifier — 상태 변이 메서드 제공
// ---------------------------------------------------------------------------

/// GTO 상태 관리 Notifier
///
/// AI 조언 Cloud Function 호출 자체는 화면(screens/)에서 직접 처리하고,
/// 이 Notifier는 순수 상태 업데이트 인터페이스만 노출한다.
class GtoNotifier extends Notifier<GtoState> {
  @override
  GtoState build() => GtoState.initial();

  // ------------------------------------------------------------------
  // 포지션 선택
  // ------------------------------------------------------------------

  /// 포지션을 변경하고, 기존 AI 조언 결과와 오류 메시지를 초기화한다
  ///
  /// 포지션이 달라지면 이전 조언은 맥락이 다르므로 자동 삭제.
  void selectPosition(PokerPosition position) {
    state = state.copyWith(
      selectedPosition: position,
      gtoAdviceResult: null,
      errorMessage: null,
    );
  }

  // ------------------------------------------------------------------
  // AI 조언 입력 텍스트
  // ------------------------------------------------------------------

  /// AI 조언용 핸드 상황 입력 텍스트를 업데이트한다
  void updateHandMemoInput(String text) {
    state = state.copyWith(handMemoInput: text);
  }

  // ------------------------------------------------------------------
  // AI 조언 결과 초기화
  // ------------------------------------------------------------------

  /// 이전 조언 결과와 오류를 모두 지운다 — 재입력 전 화면 리셋 용도
  void clearAdvice() {
    state = state.copyWith(
      gtoAdviceResult: null,
      errorMessage: null,
    );
  }

  // ------------------------------------------------------------------
  // AI 조언 상태 업데이트 (화면에서 Cloud Function 호출 후 결과 주입)
  // ------------------------------------------------------------------

  /// Cloud Function 호출 시작/종료 시 로딩 상태를 토글한다
  void setAdviceLoading(bool loading) {
    state = state.copyWith(
      isLoadingAdvice: loading,
      // 로딩 시작이면 이전 오류 메시지를 초기화
      errorMessage: loading ? null : state.errorMessage,
    );
  }

  /// Cloud Function으로부터 받은 조언 결과를 저장한다
  void setAdviceResult(String result) {
    state = state.copyWith(
      gtoAdviceResult: result,
      isLoadingAdvice: false,
      errorMessage: null,
    );
  }

  /// Cloud Function 호출 실패 시 오류 메시지를 저장한다
  void setAdviceError(String error) {
    state = state.copyWith(
      errorMessage: error,
      isLoadingAdvice: false,
      gtoAdviceResult: null,
    );
  }
}

// ---------------------------------------------------------------------------
// 공개 Provider
// ---------------------------------------------------------------------------

/// 화면이 의존하는 공개 인터페이스 — GtoState와 GtoNotifier만 노출
final gtoProvider = NotifierProvider<GtoNotifier, GtoState>(GtoNotifier.new);
