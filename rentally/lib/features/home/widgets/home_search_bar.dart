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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? EnterpriseDarkTheme.primaryBackground : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.35)
                  : EnterpriseLightTheme.secondaryBorder,
              width: 1.1,
            ),
            boxShadow: [
              // Dual soft shadows (green-marked style)
              BoxShadow(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                blurRadius: 10,
                offset: const Offset(-5, -5),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: (isDark
                        ? EnterpriseDarkTheme.primaryAccent
                        : EnterpriseLightTheme.primaryAccent)
                    .withOpacity(isDark ? 0.18 : 0.12),
                blurRadius: 10,
                offset: const Offset(5, 5),
                spreadRadius: 0,
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
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? EnterpriseDarkTheme.primaryBackground : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.35)
                        : EnterpriseLightTheme.secondaryBorder,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                      blurRadius: 10,
                      offset: const Offset(-5, -5),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: (isDark
                              ? EnterpriseDarkTheme.primaryAccent
                              : EnterpriseLightTheme.primaryAccent)
                          .withOpacity(isDark ? 0.18 : 0.12),
                      blurRadius: 10,
                      offset: const Offset(5, 5),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.tune,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
