import 'package:flutter/material.dart';
import '../constants/splash_constants.dart';

/// An enhanced animated tagline widget with slide and fade effects.
/// 
/// This widget provides:
/// - Smooth fade-in animation
/// - Slide-up animation for dynamic entrance
/// - Professional typography with enhanced shadows
/// - Gradient text effect
/// - Consistent styling using design system constants
/// - Responsive text layout
class AnimatedTagline extends StatefulWidget {
  /// Animation for fading in the tagline
  final Animation<double> fadeAnimation;

  /// Creates an animated tagline widget.
  const AnimatedTagline({
    super.key,
    required this.fadeAnimation,
  });
  
  @override
  State<AnimatedTagline> createState() => _AnimatedTaglineState();
}

class _AnimatedTaglineState extends State<AnimatedTagline>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    // Start slide animation after title animation
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SplashConstants.taglineHorizontalPadding,
          ),
          child: _buildEnhancedTagline(),
        ),
      ),
    );
  }

  /// Builds the enhanced tagline with clean, readable text.
  Widget _buildEnhancedTagline() {
    return Text(
      SplashTexts.tagline,
      textAlign: TextAlign.center,
      style: _buildTaglineStyle(),
    );
  }
  
  /// Builds the main tagline text style with responsive sizing.
  TextStyle _buildTaglineStyle() {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 400;
    
    // Professional enterprise tagline sizing
    final fontSize = isTablet ? 16.0 : (isSmallScreen ? 14.0 : 15.0);
    final letterSpacing = isTablet ? 0.5 : (isSmallScreen ? 0.3 : 0.4);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: isDark 
          ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
          : const Color(0xFF1E293B),
      letterSpacing: letterSpacing,
      height: 1.4,
    );
  }
  
}
