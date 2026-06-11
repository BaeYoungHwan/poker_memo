import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

void main() async {
  // Firebase 초기화는 위젯 트리가 그려지기 전에 완료돼야 하므로 runApp() 이전에 await 처리
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // 재실행 시 기존 익명 세션을 재사용해 같은 uid(= 같은 Firestore 데이터)를 유지
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    // 초기화 실패 시에도 앱이 죽지 않도록 로그만 남기고 계속 진행
    // (CLAUDE.md 행동 지침: 모든 주요 외부 연동 호출에 try-catch 필수)
    debugPrint('Firebase 초기화 실패: $e');
  }

  // Riverpod 상태 관리를 앱 전역에서 사용하기 위해 ProviderScope로 감싼다
  runApp(const ProviderScope(child: PokerMemoApp()));
}

class PokerMemoApp extends StatelessWidget {
  const PokerMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokerMemo AI',
      debugShowCheckedModeBanner: false,
      // 앱 전체를 다크 모드로 고정 (CLAUDE.md UI/UX 규칙)
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
