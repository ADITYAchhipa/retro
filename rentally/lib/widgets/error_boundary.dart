import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show FlutterExceptionHandler, FlutterErrorDetails, kReleaseMode;
import '../utils/snackbar_utils.dart';

/// A widget that catches and handles errors in its child widget tree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final void Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  FlutterErrorDetails? _errorDetails;
  FlutterExceptionHandler? _previousOnError;
  bool _handlingError = false;

  @override
  void initState() {
    super.initState();
    // Preserve any previously set global error handler
    _previousOnError = FlutterError.onError;

    // Install a guarded global error handler that ignores benign debug-time layout errors
    FlutterError.onError = (details) {
      // Forward to any previously registered handler for logging/diagnostics
      try {
        _previousOnError?.call(details);
      } catch (_) {}

      final msg = details.exceptionAsString();
      final isBenignFrameworkIssue = msg.contains('RenderFlex overflowed') ||
          msg.contains('Floating SnackBar presented off screen') ||
          msg.contains('A RenderFlex overflowed') ||
          msg.contains('Vertical viewport was given unbounded height');

      // In debug/profile builds: never flip to fallback (log only). This avoids user-facing
      // fallback UI due to framework assertions while developing.
      if (!kReleaseMode) {
        if (isBenignFrameworkIssue) {
          debugPrint('[ErrorBoundary] Ignored benign framework error in debug: $msg');
        } else {
          debugPrint('[ErrorBoundary] Captured error (debug): $msg');
        }
        return; // Do not change UI in non-release builds
      }

      // Prevent re-entrancy
      if (_handlingError) return;
      _handlingError = true;

      // Defer UI state change to the next frame to avoid scheduling builds during layout/paint
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _hasError = true;
            _errorDetails = details;
          });
          _handlingError = false;
        });
      } else {
        _handlingError = false;
      }

      // Notify external error callback (does not mutate widget state)
      try {
        widget.onError?.call(details);
      } catch (_) {}
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _DefaultErrorWidget(error: _errorDetails);
    }
    return widget.child;
  }

  void reset() {
    if (mounted) {
      setState(() {
        _hasError = false;
        _errorDetails = null;
      });
    }
  }

  @override
  void dispose() {
    // Restore the previously registered global error handler to avoid side effects
    FlutterError.onError = _previousOnError;
    super.dispose();
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final FlutterErrorDetails? error;

  const _DefaultErrorWidget({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We apologize for the inconvenience. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final popped = await Navigator.of(context).maybePop();
                  if (!popped && context.mounted) {
                    SnackBarUtils.showInfo(context, 'No previous page to go back to');
                  }
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
