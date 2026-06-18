import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/tournament.dart';

/// Firestore CRUD 전담 서비스 — UI/상태 로직 없음
/// 경로: /users/{userId}/tournaments/{tournamentId}
class TournamentService {
  TournamentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _firestore.collection('users').doc(userId).collection('tournaments');

  /// 토너먼트 저장
  Future<void> addTournament(Tournament tournament) async {
    try {
      await _col(tournament.userId).add(tournament.toFirestore());
    } catch (e) {
      debugPrint('토너먼트 저장 실패: $e');
      rethrow;
    }
  }

  /// 토너먼트 실시간 스트림 — 날짜 내림차순 정렬, Firestore 변경 시 자동 갱신
  Stream<List<Tournament>> watchTournaments(String userId) {
    return _col(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map(Tournament.fromFirestore).toList();
      } catch (e) {
        debugPrint('토너먼트 목록 파싱 실패: $e');
        return <Tournament>[];
      }
    });
  }

  /// 토너먼트 삭제
  Future<void> deleteTournament(String userId, String tournamentId) async {
    try {
      await _col(userId).doc(tournamentId).delete();
    } catch (e) {
      debugPrint('토너먼트 삭제 실패: $e');
      rethrow;
    }
  }
}
