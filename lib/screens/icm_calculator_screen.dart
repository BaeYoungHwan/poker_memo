// ICM 계산기 화면
// 상금 구조와 플레이어 칩 스택을 입력받아 ICM 에퀴티를 표시하는 화면.
// 상태 관리는 icm_provider.dart 에서 전담 -- 이 파일은 UI만 담당한다.
// (CLAUDE.md 규칙: 상태 관리 파일과 UI 화면 파일을 철저히 분리)

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../core/theme/app_colors.dart";
import "../domain/icm_model.dart";
import "../providers/icm_provider.dart";

/// ICM 계산기 전체 화면 -- TextField 컨트롤러를 로컬에서 관리하므로 ConsumerStatefulWidget 사용
class IcmCalculatorScreen extends ConsumerStatefulWidget {
  const IcmCalculatorScreen({super.key});

  @override
  ConsumerState<IcmCalculatorScreen> createState() =>
      _IcmCalculatorScreenState();
}

class _IcmCalculatorScreenState extends ConsumerState<IcmCalculatorScreen> {
  late final TextEditingController _prize1Controller;
  late final TextEditingController _prize2Controller;
  late final TextEditingController _prize3Controller;
  final List<List<TextEditingController>> _playerControllers = [];

  @override
  void initState() {
    super.initState();
    _prize1Controller = TextEditingController();
    _prize2Controller = TextEditingController();
    _prize3Controller = TextEditingController();
    _addPlayerControllers();
    _addPlayerControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(icmProvider.notifier).reset();
      ref.read(icmProvider.notifier)
          .addPlayer(const TournamentPlayer(name: "", chipStack: 1));
      ref.read(icmProvider.notifier)
          .addPlayer(const TournamentPlayer(name: "", chipStack: 1));
    });
  }

  @override
  void dispose() {
    _prize1Controller.dispose();
    _prize2Controller.dispose();
    _prize3Controller.dispose();
    for (final cs in _playerControllers) {
      for (final c in cs) { c.dispose(); }
    }
    super.dispose();
  }

  void _addPlayerControllers() {
    _playerControllers.add([
      TextEditingController(),
      TextEditingController(),
    ]);
  }

  void _removePlayerControllers(int index) {
    final cs = _playerControllers.removeAt(index);
    for (final c in cs) { c.dispose(); }
  }

  // 상금 변경 핸들러 -- 세 필드가 바뀔 때마다 Provider에 일괄 업데이트
  void _onPrizeChanged() {
    final prizes = <double>[];
    for (final c in [_prize1Controller, _prize2Controller, _prize3Controller]) {
      final v = double.tryParse(c.text.trim()) ?? 0.0;
      if (v > 0) prizes.add(v);
    }
    ref.read(icmProvider.notifier).updatePrizes(prizes);
  }

  // 플레이어 변경 핸들러 -- 이름/칩 변경 시 Provider 업데이트
  void _onPlayerChanged(int index) {
    final cs = _playerControllers[index];
    final name = cs[0].text.trim();
    final chips = int.tryParse(cs[1].text.trim()) ?? 0;
    ref.read(icmProvider.notifier).updatePlayer(
          index,
          TournamentPlayer(
            name: name.isEmpty ? "플레이어 ${index + 1}" : name,
            chipStack: chips < 1 ? 1 : chips,
          ),
        );
  }

  bool _canCalculate(IcmInputState s) =>
      s.players.length >= 2 && s.prizes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final icmState = ref.watch(icmProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("ICM 계산기",
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: "초기화",
            onPressed: () {
              _prize1Controller.clear();
              _prize2Controller.clear();
              _prize3Controller.clear();
              for (final p in _playerControllers) { p[0].clear(); p[1].clear(); }
              ref.read(icmProvider.notifier).reset();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PrizeSectionCard(
                    prize1Controller: _prize1Controller,
                    prize2Controller: _prize2Controller,
                    prize3Controller: _prize3Controller,
                    onChanged: _onPrizeChanged,
                  ),
                  const SizedBox(height: 12),
                  _PlayerSectionCard(
                    playerControllers: _playerControllers,
                    onPlayerChanged: _onPlayerChanged,
                    onAddPlayer: () {
                      if (icmState.players.length >= 9) return;
                      setState(() => _addPlayerControllers());
                      ref.read(icmProvider.notifier).addPlayer(TournamentPlayer(
                        name: "플레이어 ${_playerControllers.length}",
                        chipStack: 1,
                      ));
                    },
                    onRemovePlayer: (i) {
                      setState(() => _removePlayerControllers(i));
                      ref.read(icmProvider.notifier).removePlayer(i);
                    },
                    playerCount: icmState.players.length,
                  ),
                  const SizedBox(height: 12),
                  if (icmState.result != null)
                    _ResultSectionCard(
                      players: icmState.players,
                      result: icmState.result!,
                    ),
                ],
              ),
            ),
          ),
          _BottomActionBar(
            isCalculating: icmState.isCalculating,
            canCalculate: _canCalculate(icmState),
            errorMessage: icmState.errorMessage,
            onCalculate: () => ref.read(icmProvider.notifier).calculate(),
          ),
        ],
      ),
    );
  }
}

