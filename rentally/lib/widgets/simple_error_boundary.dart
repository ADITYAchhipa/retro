import 'package:flutter/material.dart';

/// Simple error boundary widget to replace the complex one
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget Function(Object error)? errorBuilder;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });
  
  @override
  Widget build(BuildContext context) {
    return child;
  }
}
