import 'package:flutter/material.dart';

/// Simple reusable hover/touch scale effect wrapper
class HoverScale extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final Curve curve;
  // If true, also adds a small press scale on touch devices
  final bool enableOnTouch;

  const HoverScale({
    super.key,
    required this.child,
    this.scale = 1.015,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOutQuint,
    this.enableOnTouch = false,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHovered(bool v) {
    setState(() => _hovered = v);
  }

  void _setPressed(bool v) {
    if (!widget.enableOnTouch) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final bool active = _hovered || _pressed;
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: widget.enableOnTouch ? (_) => _setPressed(true) : null,
        onTapCancel: widget.enableOnTouch ? () => _setPressed(false) : null,
        onTapUp: widget.enableOnTouch ? (_) => _setPressed(false) : null,
        child: AnimatedScale(
          scale: active ? widget.scale : 1.0,
          duration: widget.duration,
          curve: widget.curve,
          child: widget.child,
        ),
      ),
    );
  }
}
