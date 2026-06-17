import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_memo_ai/core/theme/app_theme.dart';
import 'package:poker_memo_ai/domain/hand_memo.dart';
import 'package:poker_memo_ai/domain/tournament.dart';
import 'package:poker_memo_ai/providers/hand_memo_list_provider.dart';
import 'package:poker_memo_ai/screens/tournament_detail_screen.dart';

// Firebase 없이 테스트하기 위한 가짜 Notifier — 고정된 핸드 메모 목록을 즉시 방출
class _FixedMemoNotifier extends HandMemoListNotifier {
  _FixedMemoNotifier(this._fixed);
  final List<HandMemo> _fixed;

  @override
  Stream<List<HandMemo>> build() => Stream.value(_fixed);
}

final _tournament = Tournament(
  id: 't1',
  userId: 'u1',
  name: 'WSOP Main Event',
  date: DateTime(2026, 7, 1),
  buyIn: 500,
  createdAt: DateTime(2026, 6, 1),
);

Widget _buildTestApp(List<HandMemo> memos) {
  return ProviderScope(
    overrides: [
      handMemoListProvider.overrideWith(() => _FixedMemoNotifier(memos)),
    ],
    child: MaterialApp(
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.darkTheme,
      home: TournamentDetailScreen(tournament: _tournament),
    ),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('헤더에 토너먼트 이름/날짜/바이인이 표시된다', (tester) async {
    await tester.pumpWidget(_buildTestApp(const []));
    await tester.pump();

    expect(find.text('WSOP Main Event'), findsOneWidget);
    expect(find.text('2026.07.01'), findsOneWidget);
    expect(find.text('바이인 \$500'), findsOneWidget);
  });

  testWidgets('연결된 메모가 없으면 안내 문구가 표시된다', (tester) async {
    await tester.pumpWidget(_buildTestApp(const []));
    await tester.pump();

    expect(find.textContaining('연결된 핸드 메모가 없습니다'), findsOneWidget);
  });

  testWidgets('이 토너먼트(tournamentId 일치)와 연결된 메모만 필터링해 표시한다', (tester) async {
    final memos = [
      HandMemo(
        id: 'm1',
        userId: 'u1',
        position: PokerPosition.btn,
        noteText: '이 토너먼트 핸드입니다',
        createdAt: DateTime(2026, 7, 1, 10),
        tournamentId: 't1', // 이 토너먼트와 일치
      ),
      HandMemo(
        id: 'm2',
        userId: 'u1',
        position: PokerPosition.utg,
        noteText: '다른 토너먼트 핸드입니다',
        createdAt: DateTime(2026, 7, 2, 10),
        tournamentId: 't2', // 다른 토너먼트
      ),
      HandMemo(
        id: 'm3',
        userId: 'u1',
        position: PokerPosition.co,
        noteText: '토너먼트 미연결 핸드입니다',
        createdAt: DateTime(2026, 7, 3, 10),
        // tournamentId 없음
      ),
    ];

    await tester.pumpWidget(_buildTestApp(memos));
    await tester.pump();

    expect(find.text('이 토너먼트 핸드입니다'), findsOneWidget);
    expect(find.text('다른 토너먼트 핸드입니다'), findsNothing);
    expect(find.text('토너먼트 미연결 핸드입니다'), findsNothing);
    expect(find.text('BTN'), findsOneWidget);
  });
}
