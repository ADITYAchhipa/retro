import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/enterprise_dark_theme.dart';
import '../../../core/theme/enterprise_light_theme.dart';

/// Individual country list item widget
class CountryListItem extends StatelessWidget {
  const CountryListItem({
    super.key,
    required this.country,
    required this.isSelected,
    required this.isDesktop,
    required this.onTap,
  });

  final Map<String, dynamic> country;
  final bool isSelected;
  final bool isDesktop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        margin: EdgeInsets.only(
          bottom: isDesktop ? AppConstants.spacingS : AppConstants.spacingXS,
        ),
        decoration: _buildDecoration(theme, isDark),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            onTap: onTap,
            hoverColor: theme.colorScheme.primary.withValues(alpha: 0.02),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? AppConstants.spacingM : AppConstants.spacingS,
                vertical: isDesktop ? AppConstants.spacingS : AppConstants.spacingXS,
              ),
              child: Row(
                children: [
                  _buildCountryIcon(),
                  SizedBox(width: isDesktop ? AppConstants.spacingM : AppConstants.spacingS + 2),
                  _buildCountryInfo(theme, isDark),
                  _buildSelectionIndicator(theme, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(ThemeData theme, bool isDark) {
    return BoxDecoration(
      gradient: isSelected 
          ? LinearGradient(
              colors: isDark ? [
                EnterpriseDarkTheme.primaryAccent.withValues(alpha: 0.1),
                EnterpriseDarkTheme.primaryAccent.withValues(alpha: 0.05),
              ] : [
                EnterpriseLightTheme.primaryAccent.withValues(alpha: 0.1),
                EnterpriseLightTheme.primaryAccent.withValues(alpha: 0.05),
              ],
            )
          : LinearGradient(
              colors: isDark ? [
                EnterpriseDarkTheme.cardBackground,
                EnterpriseDarkTheme.cardBackground.withValues(alpha: 0.8),
              ] : [
                Colors.grey.shade50,
                Colors.white,
              ],
            ),
      borderRadius: BorderRadius.circular(AppConstants.radiusL),
      border: Border.all(
        color: isSelected 
            ? (isDark ? EnterpriseDarkTheme.primaryAccent : EnterpriseLightTheme.primaryAccent)
            : isDark 
                ? EnterpriseDarkTheme.primaryBorder
                : EnterpriseLightTheme.secondaryBorder, // stronger light border for visibility
        width: isSelected ? 2 : (isDark ? 1 : 1.2),
      ),
      boxShadow: isSelected ? [
        BoxShadow(
          color: (isDark ? EnterpriseDarkTheme.primaryAccent : EnterpriseLightTheme.primaryAccent).withValues(alpha: isDark ? 0.22 : 0.16),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ] : [],
    );
  }

  Widget _buildCountryIcon() {
    final countryColor = Color(country['color'] as int);
    
    return Container(
      width: isDesktop 
          ? AppConstants.flagContainerSizeDesktop 
          : AppConstants.flagContainerSizeMobile - 2,
      height: isDesktop 
          ? AppConstants.flagContainerSizeDesktop 
          : AppConstants.flagContainerSizeMobile - 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            countryColor,
            countryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.spacingM),
        border: Border.all(
          color: isSelected 
              ? countryColor
              : countryColor.withValues(alpha: 0.3),
          width: isSelected ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: countryColor.withValues(alpha: 0.18),
            blurRadius: isSelected ? 6 : 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          country['alias']!,
          style: TextStyle(
            color: Colors.white,
            fontSize: isDesktop ? 12 : 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCountryInfo(ThemeData theme, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            country['name']!,
            style: AppTextStyles.countryName(isDesktop, isSelected).copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 1),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 8 : 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? EnterpriseDarkTheme.primaryAccent : EnterpriseLightTheme.primaryAccent).withValues(alpha: 0.1)
                  : isDark 
                      ? EnterpriseDarkTheme.inputBackground.withValues(alpha: 0.4)
                      : EnterpriseLightTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Text(
              '${country['code']} • ${country['currency']}',
              style: AppTextStyles.countryCode(isDesktop, isSelected).copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionIndicator(ThemeData theme, bool isDark) {
    return AnimatedContainer(
      duration: AppConstants.animationFast,
      width: isDesktop ? 28 : 22,
      height: isDesktop ? 28 : 22,
      decoration: BoxDecoration(
        color: isSelected 
            ? (isDark ? EnterpriseDarkTheme.primaryAccent : EnterpriseLightTheme.primaryAccent)
            : isDark 
                ? EnterpriseDarkTheme.cardBackground
                : EnterpriseLightTheme.inputBackground,
        shape: BoxShape.circle,
        boxShadow: isSelected ? [
          BoxShadow(
            color: (isDark ? EnterpriseDarkTheme.primaryAccent : EnterpriseLightTheme.primaryAccent).withValues(alpha: isDark ? 0.4 : 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : [],
      ),
      child: Icon(
        isSelected ? Icons.check_rounded : Icons.radio_button_unchecked,
        color: isSelected 
            ? Colors.white 
            : isDark 
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.grey.shade500,
        size: isDesktop ? AppConstants.spacingL : AppConstants.spacingM,
      ),
    );
  }
}