// _PrizeSectionCard -- 상금 구조 입력 카드
class _PrizeSectionCard extends StatelessWidget {
  const _PrizeSectionCard({
    required this.prize1Controller,
    required this.prize2Controller,
    required this.prize3Controller,
    required this.onChanged,
  });
  final TextEditingController prize1Controller;
  final TextEditingController prize2Controller;
  final TextEditingController prize3Controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "상금 구조",
      icon: Icons.emoji_events_outlined,
      child: Column(
        children: [
          _PrizeTextField(
              controller: prize1Controller,
              label: "1등 상금",
              onChanged: (_) => onChanged()),
          const SizedBox(height: 10),
          _PrizeTextField(
              controller: prize2Controller,
              label: "2등 상금",
              onChanged: (_) => onChanged()),
          const SizedBox(height: 10),
          _PrizeTextField(
              controller: prize3Controller,
              label: "3등 상금",
              onChanged: (_) => onChanged()),
        ],
      ),
    );
  }
}

/// 상금 입력 단일 TextField
class _PrizeTextField extends StatelessWidget {
  const _PrizeTextField(
      {required this.controller,
      required this.label,
      required this.onChanged});
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp("[0-9.]")),
      ],
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: AppColors.textSecondary, fontSize: 13),
        suffixText: "\$",
        suffixStyle: const TextStyle(
            color: AppColors.gold, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.neonGreen, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// _PlayerSectionCard -- 플레이어 목록 입력 카드
class _PlayerSectionCard extends StatelessWidget {
  const _PlayerSectionCard({
    required this.playerControllers,
    required this.onPlayerChanged,
    required this.onAddPlayer,
    required this.onRemovePlayer,
    required this.playerCount,
  });
  final List<List<TextEditingController>> playerControllers;
  final ValueChanged<int> onPlayerChanged;
  final VoidCallback onAddPlayer;
  final ValueChanged<int> onRemovePlayer;
  final int playerCount;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "플레이어",
      icon: Icons.people_outline,
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: playerControllers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _PlayerRow(
              index: i,
              nameController: playerControllers[i][0],
              chipController: playerControllers[i][1],
              onChanged: () => onPlayerChanged(i),
              onRemove: playerControllers.length > 2
                  ? () => onRemovePlayer(i)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: playerCount < 9 ? onAddPlayer : null,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              playerCount < 9
                  ? "+ 플레이어 추가 ($playerCount/9)"
                  : "최대 9명 ($playerCount/9)",
            ),
            style: TextButton.styleFrom(
              foregroundColor: playerCount < 9
                  ? AppColors.neonGreen
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 플레이어 단일 행 -- 이름 + 칩 스택 + 삭제 버튼
class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.index,
    required this.nameController,
    required this.chipController,
    required this.onChanged,
    required this.onRemove,
  });
  final int index;
  final TextEditingController nameController;
  final TextEditingController chipController;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: nameController,
            onChanged: (_) => onChanged(),
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14),
            decoration:
                _deco(label: "이름", hint: "플레이어 ${index + 1}"),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: chipController,
            onChanged: (_) => onChanged(),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly
            ],
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14),
            decoration: _deco(
                label: "칩 스택", hint: "0", suffixText: "BB"),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 36,
          child: onRemove != null
              ? IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.negative, size: 20),
                  padding: EdgeInsets.zero,
                  onPressed: onRemove,
                  tooltip: "플레이어 제거",
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  InputDecoration _deco(
      {required String label,
      String? hint,
      String? suffixText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(
          color: AppColors.textSecondary, fontSize: 12),
      labelStyle: const TextStyle(
          color: AppColors.textSecondary, fontSize: 12),
      suffixText: suffixText,
      suffixStyle: const TextStyle(
          color: AppColors.textSecondary, fontSize: 12),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.neonGreen, width: 1.5)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }
}

// _ResultSectionCard -- ICM 계산 결과 표시 카드
class _ResultSectionCard extends StatelessWidget {
  const _ResultSectionCard(
      {required this.players, required this.result});
  final List<TournamentPlayer> players;
  final IcmResult result;

