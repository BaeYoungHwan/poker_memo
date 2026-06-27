import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_memo_ai/domain/weekly_report.dart';
import 'package:poker_memo_ai/providers/weekly_report_provider.dart';
import 'package:poker_memo_ai/screens/weekly_report_screen.dart';

// Firebase 없이 테스트하기 위한 가짜 Notifier
class _FakeReportNotifier extends WeeklyReportListNotifier {
  final List<WeeklyReport> _reports;
  _FakeReportNotifier([this._reports = const []]);

  @override
  Stream<List<WeeklyReport>> build() => Stream.value(_reports);

  @override
  Future<void> generateReport() async {}
}

WeeklyReport _fakeReport() => WeeklyReport(
      id: 'r1',
      generatedAt: DateTime(2026, 6, 27),
      weekStart: DateTime(2026, 6, 20),
      handsAnalyzed: 10,
      topLeaks: ['오버폴드', '3벳 부족'],
      reportText: '리포트 전문입니다',
      status: 'success',
    );

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('WeeklyReportScreen', () {
    testWidgets('빈 상태: 안내 문구 + 리포트 생성 버튼 표시', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyReportListProvider
                .overrideWith(() => _FakeReportNotifier()),
          ],
          child: const MaterialApp(home: WeeklyReportScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('아직 생성된 리포트가 없습니다'), findsOneWidget);
      expect(find.text('리포트 생성'), findsOneWidget);
    });

    testWidgets('리포트 있을 때: 약점 목록 + 새 리포트 생성 버튼 표시', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyReportListProvider
                .overrideWith(() => _FakeReportNotifier([_fakeReport()])),
          ],
          child: const MaterialApp(home: WeeklyReportScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('주요 약점'), findsOneWidget);
      expect(find.text('오버폴드'), findsOneWidget);
      expect(find.text('새 리포트 생성'), findsOneWidget);
    });

    testWidgets('전체 리포트 보기 탭하면 리포트 텍스트 펼쳐짐', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyReportListProvider
                .overrideWith(() => _FakeReportNotifier([_fakeReport()])),
          ],
          child: const MaterialApp(home: WeeklyReportScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('리포트 전문입니다'), findsNothing);
      await tester.tap(find.text('전체 리포트 보기'));
      await tester.pump();
      expect(find.text('리포트 전문입니다'), findsOneWidget);
    });
  });
}
