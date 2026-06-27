import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/stripe_links.dart';
import '../core/theme/app_colors.dart';

/// 가격 소개 화면 — Plus/Pro 파운딩 멤버 특가 + Stripe 외부 결제 링크 연결
class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제 페이지를 열 수 없습니다. 잠시 후 다시 시도해 주세요.'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('요금제')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FoundingBanner(),
            const SizedBox(height: 24),
            _PricingCard(
              tier: 'Plus',
              tagline: '핸드레인지 + ICM + 토너먼트 관리',
              originalUsd: r'9.99',
              originalKrw: '₩39,900',
              foundingUsd: r'4.99',
              foundingKrw: '₩19,900',
              features: const [
                'ICM 계산기 무제한',
                '토너먼트 상세 기록',
                '대회 포스터 AI 스캔',
                '핸드레인지 커스텀 설정',
              ],
              onSubscribeUsd: () => _openLink(context, StripeLinks.plusFoundingUsd),
              onSubscribeKrw: () => _openLink(context, StripeLinks.plusFoundingKrw),
            ),
            const SizedBox(height: 20),
            _PricingCard(
              tier: 'Pro',
              tagline: 'AI 코칭 + 주간 Leak 리포트',
              originalUsd: r'9.99',
              originalKrw: '₩149,900',
              foundingUsd: r'9.99',
              foundingKrw: '₩74,900',
              isHighlighted: true,
              features: const [
                'Plus 모든 기능 포함',
                'AI GTO 코칭 무제한',
                '주간 Leak 분석 리포트 자동 발행',
                '개인 맞춤형 핸드레인지 AI 솔루션',
              ],
              onSubscribeUsd: () => _openLink(context, StripeLinks.proFoundingUsd),
              onSubscribeKrw: () => _openLink(context, StripeLinks.proFoundingKrw),
            ),
            const SizedBox(height: 32),
            const _FreeNote(),
          ],
        ),
      ),
    );
  }
}

class _FoundingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x2639FF14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonGreen),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt, color: AppColors.neonGreen, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '파운딩 멤버 한정 · 정가 대비 50% 특가',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.tier,
    required this.tagline,
    required this.originalUsd,
    required this.originalKrw,
    required this.foundingUsd,
    required this.foundingKrw,
    required this.features,
    required this.onSubscribeUsd,
    required this.onSubscribeKrw,
    this.isHighlighted = false,
  });

  final String tier;
  final String tagline;
  final String originalUsd;
  final String originalKrw;
  final String foundingUsd;
  final String foundingKrw;
  final List<String> features;
  final VoidCallback onSubscribeUsd;
  final VoidCallback onSubscribeKrw;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isHighlighted ? AppColors.gold : AppColors.neonGreen;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? AppColors.gold : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? const Color(0x40FFD700)
                      : const Color(0x2639FF14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor),
                ),
                child: Text(
                  tier,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (isHighlighted) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BEST',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tagline,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    originalUsd,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    originalKrw,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foundingUsd,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    foundingKrw,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '/ 월',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    f,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
              ),
              onPressed: onSubscribeUsd,
              child: const Text('USD로 구독하기'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor),
              ),
              onPressed: onSubscribeKrw,
              child: const Text('KRW로 구독하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeNote extends StatelessWidget {
  const _FreeNote();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.lock_open_outlined,
            size: 28, color: AppColors.textSecondary),
        SizedBox(height: 8),
        Text(
          'Free 플랜으로도 핸드 메모 + GTO 레인지 조회를 무제한 이용할 수 있습니다.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
