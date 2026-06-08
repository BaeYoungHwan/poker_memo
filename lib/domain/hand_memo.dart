import 'package:cloud_firestore/cloud_firestore.dart';

/// 포커 테이블 포지션 — CLAUDE.md: SB/BB/UTG/HJ/CO/BTN 등 정확히 구분 필수
enum PokerPosition {
  sb,  // Small Blind
  bb,  // Big Blind
  utg, // Under The Gun
  ep,  // Early Position (UTG+1, UTG+2 통합)
  mp,  // Middle Position (LJ 포함)
  hj,  // Hijack
  co,  // Cutoff
  btn, // Button
}

extension PokerPositionLabel on PokerPosition {
  String get label {
    switch (this) {
      case PokerPosition.sb:  return 'SB';
      case PokerPosition.bb:  return 'BB';
      case PokerPosition.utg: return 'UTG';
      case PokerPosition.ep:  return 'EP';
      case PokerPosition.mp:  return 'MP';
      case PokerPosition.hj:  return 'HJ';
      case PokerPosition.co:  return 'CO';
      case PokerPosition.btn: return 'BTN';
    }
  }
}

/// 핸드 메모 — 한 번의 포커 핸드에 대한 기록
/// UI(screens/)와 상태 관리(providers/)가 이 모델을 통해서만 데이터를 주고받는다
class HandMemo {
  const HandMemo({
    required this.id,
    required this.userId,
    required this.position,
    required this.noteText,
    required this.createdAt,
  });

  final String id;
  final String userId;

  /// 핸드를 플레이한 포지션
  final PokerPosition position;

  /// 자유 형식 메모 텍스트
  final String noteText;

  final DateTime createdAt;

  /// Firestore 문서 → HandMemo 변환
  factory HandMemo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HandMemo(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      position: PokerPosition.values.firstWhere(
        (p) => p.name == data['position'],
        // 알 수 없는 포지션은 BTN으로 폴백 (데이터 파싱 실패 방지)
        orElse: () => PokerPosition.btn,
      ),
      noteText: data['noteText'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// HandMemo → Firestore 저장용 Map 변환
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'position': position.name,
      'noteText': noteText,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  HandMemo copyWith({
    String? id,
    String? userId,
    PokerPosition? position,
    String? noteText,
    DateTime? createdAt,
  }) {
    return HandMemo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      position: position ?? this.position,
      noteText: noteText ?? this.noteText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
