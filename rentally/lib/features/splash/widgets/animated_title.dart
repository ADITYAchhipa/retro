import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/splash_constants.dart';

/// An enhanced animated title widget with sophisticated typography effects.
/// 
/// This widget provides:
/// - Smooth fade-in animation
/// - Character-by-character reveal animation
/// - Professional typography with enhanced shadows
/// - Gradient text effect
/// - Consistent styling using design system constants
class AnimatedTitle extends StatefulWidget {
  /// Animation for fading in the title
  final Animation<double> fadeAnimation;

  /// Creates an animated title widget.
  const AnimatedTitle({
    super.key,
    required this.fadeAnimation,
  });
  
  @override
  State<AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<AnimatedTitle>
    with TickerProviderStateMixin {
  late AnimationController _typewriterController;
  late Animation<int> _typewriterAnimation;
  
  @override
  void initState() {
    super.initState();
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 600), // Faster for better performance
      vsync: this,
    );
    
    _typewriterAnimation = IntTween(
      begin: 0,
      end: SplashTexts.appTitle.length,
    ).animate(CurvedAnimation(
      parent: _typewriterController,
      curve: Curves.linear, // Simpler curve for performance
    ));
    
    // Start typewriter effect after fade animation begins
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _typewriterController.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _typewriterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: AnimatedBuilder(
        animation: _typewriterAnimation,
        builder: (context, child) {
          return _buildEnhancedTitle();
        },
      ),
    );
  }

  /// Builds the enhanced title with gradient and typewriter effects.
  Widget _buildEnhancedTitle() {
    final displayText = SplashTexts.appTitle.substring(0, _typewriterAnimation.value);
    
    return SizedBox(
      height: _getResponsiveTitleHeight(),
      width: double.infinity,
      child: CustomPaint(
        painter: _TitlePainter(
          text: displayText,
          textStyle: _buildTitleStyle(),
          showCursor: _typewriterAnimation.value < SplashTexts.appTitle.length,
          cursorOpacity: _typewriterAnimation.value < SplashTexts.appTitle.length 
              ? (math.sin(_typewriterController.value * math.pi * 4) + 1) / 2 
              : 0.0,
        ),
      ),
    );
  }
  
  /// Builds the main title text style with responsive sizing.
  TextStyle _buildTitleStyle() {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 400;
    
    // Industrial-grade professional font sizes with better hierarchy
    final fontSize = isTablet ? 36.0 : (isSmallScreen ? 28.0 : 32.0);
    final letterSpacing = isTablet ? -0.8 : (isSmallScreen ? -0.4 : -0.6);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: isDark ? theme.colorScheme.onSurface : const Color(0xFF1a237e),
      letterSpacing: letterSpacing,
      height: 1.0, // Normal line height for custom painter
      textBaseline: TextBaseline.alphabetic,
    );
  }
  
  /// Gets responsive title container height to prevent cutoff.
  double _getResponsiveTitleHeight() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 400;
    
    // Minimal height to eliminate gap while preserving text visibility
    return isTablet ? 50.0 : (isSmallScreen ? 40.0 : 45.0);
  }
}

/// Custom painter that renders text with full control over positioning
class _TitlePainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;
  final bool showCursor;
  final double cursorOpacity;

  _TitlePainter({
    required this.text,
    required this.textStyle,
    required this.showCursor,
    required this.cursorOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty) return;

    // Create text painter with generous height allowance
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Layout with unconstrained height to prevent clipping
    textPainter.layout(minWidth: 0, maxWidth: size.width);

    // Calculate position to center the text, accounting for descenders
    final textHeight = textPainter.height;
    final textWidth = textPainter.width;
    
    // Position text in center with extra space for descenders
    final xOffset = (size.width - textWidth) / 2;
    final yOffset = (size.height - textHeight) / 2 - 10; // Extra space above

    // Paint the text using the provided style (theme-aware)
    textPainter.paint(canvas, Offset(xOffset, yOffset));

    // Draw cursor if needed
    if (showCursor && cursorOpacity > 0) {
      final cursorPaint = Paint()
        ..color = const Color(0xFF1E40AF).withOpacity(cursorOpacity)
        ..strokeWidth = 3;
      
      final cursorX = xOffset + textWidth + 2;
      final cursorY = yOffset + (textHeight * 0.2); // Position cursor properly
      final cursorHeight = textHeight * 0.6;
      
      canvas.drawLine(
        Offset(cursorX, cursorY),
        Offset(cursorX, cursorY + cursorHeight),
        cursorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TitlePainter oldDelegate) {
    return oldDelegate.text != text ||
           oldDelegate.showCursor != showCursor ||
           oldDelegate.cursorOpacity != cursorOpacity;
  }
}
