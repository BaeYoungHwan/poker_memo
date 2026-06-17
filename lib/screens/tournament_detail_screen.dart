import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../domain/hand_memo.dart';
import '../domain/tournament.dart';
import '../providers/hand_memo_list_provider.dart';

/// 토너먼트 상세 화면 — 기본 정보 + 이 토너먼트에 연결된 핸드 메모 목록
class TournamentDetailScreen extends ConsumerWidget {
  const TournamentDetailScreen({super.key, required this.tournament});
  final Tournament tournament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(handMemoListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(tournament.name.isEmpty ? '(이름 없음)' : tournament.name,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          _HeaderCard(tournament: tournament),
          const Divider(color: AppColors.surfaceVariant, height: 1),
          Expanded(
            child: memosAsync.when(
              data: (memos) {
                final linked = memos.where((m) => m.tournamentId == tournament.id).toList();
                return linked.isEmpty
                    ? const _EmptyMemoState()
                    : _LinkedMemoList(memos: linked);
              },
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
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.tournament});
  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(tournament.date),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '바이인 \$${tournament.buyIn.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          const Icon(Icons.emoji_events_outlined, color: AppColors.gold, size: 32),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }
}

class _EmptyMemoState extends StatelessWidget {
  const _EmptyMemoState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '이 토너먼트에 연결된 핸드 메모가 없습니다\n핸드 메모 작성 시 이 토너먼트를 선택해보세요',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ),
    );
  }
}

class _LinkedMemoList extends StatelessWidget {
  const _LinkedMemoList({required this.memos});
  final List<HandMemo> memos;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: memos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _MemoRow(memo: memos[index]),
    );
  }
}

/// 연결된 핸드 메모 미리보기 행 — home_screen.dart의 카드보다 단순한 최소 형태
class _MemoRow extends StatelessWidget {
  const _MemoRow({required this.memo});
  final HandMemo memo;

  @override
  Widget build(BuildContext context) {
    final preview =
        memo.noteText.length > 50 ? '${memo.noteText.substring(0, 50)}...' : memo.noteText;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0x2639FF14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.neonGreen),
            ),
            child: Text(
              memo.position.label,
              style: const TextStyle(
                  color: AppColors.neonGreen, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              preview.isEmpty ? '(메모 없음)' : preview,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
