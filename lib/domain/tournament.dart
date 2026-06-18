import 'package:cloud_firestore/cloud_firestore.dart';

/// 토너먼트 — 사용자가 참가한 오프라인 포커 토너먼트 1건
/// 핸드 메모(`HandMemo`)는 `tournamentId`로 이 모델을 선택적으로 참조한다
/// UI(screens/)와 상태 관리(providers/)가 이 모델을 통해서만 데이터를 주고받는다
class Tournament {
  const Tournament({
    required this.id,
    required this.userId,
    required this.name,
    required this.date,
    required this.buyIn,
    required this.createdAt,
  });

  final String id;
  final String userId;

  /// 토너먼트 이름/장소 (예: "WSOP Main Event", "강남 OO포커클럽 위클리")
  final String name;

  /// 토너먼트가 열린 날짜
  final DateTime date;

  /// 바이인 금액 (USD 기준, ICM 계산기와 동일한 컨벤션)
  final double buyIn;

  final DateTime createdAt;

  /// Firestore 문서 → Tournament 변환
  factory Tournament.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tournament(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      buyIn: (data['buyIn'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Tournament → Firestore 저장용 Map 변환
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'date': Timestamp.fromDate(date),
      'buyIn': buyIn,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Tournament copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? date,
    double? buyIn,
    DateTime? createdAt,
  }) {
    return Tournament(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      date: date ?? this.date,
      buyIn: buyIn ?? this.buyIn,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
