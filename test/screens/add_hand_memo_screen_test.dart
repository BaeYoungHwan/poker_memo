import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_memo_ai/core/theme/app_theme.dart';
import 'package:poker_memo_ai/domain/hand_memo.dart';
import 'package:poker_memo_ai/domain/tournament.dart';
import 'package:poker_memo_ai/providers/hand_memo_list_provider.dart';
import 'package:poker_memo_ai/providers/tournament_list_provider.dart';
import 'package:poker_memo_ai/screens/add_hand_memo_screen.dart';

// Firebase 없이 테스트하기 위한 가짜 Notifier — 고정된 토너먼트 목록을 즉시 방출
class _FixedTournamentNotifier extends TournamentListNotifier {
  _FixedTournamentNotifier(this._fixed);
  final List<Tournament> _fixed;

  @override
  Stream<List<Tournament>> build() => Stream.value(_fixed);
}

// Firebase 없이 테스트하기 위한 가짜 Notifier — addMemo 호출 인자를 그대로 기록
class _RecordingMemoNotifier extends HandMemoListNotifier {
  PokerPosition? lastPosition;
  String? lastNoteText;
  String? lastTournamentId;

  @override
  Stream<List<HandMemo>> build() => Stream.value(const []);

  @override
  Future<void> addMemo(
    PokerPosition position,
    String noteText, {
    String? tournamentId,
  }) async {
    lastPosition = position;
    lastNoteText = noteText;
    lastTournamentId = tournamentId;
  }
}

final _tournaments = [
  Tournament(
    id: 't1',
    userId: 'u1',
    name: 'WSOP Main Event',
    date: DateTime(2026, 7, 1),
    buyIn: 500,
    createdAt: DateTime(2026, 6, 1),
  ),
  Tournament(
    id: 't2',
    userId: 'u1',
    name: '강남 위클리',
    date: DateTime(2026, 6, 20),
    buyIn: 50,
    createdAt: DateTime(2026, 6, 1),
  ),
];

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('토너먼트 선택 칩 행에 "선택 안 함"과 등록된 토너먼트 이름이 표시된다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentListProvider.overrideWith(() => _FixedTournamentNotifier(_tournaments)),
          handMemoListProvider.overrideWith(_RecordingMemoNotifier.new),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          theme: AppTheme.darkTheme,
          home: const AddHandMemoScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('선택 안 함'), findsOneWidget);
    expect(find.text('WSOP Main Event'), findsOneWidget);
    expect(find.text('강남 위클리'), findsOneWidget);
  });

  testWidgets('포지션과 토너먼트를 선택해 저장하면 선택한 tournamentId 그대로 addMemo가 호출된다',
      (tester) async {
    final notifier = _RecordingMemoNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentListProvider.overrideWith(() => _FixedTournamentNotifier(_tournaments)),
          handMemoListProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          theme: AppTheme.darkTheme,
          home: const AddHandMemoScreen(),
        ),
      ),
    );
    await tester.pump();

    // 포지션 선택
    await tester.tap(find.text('BTN'));
    await tester.pump();

    // 토너먼트 선택
    await tester.tap(find.text('WSOP Main Event'));
    await tester.pump();

    // 저장
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(notifier.lastPosition, PokerPosition.btn);
    expect(notifier.lastTournamentId, 't1');
  });

  testWidgets('토너먼트를 선택하지 않으면 tournamentId는 null로 저장된다', (tester) async {
    final notifier = _RecordingMemoNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentListProvider.overrideWith(() => _FixedTournamentNotifier(_tournaments)),
          handMemoListProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          theme: AppTheme.darkTheme,
          home: const AddHandMemoScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('SB'));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(notifier.lastPosition, PokerPosition.sb);
    expect(notifier.lastTournamentId, isNull);
  });
}
