import 'package:flutter/material.dart';

/// PokerMemo AI 다크 모드 색상 팔레트
/// 배경은 Jet Black, 포인트 컬러는 Neon Green(주요 액션/긍정 지표) + Gold(보조/하이라이트)
class AppColors {
  AppColors._();

  // 배경 — Jet Black 고정 (CLAUDE.md UI/UX 규칙)
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceVariant = Color(0xFF1E1E1E);

  // 포인트 컬러 — 주요 액션/포지티브 지표(EV+, 수익 등)에 사용
  static const Color neonGreen = Color(0xFF39FF14);

  // 포인트 컬러 — 보조 강조/프리미엄·성취 요소에 사용
  static const Color gold = Color(0xFFFFD700);

  // 텍스트
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);

  // 상태 색상 — 포커 결과(이득/손실) 표시에 사용
  static const Color positive = neonGreen;
  static const Color negative = Color(0xFFFF5252);
}
