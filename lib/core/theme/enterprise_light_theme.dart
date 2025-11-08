import 'package:flutter/material.dart';

/// Enterprise light theme constants
class EnterpriseLightTheme {
  // Background colors
  static const Color primaryBackground = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text colors
  static const Color primaryText = Color(0xFF000000);
  static const Color secondaryText = Color(0xFF666666);
  static const Color tertiaryText = Color(0xFF999999);

  // Accent colors
  static const Color primaryAccent = Color(0xFF6366F1);
  static const Color secondaryAccent = Color(0xFF8B5CF6);
  static const Color successAccent = Color(0xFF10B981);
  static const Color errorAccent = Color(0xFFEF4444);

  // Border colors
  static const Color primaryBorder = Color(0xFFE0E0E0);
  static const Color secondaryBorder = Color(0xFFF0F0F0);

  // Create a ThemeData based on these colors
  static ThemeData get themeData => ThemeData.light().copyWith(
        primaryColor: primaryAccent,
        scaffoldBackgroundColor: primaryBackground,
        cardColor: cardBackground,
        dividerColor: primaryBorder,
      );
}
