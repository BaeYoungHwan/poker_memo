import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_memo_ai/screens/pricing_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('PricingScreen', () {
    testWidgets('Plus/Pro 가격 카드와 파운딩 배너가 렌더링된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PricingScreen()),
      );
      await tester.pump();

      expect(find.text('파운딩 멤버 한정 · 정가 대비 50% 특가'), findsOneWidget);
      expect(find.text('Plus'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('BEST'), findsOneWidget);
    });

    testWidgets('USD/KRW 구독 버튼이 각 카드에 존재한다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PricingScreen()),
      );
      await tester.pump();

      expect(find.text('USD로 구독하기'), findsNWidgets(2));
      expect(find.text('KRW로 구독하기'), findsNWidgets(2));
    });

    testWidgets('Free 플랜 안내 문구가 하단에 표시된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PricingScreen()),
      );
      await tester.pump();

      expect(
        find.textContaining('Free 플랜으로도'),
        findsOneWidget,
      );
    });
  });
}
