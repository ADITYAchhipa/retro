import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/enterprise_dark_theme.dart';
import '../../../core/theme/enterprise_light_theme.dart';

/// Search field widget for filtering countries
class CountrySearchField extends StatelessWidget {
  const CountrySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.isDesktop,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isDesktop 
            ? AppConstants.maxContentWidth 
            : AppConstants.maxContentWidthMobile,
      ),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: isDark ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EnterpriseDarkTheme.cardBackground,
            EnterpriseDarkTheme.cardBackground.withValues(alpha: 0.8),
          ],
        ) : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: isDark 
              ? EnterpriseDarkTheme.primaryBorder
              : EnterpriseLightTheme.primaryAccent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? EnterpriseDarkTheme.primaryShadow.withValues(alpha: 0.35)
                : EnterpriseLightTheme.primaryAccent.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          if (isDark) BoxShadow(
            color: EnterpriseDarkTheme.primaryAccent.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontSize: isDesktop 
              ? AppConstants.fontSizeBodyDesktop 
              : AppConstants.fontSizeBodyMobile,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search for your country...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: isDesktop 
                ? AppConstants.fontSizeBodyDesktop 
                : AppConstants.fontSizeBodyMobile,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
          prefixIcon: _buildSearchIcon(theme),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppConstants.spacingXL : AppConstants.spacingL,
            vertical: isDesktop ? AppConstants.spacingM - 2 : AppConstants.spacingS + 2, // more compact on phones
          ),
          filled: true,
          fillColor: isDark ? EnterpriseDarkTheme.inputBackground : EnterpriseLightTheme.inputBackground,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSearchIcon(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM, vertical: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [
            EnterpriseDarkTheme.primaryAccent,
            EnterpriseDarkTheme.secondaryAccent,
          ] : [
            EnterpriseLightTheme.primaryAccent,
            EnterpriseLightTheme.secondaryAccent,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.search_rounded,
        color: Colors.white,
        size: isDesktop ? AppConstants.spacingXL : AppConstants.spacingL + 2,
      ),
    );
  }
}
