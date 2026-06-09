import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../domain/hand_memo.dart';
import '../providers/gto_provider.dart';
import '../services/gto_range_service.dart';

/// GTO 핸드레인지 화면
/// 포지션별 오픈 레이즈 레인지를 13x13 그리드로 시각화하고,
/// 하단에서 AI GTO 조언(Pro 티어, 추후 연동)을 요청할 수 있다.
class GtoRangeScreen extends ConsumerWidget {
  const GtoRangeScreen({super.key});

  /// BB는 오픈 레인지가 없으므로 ChoiceChip 표시 대상에서 제외
  static const List<PokerPosition> _selectablePositions = [
    PokerPosition.utg,
    PokerPosition.hj,
    PokerPosition.co,
    PokerPosition.btn,
    PokerPosition.sb,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gtoState = ref.watch(gtoProvider);
    final notifier = ref.read(gtoProvider.notifier);

    final allHands = GtoRangeService.allHands();
    final openRange = GtoRangeService.getOpenRange(gtoState.selectedPosition);
    final rangePercent =
        GtoRangeService.rangePercentage(gtoState.selectedPosition);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'GTO 핸드레인지',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          _PositionChipRow(
            positions: _selectablePositions,
            selected: gtoState.selectedPosition,
            onSelect: (pos) {
              notifier.selectPosition(pos);
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${gtoState.selectedPosition.label} 오픈 레인지: '
                '${rangePercent.toStringAsFixed(1)}%',
                style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _HandGrid(allHands: allHands, openRange: openRange),
            ),
          ),

          const Divider(color: AppColors.surfaceVariant, height: 1),
          _AdviceSection(gtoState: gtoState, notifier: notifier),
        ],
      ),
    );
  }
}

// PositionChipRow
class _PositionChipRow extends StatelessWidget {
  const _PositionChipRow({required this.positions, required this.selected, required this.onSelect});
  final List<PokerPosition> positions;
  final PokerPosition selected;
  final ValueChanged<PokerPosition> onSelect;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: positions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final pos = positions[index];
          final isSelected = pos == selected;
          return ChoiceChip(
            label: Text(pos.label, style: TextStyle(
              color: isSelected ? Colors.black : AppColors.textSecondary,
              fontWeight: FontWeight.bold, fontSize: 13)),
            selected: isSelected,
            // 선택된 포지션: neonGreen 배경 / 미선택: surfaceVariant 배경
            selectedColor: AppColors.neonGreen,
            backgroundColor: AppColors.surfaceVariant,
            side: BorderSide(color: isSelected ? AppColors.neonGreen : AppColors.surfaceVariant),
            onSelected: (_) => onSelect(pos),
          );
        },
      ),
    );
  }
}

// HandGrid
class _HandGrid extends StatelessWidget {
  const _HandGrid({required this.allHands, required this.openRange});
  final List<String> allHands;
  final Set<String> openRange;
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // 물리적 스크롤을 막고 Expanded 가 공간을 채우도록 설정
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        // 13열: 핸드 매트릭스 열 수
        crossAxisCount: 13,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemCount: allHands.length,
      itemBuilder: (context, index) {
        final hand = allHands[index];
        final inRange = openRange.contains(hand);
        return _HandCell(hand: hand, inRange: inRange);
      },
    );
  }
}

/// 개별 핸드 셀 - 레인지 포함 여부에 따라 배경/텍스트 색상 분기
class _HandCell extends StatelessWidget {
  const _HandCell({required this.hand, required this.inRange});
  final String hand;
  final bool inRange;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // 레인지 포함: neonGreen 배경 / 미포함: surfaceVariant 배경
        color: inRange ? AppColors.neonGreen : AppColors.surfaceVariant,
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          hand,
          textAlign: TextAlign.center,
          style: TextStyle(
            // 레인지 포함: 검정 텍스트 / 미포함: 어두운 보조 텍스트
            color: inRange ? Colors.black : AppColors.textSecondary,
            fontSize: 9,
            fontWeight: inRange ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// AdviceSection
class _AdviceSection extends ConsumerWidget {
  const _AdviceSection({required this.gtoState, required this.notifier});
  final GtoState gtoState;
  final GtoNotifier notifier;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        // 소프트 키보드 올라올 때 하단 패딩 유지
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 핸드 상황 입력 필드
          TextField(
            onChanged: notifier.updateHandMemoInput,
            decoration: InputDecoration(
              hintText: '핸드 상황을 입력하세요...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true, fillColor: AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: gtoState.isLoadingAdvice ? null : () => _onAdvicePressed(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: gtoState.isLoadingAdvice
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('AI GTO 조언 받기',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          if (gtoState.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(gtoState.errorMessage!,
              style: const TextStyle(color: AppColors.negative, fontSize: 13)),
          ],
          if (gtoState.gtoAdviceResult != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                // neonGreen 40% 불투명도 테두리
                border: Border.all(color: const Color(0x6639FF14)),
              ),
              child: Text(gtoState.gtoAdviceResult!,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  /// 조언 버튼 탭 핸들러 - 현재는 더미(Pro 티어 스낵바), 추후 Cloud Function 연동
  void _onAdvicePressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Pro 티어 기능입니다'),
      backgroundColor: AppColors.surfaceVariant,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }
}
