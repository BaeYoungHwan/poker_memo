import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_memo_ai/domain/tournament.dart';

void main() {
  group('Tournament — Firestore 직렬화 라운드트립', () {
    test('toFirestore -> fromFirestore 변환 시 모든 필드가 보존된다', () async {
      final firestore = FakeFirebaseFirestore();
      final original = Tournament(
        id: '',
        userId: 'user1',
        name: 'WSOP Main Event',
        date: DateTime(2026, 7, 1),
        buyIn: 500.0,
        createdAt: DateTime(2026, 6, 17, 10, 30),
      );

      final docRef = await firestore.collection('tournaments').add(original.toFirestore());
      final snapshot = await docRef.get();
      final restored = Tournament.fromFirestore(snapshot);

      expect(restored.id, docRef.id);
      expect(restored.userId, 'user1');
      expect(restored.name, 'WSOP Main Event');
      expect(restored.date, DateTime(2026, 7, 1));
      expect(restored.buyIn, 500.0);
      expect(restored.createdAt, DateTime(2026, 6, 17, 10, 30));
    });
  });

  group('Tournament.copyWith', () {
    test('지정한 필드만 갱신하고 나머지는 유지한다', () {
      final original = Tournament(
        id: '1',
        userId: 'u',
        name: 'A',
        date: DateTime(2026, 1, 1),
        buyIn: 100,
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(name: 'B', buyIn: 200);

      expect(updated.name, 'B');
      expect(updated.buyIn, 200);
      expect(updated.id, '1');
      expect(updated.userId, 'u');
    });
  });
}
