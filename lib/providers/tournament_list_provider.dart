import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tournament.dart';
import '../services/tournament_service.dart';

final _tournamentServiceProvider = Provider<TournamentService>(
  (_) => TournamentService(),
);

/// 토너먼트 목록 상태 관리 — UI가 참조하는 유일한 인터페이스
/// StreamNotifier: Firestore 스트림을 구독하고 변경 시 자동으로 UI 갱신
final tournamentListProvider =
    StreamNotifierProvider<TournamentListNotifier, List<Tournament>>(
  TournamentListNotifier.new,
);

class TournamentListNotifier extends StreamNotifier<List<Tournament>> {
  @override
  Stream<List<Tournament>> build() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      // 인증 전이거나 Firebase 미초기화 상태면 빈 목록 반환
      if (uid == null) return Stream.value([]);
      return ref.read(_tournamentServiceProvider).watchTournaments(uid);
    } catch (e) {
      // Firebase 미초기화(웹 설정 누락 등) 시 앱이 죽지 않도록 빈 목록으로 폴백
      debugPrint('Firebase 미초기화 상태에서 토너먼트 로드 시도: $e');
      return Stream.value([]);
    }
  }

  /// 새 토너먼트 추가 — Firestore 스트림이 자동 갱신하므로 별도 state 조작 불필요
  Future<void> addTournament(String name, DateTime date, double buyIn) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final tournament = Tournament(
      id: '',
      userId: uid,
      name: name.trim(),
      date: date,
      buyIn: buyIn,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(_tournamentServiceProvider).addTournament(tournament);
    } catch (e) {
      debugPrint('토너먼트 추가 실패: $e');
      rethrow;
    }
  }

  /// 토너먼트 삭제 — Firestore 스트림이 자동 갱신
  Future<void> deleteTournament(String tournamentId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await ref.read(_tournamentServiceProvider).deleteTournament(uid, tournamentId);
    } catch (e) {
      debugPrint('토너먼트 삭제 실패: $e');
      rethrow;
    }
  }
}
