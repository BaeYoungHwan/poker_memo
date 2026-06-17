import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_memo_ai/core/theme/app_theme.dart';
import 'package:poker_memo_ai/domain/tournament.dart';
import 'package:poker_memo_ai/providers/tournament_list_provider.dart';
import 'package:poker_memo_ai/screens/add_tournament_screen.dart';
import 'package:poker_memo_ai/screens/tournament_list_screen.dart';

// Firebase 없이 테스트하기 위한 가짜 Notifier — 고정된 토너먼트 목록을 즉시 방출
class _FixedTournamentNotifier extends TournamentListNotifier {
  _FixedTournamentNotifier([this._fixed = const []]);
  final List<Tournament> _fixed;

  @override
  Stream<List<Tournament>> build() => Stream.value(_fixed);
}

Widget _buildTestApp(List<Tournament> fixed) {
  return ProviderScope(
    overrides: [
      tournamentListProvider.overrideWith(() => _FixedTournamentNotifier(fixed)),
    ],
    child: MaterialApp(
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.darkTheme,
      home: const TournamentListScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('토너먼트가 없을 때 빈 상태 안내 문구와 FAB가 표시된다', (tester) async {
    await tester.pumpWidget(_buildTestApp(const []));
    await tester.pump();

    expect(find.text('아직 기록한 토너먼트가 없습니다'), findsOneWidget);
    expect(find.text('+ 버튼을 눌러 첫 토너먼트를 기록해보세요'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('토너먼트가 있을 때 이름/날짜/바이인이 카드로 렌더링된다', (tester) async {
    final tournaments = [
      Tournament(
        id: 't1',
        userId: 'u1',
        name: 'WSOP Main Event',
        date: DateTime(2026, 7, 1),
        buyIn: 500,
        createdAt: DateTime(2026, 6, 1),
      ),
    ];
    await tester.pumpWidget(_buildTestApp(tournaments));
    await tester.pump();

    expect(find.text('WSOP Main Event'), findsOneWidget);
    expect(find.text('2026.07.01'), findsOneWidget);
    expect(find.text('\$500'), findsOneWidget);
    expect(find.text('아직 기록한 토너먼트가 없습니다'), findsNothing);
  });

  testWidgets('FAB를 누르면 AddTournamentScreen으로 이동한다', (tester) async {
    await tester.pumpWidget(_buildTestApp(const []));
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(AddTournamentScreen), findsOneWidget);
  });
}
