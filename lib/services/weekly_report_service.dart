import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/weekly_report.dart';

/// Firestore weekly_reports CRUD 전담 서비스 — UI/상태 로직 없음
/// 경로: /users/{userId}/weekly_reports/{reportId}
class WeeklyReportService {
  WeeklyReportService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('weekly_reports');

  /// 주간 리포트 실시간 스트림 — 최신순 10건
  Stream<List<WeeklyReport>> watchReports(String userId) {
    return _col(userId)
        .orderBy('generatedAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) {
      try {
        return snap.docs.map(WeeklyReport.fromFirestore).toList();
      } catch (e) {
        debugPrint('주간 리포트 목록 파싱 실패: $e');
        return <WeeklyReport>[];
      }
    });
  }
}
