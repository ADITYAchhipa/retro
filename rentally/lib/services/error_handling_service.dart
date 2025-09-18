import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/snackbar_utils.dart';

// Error types enum
enum ErrorType {
  network,
  authentication,
  validation,
  permission,
  notFound,
  serverError,
  unknown,
}

// Error severity levels
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

// Custom error class
class AppError {
  final String code;
  final String message;
  final ErrorType type;
  final ErrorSeverity severity;
  final String? details;
  final DateTime timestamp;
  final StackTrace? stackTrace;

  AppError({
    required this.code,
    required this.message,
    required this.type,
    this.severity = ErrorSeverity.error,
    this.details,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'AppError(code: $code, message: $message, type: $type, severity: $severity)';
  }
}

// Error handling service
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final List<AppError> _errorHistory = [];
  
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);

  // Handle different types of errors
  void handleError(AppError error, BuildContext? context) {
    _logError(error);
    _addToHistory(error);
    
    if (context != null) {
      _showUserFeedback(error, context);
    }
  }

  // Log error for debugging
  void _logError(AppError error) {
    debugPrint('🚨 [${error.severity.name.toUpperCase()}] ${error.type.name}: ${error.message}');
    if (error.details != null) {
      debugPrint('📝 Details: ${error.details}');
    }
    if (error.stackTrace != null) {
      debugPrint('📍 Stack trace: ${error.stackTrace}');
    }
  }

  // Add error to history
  void _addToHistory(AppError error) {
    _errorHistory.add(error);
    // Keep only last 50 errors
    if (_errorHistory.length > 50) {
      _errorHistory.removeAt(0);
    }
  }

  // Show appropriate user feedback
  void _showUserFeedback(AppError error, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    switch (error.severity) {
      case ErrorSeverity.info:
        _showSnackBar(context, error.message, Colors.blue);
        break;
      case ErrorSeverity.warning:
        _showSnackBar(context, error.message, Colors.orange);
        break;
      case ErrorSeverity.error:
        _showErrorDialog(context, error, l10n);
        break;
      case ErrorSeverity.critical:
        _showCriticalErrorDialog(context, error, l10n);
        break;
    }
  }

  // Show snackbar for minor errors
  void _showSnackBar(BuildContext context, String message, Color color) {
    // Use appropriate snackbar type based on color
    if (color == Colors.red || color.value == 0xFFEF4444) {
      SnackBarUtils.showError(context, message);
    } else if (color == Colors.orange || color.value == 0xFFF59E0B) {
      SnackBarUtils.showWarning(context, message);
    } else if (color == Colors.green || color.value == 0xFF10B981) {
      SnackBarUtils.showSuccess(context, message);
    } else {
      SnackBarUtils.showInfo(context, message);
    }
  }

  // Show error dialog for standard errors
  void _showErrorDialog(BuildContext context, AppError error, AppLocalizations? l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: Text(l10n?.error ?? 'Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.message),
            if (error.details != null) ...[
              const SizedBox(height: 8),
              Text(
                error.details!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.ok ?? 'OK'),
          ),
          if (error.type == ErrorType.network)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retry logic could be implemented here
              },
              child: Text(l10n?.tryAgain ?? 'Try Again'),
            ),
        ],
      ),
    );
  }

  // Show critical error dialog
  void _showCriticalErrorDialog(BuildContext context, AppError error, AppLocalizations? l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: Text(l10n?.error ?? 'Critical Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error.message),
            const SizedBox(height: 16),
            const Text(
              'The app may need to restart to recover.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Could implement app restart logic here
            },
            child: Text(l10n?.ok ?? 'OK'),
          ),
        ],
      ),
    );
  }

  // Convenience methods for common error types
  void showNetworkError(BuildContext? context, {String? details}) {
    handleError(
      AppError(
        code: 'NETWORK_ERROR',
        message: 'Network connection failed. Please check your internet connection.',
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        details: details,
      ),
      context,
    );
  }

  void showAuthenticationError(BuildContext? context, {String? details}) {
    handleError(
      AppError(
        code: 'AUTH_ERROR',
        message: 'Authentication failed. Please log in again.',
        type: ErrorType.authentication,
        severity: ErrorSeverity.error,
        details: details,
      ),
      context,
    );
  }

  void showValidationError(BuildContext? context, String message, {String? details}) {
    handleError(
      AppError(
        code: 'VALIDATION_ERROR',
        message: message,
        type: ErrorType.validation,
        severity: ErrorSeverity.warning,
        details: details,
      ),
      context,
    );
  }

  void showPermissionError(BuildContext? context, {String? details}) {
    handleError(
      AppError(
        code: 'PERMISSION_ERROR',
        message: 'Permission denied. Please grant the required permissions.',
        type: ErrorType.permission,
        severity: ErrorSeverity.error,
        details: details,
      ),
      context,
    );
  }

  void showNotFoundError(BuildContext? context, String resource, {String? details}) {
    handleError(
      AppError(
        code: 'NOT_FOUND_ERROR',
        message: '$resource not found.',
        type: ErrorType.notFound,
        severity: ErrorSeverity.error,
        details: details,
      ),
      context,
    );
  }

  void showServerError(BuildContext? context, {String? details}) {
    handleError(
      AppError(
        code: 'SERVER_ERROR',
        message: 'Server error occurred. Please try again later.',
        type: ErrorType.serverError,
        severity: ErrorSeverity.error,
        details: details,
      ),
      context,
    );
  }

  void showSuccessMessage(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.green);
  }

  void showInfoMessage(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.blue);
  }

  void showWarningMessage(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.orange);
  }

  // Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
  }

  // Get errors by type
  List<AppError> getErrorsByType(ErrorType type) {
    return _errorHistory.where((error) => error.type == type).toList();
  }

  // Get recent errors (last hour)
  List<AppError> getRecentErrors() {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return _errorHistory.where((error) => error.timestamp.isAfter(oneHourAgo)).toList();
  }
}

// Riverpod provider for error handling service
final errorHandlingServiceProvider = Provider<ErrorHandlingService>((ref) {
  return ErrorHandlingService();
});

// Error state notifier for reactive error handling
class ErrorStateNotifier extends StateNotifier<List<AppError>> {
  ErrorStateNotifier() : super([]);

  void addError(AppError error) {
    state = [...state, error];
  }

  void clearErrors() {
    state = [];
  }

  void removeError(AppError error) {
    state = state.where((e) => e != error).toList();
  }
}

final errorStateProvider = StateNotifierProvider<ErrorStateNotifier, List<AppError>>((ref) {
  return ErrorStateNotifier();
});

// Extension for easy error handling in widgets
extension ErrorHandlingExtension on BuildContext {
  void showError(String message, {ErrorType type = ErrorType.unknown, String? details}) {
    ErrorHandlingService().handleError(
      AppError(
        code: 'WIDGET_ERROR',
        message: message,
        type: type,
        details: details,
      ),
      this,
    );
  }

  void showSuccess(String message) {
    ErrorHandlingService().showSuccessMessage(this, message);
  }

  void showInfo(String message) {
    ErrorHandlingService().showInfoMessage(this, message);
  }

  void showWarning(String message) {
    ErrorHandlingService().showWarningMessage(this, message);
  }
}
