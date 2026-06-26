import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../domain/hand_memo.dart';
import '../providers/hand_memo_list_provider.dart';
import '../providers/tournament_list_provider.dart';

/// 핸드 메모 상세 화면 - 읽기/편집 모드 전환 가능
class HandMemoDetailScreen extends ConsumerStatefulWidget {
  const HandMemoDetailScreen({super.key, required this.memo});

  final HandMemo memo;

  @override
  ConsumerState<HandMemoDetailScreen> createState() =>
      _HandMemoDetailScreenState();
}
class _HandMemoDetailScreenState extends ConsumerState<HandMemoDetailScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  late PokerPosition _selectedPosition;
  late String? _selectedTournamentId;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.memo.position;
    _selectedTournamentId = widget.memo.tournamentId;
    _noteController = TextEditingController(text: widget.memo.noteText);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _enterEdit() => setState(() => _isEditing = true);

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _selectedPosition = widget.memo.position;
      _selectedTournamentId = widget.memo.tournamentId;
      _noteController.text = widget.memo.noteText;
    });
  }

  void setPosition(PokerPosition pos) => setState(() => _selectedPosition = pos);
  void setTournamentId(String? id) => setState(() => _selectedTournamentId = id);

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final updated = widget.memo.copyWith(
        position: _selectedPosition,
        noteText: _noteController.text.trim(),
        tournamentId: _selectedTournamentId,
      );
      await ref.read(handMemoListProvider.notifier).updateMemo(updated);
      if (mounted) setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('핸드 메모'),
        actions: _isEditing
            ? [
                TextButton(
                  onPressed: _cancelEdit,
                  child: const Text('취소',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '편집',
                  onPressed: _enterEdit,
                ),
              ],
      ),
      body: _isEditing ? _EditBody(this) : _ReadBody(widget.memo, ref),
      bottomNavigationBar: _isEditing
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('저장'),
              ),
            )
          : null,
    );
  }
}

class _ReadBody extends StatelessWidget {
  const _ReadBody(this.memo, this.ref);
  final HandMemo memo;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(tournamentListProvider);
    String? tournamentName;
    tournamentsAsync.whenData((list) {
      if (memo.tournamentId != null) {
        final matches = list.where((t) => t.id == memo.tournamentId);
        if (matches.isNotEmpty) tournamentName = matches.first.name;
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x2639FF14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.neonGreen),
                ),
                child: Text(
                  memo.position.label,
                  style: const TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(memo.createdAt),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          if (tournamentName != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined,
                    color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 6),
                Text(tournamentName!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const Text('메모', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 13,
            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              memo.noteText.isEmpty ? '(메모 없음)' : memo.noteText,
              style: TextStyle(
                color: memo.noteText.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontSize: 15, height: 1.6,
              ),
            ),
          ),
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

class _EditBody extends StatelessWidget {
  const _EditBody(this.state);
  final _HandMemoDetailScreenState state;

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = state.ref.watch(tournamentListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text('포지션', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 13,
            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: PokerPosition.values.map((pos) {
              final isSelected = state._selectedPosition == pos;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(pos.label),
                  selected: isSelected,
                  onSelected: (_) =>
                      state.setPosition(pos),
                  selectedColor: AppColors.neonGreen,
                  backgroundColor: AppColors.surfaceVariant,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontWeight: FontWeight.bold, fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.neonGreen : Colors.transparent,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              );
            }).toList(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text('토너먼트 (선택)', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 13,
            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
        SizedBox(
          height: 40,
          child: tournamentsAsync.when(
            data: (tournaments) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _TournamentChip(
                    label: '선택 안 함',
                    isSelected: state._selectedTournamentId == null,
                    onSelected: () =>
                        state.setTournamentId(null),
                  ),
                  ...tournaments.map((t) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _TournamentChip(
                          label: t.name,
                          isSelected: state._selectedTournamentId == t.id,
                          onSelected: () => state.setTournamentId(t.id),
                        ),
                      )),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text('메모', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 13,
            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: state._noteController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: '이 핸드에서 일어난 일을 자유롭게 기록하세요',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.neonGreen),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TournamentChip extends StatelessWidget {
  const _TournamentChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.neonGreen,
      backgroundColor: AppColors.surfaceVariant,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textPrimary,
        fontWeight: FontWeight.bold, fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.neonGreen : Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
