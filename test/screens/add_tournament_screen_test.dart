import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_memo_ai/core/theme/app_theme.dart';
import 'package:poker_memo_ai/domain/tournament.dart';
import 'package:poker_memo_ai/providers/tournament_list_provider.dart';
import 'package:poker_memo_ai/screens/add_tournament_screen.dart';

// Firebase 없이 테스트하기 위한 가짜 Notifier — addTournament 호출 인자를 그대로 기록
class _RecordingTournamentNotifier extends TournamentListNotifier {
  String? lastName;
  DateTime? lastDate;
  double? lastBuyIn;

  @override
  Stream<List<Tournament>> build() => Stream.value(const []);

  @override
  Future<void> addTournament(String name, DateTime date, double buyIn) async {
    lastName = name;
    lastDate = date;
    lastBuyIn = buyIn;
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('이름이 비어있으면 저장 버튼이 비활성화된다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tournamentListProvider.overrideWith(_RecordingTournamentNotifier.new)],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          theme: AppTheme.darkTheme,
          home: const AddTournamentScreen(),
        ),
      ),
    );
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('이름 입력 후 저장 버튼이 활성화되고, 탭하면 입력값 그대로 addTournament가 호출된다',
      (tester) async {
    final notifier = _RecordingTournamentNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [tournamentListProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          theme: AppTheme.darkTheme,
          home: const AddTournamentScreen(),
        ),
      ),
    );
    await tester.pump();

    // 이름 입력
    await tester.enterText(find.byType(TextField).first, 'WSOP Main Event');
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);

    // 바이인 입력 (두 번째 TextField)
    await tester.enterText(find.byType(TextField).last, '500');
    await tester.pump();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(notifier.lastName, 'WSOP Main Event');
    expect(notifier.lastBuyIn, 500.0);
  });
}
