import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kReleaseMode, FlutterExceptionHandler, FlutterErrorDetails;
import '../../utils/snackbar_utils.dart';

/// A comprehensive error boundary widget that catches and handles errors gracefully
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? fallbackTitle;
  final String? fallbackMessage;
  final VoidCallback? onRetry;
  final bool showRetryButton;
  final bool reportErrors;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackTitle,
    this.fallbackMessage,
    this.onRetry,
    this.showRetryButton = true,
    this.reportErrors = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  bool _hasError = false;
  FlutterExceptionHandler? _previousOnError;
  bool _handlingError = false;

  @override
  void initState() {
    super.initState();
    // Preserve any previous handler
    _previousOnError = FlutterError.onError;
    // Set up guarded global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (widget.reportErrors) {
        debugPrint('Error caught by ErrorBoundary: ${details.exception}');
      }
      // Forward to previously registered handler
      try { _previousOnError?.call(details); } catch (_) {}

      // In debug/profile, log only and do not flip to fallback UI
      if (!kReleaseMode) {
        return;
      }

      if (_handlingError) return;
      _handlingError = true;

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) { _handlingError = false; return; }
          setState(() {
            _error = details.exception;
            _hasError = true;
          });
          _handlingError = false;
        });
      } else {
        _handlingError = false;
      }
    };
  }

  void _retry() {
    setState(() {
      _error = null;
      _hasError = false;
    });
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget(context);
    }

    return widget.child;
  }

  Widget _buildErrorWidget(BuildContext context) {
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                widget.fallbackTitle ?? 'Something went wrong',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.fallbackMessage ?? 
                'We encountered an unexpected error. Please try again.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (widget.showRetryButton) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextButton.icon(
                onPressed: () {
                  final errorText = _error.toString();
                  Clipboard.setData(ClipboardData(text: errorText));
                  SnackBarUtils.showInfo(context, 'Error details copied to clipboard');
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Error Details'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that wraps async operations with error handling
class AsyncErrorBoundary extends StatefulWidget {
  final Future<Widget> Function() builder;
  final Widget? loadingWidget;
  final Widget Function(Object error)? errorBuilder;
  final VoidCallback? onRetry;

  const AsyncErrorBoundary({
    super.key,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.onRetry,
  });

  @override
  State<AsyncErrorBoundary> createState() => _AsyncErrorBoundaryState();
}

class _AsyncErrorBoundaryState extends State<AsyncErrorBoundary> {
  late Future<Widget> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.builder();
  }

  void _retry() {
    setState(() {
      _future = widget.builder();
    });
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget ?? 
            const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          if (widget.errorBuilder != null) {
            return widget.errorBuilder!(snapshot.error!);
          }
          
          return ErrorBoundary(
            onRetry: _retry,
            child: Container(),
          );
        }

        return snapshot.data ?? Container();
      },
    );
  }
}

/// Network error boundary for handling connectivity issues
class NetworkErrorBoundary extends StatelessWidget {
  final Widget child;
  final bool isConnected;
  final VoidCallback? onRetry;

  const NetworkErrorBoundary({
    super.key,
    required this.child,
    required this.isConnected,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!isConnected) {
      return _buildNoConnectionWidget(context);
    }
    return child;
  }

  Widget _buildNoConnectionWidget(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'No Internet Connection',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please check your internet connection and try again.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (onRetry != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
