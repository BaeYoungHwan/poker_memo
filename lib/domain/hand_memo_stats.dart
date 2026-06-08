/// 핸드 메모 통계 — 화면(UI)과 상태 관리(Provider) 양쪽이 공유하는 순수 데이터 모델
///
/// Flutter/Riverpod에 의존하지 않는 순수 Dart 클래스로 두어,
/// `lib/screens/`(UI)와 `lib/providers/`(상태 관리)가 서로의 구현이 아닌
/// 이 모델(인터페이스 역할)을 통해서만 데이터를 주고받도록 한다.
class HandMemoStats {
  const HandMemoStats({required this.totalCount});

  /// 지금까지 기록된 핸드 메모 총 개수
  final int totalCount;

  factory HandMemoStats.initial() => const HandMemoStats(totalCount: 0);

  HandMemoStats copyWith({int? totalCount}) {
    return HandMemoStats(totalCount: totalCount ?? this.totalCount);
  }
}
