import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';

/// Comprehensive form error handling and validation system
class FormErrorHandler {
  static const Map<String, String> _errorMessages = {
    'required': 'This field is required',
    'email': 'Please enter a valid email address',
    'password': 'Password must be at least 8 characters',
    'passwordMatch': 'Passwords do not match',
    'phone': 'Please enter a valid phone number',
    'name': 'Name must be at least 2 characters',
    'creditCard': 'Please enter a valid credit card number',
    'cvv': 'Please enter a valid CVV',
    'expiryDate': 'Please enter a valid expiry date',
    'amount': 'Please enter a valid amount',
    'minLength': 'Must be at least {min} characters',
    'maxLength': 'Must be no more than {max} characters',
    'numeric': 'Please enter numbers only',
    'alphanumeric': 'Please enter letters and numbers only',
    'url': 'Please enter a valid URL',
    'date': 'Please enter a valid date',
    'time': 'Please enter a valid time',
    'range': 'Value must be between {min} and {max}',
  };

  /// Get localized error message
  static String getErrorMessage(String key, {Map<String, dynamic>? params}) {
    String message = _errorMessages[key] ?? 'Invalid input';
    
    if (params != null) {
      params.forEach((key, value) {
        message = message.replaceAll('{$key}', value.toString());
      });
    }
    
    return message;
  }

  /// Show form error snackbar
  static void showFormError(BuildContext context, String message) {
    SnackBarUtils.showError(context, message);
  }

  /// Show form success snackbar
  static void showFormSuccess(BuildContext context, String message) {
    SnackBarUtils.showSuccess(context, message);
  }

  /// Validate form and show errors
  static bool validateForm(GlobalKey<FormState> formKey, BuildContext context) {
    if (!formKey.currentState!.validate()) {
      showFormError(context, 'Please fix the errors above');
      return false;
    }
    return true;
  }

  /// Handle async form submission with error handling
  static Future<bool> handleFormSubmission(
    Future<void> Function() submitFunction, {
    String? successMessage,
    String? errorMessage,
    required BuildContext context,
  }) async {
    try {
      await submitFunction();
      if (successMessage != null && context.mounted) {
        showFormSuccess(context, successMessage);
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        showFormError(
          context, 
          errorMessage ?? 'An error occurred: ${e.toString()}'
        );
      }
      return false;
    }
  }
}

/// Enhanced form field with built-in error handling
class EnhancedFormField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool enabled;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final String? initialValue;
  final bool required;

  const EnhancedFormField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.initialValue,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            children: required ? [
              TextSpan(
                text: ' *',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ] : null,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          enabled: enabled,
          onTap: onTap,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

/// Loading button with error handling
class LoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const LoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.primary,
          foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    foregroundColor ?? theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
