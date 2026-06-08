import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../providers/hand_memo_stats_provider.dart';

/// 앱 진입 후 표시되는 홈 화면 — 다크 모드 테마 + Riverpod 상태 연동 확인용 임시 화면
/// (추후 핸드 메모 목록·리포트 화면으로 교체 예정)
///
/// `handMemoStatsProvider`가 노출하는 [HandMemoStats] 모델과 Provider 핸들만 참조하며,
/// 상태를 어떻게 계산·저장하는지(Notifier 내부 구현)는 알지 못한다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(handMemoStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PokerMemo AI')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.style, size: 72, color: AppColors.neonGreen),
            const SizedBox(height: 16),
            const Text(
              'PokerMemo AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '핸드 메모를 기록하고 AI 리크 분석을 받아보세요',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Text(
              '지금까지 기록한 핸드 메모: ${stats.totalCount}개',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      // 한 손 조작을 위해 주요 액션 버튼을 화면 하단에 배치
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: ElevatedButton(
          onPressed: () => ref.read(handMemoStatsProvider.notifier).recordNewMemo(),
          child: const Text('핸드 메모 작성하기'),
        ),
      ),
    );
  }
}