  @override
  Widget build(BuildContext context) {
    // 에퀴티 내림차순 정렬 -- 높은 에퀴티가 위에 표시
    final sortedPlayers = [...players]..sort((a, b) {
        final eqA = result.equities[a.name] ?? 0.0;
        final eqB = result.equities[b.name] ?? 0.0;
        return eqB.compareTo(eqA);
      });
    return _SectionCard(
      title: "ICM 에퀴티 결과",
      icon: Icons.bar_chart,
      child: Column(
        children: [
          // 총 프라이즈 풀 요약 배너
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x1A39FF14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x4D39FF14)),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text("총 프라이즈 풀",
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13)),
                Text(
                  "\$${result.totalPrizePool.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ResultTableHeader(),
          const Divider(
              color: AppColors.surfaceVariant, height: 1),
          ...sortedPlayers.asMap().entries.map((e) {
            final rank = e.key + 1;
            final p = e.value;
            final eq = result.equities[p.name] ?? 0.0;
            final tot =
                players.fold(0, (s, x) => s + x.chipStack);
            final cpct = tot > 0
                ? (p.chipStack / tot * 100)
                : 0.0;
            final epct = result.totalPrizePool > 0
                ? (eq / result.totalPrizePool * 100)
                : 0.0;
            return _ResultTableRow(
              rank: rank,
              playerName: p.name,
              chipStack: p.chipStack,
              chipPct: cpct,
              equity: eq,
              equityPct: epct,
            );
          }),
        ],
      ),
    );
  }
}

/// 결과 테이블 헤더
class _ResultTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 28),
          Expanded(
            flex: 3,
            child: Text("플레이어",
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text("칩스택",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text("에퀴티",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text("비율",
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// 결과 테이블 단일 행
class _ResultTableRow extends StatelessWidget {
  const _ResultTableRow({
    required this.rank,
    required this.playerName,
    required this.chipStack,
    required this.chipPct,
    required this.equity,
    required this.equityPct,
  });
  final int rank;
  final String playerName;
  final int chipStack;
  final double chipPct;
  final double equity;
  final double equityPct;

  @override
  Widget build(BuildContext context) {
    // 1위는 골드, 나머지는 일반 텍스트 색상
    final rc =
        rank == 1 ? AppColors.gold : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text("$rank",
                style: TextStyle(
                    color: rc,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text(playerName,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                Text(_fmt(chipStack),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12)),
                Text("${chipPct.toStringAsFixed(1)}%",
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10)),
              ],
            ),
          ),
          // 에퀴티 금액 -- neonGreen 강조
          Expanded(
            flex: 2,
            child: Text(
              "\$${equity.toStringAsFixed(2)}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "${equityPct.toStringAsFixed(1)}%",
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 칩 수를 K / M 단위로 포맷
  String _fmt(int chips) {
    if (chips >= 1000000) {
      return "${(chips / 1000000).toStringAsFixed(1)}M";
    }
    if (chips >= 1000) {
      return "${(chips / 1000).toStringAsFixed(1)}K";
    }
    return chips.toString();
  }
}

// _BottomActionBar -- 하단 고정 계산 버튼 + 에러 메시지
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.isCalculating,
    required this.canCalculate,
    required this.errorMessage,
    required this.onCalculate,
  });
  final bool isCalculating;
  final bool canCalculate;
  final String? errorMessage;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
              top: BorderSide(
                  color: AppColors.surfaceVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            // 에러 메시지 배너 -- 에러가 있을 때만 표시
            if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0x1AFF5252),
                  borderRadius:
                      BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0x4DFF5252)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.negative,
                        size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                            color: AppColors.negative,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            // 계산 버튼 또는 로딩 스피너
            SizedBox(
              height: 52,
              child: isCalculating
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                              color:
                                  AppColors.neonGreen,
                              strokeWidth: 3),
                    )
                  : ElevatedButton(
                      onPressed: canCalculate
                          ? onCalculate
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.neonGreen,
                        disabledBackgroundColor:
                            const Color(0x4D39FF14),
                        foregroundColor: Colors.black,
                        disabledForegroundColor:
                            AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    12)),
                        textStyle: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 16),
                      ),
                      child: const Text("ICM 계산하기"),
                    ),
            ),
            // 비활성 안내 메시지
            if (!canCalculate && !isCalculating) ...[
              const SizedBox(height: 6),
              const Text(
                "플레이어 2명 이상, 상금 1개 이상 입력 후 계산 가능합니다",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// _SectionCard -- 공통 섹션 카드 레이아웃
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon,
                    color: AppColors.neonGreen,
                    size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(
            color: AppColors.surfaceVariant,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          const SizedBox(height: 12),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
