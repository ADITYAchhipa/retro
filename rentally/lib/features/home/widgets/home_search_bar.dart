import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/enterprise_dark_theme.dart';
import '../../../core/theme/enterprise_light_theme.dart';

/// Search bar widget for the home screen
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    required this.theme,
    required this.isDark,
  });

  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Navigate to search screen, keeping previous route on the stack for back navigation
          context.push('/search');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? EnterpriseDarkTheme.cardBackground : EnterpriseLightTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: isDark ? Border.all(
              color: EnterpriseDarkTheme.primaryBorder,
              width: 1,
            ) : Border.all(
              color: EnterpriseLightTheme.secondaryBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? EnterpriseDarkTheme.primaryShadow.withOpacity(0.3)
                    : EnterpriseLightTheme.cardShadow.withOpacity(0.08),
                blurRadius: isDark ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: isDark ? EnterpriseDarkTheme.primaryAccent : EnterpriseLightTheme.secondaryText,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search properties or vehicles...',
              style: TextStyle(
                color: isDark ? EnterpriseDarkTheme.tertiaryText : EnterpriseLightTheme.tertiaryText,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}
