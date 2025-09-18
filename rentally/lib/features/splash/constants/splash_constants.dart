import 'package:flutter/material.dart';

/// Constants for the splash screen including colors, animations, and sizing.
class SplashConstants {
  // Animation durations - Smoother timing
  static const Duration mainAnimationDuration = Duration(milliseconds: 1500);
  static const Duration pulseAnimationDuration = Duration(milliseconds: 3000);
  
  // Logo and icon sizing
  static const double logoSize = 60.0;
  static const double logoContainerPadding = 18.0;
  
  // Typography - Enhanced for better readability
  static const double titleFontSize = 36.0;
  static const double taglineFontSize = 14.0;
  static const double trustBadgeFontSize = 12.0;
  static const double buttonFontSize = 18.0;
  
  // Spacing - Further increased for maximum visual breathing room
  static const double titleSpacing = 48.0;
  static const double taglineSpacing = 32.0;
  static const double trustBadgeSpacing = 70.0;
  static const double buttonSpacing = 82.0;
  static const double trustBadgeIconSpacing = 8.0;
  
  // Button styling
  static const double buttonVerticalPadding = 16.0;
  static const double buttonBorderRadius = 24.0;
  static const double buttonElevation = 8.0;
  static const double buttonIconSize = 18.0;
  static const double buttonIconSpacing = 6.0;
  
  // Trust badge styling - Optimized for professional mobile appearance
  static const double trustBadgeIconSize = 20.0;
  static const double trustBadgeIconPadding = 12.0;
  static const double trustBadgeBorderRadius = 12.0;
  static const double trustBadgeContainerRadius = 20.0;
  static const double trustBadgeContainerPadding = 20.0;
  
  // Container constraints - Increased button width for better mobile presence
  static const double maxButtonWidth = 500.0;
  static const double responsiveMaxWidth = 600.0;
  static const double horizontalMargin = 48.0;
  static const double taglineHorizontalPadding = 64.0;
}

/// Color palette for the splash screen.
class SplashColors {
  // Primary colors
  static const Color primary = Color(0xFF1E40AF);
  static const Color primaryDark = Color(0xFF1a237e);
  
  // Background gradient colors
  static const Color gradientStart = Color(0xFF1E40AF);
  static const Color gradientMiddle = Color(0xFFF8FAFC);
  static const Color gradientEnd = Color(0xFF3B82F6);
  
  // Logo container gradient
  static const Color logoGradientStart = Color.fromARGB(255, 175, 187, 252);
  static const Color logoGradientMiddle = Color.fromARGB(255, 126, 185, 243);
  static const Color logoGradientEnd = Color(0xFFE2E8F0);
  
  // Text colors
  static const Color titleColor = Color(0xFF1a237e);
  static const Color taglineColor = Color(0xFF475569);
  
  // Trust badge colors
  static const Color secureColor = Color(0xFF059669);
  static const Color verifiedColor = Color(0xFF6366F1);
  static const Color supportColor = Color.fromARGB(255, 252, 189, 95);
  
  // Shadow colors
  static const Color primaryShadow = Color(0x331E40AF);
  static const Color whiteShadow = Color(0xE6FFFFFF);
  static const Color blueShadow = Color.fromARGB(26, 57, 110, 184);
  
  // Trust badge container
  static const Color trustBadgeBackground = Colors.white;
  static const double trustBadgeBackgroundOpacity = 0.8;
  static const double trustBadgeShadowOpacity = 0.1;
}

/// Animation curves and configurations for the splash screen.
class SplashAnimations {
  static const Curve fadeInCurve = Curves.easeInOut;
  static const Curve scaleInCurve = Curves.easeOutBack;
  static const Curve pulseInOutCurve = Curves.easeInOutSine;
  
  // Animation ranges
  static const double fadeStart = 0.0;
  static const double fadeEnd = 1.0;
  static const double scaleStart = 0.5;
  static const double scaleEnd = 1.0;
  static const double pulseStart = 1.0;
  static const double pulseEnd = 1.1;
}

/// Text content for the splash screen.
class SplashTexts {
  static const String appTitle = 'Rentaly';
  static const String tagline = 'Find Rooms, Vehicles, & More Anywhere in the World';
  static const String buttonText = 'Get Started';
  
  // Trust badge labels
  static const String secureLabel = 'Secure';
  static const String verifiedLabel = 'Verified';
  static const String supportLabel = '24/7 Support';
}

/// Shadow configurations for various UI elements.
class SplashShadows {
  static const List<BoxShadow> logoShadows = [
    BoxShadow(
      color: SplashColors.primaryShadow,
      blurRadius: 30,
      offset: Offset(0, 15),
      spreadRadius: 5,
    ),
    BoxShadow(
      color: SplashColors.whiteShadow,
      blurRadius: 15,
      offset: Offset(-8, -8),
    ),
    BoxShadow(
      color: SplashColors.blueShadow,
      blurRadius: 20,
      offset: Offset(8, 8),
    ),
  ];
  
  static List<BoxShadow> trustBadgeShadows = [
    BoxShadow(
      color: SplashColors.primary.withOpacity(SplashColors.trustBadgeShadowOpacity),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
  
  static List<BoxShadow> trustBadgeIconShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static const List<Shadow> titleShadows = [
    Shadow(
      color: Color.fromRGBO(255, 255, 255, 0.8),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];
  
  static const List<Shadow> taglineShadows = [
    Shadow(
      color: Color.fromRGBO(255, 255, 255, 0.6),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];
}
