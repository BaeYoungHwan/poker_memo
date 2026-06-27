// Stripe 결제 링크 상수 — 실제 Stripe 대시보드에서 생성한 Payment Link URL로 교체 필요
// Stripe Dashboard > Payment Links > Create link
abstract final class StripeLinks {
  // Plus 티어 — 파운딩 멤버 특가 (정가의 50%)
  // 교체: https://buy.stripe.com/YOUR_PLUS_FOUNDING_LINK
  static const String plusFoundingUsd =
      'https://buy.stripe.com/PLACEHOLDER_PLUS_USD';
  static const String plusFoundingKrw =
      'https://buy.stripe.com/PLACEHOLDER_PLUS_KRW';

  // Pro 티어 — 파운딩 멤버 특가 (정가의 50%)
  // 교체: https://buy.stripe.com/YOUR_PRO_FOUNDING_LINK
  static const String proFoundingUsd =
      'https://buy.stripe.com/PLACEHOLDER_PRO_USD';
  static const String proFoundingKrw =
      'https://buy.stripe.com/PLACEHOLDER_PRO_KRW';
}
