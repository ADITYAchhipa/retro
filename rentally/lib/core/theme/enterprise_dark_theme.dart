import 'package:flutter/material.dart';

class EnterpriseDarkTheme {
  // True luxury dark backgrounds - sophisticated and refined
  static const Color primaryBackground = Color(0xFF0A0D12);      // Deep obsidian
  static const Color secondaryBackground = Color(0xFF111419);    // Rich charcoal
  static const Color surfaceBackground = Color(0xFF161B22);      // Elevated surface
  static const Color cardBackground = Color(0xFF1C2128);         // Premium card surface
  static const Color premiumCardBackground = Color(0xFF22272E);  // Luxury card variant
  
  // Refined luxury accent system - muted sophistication
  static const Color primaryAccent = Color(0xFF2563EB);          // Refined royal blue
  static const Color secondaryAccent = Color(0xFF4F46E5);        // Sophisticated indigo
  static const Color tertiaryAccent = Color(0xFF7C3AED);         // Elegant purple
  static const Color successAccent = Color(0xFF059669);          // Muted emerald
  static const Color warningAccent = Color(0xFFCA8A04);          // Refined gold
  static const Color errorAccent = Color(0xFFDC2626);            // Sophisticated red
  static const Color premiumAccent = Color(0xFFF59E0B);          // Luxury amber
  static const Color platinumAccent = Color(0xFF9CA3AF);         // Refined silver
  
  // Sophisticated text hierarchy - luxury typography
  static const Color primaryText = Color(0xFFF6F8FA);            // Refined white
  static const Color secondaryText = Color(0xFFD0D7DE);          // Sophisticated gray
  static const Color tertiaryText = Color(0xFF8B949E);           // Muted silver
  static const Color mutedText = Color(0xFF656D76);              // Subtle gray
  static const Color premiumText = Color(0xFFF59E0B);            // Luxury accent text
  static const Color onPrimaryAccent = Color(0xFFFFFFFF);        // White on accent
  static const Color onSurface = Color(0xFFE6EDF3);              // Soft surface text
  
  // Refined border system - subtle luxury
  static const Color primaryBorder = Color(0xFF30363D);          // Refined border
  static const Color accentBorder = Color(0xFF2563EB);           // Accent border
  static const Color mutedBorder = Color(0xFF21262D);            // Subtle border
  static const Color goldBorder = Color(0xFFF59E0B);             // Luxury gold border
  static const Color platinumBorder = Color(0xFF656D76);         // Refined platinum
  
  // Sophisticated shadow system - premium depth
  static const Color primaryShadow = Color(0xFF000000);          // Pure black shadow
  static const Color accentShadow = Color(0xFF1E40AF);           // Refined blue glow
  static const Color premiumShadow = Color(0xFFB45309);          // Warm gold shadow
  static const Color luxuryShadow = Color(0xFF010409);           // Ultra-deep shadow
  
  // Enterprise luxury gradient system - sophisticated depth
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0D12),
      Color(0xFF111419),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF161B22),
      Color(0xFF1C2128),
    ],
  );

  // Premium enterprise gradient with refined depth
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1C2128),
      Color(0xFF22272E),
      Color(0xFF2D333B),
    ],
  );

  // Platinum enterprise gradient for luxury features
  static const LinearGradient platinumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF30363D),
      Color(0xFF373E47),
      Color(0xFF424A53),
    ],
  );

  static const Color inputBackground = Color(0xFF30363D);        // Enterprise input background

  // Enterprise luxury card decorations with sophisticated depth
  static BoxDecoration get primaryCardDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: primaryBorder.withValues(alpha: 0.3), width: 0.5),
    boxShadow: [
      BoxShadow(
        color: luxuryShadow.withValues(alpha: 0.8),
        blurRadius: 40,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: primaryAccent.withValues(alpha: 0.05),
        blurRadius: 60,
        offset: const Offset(0, 24),
      ),
      BoxShadow(
        color: primaryShadow.withValues(alpha: 0.9),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ],
  );

  // Enterprise premium card for luxury features
  static BoxDecoration get premiumCardDecoration => BoxDecoration(
    gradient: premiumGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: goldBorder.withValues(alpha: 0.2), width: 0.5),
    boxShadow: [
      BoxShadow(
        color: premiumShadow.withValues(alpha: 0.6),
        blurRadius: 48,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: premiumAccent.withValues(alpha: 0.08),
        blurRadius: 72,
        offset: const Offset(0, 32),
      ),
      BoxShadow(
        color: luxuryShadow.withValues(alpha: 0.95),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get secondaryCardDecoration => BoxDecoration(
    color: surfaceBackground,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: mutedBorder.withValues(alpha: 0.5),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: primaryShadow.withValues(alpha: 0.1),
        blurRadius: 12,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Enterprise trust-building button gradient
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2563EB),
      Color(0xFF3B82F6),
    ],
  );

  // Enterprise premium gold button gradient
  static const LinearGradient premiumButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFCA8A04),
      Color(0xFFF59E0B),
    ],
  );

  // Enterprise platinum button gradient
  static const LinearGradient platinumButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF656D76),
      Color(0xFF9CA3AF),
    ],
  );

  static BoxDecoration get buttonDecoration => BoxDecoration(
    gradient: buttonGradient,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: primaryAccent.withValues(alpha: 0.25),
        blurRadius: 32,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: luxuryShadow.withValues(alpha: 0.8),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static BoxDecoration get premiumButtonDecoration => BoxDecoration(
    gradient: premiumButtonGradient,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: premiumShadow.withValues(alpha: 0.3),
        blurRadius: 36,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: premiumAccent.withValues(alpha: 0.15),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration get platinumButtonDecoration => BoxDecoration(
    gradient: platinumButtonGradient,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: platinumBorder.withValues(alpha: 0.4),
        blurRadius: 28,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: luxuryShadow.withValues(alpha: 0.6),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get outlineButtonDecoration => BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: primaryBorder.withValues(alpha: 0.4),
      width: 0.5,
    ),
  );

  static BoxDecoration get premiumOutlineDecoration => BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: goldBorder.withValues(alpha: 0.3),
      width: 0.5,
    ),
  );
  
  // Text Styles
  static const TextStyle headlineStyle = TextStyle(
    color: primaryText,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  
  static const TextStyle titleStyle = TextStyle(
    color: primaryText,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    color: secondaryText,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );
  
  static const TextStyle captionStyle = TextStyle(
    color: tertiaryText,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );
  
  static const TextStyle buttonTextStyle = TextStyle(
    color: primaryText,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  static const TextStyle accentTextStyle = TextStyle(
    color: primaryAccent,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}
