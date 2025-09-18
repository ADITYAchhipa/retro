import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/auth_router.dart';

/// An enhanced animated "Get Started" button with modern styling and effects.
/// 
/// This widget provides:
/// - Smooth fade-in animation
/// - Scale and bounce animations on hover/press
/// - Professional gradient styling with enhanced shadows
/// - Glassmorphism effect
/// - Shimmer animation
/// - Responsive width constraints
/// - Navigation to onboarding screen
/// - Icon and text layout with proper spacing
class GetStartedButton extends StatefulWidget {
  /// Animation for fading in the button
  final Animation<double> fadeAnimation;

  /// Creates a get started button widget.
  const GetStartedButton({
    super.key,
    required this.fadeAnimation,
  });
  
  @override
  State<GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<GetStartedButton>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _scaleController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Smoother shimmer
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200), // Smoother scale response
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97, // Gentler scale effect
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic, // Smoother curve
    ));
    
    // Disable continuous shimmer for better performance
    // _shimmerController.repeat();
  }
  
  @override
  void dispose() {
    _shimmerController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400.0),
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : 20.0,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_shimmerAnimation, _scaleAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: _buildEnhancedButton(context),
            );
          },
        ),
      ),
    );
  }

  /// Builds the enhanced button with glassmorphism and shimmer effects.
  Widget _buildEnhancedButton(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
        _handleButtonPress(context);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      child: Container(
        decoration: _buildButtonDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Stack(
            children: [
              // Main button content
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                ),
                child: _buildButtonContent(),
              ),
              // Shimmer overlay
              _buildShimmerOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles the button press and navigates to onboarding.
  void _handleButtonPress(BuildContext context) {
    if (context.mounted) {
      context.go(Routes.onboarding);
    }
  }

  /// Builds the enhanced button decoration with glassmorphism.
  BoxDecoration _buildButtonDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3B82F6), // Lighter blue
          Color(0xFF2563EB), // Medium blue
          Color(0xFF1E40AF), // Navy blue from theme
        ],
        stops: [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(12.0),
      border: Border.all(
        color: const Color(0xFF3B82F6).withOpacity(0.3),
        width: 1,
      ),
      boxShadow: [
        // Primary shadow
        BoxShadow(
          color: const Color(0xFF1E40AF).withOpacity(0.4), // Navy blue shadow
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 2,
        ),
        // Inner glow
        BoxShadow(
          color: const Color(0xFF60A5FA).withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, -2),
          spreadRadius: -5,
        ),
        // Depth shadow
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  /// Builds the shimmer overlay effect.
  Widget _buildShimmerOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(_shimmerAnimation.value - 1, 0),
            end: Alignment(_shimmerAnimation.value, 0),
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.2),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  /// Builds the enhanced button content with animated icon and text.
  Widget _buildButtonContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400), // Smoother icon animation
          transform: Matrix4.translationValues(
            _isPressed ? 2 : 0,
            0,
            0,
          ),
          child: Icon(
            Icons.rocket_launch_rounded,
            size: _getResponsiveIconSize(),
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12.0),
        Text(
          'Get Started',
          style: _buildButtonTextStyle(),
        ),
      ],
    );
  }

  /// Builds the button text style with professional mobile sizing.
  TextStyle _buildButtonTextStyle() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 400;
    
    final fontSize = isTablet ? 15.0 : (isSmallScreen ? 14.0 : 14.5);
    final letterSpacing = isTablet ? 0.3 : (isSmallScreen ? 0.25 : 0.3);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: letterSpacing,
      color: Colors.white,
      shadows: const [
        Shadow(
          color: Colors.black38,
          offset: Offset(0, 2),
          blurRadius: 4,
        ),
        Shadow(
          color: Colors.black26,
          offset: Offset(1, 1),
          blurRadius: 2,
        ),
      ],
    );
  }
  
  /// Gets responsive icon size based on screen size.
  double _getResponsiveIconSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 400;
    
    return isTablet ? 18.0 : (isSmallScreen ? 16.0 : 17.0);
  }
}
