import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../domain/weekly_report.dart';
import '../providers/weekly_report_provider.dart';

/// 주간 리포트 화면 - 최신 Leak 분석 리포트 조회 + 수동 생성 요청
class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  bool _isGenerating = false;

  Future<void> _generate() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      await ref.read(weeklyReportListProvider.notifier).generateReport();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리포트가 생성되었습니다!'),
            backgroundColor: AppColors.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(weeklyReportListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('주간 Leak 리포트')),
      body: reportsAsync.when(
        data: (reports) => reports.isEmpty
            ? _EmptyState(onGenerate: _generate, isGenerating: _isGenerating)
            : _ReportList(
                reports: reports,
                onGenerate: _generate,
                isGenerating: _isGenerating,
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonGreen),
        ),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: const TextStyle(color: AppColors.negative),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onGenerate,
    required this.isGenerating,
  });
  final VoidCallback onGenerate;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const Icon(Icons.analytics_outlined,
            size: 72, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        const Text(
          '아직 생성된 리포트가 없습니다',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            '최근 7일간 핸드 메모를 분석해 약점 리포트를 만들어 드립니다',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        const Spacer(),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isGenerating ? null : onGenerate,
              child: isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2),
                    )
                  : const Text('리포트 생성'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({
    required this.reports,
    required this.onGenerate,
    required this.isGenerating,
  });
  final List<WeeklyReport> reports;
  final VoidCallback onGenerate;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _ReportCard(report: reports[index]),
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isGenerating ? null : onGenerate,
              child: isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2),
                    )
                  : const Text('새 리포트 생성'),
            ),
          ),
        ),
      ],
    );
  }
}

/// 개별 리포트 카드 - 약점 요약 + 전체 텍스트 펼치기/접기
class _ReportCard extends StatefulWidget {
  const _ReportCard({required this.report});
  final WeeklyReport report;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                _formatDate(r.generatedAt),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x2639FF14),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.neonGreen),
                ),
                child: Text(
                  '${r.handsAnalyzed}핸드 분석',
                  style: const TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (r.topLeaks.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              '주요 약점',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...r.topLeaks.map(
              (leak) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        size: 14, color: AppColors.gold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        leak,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Text(
                    _expanded ? '접기' : '전체 리포트 보기',
                    style:
                        const TextStyle(color: AppColors.neonGreen, fontSize: 13),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.neonGreen,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                r.reportText,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13, height: 1.6),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d2 = dt.day.toString().padLeft(2, '0');
    return '$y.$m.$d2';
  }
}
