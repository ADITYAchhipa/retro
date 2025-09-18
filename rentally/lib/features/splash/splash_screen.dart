import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/responsive_layout.dart';
import '../../app/app_state.dart';
import 'constants/splash_constants.dart';
import 'widgets/animated_logo.dart';
import 'widgets/animated_title.dart';
import 'widgets/animated_tagline.dart';
import 'widgets/trust_indicators.dart';
import 'widgets/get_started_button.dart';
import 'widgets/splash_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

/// Private state class for the splash screen.
///
/// Manages animations and user interactions with a clean, modular approach.
/// Uses multiple animation controllers for smooth, professional transitions.
class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _mainController;
  late AnimationController _pulseController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimationControllers();
    _initializeAnimations();
    _startAnimations();
  }


  /// Initializes the animation controllers with optimized durations.
  void _initializeAnimationControllers() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 300), // Reduced from original
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800), // Reduced from original
      vsync: this,
    );
  }

  /// Initializes all animations with proper curves and ranges.
  void _initializeAnimations() {
    _fadeAnimation = Tween<double>(
      begin: SplashAnimations.fadeStart,
      end: SplashAnimations.fadeEnd,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: SplashAnimations.fadeInCurve,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: SplashAnimations.scaleStart,
      end: SplashAnimations.scaleEnd,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: SplashAnimations.scaleInCurve,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: SplashAnimations.pulseStart,
      end: SplashAnimations.pulseEnd,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: SplashAnimations.pulseInOutCurve,
    ));
  }

  /// Starts all animations in the correct sequence.
  void _startAnimations() {
    _mainController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check auth state and return empty container if authenticated
    final authState = ref.watch(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      body: SplashBackground(
        child: SafeArea(
          child: ResponsiveLayout(
            maxWidth: SplashConstants.responsiveMaxWidth,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  /// Builds the main content with industrial-grade professional layout.
  Widget _buildContent() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final availableHeight = screenSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom;
    
    // Professional enterprise spacing - more generous and structured
    final horizontalPadding = isTablet ? 48.0 : 24.0;
    final sectionSpacing = availableHeight * (isTablet ? 0.08 : 0.06); // tighter on phones
    final elementSpacing = availableHeight * (isTablet ? 0.04 : 0.035); // tighter on phones
    final bottomPadding = isTablet ? 40.0 : 24.0; // slightly tighter on phones
    final double phoneScale = isTablet
        ? 1.0
        : (availableHeight < 560
            ? 0.88
            : (availableHeight < 640
                ? 0.94
                : 1.0));
    
    // On phones, render a fixed layout without scrolling to avoid scroll on splash
    if (!isTablet) {
      return Container(
        constraints: BoxConstraints(
          minHeight: availableHeight,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: availableHeight * 0.06,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo and branding section
            Column(
              children: [
                SizedBox(height: availableHeight * 0.08),
                Transform.scale(scale: phoneScale, child: _buildAnimatedLogo()),
                SizedBox(height: elementSpacing * 2),
                Transform.scale(scale: phoneScale, child: _buildAnimatedTitle()),
                const SizedBox(height: 16),
                _buildAnimatedTagline(),
              ],
            ),
            // Trust indicators section
            Column(
              children: [
                SizedBox(height: sectionSpacing * 0.2),
                _buildTrustIndicators(),
                SizedBox(height: sectionSpacing * 0.8),
              ],
            ),
            // CTA section
            Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Column(
                children: [
                  _buildGetStartedButton(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Tablets/desktop: allow scrolling for flexible window sizes
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          minHeight: availableHeight,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: availableHeight * 0.06,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                SizedBox(height: availableHeight * 0.08),
                _buildAnimatedLogo(),
                SizedBox(height: elementSpacing * 2),
                _buildAnimatedTitle(),
                const SizedBox(height: 16),
                _buildAnimatedTagline(),
              ],
            ),
            Column(
              children: [
                SizedBox(height: sectionSpacing * 0.2),
                _buildTrustIndicators(),
                SizedBox(height: sectionSpacing * 0.8),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Column(
                children: [
                  _buildGetStartedButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the animated logo component.
  Widget _buildAnimatedLogo() {
    return AnimatedLogo(
      fadeAnimation: _fadeAnimation,
      scaleAnimation: _scaleAnimation,
      pulseAnimation: _pulseAnimation,
    );
  }

  /// Builds the animated title component.
  Widget _buildAnimatedTitle() {
    return AnimatedTitle(
      fadeAnimation: _fadeAnimation,
    );
  }

  /// Builds the animated tagline component.
  Widget _buildAnimatedTagline() {
    return AnimatedTagline(
      fadeAnimation: _fadeAnimation,
    );
  }

  /// Builds the trust indicators component.
  Widget _buildTrustIndicators() {
    return TrustIndicators(
      fadeAnimation: _fadeAnimation,
    );
  }

  /// Builds the get started button component.
  Widget _buildGetStartedButton() {
    return GetStartedButton(
      fadeAnimation: _fadeAnimation,
    );
  }
}
