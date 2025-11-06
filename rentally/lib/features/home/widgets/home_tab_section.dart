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
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        color: isDark ? EnterpriseDarkTheme.primaryBackground : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.35)
              : EnterpriseLightTheme.secondaryBorder,
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
      child: TabBar(
        controller: tabController,
        onTap: onTabChanged,
        // Remove any Material divider line that might render inside the control
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
            width: 1,
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
        padding: const EdgeInsets.all(2),
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
