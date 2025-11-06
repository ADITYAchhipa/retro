import 'dart:ui';
import 'package:flutter/material.dart';

/// Lightweight Neumorphism + Glass helpers for a luxe, modern UI
/// Inspired by the provided references. No third-party packages required.
///
/// Usage patterns:
/// - NeoDecoration.outer(context, radius: 16) -> a soft raised surface
/// - NeoDecoration.outer(context, pressed: true) -> an "inset" pressed look
/// - NeoGlass(...) -> subtle frosted glass container
class NeoDecoration {
  /// Base background color for a surface depending on theme
  static Color baseColor(BuildContext context, {Color? color}) {
    if (color != null) return color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF111419) : Colors.white;
  }

  /// Paired shadows to create soft depth (top-left highlight, bottom-right shadow)
  static List<BoxShadow> shadows(
    BuildContext context, {
    double distance = 6,
    double blur = 12,
    double spread = 0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // In light theme: bright highlight and soft slate shadow
    // In dark theme: subtle highlight and deep black shadow
    final highlight = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.90);
    final shadow = isDark
        ? Colors.black.withOpacity(0.48)
        : const Color(0xFFA3B1C6).withOpacity(0.70);
    return [
      BoxShadow(
        color: shadow,
        offset: Offset(distance, distance),
        blurRadius: blur,
        spreadRadius: spread,
      ),
      BoxShadow(
        color: highlight,
        offset: Offset(-distance, -distance),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  /// Soft raised surface. If [pressed] is true, flips the light directions to feel inset.
  static BoxDecoration outer(
    BuildContext context, {
    double radius = 12,
    Color? color,
    double distance = 6,
    double blur = 12,
    bool pressed = false,
    Color? borderColor,
    double borderWidth = 1,
    BorderStyle borderStyle = BorderStyle.solid,
    double spread = 0,
    List<BoxShadow>? extraShadows,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = baseColor(context, color: color);

    final highlight = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.white.withOpacity(0.85);
    final shadow = isDark
        ? Colors.black.withOpacity(0.45)
        : const Color(0xFFA3B1C6).withOpacity(0.75);

    // Scale down spread globally and clamp to prevent heavy halos, esp. on white.
    // Make it more subtle across the board.
    double scaledSpread = spread <= 0 ? 0 : spread * (isDark ? 0.30 : 0.25);
    // Clamp the maximum effective spread even tighter
    scaledSpread = scaledSpread.clamp(0.0, isDark ? 0.25 : 0.25);

    final List<BoxShadow> pair = pressed
        ? [
            // Flip directions for a "pressed/concave" feel
            BoxShadow(
              color: highlight,
              offset: Offset(distance, distance),
              blurRadius: blur,
              spreadRadius: scaledSpread,
            ),
            BoxShadow(
              color: shadow,
              offset: Offset(-distance, -distance),
              blurRadius: blur,
              spreadRadius: scaledSpread,
            ),
          ]
        : shadows(context, distance: distance, blur: blur, spread: scaledSpread);

    final List<BoxShadow> allShadows = [
      ...pair,
      if (extraShadows != null) ...extraShadows,
    ];

    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: allShadows,
      border: borderColor != null
          ? Border.all(color: borderColor, width: borderWidth, style: borderStyle)
          : null,
    );
  }
}

/// Raised circular icon button with Neo decoration
class NeoIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size; // outer container size
  final double? iconSize; // inner icon size
  final Color? iconColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final String? tooltip;
  final Color? borderColor;
  final double? spread; // optional shadow spread override
  final Color? backgroundColor; // optional fill color
  final bool active; // shows a subtle premium halo when true
  final Color? accentColor; // optional custom halo color

  const NeoIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 32,
    this.iconSize,
    this.iconColor,
    this.margin,
    this.padding,
    this.tooltip,
    this.borderColor,
    this.spread,
    this.backgroundColor,
    this.active = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = borderColor ?? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08));
    final accent = accentColor ?? Theme.of(context).colorScheme.primary;
    final List<BoxShadow>? halo = active
        ? [
            BoxShadow(
              color: accent.withOpacity(isDark ? 0.16 : 0.10),
              blurRadius: isDark ? 9 : 7,
              spreadRadius: isDark ? 0.4 : 0.6,
              offset: const Offset(0, 2),
            ),
          ]
        : null;
    final child = Container(
      margin: margin,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: NeoDecoration.outer(
        context,
        radius: size / 2,
        distance: isDark ? 4 : 6,
        blur: isDark ? 9 : 12,
        color: backgroundColor,
        borderColor: border,
        borderWidth: 1,
        spread: spread ?? (isDark ? 0.3 : 0.7),
        extraShadows: halo,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Icon(
          icon,
          size: iconSize ?? (size * 0.58),
          color: iconColor ?? (isDark ? Colors.white : Colors.black87),
        ),
      ),
    );

    final button = GestureDetector(onTap: onTap, child: child);
    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Simple frosted glass container for callouts/banners.
class NeoGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final double blur;
  final Color? backgroundColor; // color behind the blur
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  // When set to 0, the border is omitted entirely to avoid hairline seams
  final double borderWidth;

  const NeoGlass({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.blur = 12,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.65));
    final border = borderColor ??
        (isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.8));
    
    // Fast path without blur to avoid anti-aliased seams on curved edges.
    if (blur <= 0) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          boxShadow: boxShadow,
          borderRadius: borderRadius,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: borderRadius,
            border: borderWidth <= 0
                ? null
                : Border.all(color: border, width: borderWidth),
          ),
          child: child,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: boxShadow,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.hardEdge,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: borderRadius,
              border: borderWidth <= 0
                  ? null
                  : Border.all(color: border, width: borderWidth),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
