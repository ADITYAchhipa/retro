import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/enterprise_dark_theme.dart';
import '../../../core/theme/enterprise_light_theme.dart';
import '../../../core/neo/neo_text.dart';

/// Header widget for the home screen containing greeting and notifications
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      decoration: BoxDecoration(
        color: isDark ? EnterpriseDarkTheme.primaryBackground : EnterpriseLightTheme.primaryBackground,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Neo3DText(
            'Rentaly',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to notifications screen using GoRouter
                    context.go('/notifications');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? EnterpriseDarkTheme.primaryBackground : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.35)
                            : Colors.black.withOpacity(0.06),
                        width: 1,
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
                      Icons.notifications_outlined,
                      color: isDark ? EnterpriseDarkTheme.primaryAccent : EnterpriseLightTheme.primaryAccent,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to profile screen using GoRouter
                    context.go('/profile');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? EnterpriseDarkTheme.primaryBackground : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.35)
                            : Colors.black.withOpacity(0.06),
                        width: 1,
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
                      Icons.person,
                      color: isDark ? EnterpriseDarkTheme.primaryAccent : EnterpriseLightTheme.primaryAccent,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
