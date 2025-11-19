import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Loading state types
enum LoadingType {
  initial,
  refresh,
  loadMore,
  submit,
  upload,
  download,
  search,
  custom,
}

// Loading state class
class LoadingState {
  final bool isLoading;
  final LoadingType type;
  final String? message;
  final double? progress;
  final String? identifier;

  const LoadingState({
    this.isLoading = false,
    this.type = LoadingType.initial,
    this.message,
    this.progress,
    this.identifier,
  });

  LoadingState copyWith({
    bool? isLoading,
    LoadingType? type,
    String? message,
    double? progress,
    String? identifier,
  }) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      type: type ?? this.type,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      identifier: identifier ?? this.identifier,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoadingState &&
        other.isLoading == isLoading &&
        other.type == type &&
        other.message == message &&
        other.progress == progress &&
        other.identifier == identifier;
  }

  @override
  int get hashCode {
    return isLoading.hashCode ^
        type.hashCode ^
        message.hashCode ^
        progress.hashCode ^
        identifier.hashCode;
  }
}

// Loading service for managing loading states
class LoadingService extends StateNotifier<Map<String, LoadingState>> {
  LoadingService() : super({});

  // Start loading with optional message and progress
  void startLoading({
    required String key,
    LoadingType type = LoadingType.initial,
    String? message,
    double? progress,
  }) {
    state = {
      ...state,
      key: LoadingState(
        isLoading: true,
        type: type,
        message: message,
        progress: progress,
        identifier: key,
      ),
    };
  }

  // Update loading progress
  void updateProgress({
    required String key,
    required double progress,
    String? message,
  }) {
    final currentState = state[key];
    if (currentState != null && currentState.isLoading) {
      state = {
        ...state,
        key: currentState.copyWith(
          progress: progress,
          message: message,
        ),
      };
    }
  }

  // Update loading message
  void updateMessage({
    required String key,
    required String message,
  }) {
    final currentState = state[key];
    if (currentState != null && currentState.isLoading) {
      state = {
        ...state,
        key: currentState.copyWith(message: message),
      };
    }
  }

  // Stop loading
  void stopLoading(String key) {
    final newState = Map<String, LoadingState>.from(state);
    newState.remove(key);
    state = newState;
  }

  // Check if specific key is loading
  bool isLoading(String key) {
    return state[key]?.isLoading ?? false;
  }

  // Get loading state for specific key
  LoadingState? getLoadingState(String key) {
    return state[key];
  }

  // Check if any loading is active
  bool get hasAnyLoading {
    return state.values.any((loading) => loading.isLoading);
  }

  // Get all active loading states
  List<LoadingState> get activeLoadingStates {
    return state.values.where((loading) => loading.isLoading).toList();
  }

  // Clear all loading states
  void clearAll() {
    state = {};
  }
}

// Providers
final loadingServiceProvider = StateNotifierProvider<LoadingService, Map<String, LoadingState>>((ref) {
  return LoadingService();
});

// Specific loading providers for common operations
final authLoadingProvider = Provider<bool>((ref) {
  final loadingStates = ref.watch(loadingServiceProvider);
  return loadingStates['auth']?.isLoading ?? false;
});

final searchLoadingProvider = Provider<bool>((ref) {
  final loadingStates = ref.watch(loadingServiceProvider);
  return loadingStates['search']?.isLoading ?? false;
});

final bookingLoadingProvider = Provider<bool>((ref) {
  final loadingStates = ref.watch(loadingServiceProvider);
  return loadingStates['booking']?.isLoading ?? false;
});

final uploadLoadingProvider = Provider<LoadingState?>((ref) {
  final loadingStates = ref.watch(loadingServiceProvider);
  return loadingStates['upload'];
});

// Loading overlay widget
class LoadingOverlay extends ConsumerWidget {
  final Widget child;
  final String? loadingKey;
  final bool showOverlay;

  const LoadingOverlay({
    super.key,
    required this.child,
    this.loadingKey,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingStates = ref.watch(loadingServiceProvider);
    final isLoading = loadingKey != null 
        ? (loadingStates[loadingKey]?.isLoading ?? false)
        : loadingStates.values.any((state) => state.isLoading);

    return Stack(
      children: [
        child,
        if (isLoading && showOverlay)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Custom loading indicator widget
class CustomLoadingIndicator extends ConsumerWidget {
  final String loadingKey;
  final Widget? child;
  final bool showMessage;
  final bool showProgress;

  const CustomLoadingIndicator({
    super.key,
    required this.loadingKey,
    this.child,
    this.showMessage = true,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingState = ref.watch(loadingServiceProvider)[loadingKey];
    
    if (loadingState == null || !loadingState.isLoading) {
      return child ?? const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showProgress && loadingState.progress != null)
          LinearProgressIndicator(value: loadingState.progress)
        else
          const CircularProgressIndicator(),
        if (showMessage && loadingState.message != null) ...[
          const SizedBox(height: 8),
          Text(
            loadingState.message!,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// Loading button widget
class LoadingButton extends ConsumerWidget {
  final String loadingKey;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const LoadingButton({
    super.key,
    required this.loadingKey,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(loadingServiceProvider)[loadingKey]?.isLoading ?? false;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : child,
    );
  }
}

// Loading list tile widget
class LoadingListTile extends ConsumerWidget {
  final String loadingKey;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;

  const LoadingListTile({
    super.key,
    required this.loadingKey,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(loadingServiceProvider)[loadingKey]?.isLoading ?? false;

    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: isLoading ? null : onTap,
    );
  }
}

// Shimmer loading effect widget
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? theme.colorScheme.surface;
    final highlightColor = widget.highlightColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.1);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// Extension for easy loading management
extension LoadingExtension on WidgetRef {
  void startLoading(String key, {LoadingType type = LoadingType.initial, String? message}) {
    read(loadingServiceProvider.notifier).startLoading(
      key: key,
      type: type,
      message: message,
    );
  }

  void stopLoading(String key) {
    read(loadingServiceProvider.notifier).stopLoading(key);
  }

  void updateProgress(String key, double progress, {String? message}) {
    read(loadingServiceProvider.notifier).updateProgress(
      key: key,
      progress: progress,
      message: message,
    );
  }

  bool isLoading(String key) {
    return read(loadingServiceProvider.notifier).isLoading(key);
  }
}
