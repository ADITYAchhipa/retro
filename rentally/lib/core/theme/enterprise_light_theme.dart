import 'package:flutter/material.dart';

/// Enterprise Light Theme Colors and Styles
/// Based on clean, professional design with navy blue accents
class EnterpriseLightTheme {
  // Primary Colors - Premium white hierarchy
  static const Color primaryBackground = Color(0xFFFBFCFE); // Pure white with subtle blue tint
  static const Color surfaceBackground = Color(0xFFF8FAFC); // Light gray-white for surfaces
  
  // Accent Colors - Enhanced dark navy for sophistication
  static const Color primaryAccent = Color(0xFF0D47A1); // Dark navy trust blue
  static const Color secondaryAccent = Color(0xFF1565C0); // Deep professional blue
  static const Color accentHover = Color(0xFF0A1628); // Very dark navy for interactions
  
  // Text Colors - Enhanced with navy tones
  static const Color primaryText = Color(0xFF1E293B); // Dark navy-gray for readability
  static const Color secondaryText = Color(0xFF334155); // Navy-charcoal for secondary text
  static const Color tertiaryText = Color(0xFF475569); // Slate navy for tertiary text
  static const Color onPrimaryAccent = Color(0xFFFFFFFF); // Clean white text
  
  // Border Colors - Premium hierarchy
  static const Color primaryBorder = Color(0xFFF1F5F9); // Very light slate borders
  static const Color secondaryBorder = Color(0xFFCBD5E1); // Medium slate borders for better visibility
  static const Color subtleBorder = Color(0xFFF8FAFC); // Subtle borders for minimal separation
  static const Color accentBorder = Color(0xFF0D47A1); // Dark navy borders
  
  // Card and Surface Colors - Premium white hierarchy
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure white cards for contrast
  static const Color cardShadow = Color(0xFF64748B); // Soft slate shadow
  static const Color cardBorder = Color(0xFFE2E8F0); // Light slate border
  static const Color elevatedCardBackground = Color(0xFFFEFEFE); // Slightly off-white for elevated cards
  
  // Input Colors - Premium white tones
  static const Color inputBackground = Color(0xFFF1F5F9); // Light slate-white for inputs
  static const Color inputBorder = Color(0xFFCBD5E1); // Medium slate border
  static const Color inputFocusBorder = Color(0xFF0D47A1); // Dark navy focus
  static const Color inputHoverBackground = Color(0xFFF8FAFC); // Lighter on hover
  
  // Shadow Colors
  static const Color primaryShadow = Color(0xFF000000); // Black shadow base
  static const Color surfaceShadow = Color(0xFF111827); // Darker gray surface shadow
  
  // Status Colors - Trust-building and reassuring
  static const Color successColor = Color(0xFF28A745); // Reassuring green for confirmations
  static const Color warningColor = Color(0xFFFFC107); // Gentle warning yellow
  static const Color errorColor = Color(0xFFDC3545); // Clear but not alarming red
  static const Color infoColor = Color(0xFF17A2B8); // Calming info blue
  
  // Blue Shades for Trust & Safety
  static const Color lightBlue = Color(0xFF42A5F5); // Light trustworthy blue
  static const Color mediumBlue = Color(0xFF2196F3); // Medium professional blue
  static const Color darkBlue = Color(0xFF0D47A1); // Dark authority blue
  static const Color skyBlue = Color(0xFF03DAC6); // Sky blue for positive actions
  static const Color navyBlue = Color(0xFF1A237E); // Navy blue for premium features
  static const Color steelBlue = Color(0xFF455A64); // Steel blue for secondary elements
  
  // Dark Navy Blue Shades
  static const Color darkNavy = Color(0xFF0A1628); // Very dark navy for headers
  static const Color midnightBlue = Color(0xFF1E293B); // Midnight blue for emphasis
  static const Color deepNavy = Color(0xFF0F172A); // Deep navy for premium elements
  static const Color charcoalBlue = Color(0xFF334155); // Charcoal blue for text
  static const Color slateNavy = Color(0xFF475569); // Slate navy for borders
  
  // Enhanced Dark Navy Gradients for Sophistication
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8F9FA), Color(0xFFF1F3F4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Trust-building dark navy gradients
  static const LinearGradient trustGradient = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient lightBlueGradient = LinearGradient(
    colors: [Color(0xFF42A5F5), Color(0xFF03DAC6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Dark Navy Gradients for Premium Feel
  static const LinearGradient darkNavyGradient = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient midnightGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF334155)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient eliteGradient = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Button Styles - Trust-building and welcoming
  static BoxDecoration primaryButtonDecoration = BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: primaryAccent.withOpacity(0.25),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration secondaryButtonDecoration = BoxDecoration(
    color: elevatedCardBackground,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: secondaryBorder, width: 1),
    boxShadow: [
      BoxShadow(
        color: primaryShadow.withOpacity(0.06),
        blurRadius: 3,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Trust button for verified listings
  static BoxDecoration trustButtonDecoration = BoxDecoration(
    gradient: trustGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: lightBlue.withOpacity(0.25),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Card Styles - Premium white hierarchy
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: secondaryBorder, width: 1),
    boxShadow: [
      BoxShadow(
        color: cardShadow.withOpacity(0.05),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration elevatedCardDecoration = BoxDecoration(
    color: elevatedCardBackground,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: subtleBorder, width: 1),
    boxShadow: [
      BoxShadow(
        color: cardShadow.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ],
  );
  
  // Premium badge decoration for verified properties
  static BoxDecoration premiumBadgeDecoration = BoxDecoration(
    color: navyBlue,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: navyBlue.withOpacity(0.3),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
