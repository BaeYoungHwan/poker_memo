import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:poker_memo_ai/domain/weekly_report.dart';

void main() {
  group('WeeklyReport.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('정상 데이터로 파싱 성공', () async {
      final now = Timestamp.now();
      final weekStart = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 7)));

      await fakeFirestore
          .collection('users')
          .doc('u1')
          .collection('weekly_reports')
          .doc('r1')
          .set({
        'generatedAt': now,
        'weekStart': weekStart,
        'handsAnalyzed': 42,
        'topLeaks': ['leak1', 'leak2'],
        'reportText': '리포트 전문',
        'status': 'success',
      });

      final snap = await fakeFirestore
          .collection('users')
          .doc('u1')
          .collection('weekly_reports')
          .doc('r1')
          .get();

      final report = WeeklyReport.fromFirestore(snap);

      expect(report.id, 'r1');
      expect(report.handsAnalyzed, 42);
      expect(report.topLeaks, ['leak1', 'leak2']);
      expect(report.reportText, '리포트 전문');
      expect(report.status, 'success');
    });

    test('topLeaks 누락 시 빈 리스트 반환', () async {
      final now = Timestamp.now();
      final weekStart = Timestamp.fromDate(DateTime.now());

      await fakeFirestore
          .collection('users')
          .doc('u2')
          .collection('weekly_reports')
          .doc('r2')
          .set({
        'generatedAt': now,
        'weekStart': weekStart,
        'handsAnalyzed': 0,
        'reportText': '',
        'status': 'pending',
      });

      final snap = await fakeFirestore
          .collection('users')
          .doc('u2')
          .collection('weekly_reports')
          .doc('r2')
          .get();

      final report = WeeklyReport.fromFirestore(snap);
      expect(report.topLeaks, isEmpty);
    });
  });
}
