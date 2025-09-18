import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Header widget for the country selection screen
/// Contains the animated icon, title, and description
class CountrySelectionHeader extends StatelessWidget {
  const CountrySelectionHeader({
    super.key,
    required this.pulseAnimation,
    required this.isDesktop,
  });

  final Animation<double> pulseAnimation;
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
      margin: EdgeInsets.only(
        bottom: isDesktop ? AppConstants.spacingXXL : AppConstants.spacingXL,
      ),
      padding: EdgeInsets.all(
        isDesktop ? AppConstants.spacingXXL : AppConstants.spacingXL,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [
            theme.colorScheme.surface.withOpacity(0.98),
            theme.colorScheme.surface.withOpacity(0.92),
            theme.colorScheme.surface.withOpacity(0.95),
          ] : [
            Colors.white.withOpacity(0.98),
            Colors.white.withOpacity(0.92),
            const Color(0xFFFBFCFE).withOpacity(0.95),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1) 
              : const Color(0xFFE2E8F0).withOpacity(0.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(isDark ? 0.12 : 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.white.withOpacity(0.7),
              blurRadius: 1,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
        ],
      ),
      child: Column(
        children: [
          // Static 3D icon
          _build3DIcon(),
          SizedBox(height: isDesktop ? AppConstants.spacingXL : AppConstants.spacingL),
          
          // Title
          Text(
            'Choose Your Location',
            style: AppTextStyles.heading1(isDesktop).copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isDesktop ? AppConstants.spacingL : AppConstants.spacingM),
          
          // Description
          Text(
            'Select your country to unlock personalized rental experiences tailored just for you.',
            style: AppTextStyles.body(isDesktop).copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _build3DIcon() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
          width: isDesktop 
              ? AppConstants.iconContainerSizeDesktop 
              : AppConstants.iconContainerSizeMobile,
          height: isDesktop 
              ? AppConstants.iconContainerSizeDesktop 
              : AppConstants.iconContainerSizeMobile,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
                theme.colorScheme.primary.withOpacity(0.6),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(isDark ? 0.4 : 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.public_rounded,
            size: isDesktop ? AppConstants.iconSizeLarge : AppConstants.iconSizeMedium,
            color: Colors.white,
          ),
        );
      },
    );
  }
}
