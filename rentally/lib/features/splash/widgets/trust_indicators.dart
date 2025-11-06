import 'package:flutter/material.dart';
import '../constants/splash_constants.dart';

/// A widget that displays trust indicators (badges) with fade animation.
/// 
/// This widget shows three trust badges:
/// - Secure: Emphasizes security features
/// - Verified: Highlights verification process
/// - 24/7 Support: Shows customer support availability
/// 
/// Features:
/// - Smooth fade-in animation
/// - Professional glassmorphic container
/// - Evenly spaced badge layout
/// - Individual badge animations and styling
class TrustIndicators extends StatelessWidget {
  /// Animation for fading in the trust indicators
  final Animation<double> fadeAnimation;

  /// Creates a trust indicators widget.
  const TrustIndicators({
    super.key,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : 16.0,
      ),
        padding: const EdgeInsets.all(SplashConstants.trustBadgeContainerPadding),
        decoration: _buildContainerDecoration(),
        child: _buildTrustBadgeRow(),
      ),
    );
  }

  /// Builds the enhanced container decoration with better visibility.
  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(SplashConstants.trustBadgeContainerRadius),
      border: Border.all(
        color: const Color(0xFFE2E8F0),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        const BoxShadow(
          color: Colors.white,
          blurRadius: 5,
          offset: Offset(0, -1),
        ),
      ],
    );
  }

  /// Builds the trust badge row with responsive spacing and layout.
  Widget _buildTrustBadgeRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 600;
        final isSmallScreen = screenWidth < 400;
        
        // Optimized mobile spacing for professional appearance
        final badgeSpacing = isTablet ? 24.0 : (isSmallScreen ? 12.0 : 16.0);
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Expanded(
              child: TrustBadge(
                icon: Icons.security,
                label: 'Secure',
                color: Color(0xFF10B981),
              ),
            ),
            SizedBox(width: badgeSpacing),
            const Expanded(
              child: TrustBadge(
                icon: Icons.verified,
                label: 'Verified',
                color: Color(0xFF3B82F6),
              ),
            ),
            SizedBox(width: badgeSpacing),
            const Expanded(
              child: TrustBadge(
                icon: Icons.support_agent,
                label: '24/7 Support',
                color: Color(0xFFF59E0B),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A single trust badge widget with icon and label.
/// 
/// This widget creates an individual trust badge with:
/// - Colored gradient background
/// - Professional shadow effects
/// - Icon and text layout
/// - Consistent styling
class TrustBadge extends StatelessWidget {
  /// The icon to display in the badge
  final IconData icon;
  
  /// The text label for the badge
  final String label;
  
  /// The primary color for the badge
  final Color color;

  /// Creates a trust badge widget.
  const TrustBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconContainer(),
        const SizedBox(height: SplashConstants.trustBadgeIconSpacing),
        _buildLabel(),
      ],
    );
  }

  /// Builds the icon container with gradient background and shadow.
  Widget _buildIconContainer() {
    return Container(
      padding: const EdgeInsets.all(SplashConstants.trustBadgeIconPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(SplashConstants.trustBadgeBorderRadius),
        boxShadow: SplashShadows.trustBadgeIconShadow(color),
      ),
      child: Icon(
        icon,
        color: color,
        size: SplashConstants.trustBadgeIconSize,
      ),
    );
  }

  /// Builds the text label with responsive styling.
  Widget _buildLabel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;
        final isSmallScreen = screenWidth < 400;
        
        final fontSize = isTablet ? 12.0 : (isSmallScreen ? 10.5 : 11.0);
        
        return Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B), // Very dark for maximum contrast
            height: 1.3,
            letterSpacing: 0.2,
            shadows: const [
              Shadow(
                color: Colors.white,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
              Shadow(
                color: Colors.white,
                offset: Offset(1, 0),
                blurRadius: 1,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}
