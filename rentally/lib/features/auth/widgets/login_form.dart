import 'package:flutter/material.dart';
import 'auth_form_field.dart';
import 'auth_button.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final bool isLoading;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.onLogin,
    required this.onForgotPassword,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Form(
      key: formKey,
      child: Column(
        children: [
          // Email Field
          AuthFormField(
            controller: emailController,
            label: 'Email',
            hintText: 'Enter your email address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: AuthValidators.validateEmail,
          ),
          
          const SizedBox(height: 20),
          
          // Password Field
          AuthFormField(
            controller: passwordController,
            label: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline,
            obscureText: obscurePassword,
            validator: AuthValidators.validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
              onPressed: onTogglePasswordVisibility,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              child: Text(
                'Forgot Password?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Login Button
          AuthButton(
            text: 'Sign In',
            onPressed: onLogin,
            isLoading: isLoading,
            icon: Icons.login,
          ),
        ],
      ),
    );
  }
}
