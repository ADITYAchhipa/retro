import 'package:flutter/material.dart';

class AppTheme {
  // Colors per spec
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color primaryTeal = Color(0xFF059669);
  static const Color secondaryYellow = Color(0xFFF59E0B);
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color bgDark = Color(0xFF111827);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: primaryBlue,
      secondary: secondaryYellow,
    );
    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgLight,
      textTheme: base.textTheme,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0D12),
        foregroundColor: Color(0xFFF6F8FA),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFFF6F8FA),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryYellow,
        foregroundColor: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    
    // Enterprise luxury dark color scheme - true sophistication
    const colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: Color(0xFF2563EB),           // Refined royal blue
      onPrimary: Color(0xFFFFFFFF),         // White on blue
      secondary: Color(0xFF059669),         // Muted emerald
      onSecondary: Color(0xFFFFFFFF),       // White on green
      tertiary: Color(0xFFF59E0B),          // Luxury amber
      onTertiary: Color(0xFF000000),        // Black on gold
      surface: Color(0xFF1C2128),           // Premium card surface
      onSurface: Color(0xFFF6F8FA),         // Refined white
      error: Color(0xFFDC2626),             // Sophisticated red
      outline: Color(0xFF30363D),           // Refined border
      outlineVariant: Color(0xFF21262D),    // Subtle border
      surfaceContainerHighest: Color(0xFF161B22),    // Elevated surface
      onSurfaceVariant: Color(0xFFD0D7DE),  // Sophisticated gray
    );
    
    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0A0D12),
      cardColor: const Color(0xFF1C2128),
      dividerColor: const Color(0xFF30363D),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFFF6F8FA),
        displayColor: const Color(0xFFF6F8FA),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111419),
        foregroundColor: Color(0xFFF6F8FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF30363D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C2128),
        elevation: 10,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shadowColor: Colors.black.withValues(alpha: 0.6),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
