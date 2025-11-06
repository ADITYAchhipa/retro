import 'package:flutter/material.dart';
import '../../../core/theme/enterprise_dark_theme.dart';

class AuthFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool compact;
  final bool emphasizeBorder;

  const AuthFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.onTap,
    this.readOnly = false,
    this.compact = false,
    this.emphasizeBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textStyle = (compact ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)?.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final hintTextStyle = (compact ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.5),
    );
    final double prefixSize = compact ? 18 : 20;
    final double verticalPad = compact ? 12 : 16;
    // Border styling
    final Color baseBorderColor = isDark
        ? EnterpriseDarkTheme.primaryBorder
        : theme.colorScheme.outline.withOpacity(0.75);
    final Color emphasizedBorderColor = isDark
        ? EnterpriseDarkTheme.primaryBorder
        : theme.colorScheme.outline.withOpacity(1.0);
    final Color borderColor = emphasizeBorder ? emphasizedBorderColor : baseBorderColor;
    final double borderWidth = emphasizeBorder ? 1.6 : 1.1;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field Label
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Text Form Field
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap,
          readOnly: readOnly,
          style: textStyle,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: hintTextStyle,
            prefixIcon: Icon(
              prefixIcon,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              size: prefixSize,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark 
                ? EnterpriseDarkTheme.inputBackground
                : theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: borderColor,
                width: borderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: borderColor,
                width: borderWidth,
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
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: verticalPad,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain a special character';
    }
    
    return null;
  }
  
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }
  
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }
  
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
}
