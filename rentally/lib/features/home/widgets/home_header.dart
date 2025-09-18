import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/enterprise_dark_theme.dart';
import '../../../core/theme/enterprise_light_theme.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? EnterpriseDarkTheme.primaryBackground : EnterpriseLightTheme.primaryBackground,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Rentaly',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? EnterpriseDarkTheme.primaryAccent : EnterpriseLightTheme.primaryAccent,
            ),
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
                      color: isDark ? EnterpriseDarkTheme.cardBackground : EnterpriseLightTheme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: isDark ? Border.all(
                        color: EnterpriseDarkTheme.primaryBorder,
                        width: 1,
                      ) : null,
                      boxShadow: [
                        BoxShadow(
                          color: isDark 
                              ? EnterpriseDarkTheme.primaryShadow.withOpacity(0.3)
                              : EnterpriseLightTheme.cardShadow.withOpacity(0.1),
                          blurRadius: isDark ? 8 : 4,
                          offset: const Offset(0, 2),
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
                      color: isDark ? EnterpriseDarkTheme.primaryAccent : EnterpriseLightTheme.primaryAccent,
                      borderRadius: BorderRadius.circular(20),
                      border: isDark ? Border.all(
                        color: EnterpriseDarkTheme.primaryBorder,
                        width: 2,
                      ) : null,
                      boxShadow: [
                        BoxShadow(
                          color: isDark 
                              ? EnterpriseDarkTheme.primaryShadow.withOpacity(0.3)
                              : EnterpriseLightTheme.cardShadow.withOpacity(0.1),
                          blurRadius: isDark ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
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
