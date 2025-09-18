import 'package:flutter/material.dart';

/// A professional static background widget with clean gradient design.
/// 
/// This widget provides:
/// - Static professional gradient background
/// - Clean, modern color scheme
/// - Optimized performance without animations
/// - Consistent styling for professional appearance
class SplashBackground extends StatelessWidget {
  /// The child widget to display over the background
  final Widget child;

  /// Creates a splash background widget.
  const SplashBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _buildBackgroundDecoration(context),
      child: child,
    );
  }

  /// Builds the professional static background decoration.
  BoxDecoration _buildBackgroundDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isDark) {
      // Calmer, low-contrast dark gradient aligned with app dark theme
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.background,
            theme.colorScheme.surface.withOpacity(0.95),
            theme.colorScheme.background,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      );
    }

    return const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0.0, -0.3), // Slightly above center
        radius: 1.2,
        colors: [
          Color(0xFFFFFFFF), // Pure white at center
          Color(0xFFF8FAFC), // Very light gray-blue
          Color(0xFFF1F5F9), // Light slate
          Color(0xFFE2E8F0), // Professional gray
          Color(0xFFCBD5E1), // Subtle darker gray
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ),
    );
  }
}
