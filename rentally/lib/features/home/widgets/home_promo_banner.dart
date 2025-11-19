import 'package:flutter/material.dart';
import '../../../core/theme/enterprise_dark_theme.dart';
import '../../../core/theme/enterprise_light_theme.dart';
import '../../../core/neo/neo.dart';

/// Promotional banner widget for the home screen
class HomePromoBanner extends StatelessWidget {
  const HomePromoBanner({
    super.key,
    required this.theme,
    required this.isDark,
  });

  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? EnterpriseDarkTheme.primaryAccent : EnterpriseLightTheme.primaryAccent;
    return NeoGlass(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: BorderRadius.circular(16),
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : EnterpriseLightTheme.primaryAccent.withValues(alpha: 0.08),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : EnterpriseLightTheme.secondaryBorder,
      boxShadow: [
        // Dual soft shadows (green-marked style)
        BoxShadow(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          blurRadius: 10,
          offset: const Offset(-5, -5),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: (isDark
                  ? EnterpriseDarkTheme.primaryAccent
                  : EnterpriseLightTheme.primaryAccent)
              .withValues(alpha: isDark ? 0.18 : 0.12),
          blurRadius: 10,
          offset: const Offset(5, 5),
          spreadRadius: 0,
        ),
      ],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎉 Special Offer!',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get 20% off on your first rental',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent.withValues(alpha: 0.95), accent.withValues(alpha: 0.75)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      // Dual soft shadows for the CTA
                      BoxShadow(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                        blurRadius: 10,
                        offset: const Offset(-5, -5),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: (isDark
                                ? EnterpriseDarkTheme.primaryAccent
                                : EnterpriseLightTheme.primaryAccent)
                            .withValues(alpha: isDark ? 0.18 : 0.15),
                        blurRadius: 10,
                        offset: const Offset(5, 5),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Claim Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : EnterpriseLightTheme.secondaryBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                  blurRadius: 10,
                  offset: const Offset(-5, -5),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: (isDark
                          ? EnterpriseDarkTheme.primaryAccent
                          : EnterpriseLightTheme.primaryAccent)
                      .withValues(alpha: isDark ? 0.18 : 0.12),
                  blurRadius: 10,
                  offset: const Offset(5, 5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.local_offer,
              color: accent,
              size: 24,
            ),
          )
        ],
      ),
    );
  }
}
