import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/enterprise_dark_theme.dart';
import '../../../core/theme/enterprise_light_theme.dart';
import '../../../services/country_service.dart';
import '../../../services/user_preferences_service.dart';

/// Continue button widget with loading states and animations
class ContinueButton extends ConsumerWidget {
  const ContinueButton({
    super.key,
    required this.selectedCountry,
    required this.isLoading,
    required this.hasError,
    required this.isDesktop,
    required this.onPressed,
  });

  final String? selectedCountry;
  final bool isLoading;
  final bool hasError;
  final bool isDesktop;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = selectedCountry != null && !isLoading;
    
    return AnimatedContainer(
      duration: AppConstants.animationSlow,
      curve: Curves.easeInOutCubic,
      width: isDesktop ? 450.0 : double.infinity, // Reduced width for desktop
      height: isDesktop 
          ? AppConstants.buttonHeightDesktop 
          : 56.0,
      decoration: _buildDecoration(isEnabled, theme, isDark),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          onTap: isEnabled ? () => _handleContinue(ref) : null,
          hoverColor: isEnabled 
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          splashColor: isEnabled 
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isDesktop ? AppConstants.spacingXL : 16.0,
              horizontal: isDesktop ? 32 : 24.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ..._buildLoadingContent(),
                if (!isLoading && isEnabled) ..._buildEnabledContent(),
                _buildButtonText(),
              ],
            ),
          ),
        ),
      ),
    );
  }


  BoxDecoration _buildDecoration(bool isEnabled, ThemeData theme, bool isDark) {
    return BoxDecoration(
      gradient: isEnabled
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [
                EnterpriseDarkTheme.primaryAccent,
                EnterpriseDarkTheme.secondaryAccent,
                EnterpriseDarkTheme.primaryAccent.withValues(alpha: 0.8),
              ] : [
                EnterpriseLightTheme.primaryAccent,
                EnterpriseLightTheme.secondaryAccent,
                EnterpriseLightTheme.primaryAccent.withValues(alpha: 0.8),
              ],
            )
          : LinearGradient(
              colors: [
                theme.colorScheme.onSurface.withValues(alpha: 0.3),
                theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ],
            ),
      borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      boxShadow: const [],
    );
  }

  List<Widget> _buildLoadingContent() {
    return [
      SizedBox(
        width: isDesktop ? AppConstants.spacingXL : AppConstants.spacingL + 2,
        height: isDesktop ? AppConstants.spacingXL : AppConstants.spacingL + 2,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
      SizedBox(width: isDesktop ? AppConstants.spacingM : AppConstants.spacingS + 2),
    ];
  }

  List<Widget> _buildEnabledContent() {
    return [
      Container(
        width: isDesktop ? 32.0 : 28.0, // Fixed container size
        height: isDesktop ? 32.0 : 28.0, // Fixed container size
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Center( // Ensure perfect centering
          child: Icon(
            hasError ? Icons.refresh_rounded : Icons.arrow_forward_rounded,
            color: Colors.white,
            size: isDesktop ? 18.0 : 16.0, // Slightly smaller for better fit
          ),
        ),
      ),
      SizedBox(width: isDesktop ? AppConstants.spacingM : AppConstants.spacingS + 2),
    ];
  }

  Widget _buildButtonText() {
    final text = _getButtonText();
    final isEnabled = selectedCountry != null || isLoading;
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Text(
          text,
          style: AppTextStyles.button(isDesktop).copyWith(
            color: isEnabled 
                ? Colors.white 
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        );
      },
    );
  }

  String _getButtonText() {
    if (isLoading) return 'Processing...';
    if (hasError) return 'Try Again';
    if (selectedCountry != null) return 'Continue to Rentaly';
    return 'Select a Country First';
  }

  void _handleContinue(WidgetRef ref) {
    if (selectedCountry != null) {
      // Update currency based on selected country
      final currency = CountryService.getCurrencyForCountry(selectedCountry!);
      ref.read(userPreferencesProvider.notifier).updateCurrency(currency);
    }
    
    // Call the original onPressed callback
    onPressed?.call();
  }
}
