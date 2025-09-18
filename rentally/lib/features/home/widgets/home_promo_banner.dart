import 'package:flutter/material.dart';
import '../../../core/theme/enterprise_dark_theme.dart';
import '../../../core/theme/enterprise_light_theme.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: isDark 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  EnterpriseDarkTheme.primaryAccent.withOpacity(0.8),
                  EnterpriseDarkTheme.secondaryAccent.withOpacity(0.6),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  EnterpriseLightTheme.primaryAccent,
                  EnterpriseLightTheme.secondaryAccent,
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? EnterpriseDarkTheme.primaryAccent.withOpacity(0.4)
              : EnterpriseLightTheme.primaryAccent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? EnterpriseDarkTheme.primaryAccent.withOpacity(0.3)
                : EnterpriseLightTheme.primaryAccent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎉 Special Offer!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Get 20% off on your first rental',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Claim Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.local_offer,
            color: Colors.white,
            size: 28,
          ),
        ],
      ),
    );
  }
}
