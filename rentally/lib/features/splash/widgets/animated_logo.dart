import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/splash_constants.dart';

/// An enhanced animated logo widget with multiple sophisticated animations.
/// 
/// This widget creates a premium logo display with:
/// - Fade-in animation for smooth appearance
/// - Scale animation with elastic effect
/// - Continuous pulse animation for visual appeal
/// - Rotating shimmer effect
/// - Professional gradient background with enhanced shadows
/// - Glassmorphism effect
/// - Error handling with fallback icon
class AnimatedLogo extends StatefulWidget {
  /// Animation for fading in the logo container
  final Animation<double> fadeAnimation;
  
  /// Animation for scaling the logo container
  final Animation<double> scaleAnimation;
  
  /// Animation for pulsing the logo icon
  final Animation<double> pulseAnimation;

  /// Creates an animated logo widget.
  /// 
  /// All animation parameters are required to ensure proper
  /// synchronization with the parent animation controllers.
  const AnimatedLogo({
    super.key,
    required this.fadeAnimation,
    required this.scaleAnimation,
    required this.pulseAnimation,
  });
  
  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  
  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000), // Smoother shimmer animation
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut, // Smoother curve
    ));
    
    // Single shimmer animation for smoothness
    _shimmerController.forward();
  }
  
  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: ScaleTransition(
        scale: widget.scaleAnimation,
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return _buildEnhancedLogoContainer();
          },
        ),
      ),
    );
  }

  /// Builds the enhanced logo container with glassmorphism and shimmer effects.
  Widget _buildEnhancedLogoContainer() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow rings removed for a flatter look
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        // Main logo container with glassmorphism
        Container(
          padding: const EdgeInsets.all(SplashConstants.logoContainerPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.1),
                SplashColors.logoGradientStart.withValues(alpha: 0.3),
                SplashColors.logoGradientMiddle.withValues(alpha: 0.2),
                SplashColors.logoGradientEnd.withValues(alpha: 0.1),
              ],
              stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: const [],
          ),
          child: _buildPulsingLogo(),
        ),
      ],
    );
  }

  /// Builds the pulsing logo icon with enhanced effects.
  Widget _buildPulsingLogo() {
    return ScaleTransition(
      scale: widget.pulseAnimation,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/icons/app_icon.png',
            width: SplashConstants.logoSize,
            height: SplashConstants.logoSize,
            fit: BoxFit.cover,
            errorBuilder: _buildFallbackIcon,
          ),
        ),
      ),
    );
  }

  /// Builds an enhanced fallback icon when the main logo fails to load.
  Widget _buildFallbackIcon(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      width: SplashConstants.logoSize,
      height: SplashConstants.logoSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SplashColors.primary,
            SplashColors.primaryDark,
          ],
        ),
      ),
      child: const Icon(
        Icons.home_work_rounded,
        size: SplashConstants.logoSize * 0.6,
        color: Colors.white,
      ),
    );
  }
}
