import 'package:flutter/material.dart';
import '../../../core/theme/enterprise_dark_theme.dart';
import '../../../core/theme/enterprise_light_theme.dart';

/// Tab section widget for switching between Properties and Vehicles
class HomeTabSection extends StatelessWidget {
  const HomeTabSection({
    super.key,
    required this.tabController,
    required this.theme,
    required this.isDark,
    this.onTabChanged,
  });

  final TabController tabController;
  final ThemeData theme;
  final bool isDark;
  final void Function(int index)? onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? EnterpriseDarkTheme.cardBackground : EnterpriseLightTheme.surfaceBackground,
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
                : EnterpriseLightTheme.cardShadow.withOpacity(0.1),
            blurRadius: isDark ? 8 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: tabController,
        onTap: onTabChanged,
        // Remove any Material divider line that might render inside the control
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: isDark 
              ? const LinearGradient(
                  colors: [
                    EnterpriseDarkTheme.primaryAccent,
                    EnterpriseDarkTheme.secondaryAccent,
                  ],
                )
              : const LinearGradient(
                  colors: [
                    EnterpriseLightTheme.primaryAccent,
                    EnterpriseLightTheme.secondaryAccent,
                  ],
                ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? EnterpriseDarkTheme.primaryAccent.withOpacity(0.3)
                  : EnterpriseLightTheme.primaryAccent.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        padding: const EdgeInsets.all(4),
        labelPadding: EdgeInsets.zero,
        tabs: const [
          Tab(
            height: 40,
            child: Text('Properties', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Tab(
            height: 40,
            child: Text('Vehicles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
