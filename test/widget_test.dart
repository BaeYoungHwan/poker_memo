import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_memo_ai/main.dart';
import 'package:poker_memo_ai/core/theme/app_colors.dart';

void main() {
  testWidgets('홈 화면이 다크 모드 테마로 렌더링되는지 확인', (WidgetTester tester) async {
    // Riverpod Provider를 사용하므로 ProviderScope로 감싸서 렌더링
    await tester.pumpWidget(const ProviderScope(child: PokerMemoApp()));

    // 앱 타이틀과 핵심 액션 버튼이 표시되는지 확인
    expect(find.text('PokerMemo AI'), findsWidgets);
    expect(find.text('핸드 메모 작성하기'), findsOneWidget);

    // Scaffold 배경이 Jet Black(#000000)으로 고정되는지 확인 (CLAUDE.md 다크 모드 규칙)
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor ?? Theme.of(tester.element(find.byType(Scaffold).first)).scaffoldBackgroundColor, AppColors.background);
  });

  testWidgets('핸드 메모 작성 버튼을 누르면 통계 카운트가 증가한다 (Provider 연동 확인)', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PokerMemoApp()));

    expect(find.text('지금까지 기록한 핸드 메모: 0개'), findsOneWidget);

    await tester.tap(find.text('핸드 메모 작성하기'));
    await tester.pump();

    expect(find.text('지금까지 기록한 핸드 메모: 1개'), findsOneWidget);
  });
}
