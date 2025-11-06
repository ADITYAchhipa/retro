import 'package:flutter/material.dart';

@immutable
class ListingCardTheme extends ThemeExtension<ListingCardTheme> {
  final Color? priceColor;
  final Color? titleColor;
  final Color? ratingColor;
  final Color? chipBackgroundColor;
  final Color? chipBorderColor;
  final Color? chipTextColor;
  final Color? discountBadgeBackgroundColor;
  final Color? discountBadgeBorderColor;
  final Color? discountBadgeTextColor;
  final double cardRadius;
  final Color? cardBorderColor;
  final bool cardShadow;
  final Color? actionIconColor;
  final Color? actionBackgroundColor;
  final Color? actionBorderColor;
  final double actionSpread;

  const ListingCardTheme({
    this.priceColor,
    this.titleColor,
    this.ratingColor,
    this.chipBackgroundColor,
    this.chipBorderColor,
    this.chipTextColor,
    this.discountBadgeBackgroundColor,
    this.discountBadgeBorderColor,
    this.discountBadgeTextColor,
    this.cardRadius = 12,
    this.cardBorderColor,
    this.cardShadow = false,
    this.actionIconColor,
    this.actionBackgroundColor,
    this.actionBorderColor,
    this.actionSpread = 0.0,
  });

  static ListingCardTheme defaults({required bool dark}) {
    if (dark) {
      return ListingCardTheme(
        priceColor: const Color(0xFF3B82F6),
        titleColor: null,
        ratingColor: null,
        chipBackgroundColor: const Color(0xFFFFFFFF).withOpacity(0.06),
        chipBorderColor: const Color(0xFF94A3B8),
        chipTextColor: const Color(0xFF93C5FD),
        discountBadgeBackgroundColor: const Color(0xFFE11D48),
        discountBadgeBorderColor: const Color(0xFFE11D48),
        discountBadgeTextColor: const Color(0xFFBE123C),
        cardRadius: 12,
        cardBorderColor: const Color(0xFF334155),
        cardShadow: false,
        actionIconColor: const Color(0xFFE2E8F0),
        actionBackgroundColor: Colors.transparent,
        actionBorderColor: Colors.transparent,
        actionSpread: 0.0,
      );
    }
    return ListingCardTheme(
      priceColor: const Color(0xFF1D4ED8),
      titleColor: null,
      ratingColor: null,
      chipBackgroundColor: const Color(0xFF000000).withOpacity(0.04),
      chipBorderColor: const Color(0xFF94A3B8),
      chipTextColor: const Color(0xFF1F2937),
      discountBadgeBackgroundColor: const Color(0xFFE11D48),
      discountBadgeBorderColor: const Color(0xFFE11D48),
      discountBadgeTextColor: const Color(0xFFBE123C),
      cardRadius: 12,
      cardBorderColor: const Color(0xFFE5E7EB),
      cardShadow: false,
      actionIconColor: const Color(0xFF111827),
      actionBackgroundColor: Colors.transparent,
      actionBorderColor: Colors.transparent,
      actionSpread: 0.0,
    );
  }

  @override
  ListingCardTheme copyWith({
    Color? priceColor,
    Color? titleColor,
    Color? ratingColor,
    Color? chipBackgroundColor,
    Color? chipBorderColor,
    Color? chipTextColor,
    Color? discountBadgeBackgroundColor,
    Color? discountBadgeBorderColor,
    Color? discountBadgeTextColor,
    double? cardRadius,
    Color? cardBorderColor,
    bool? cardShadow,
    Color? actionIconColor,
    Color? actionBackgroundColor,
    Color? actionBorderColor,
    double? actionSpread,
  }) {
    return ListingCardTheme(
      priceColor: priceColor ?? this.priceColor,
      titleColor: titleColor ?? this.titleColor,
      ratingColor: ratingColor ?? this.ratingColor,
      chipBackgroundColor: chipBackgroundColor ?? this.chipBackgroundColor,
      chipBorderColor: chipBorderColor ?? this.chipBorderColor,
      chipTextColor: chipTextColor ?? this.chipTextColor,
      discountBadgeBackgroundColor: discountBadgeBackgroundColor ?? this.discountBadgeBackgroundColor,
      discountBadgeBorderColor: discountBadgeBorderColor ?? this.discountBadgeBorderColor,
      discountBadgeTextColor: discountBadgeTextColor ?? this.discountBadgeTextColor,
      cardRadius: cardRadius ?? this.cardRadius,
      cardBorderColor: cardBorderColor ?? this.cardBorderColor,
      cardShadow: cardShadow ?? this.cardShadow,
      actionIconColor: actionIconColor ?? this.actionIconColor,
      actionBackgroundColor: actionBackgroundColor ?? this.actionBackgroundColor,
      actionBorderColor: actionBorderColor ?? this.actionBorderColor,
      actionSpread: actionSpread ?? this.actionSpread,
    );
  }

  @override
  ListingCardTheme lerp(ThemeExtension<ListingCardTheme>? other, double t) {
    if (other is! ListingCardTheme) return this;
    return ListingCardTheme(
      priceColor: Color.lerp(priceColor, other.priceColor, t),
      titleColor: Color.lerp(titleColor, other.titleColor, t),
      ratingColor: Color.lerp(ratingColor, other.ratingColor, t),
      chipBackgroundColor: Color.lerp(chipBackgroundColor, other.chipBackgroundColor, t),
      chipBorderColor: Color.lerp(chipBorderColor, other.chipBorderColor, t),
      chipTextColor: Color.lerp(chipTextColor, other.chipTextColor, t),
      discountBadgeBackgroundColor: Color.lerp(discountBadgeBackgroundColor, other.discountBadgeBackgroundColor, t),
      discountBadgeBorderColor: Color.lerp(discountBadgeBorderColor, other.discountBadgeBorderColor, t),
      discountBadgeTextColor: Color.lerp(discountBadgeTextColor, other.discountBadgeTextColor, t),
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t) ?? cardRadius,
      cardBorderColor: Color.lerp(cardBorderColor, other.cardBorderColor, t),
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      actionIconColor: Color.lerp(actionIconColor, other.actionIconColor, t),
      actionBackgroundColor: Color.lerp(actionBackgroundColor, other.actionBackgroundColor, t),
      actionBorderColor: Color.lerp(actionBorderColor, other.actionBorderColor, t),
      actionSpread: lerpDouble(actionSpread, other.actionSpread, t) ?? actionSpread,
    );
  }
}

double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
