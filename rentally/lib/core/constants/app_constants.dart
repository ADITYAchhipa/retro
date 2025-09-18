import 'package:flutter/material.dart';

/// Application-wide constants for consistent sizing, colors, and styling
class AppConstants {
  AppConstants._();

  // Screen breakpoints
  static const double desktopBreakpoint = 1024.0;
  static const double tabletBreakpoint = 768.0;

  // Sizing constants
  static const double maxContentWidth = 420.0;
  static const double maxContentWidthMobile = 360.0;
  
  // Button dimensions
  static const double buttonHeightDesktop = 56.0;
  static const double buttonHeightMobile = 52.0;
  static const double buttonWidthExpandedDesktop = 320.0;
  static const double buttonWidthExpandedMobile = 280.0;
  static const double buttonWidthCollapsedDesktop = 280.0;
  static const double buttonWidthCollapsedMobile = 240.0;
  
  // Icon sizes
  static const double iconSizeLarge = 24.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeSmall = 16.0;
  
  // Container sizes
  static const double iconContainerSizeDesktop = 52.0;
  static const double iconContainerSizeMobile = 48.0;
  static const double flagContainerSizeDesktop = 40.0;
  static const double flagContainerSizeMobile = 36.0;
  static const double backButtonSize = 36.0;
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  
  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 18.0;
  static const double radiusXXL = 20.0;
  static const double radiusCard = 24.0;
  
  // Typography
  static const double fontSizeH1Desktop = 24.0;
  static const double fontSizeH1Mobile = 20.0;
  static const double fontSizeH2Desktop = 15.0;
  static const double fontSizeH2Mobile = 14.0;
  static const double fontSizeBodyDesktop = 14.0;
  static const double fontSizeBodyMobile = 13.0;
  static const double fontSizeButtonDesktop = 15.0;
  static const double fontSizeButtonMobile = 14.0;
  static const double fontSizeSmallDesktop = 11.0;
  static const double fontSizeSmallMobile = 10.0;
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationEntry = Duration(milliseconds: 800);
  static const Duration animationPulse = Duration(seconds: 2);
  static const Duration animationSimulatedDelay = Duration(milliseconds: 800);

  // Referral
  static const String referralBaseUrl = 'https://rentally.app/ref';

  // Compliance thresholds
  // Bookings at or above this total require KYC verification
  static const double kycHighValueThreshold = 1000.0; // in default currency units
}

/// Color constants for consistent theming
class AppColorsLegacy {
  AppColorsLegacy._();
  
  // Primary colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  
  // Surface colors
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFEFF6FF);
  static const Color surfaceMedium = Color(0xFFDBEAFE);
  static const Color surfaceDark = Color(0xFFBFDBFE);
  static const Color surfacePurple = Color(0xFFDDD6FE);
  
  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  
  // Border colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFCBD5E1);
  
  // State colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}

/// Text style constants
class AppTextStyles {
  AppTextStyles._();
  
  static TextStyle heading1(bool isDesktop) => TextStyle(
    fontSize: isDesktop ? AppConstants.fontSizeH1Desktop : AppConstants.fontSizeH1Mobile,
    fontWeight: FontWeight.w900,
    color: AppColorsLegacy.textPrimary,
    letterSpacing: -0.8,
    height: 1.1,
    shadows: [
      Shadow(
        color: Colors.black.withOpacity(0.1),
        offset: const Offset(0, 2),
        blurRadius: 4,
      ),
    ],
  );
  
  static TextStyle body(bool isDesktop) => TextStyle(
    color: AppColorsLegacy.textSecondary,
    fontSize: isDesktop ? AppConstants.fontSizeBodyDesktop : AppConstants.fontSizeBodyMobile,
    height: 1.6,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  static TextStyle button(bool isDesktop) => TextStyle(
    fontSize: isDesktop ? AppConstants.fontSizeButtonDesktop : AppConstants.fontSizeButtonMobile,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
    height: 1.2,
  );
  
  static TextStyle countryName(bool isDesktop, bool isSelected) => TextStyle(
    fontWeight: FontWeight.w800,
    color: isSelected ? AppColorsLegacy.primary : AppColorsLegacy.textPrimary,
    fontSize: isDesktop ? AppConstants.fontSizeH2Desktop : AppConstants.fontSizeH2Mobile,
    letterSpacing: -0.3,
    height: 1.2,
  );
  
  static TextStyle countryCode(bool isDesktop, bool isSelected) => TextStyle(
    color: isSelected ? AppColorsLegacy.primary : AppColorsLegacy.textSecondary,
    fontWeight: FontWeight.w700,
    fontSize: isDesktop ? AppConstants.fontSizeSmallDesktop : AppConstants.fontSizeSmallMobile,
    letterSpacing: 0.5,
  );
}
