import 'package:flutter/material.dart';

/// Enterprise dark theme constants
class EnterpriseDarkTheme {
  // Background colors
  static const Color primaryBackground = Color(0xFF121212);
  static const Color secondaryBackground = Color(0xFF1E1E1E);
  static const Color cardBackground = Color(0xFF2C2C2C);

  // Text colors
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB0B0B0);
  static const Color tertiaryText = Color(0xFF808080);

  // Accent colors
  static const Color primaryAccent = Color(0xFF6366F1);
  static const Color secondaryAccent = Color(0xFF8B5CF6);
  static const Color successAccent = Color(0xFF10B981);
  static const Color errorAccent = Color(0xFFEF4444);

  // Border colors
  static const Color primaryBorder = Color(0xFF404040);
  static const Color secondaryBorder = Color(0xFF303030);

  // Create a ThemeData based on these colors
  static ThemeData get themeData => ThemeData.dark().copyWith(
        primaryColor: primaryAccent,
        scaffoldBackgroundColor: primaryBackground,
        cardColor: cardBackground,
        dividerColor: primaryBorder,
      );
}
