import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../domain/hand_memo.dart';
import '../providers/hand_memo_list_provider.dart';
import '../providers/tournament_list_provider.dart';

/// 핸드 메모 작성 화면
/// CLAUDE.md UI 규칙: 하단 버튼 고정(SafeArea), 52dp 높이, 한 손 조작 우선
class AddHandMemoScreen extends ConsumerStatefulWidget {
  const AddHandMemoScreen({super.key});

  @override
  ConsumerState<AddHandMemoScreen> createState() => _AddHandMemoScreenState();
}

class _AddHandMemoScreenState extends ConsumerState<AddHandMemoScreen> {
  PokerPosition? _selectedPosition;
  // null이면 "선택 안 함" — 특정 토너먼트와 연결하지 않은 메모
  String? _selectedTournamentId;
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedPosition == null || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      await ref.read(handMemoListProvider.notifier).addMemo(
            _selectedPosition!,
            _noteController.text,
            tournamentId: _selectedTournamentId,
          );
      if (mounted) Navigator.pop(context);
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
    final canSave = _selectedPosition != null && !_isSaving;
    final tournamentsAsync = ref.watch(tournamentListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('핸드 메모 작성')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 포지션 선택 레이블
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              '포지션',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // 포지션 ChoiceChip — 가로 스크롤
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: PokerPosition.values.map((pos) {
                final isSelected = _selectedPosition == pos;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(pos.label),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedPosition = pos),
                    selectedColor: AppColors.neonGreen,
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.black : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.neonGreen
                          : Colors.transparent,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ),
          // 토너먼트 선택 레이블 (선택 사항)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              '토너먼트 (선택)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // 토너먼트 ChoiceChip — "선택 안 함" + 등록된 토너먼트 목록, 가로 스크롤
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
                      isSelected: _selectedTournamentId == null,
                      onSelected: () =>
                          setState(() => _selectedTournamentId = null),
                    ),
                    ...tournaments.map((t) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _TournamentChip(
                            label: t.name,
                            isSelected: _selectedTournamentId == t.id,
                            onSelected: () =>
                                setState(() => _selectedTournamentId = t.id),
                          ),
                        )),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),
          // 메모 입력 레이블
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              '메모',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // 자유 형식 메모 입력 필드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _noteController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText:
                      '이 핸드에서 일어난 일을 자유롭게 기록하세요\n(예: BTN vs BB, 3bet pot, river 블러프 콜)',
                  hintStyle: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.neonGreen),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ],
      ),
      // 저장 버튼 — 하단 고정, 포지션 미선택 시 비활성화
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton(
          onPressed: canSave ? _save : null,
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
      ),
    );
  }
}

/// 토너먼트 선택용 단일 칩 — 포지션 ChoiceChip과 동일한 스타일 컨벤션
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
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.neonGreen : Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
