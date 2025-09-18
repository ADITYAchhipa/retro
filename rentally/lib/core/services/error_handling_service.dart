import 'package:flutter/foundation.dart';

/// Lightweight core error handling shim used by unit tests.
/// This is intentionally minimal and independent from the app-level
/// error handling service in `lib/services/error_handling_service.dart`.
class ErrorHandlingService {
  /// No-op initializer to satisfy tests.
  void initialize() {}

  /// Logs an error message with optional context and stack trace.
  void logError(String message, StackTrace stackTrace, [String? context]) {
    debugPrint('CORE ErrorHandlingService: $message');
    if (context != null && context.isNotEmpty) {
      debugPrint('Context: $context');
    }
    debugPrint('StackTrace: $stackTrace');
  }

  /// Executes an async action and captures any error, returning null on failure.
  Future<T?> handleAsync<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, st) {
      logError(e.toString(), st, 'handleAsync');
      return null;
    }
  }
}
