import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Performance manager to optimize app performance and reduce lag
class PerformanceManager {
  static final PerformanceManager _instance = PerformanceManager._internal();
  factory PerformanceManager() => _instance;
  PerformanceManager._internal();

  // Animation optimization settings
  static const Duration _reducedAnimationDuration = Duration(milliseconds: 200);
  static const Duration _fastAnimationDuration = Duration(milliseconds: 100);
  
  // Performance flags
  bool _isLowPerformanceMode = false;
  bool _reduceAnimations = false;
  
  /// Initialize performance optimizations
  void initialize() {
    // Detect device performance capabilities
    _detectPerformanceCapabilities();
    
    // Set animation scale based on device performance
    _optimizeAnimationScale();
  }
  
  /// Detect if device has limited performance capabilities
  void _detectPerformanceCapabilities() {
    // Simple heuristic: if frame rate drops below 45fps, enable low performance mode
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // This is a simplified check - in production you'd use more sophisticated metrics
      _isLowPerformanceMode = false; // Default to false for now
    });
  }
  
  /// Optimize animation scale for performance
  void _optimizeAnimationScale() {
    if (_isLowPerformanceMode) {
      _reduceAnimations = true;
    }
  }
  
  /// Get optimized animation duration
  Duration getAnimationDuration(Duration original) {
    if (_reduceAnimations) {
      return _fastAnimationDuration;
    }
    return original.inMilliseconds > 300 
        ? _reducedAnimationDuration 
        : original;
  }
  
  /// Check if animations should be reduced
  bool get shouldReduceAnimations => _reduceAnimations;
  
  /// Get optimized curve for animations
  Curve getOptimizedCurve(Curve original) {
    if (_reduceAnimations) {
      return Curves.linear; // Fastest curve
    }
    return original;
  }
  
  /// Optimize widget for performance
  Widget optimizeWidget(Widget child) {
    if (_isLowPerformanceMode) {
      return RepaintBoundary(child: child);
    }
    return child;
  }
  
  /// Create performance-optimized animation controller
  AnimationController createOptimizedController({
    required Duration duration,
    required TickerProvider vsync,
    String? debugLabel,
  }) {
    return AnimationController(
      duration: getAnimationDuration(duration),
      vsync: vsync,
      debugLabel: debugLabel,
    );
  }
}

/// Mixin to add performance optimizations to StatefulWidgets
mixin PerformanceOptimizedState<T extends StatefulWidget> on State<T> {
  final PerformanceManager _performanceManager = PerformanceManager();
  
  /// Create optimized animation controller
  /// Note: This requires the State to also use TickerProviderStateMixin
  AnimationController createOptimizedController({
    required Duration duration,
    required TickerProvider vsync,
    String? debugLabel,
  }) {
    return _performanceManager.createOptimizedController(
      duration: duration,
      vsync: vsync,
      debugLabel: debugLabel,
    );
  }
  
  /// Get optimized animation duration
  Duration getOptimizedDuration(Duration duration) {
    return _performanceManager.getAnimationDuration(duration);
  }
  
  /// Get optimized curve
  Curve getOptimizedCurve(Curve curve) {
    return _performanceManager.getOptimizedCurve(curve);
  }
}

/// Widget wrapper for performance optimization
class PerformanceOptimizedWidget extends StatelessWidget {
  final Widget child;
  final bool enableRepaintBoundary;
  final bool enableAutomaticKeepAlive;
  
  const PerformanceOptimizedWidget({
    super.key,
    required this.child,
    this.enableRepaintBoundary = true,
    this.enableAutomaticKeepAlive = false,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget optimizedChild = child;
    
    if (enableRepaintBoundary) {
      optimizedChild = RepaintBoundary(child: optimizedChild);
    }
    
    if (enableAutomaticKeepAlive) {
      optimizedChild = AutomaticKeepAlive(child: optimizedChild);
    }
    
    return optimizedChild;
  }
}

/// Optimized list view for better performance
class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  
  const OptimizedListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          key: ValueKey(index),
          child: children[index],
        );
      },
    );
  }
}

