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
            theme.colorScheme.surface,
            theme.colorScheme.surface.withValues(alpha: 0.95),
            theme.colorScheme.surface,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      );
    }

    // Light theme: bright white background
    return const BoxDecoration(
      color: Colors.white,
    );
  }
}
