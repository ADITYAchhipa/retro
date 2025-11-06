import 'package:flutter/material.dart';
import '../theme/enterprise_dark_theme.dart';
import '../theme/enterprise_light_theme.dart';

/// Neo3DText renders a premium embossed/raised 3D text effect
/// inspired by the neumorphic language in this app.
///
/// It fills text with the current theme's accent color and applies
/// paired highlight and shadow to simulate depth. The effect is
/// subtle in dark mode per product preference.
class Neo3DText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final double depth; // pixel offset for highlight/shadow
  final double blur;  // blur radius for highlight/shadow
  final double letterSpacing;

  const Neo3DText(
    this.text, {
    super.key,
    this.fontSize = 28,
    this.fontWeight = FontWeight.w800,
    this.depth = 1.8,
    this.blur = 3.5,
    this.letterSpacing = -0.2,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = isDark
        ? EnterpriseDarkTheme.primaryAccent
        : EnterpriseLightTheme.primaryAccent;

    // Subtle highlight/shadow tuned for calmer dark mode
    final Color shadowColor = isDark
        ? Colors.black.withOpacity(0.50)
        : Colors.black.withOpacity(0.14);
    final Color highlightColor = isDark
        ? Colors.white.withOpacity(0.14)
        : Colors.white.withOpacity(0.95);

    // Bottom-right soft extrude layer for added depth (very subtle)
    final Widget extrude = Transform.translate(
      offset: Offset(depth, depth),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: shadowColor,
        ),
      ),
    );

    // Main filled text with paired highlight/shadow for beveled feel
    final Widget filled = Text(
      text,
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: accent,
        shadows: [
          Shadow(offset: Offset(depth, depth), blurRadius: blur * 1.6, color: shadowColor),
          Shadow(offset: Offset(-depth, -depth), blurRadius: blur * 1.4, color: highlightColor),
        ],
      ),
    );

    return Semantics(
      header: true,
      label: text,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          extrude,
          filled,
        ],
      ),
    );
  }
}
