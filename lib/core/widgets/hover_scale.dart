import 'package:flutter/material.dart';

/// Widget that scales on hover/touch for interactive feedback
class HoverScale extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final Curve curve;
  final bool enableOnTouch;

  const HoverScale({
    super.key,
    required this.child,
    this.scale = 1.05,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
    this.enableOnTouch = false,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isScaled = _isHovered || _isPressed;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.enableOnTouch ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.enableOnTouch ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.enableOnTouch ? () => setState(() => _isPressed = false) : null,
        child: AnimatedScale(
          scale: isScaled ? widget.scale : 1.0,
          duration: widget.duration,
          curve: widget.curve,
          child: widget.child,
        ),
      ),
    );
  }
}
