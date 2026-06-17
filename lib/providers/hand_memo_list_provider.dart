import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/hand_memo.dart';
import '../services/hand_memo_service.dart';

final _handMemoServiceProvider = Provider<HandMemoService>(
  (_) => HandMemoService(),
);

/// 핸드 메모 목록 상태 관리 — UI가 참조하는 유일한 인터페이스
/// StreamNotifier: Firestore 스트림을 구독하고 변경 시 자동으로 UI 갱신
final handMemoListProvider =
    StreamNotifierProvider<HandMemoListNotifier, List<HandMemo>>(
  HandMemoListNotifier.new,
);

class HandMemoListNotifier extends StreamNotifier<List<HandMemo>> {
  @override
  Stream<List<HandMemo>> build() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      // 인증 전이거나 Firebase 미초기화 상태면 빈 목록 반환
      if (uid == null) return Stream.value([]);
      return ref.read(_handMemoServiceProvider).watchMemos(uid);
    } catch (e) {
      // Firebase 미초기화(웹 설정 누락 등) 시 앱이 죽지 않도록 빈 목록으로 폴백
      debugPrint('Firebase 미초기화 상태에서 메모 로드 시도: $e');
      return Stream.value([]);
    }
  }

  /// 새 핸드 메모 추가 — Firestore 스트림이 자동 갱신하므로 별도 state 조작 불필요
  /// [tournamentId]가 주어지면 해당 토너먼트와 연결되고, null이면 미연결 메모로 저장된다
  Future<void> addMemo(
    PokerPosition position,
    String noteText, {
    String? tournamentId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final memo = HandMemo(
      id: '',
      userId: uid,
      position: position,
      noteText: noteText.trim(),
      createdAt: DateTime.now(),
      tournamentId: tournamentId,
    );

    try {
      await ref.read(_handMemoServiceProvider).addMemo(memo);
    } catch (e) {
      debugPrint('메모 추가 실패: $e');
      rethrow;
    }
  }

  /// 핸드 메모 삭제 — Firestore 스트림이 자동 갱신
  Future<void> deleteMemo(String memoId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await ref.read(_handMemoServiceProvider).deleteMemo(uid, memoId);
    } catch (e) {
      debugPrint('메모 삭제 실패: $e');
      rethrow;
    }
  }
}
