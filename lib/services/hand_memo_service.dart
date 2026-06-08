import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/hand_memo.dart';

/// Firestore CRUD 전담 서비스 — UI/상태 로직 없음
/// 경로: /users/{userId}/hand_memos/{memoId}
class HandMemoService {
  HandMemoService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _firestore.collection('users').doc(userId).collection('hand_memos');

  /// 핸드 메모 저장
  Future<void> addMemo(HandMemo memo) async {
    try {
      await _col(memo.userId).add(memo.toFirestore());
    } catch (e) {
      debugPrint('핸드 메모 저장 실패: $e');
      rethrow;
    }
  }

  /// 핸드 메모 실시간 스트림 — 최신순 정렬, Firestore 변경 시 자동 갱신
  Stream<List<HandMemo>> watchMemos(String userId) {
    return _col(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map(HandMemo.fromFirestore).toList();
      } catch (e) {
        debugPrint('핸드 메모 목록 파싱 실패: $e');
        return <HandMemo>[];
      }
    });
  }

  /// 핸드 메모 삭제
  Future<void> deleteMemo(String userId, String memoId) async {
    try {
      await _col(userId).doc(memoId).delete();
    } catch (e) {
      debugPrint('핸드 메모 삭제 실패: $e');
      rethrow;
    }
  }
}
