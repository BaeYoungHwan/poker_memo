import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_memo_ai/core/theme/app_theme.dart';
import 'package:poker_memo_ai/domain/hand_memo.dart';
import 'package:poker_memo_ai/domain/tournament.dart';
import 'package:poker_memo_ai/providers/hand_memo_list_provider.dart';
import 'package:poker_memo_ai/providers/tournament_list_provider.dart';
import 'package:poker_memo_ai/screens/gto_range_screen.dart';
import 'package:poker_memo_ai/screens/home_screen.dart';
import 'package:poker_memo_ai/screens/icm_calculator_screen.dart';
import 'package:poker_memo_ai/screens/tournament_list_screen.dart';

// Firebase 없이 테스트하기 위한 가짜 Notifier들 — 빈 목록을 즉시 방출
class _EmptyMemoNotifier extends HandMemoListNotifier {
  @override
  Stream<List<HandMemo>> build() => Stream.value(const []);
}

class _EmptyTournamentNotifier extends TournamentListNotifier {
  @override
  Stream<List<Tournament>> build() => Stream.value(const []);
}

Widget _buildTestApp() {
  return ProviderScope(
    overrides: [
      handMemoListProvider.overrideWith(_EmptyMemoNotifier.new),
      tournamentListProvider.overrideWith(_EmptyTournamentNotifier.new),
    ],
    child: MaterialApp(
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('AppBar에 토너먼트/ICM/GTO 진입점 아이콘 3개가 표시된다', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();

    expect(find.byTooltip('토너먼트'), findsOneWidget);
    expect(find.byTooltip('ICM 계산기'), findsOneWidget);
    expect(find.byTooltip('GTO 핸드레인지'), findsOneWidget);
  });

  testWidgets('토너먼트 아이콘을 누르면 TournamentListScreen으로 이동한다', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();

    await tester.tap(find.byTooltip('토너먼트'));
    await tester.pumpAndSettle();

    expect(find.byType(TournamentListScreen), findsOneWidget);
  });

  testWidgets('ICM 계산기 아이콘을 누르면 IcmCalculatorScreen으로 이동한다', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();

    await tester.tap(find.byTooltip('ICM 계산기'));
    await tester.pumpAndSettle();

    expect(find.byType(IcmCalculatorScreen), findsOneWidget);
  });

  testWidgets('GTO 핸드레인지 아이콘을 누르면 GtoRangeScreen으로 이동한다', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();

    await tester.tap(find.byTooltip('GTO 핸드레인지'));
    await tester.pumpAndSettle();

    expect(find.byType(GtoRangeScreen), findsOneWidget);
  });
}
