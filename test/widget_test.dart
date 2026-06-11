import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_memo_ai/core/theme/app_colors.dart';
import 'package:poker_memo_ai/core/theme/app_theme.dart';
import 'package:poker_memo_ai/domain/hand_memo.dart';
import 'package:poker_memo_ai/providers/hand_memo_list_provider.dart';
import 'package:poker_memo_ai/screens/home_screen.dart';

// Firebase 없이 테스트하기 위한 가짜 Notifier — HandMemoListNotifier를 상속해 overrideWith 타입 일치
class _EmptyMemoNotifier extends HandMemoListNotifier {
  @override
  Stream<List<HandMemo>> build() => Stream.value([]);
}

/// Firebase 없이 HomeScreen을 렌더링하는 헬퍼 — 프로바이더를 가짜로 교체
Widget _buildTestApp(HandMemoListNotifier Function() notifierFactory) {
  return ProviderScope(
    overrides: [
      handMemoListProvider.overrideWith(notifierFactory),
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

  testWidgets('홈 화면이 다크 모드 테마로 렌더링된다', (tester) async {
    await tester.pumpWidget(_buildTestApp(_EmptyMemoNotifier.new));
    await tester.pump();

    // 앱 타이틀 확인
    expect(find.text('PokerMemo AI'), findsWidgets);

    // Scaffold 배경이 Jet Black(#000000)인지 확인 (CLAUDE.md 다크 모드 규칙)
    final scaffold =
        tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(
      scaffold.backgroundColor ??
          Theme.of(tester.element(find.byType(Scaffold).first))
              .scaffoldBackgroundColor,
      AppColors.background,
    );
  });

  testWidgets('메모가 없을 때 빈 상태 안내 문구와 FAB가 표시된다', (tester) async {
    await tester.pumpWidget(_buildTestApp(_EmptyMemoNotifier.new));
    await tester.pump();

    expect(find.text('아직 기록한 핸드가 없습니다'), findsOneWidget);
    expect(find.text('+ 버튼을 눌러 첫 핸드를 기록해보세요'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
