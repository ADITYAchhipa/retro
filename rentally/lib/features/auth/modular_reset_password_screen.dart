import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Modular auth widgets
import 'widgets/auth_header.dart';
import 'widgets/auth_form_field.dart';
import 'widgets/auth_button.dart';

// Design system
import '../../core/neo/neo.dart';

// Services

class ModularResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String successPath;
  
  const ModularResetPasswordScreen({
    super.key,
    required this.email,
    this.successPath = '/password-changed',
  });

  @override
  ConsumerState<ModularResetPasswordScreen> createState() => _ModularResetPasswordScreenState();
}

class _ModularResetPasswordScreenState extends ConsumerState<ModularResetPasswordScreen> {
  // ========================================
  // 📝 FORM STATE & CONTROLLERS
  // ========================================
  
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // ========================================
  // 🔄 LIFECYCLE METHODS
  // ========================================
  
  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                
                // ========================================
                // 📱 HEADER SECTION
                // ========================================
                AuthHeader(
                  title: 'Reset Password',
                  subtitle: 'Create a new secure password for your account',
                  showBackButton: true,
                  showLogo: true,
                  centered: true,
                  compact: true,
                  onBackPressed: () => Navigator.pop(context),
                ),
                
                const SizedBox(height: 30),
                
                // ========================================
                // 📝 RESET PASSWORD FORM
                // ========================================
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // New Password Field
                      AuthFormField(
                        controller: _passwordController,
                        label: 'New Password',
                        hintText: 'Enter your new password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            size: 18,
                          ),
                        ),
                        compact: true,
                        emphasizeBorder: true,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Confirm Password Field
                      AuthFormField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hintText: 'Confirm your new password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        validator: _validateConfirmPassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            size: 18,
                          ),
                        ),
                        compact: true,
                        emphasizeBorder: true,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Password Requirements
                      _buildPasswordRequirements(theme, isDark),
                      
                      const SizedBox(height: 32),
                      
                      // Reset Password Button
                      AuthButton(
                        text: 'Reset Password',
                        onPressed: _handleResetPassword,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  // ========================================
  // 🎨 UI HELPER METHODS
  // ========================================
  
  Widget _buildPasswordRequirements(ThemeData theme, bool isDark) {
    final password = _passwordController.text;
    
    return NeoGlass(
      padding: const EdgeInsets.all(16),
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      borderColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
      borderWidth: 1,
      blur: isDark ? 10 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Password Requirements',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRequirement(
            'At least 8 characters',
            password.length >= 8,
            theme,
            isDark,
          ),
          _buildRequirement(
            'Contains uppercase letter',
            password.contains(RegExp(r'[A-Z]')),
            theme,
            isDark,
          ),
          _buildRequirement(
            'Contains lowercase letter',
            password.contains(RegExp(r'[a-z]')),
            theme,
            isDark,
          ),
          _buildRequirement(
            'Contains number',
            password.contains(RegExp(r'[0-9]')),
            theme,
            isDark,
          ),
          _buildRequirement(
            'Contains special character',
            password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
            theme,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isMet 
                  ? Colors.green.withValues(alpha: 0.15) 
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMet ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: isMet ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isMet 
                    ? Colors.green 
                    : (isDark ? Colors.white70 : Colors.grey[700]),
                fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🔍 VALIDATION METHODS
  // ========================================
  
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain special character';
    }
    
    return null;
  }
  
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // ========================================
  // 🔄 ACTION METHODS
  // ========================================
  
  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // Navigate to success screen (supports both auth and account flows)
        context.pushReplacement(widget.successPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset password: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
