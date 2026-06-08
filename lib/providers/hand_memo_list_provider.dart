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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // 인증 전 상태면 빈 목록 반환 (main.dart에서 익명 인증 완료 후 runApp하므로 실질적으로 발생 안 함)
    if (uid == null) return Stream.value([]);
    return ref.read(_handMemoServiceProvider).watchMemos(uid);
  }

  /// 새 핸드 메모 추가 — Firestore 스트림이 자동 갱신하므로 별도 state 조작 불필요
  Future<void> addMemo(PokerPosition position, String noteText) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final memo = HandMemo(
      id: '',
      userId: uid,
      position: position,
      noteText: noteText.trim(),
      createdAt: DateTime.now(),
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
