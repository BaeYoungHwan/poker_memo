import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_functions/cloud_functions.dart';
import '../domain/weekly_report.dart';
import '../services/weekly_report_service.dart';

final _weeklyReportServiceProvider = Provider<WeeklyReportService>(
  (_) => WeeklyReportService(),
);

/// 주간 리포트 목록 상태 관리 — Firestore 스트림 구독
final weeklyReportListProvider =
    StreamNotifierProvider<WeeklyReportListNotifier, List<WeeklyReport>>(
  WeeklyReportListNotifier.new,
);

class WeeklyReportListNotifier extends StreamNotifier<List<WeeklyReport>> {
  @override
  Stream<List<WeeklyReport>> build() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return Stream.value([]);
      return ref.read(_weeklyReportServiceProvider).watchReports(uid);
    } catch (e) {
      debugPrint('Firebase 미초기화 상태에서 주간 리포트 로드 시도: $e');
      return Stream.value([]);
    }
  }

  /// generateWeeklyReportForUser callable 호출 → Firestore 스트림이 자동 갱신
  Future<void> generateReport() async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable(
              'generateWeeklyReportForUser');
      await callable.call({});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? '리포트 생성 중 오류가 발생했습니다.');
    }
  }
}
