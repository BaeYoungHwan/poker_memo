import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../domain/hand_memo.dart';
import '../providers/hand_memo_list_provider.dart';
import 'add_hand_memo_screen.dart';
import 'gto_range_screen.dart';
import 'icm_calculator_screen.dart';
import 'tournament_list_screen.dart';

/// 핸드 메모 목록 홈 화면
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(handMemoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PokerMemo AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: '토너먼트',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TournamentListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'ICM 계산기',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IcmCalculatorScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.grid_on_outlined),
            tooltip: 'GTO 핸드레인지',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GtoRangeScreen()),
            ),
          ),
        ],
      ),
      body: memosAsync.when(
        data: (memos) => memos.isEmpty
            ? _EmptyState()
            : _MemoList(memos: memos),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonGreen),
        ),
        error: (e, _) => Center(
          child: Text(
            '오류가 발생했습니다\n$e',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.negative),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddHandMemoScreen()),
        ),
        backgroundColor: AppColors.neonGreen,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_outlined, size: 72, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            '아직 기록한 핸드가 없습니다',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            '+ 버튼을 눌러 첫 핸드를 기록해보세요',
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _MemoList extends ConsumerWidget {
  const _MemoList({required this.memos});
  final List<HandMemo> memos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: memos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final memo = memos[index];
        return Dismissible(
          key: ValueKey(memo.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.negative,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) =>
              ref.read(handMemoListProvider.notifier).deleteMemo(memo.id),
          child: _MemoCard(memo: memo),
        );
      },
    );
  }
}

class _MemoCard extends StatelessWidget {
  const _MemoCard({required this.memo});
  final HandMemo memo;

  @override
  Widget build(BuildContext context) {
    final preview = memo.noteText.length > 50
        ? '${memo.noteText.substring(0, 50)}...'
        : memo.noteText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 포지션 뱃지
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x2639FF14), // neonGreen 15% 불투명도
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.neonGreen),
            ),
            child: Text(
              memo.position.label,
              style: const TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 메모 미리보기 + 날짜
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.isEmpty ? '(메모 없음)' : preview,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(memo.createdAt),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y.$m.$d $h:$min';
  }
}
