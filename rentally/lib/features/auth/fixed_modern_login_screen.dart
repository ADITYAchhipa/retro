import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Services and utilities
import '../../services/error_handling_service.dart';
import '../../services/loading_service.dart';
import '../../widgets/responsive_layout.dart';

// App state and theme
import '../../app/app_state.dart';
import '../../core/theme/enterprise_dark_theme.dart';

class FixedModernLoginScreen extends ConsumerStatefulWidget {
  const FixedModernLoginScreen({super.key});

  @override
  ConsumerState<FixedModernLoginScreen> createState() => _FixedModernLoginScreenState();
}

class _FixedModernLoginScreenState extends ConsumerState<FixedModernLoginScreen> {
  // ========================================
  // 📝 FORM CONTROLLERS AND STATE
  // ========================================
  
  /// Form key for validation management
  final _formKey = GlobalKey<FormState>();
  
  /// Email input controller
  final _emailController = TextEditingController();
  
  /// Password input controller  
  final _passwordController = TextEditingController();
  
  /// Controls password visibility toggle
  bool _obscurePassword = true;

  // ========================================
  // 🧹 CLEANUP AND DISPOSAL
  // ========================================
  
  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ========================================
  // 🔄 ACTION METHODS
  // ========================================
  
  // Biometric login removed
  
  /// Handles user login process with validation and error handling
  /// 
  /// Process:
  /// 1. Validates form inputs
  /// 2. Shows loading state
  /// 3. Calls authentication service
  /// 4. Handles success/error responses
  /// 5. Navigates to appropriate screen
  /// 
  void _login() async {
    // Step 1: Validate form inputs
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        context.showError('Please fix the validation errors above', type: ErrorType.validation);
      }
      return;
    }
    
    // Cache notifier up-front to avoid using ref after this widget might be disposed by navigation
    final loadingNotifier = ref.read(loadingServiceProvider.notifier);

    try {
      // Step 2: Show loading state to user
      loadingNotifier.startLoading(key: 'auth', type: LoadingType.submit, message: 'Signing in...');
      
      // Step 3: Attempt authentication with backend
      await ref.read(authProvider.notifier).signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      // Step 4: Check if widget is still mounted (safety check)
      if (!mounted) return;
      
      // Step 5: Verify authentication success
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.authenticated && authState.user != null) {
        context.showSuccess('Successfully signed in!');
        // Let the router handle navigation automatically via redirect logic
        // No manual navigation needed - router will redirect based on auth state
      } else {
        context.showError('Login failed. Please check your credentials.');
      }
    } catch (e) {
      if (mounted) {
        context.showError('Login failed: ${e.toString()}');
      }
    } finally {
      // Use cached notifier; safe even if this widget was disposed during navigation
      loadingNotifier.stopLoading('auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? EnterpriseDarkTheme.primaryGradient : const RadialGradient(
            center: Alignment(0.0, -0.4),
            radius: 1.5,
            colors: [
              Color(0xFFFDFDFF),
              Color(0xFFF8FAFF),
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
              Color(0xFFF8FAFC),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: ResponsiveLayout(
          maxWidth: 480,
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top - 
                    MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                  
                  // Modern App Logo
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: isDark ? const LinearGradient(
                          colors: [
                            EnterpriseDarkTheme.primaryAccent,
                            EnterpriseDarkTheme.secondaryAccent,
                          ],
                        ) : LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isDark 
                                ? EnterpriseDarkTheme.primaryAccent.withOpacity(0.4)
                                : theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home_work_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Modern Title Section
                  Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: isDark ? [
                            EnterpriseDarkTheme.primaryAccent,
                            EnterpriseDarkTheme.tertiaryAccent,
                          ] : [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Welcome Back',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Sign in to continue your journey',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Modern Login Form
                  Container(
                    decoration: BoxDecoration(
                      gradient: isDark ? LinearGradient(
                        colors: [
                          const Color(0xFF21262D).withOpacity(0.9),
                          const Color(0xFF30363D),
                        ],
                      ) : null,
                      color: isDark ? null : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark 
                            ? const Color(0xFF58A6FF).withOpacity(0.4)
                            : theme.colorScheme.outline.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark 
                              ? const Color(0xFF58A6FF).withOpacity(0.2)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Modern Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'Enter your email',
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? EnterpriseDarkTheme.primaryAccent.withOpacity(0.1)
                                        : theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.email_outlined,
                                    color: isDark 
                                        ? EnterpriseDarkTheme.primaryAccent
                                        : theme.colorScheme.primary,
                                    size: 16,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark ? EnterpriseDarkTheme.inputBackground : theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withOpacity(0.22) : theme.colorScheme.outline,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withOpacity(0.22) : theme.colorScheme.outline,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? EnterpriseDarkTheme.primaryAccent : theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Modern Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? EnterpriseDarkTheme.primaryAccent.withOpacity(0.1)
                                        : theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.lock_outlined,
                                    color: isDark 
                                        ? EnterpriseDarkTheme.primaryAccent
                                        : theme.colorScheme.primary,
                                    size: 16,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: isDark 
                                        ? EnterpriseDarkTheme.primaryAccent
                                        : theme.colorScheme.primary,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: isDark ? EnterpriseDarkTheme.inputBackground : theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withOpacity(0.22) : theme.colorScheme.outline,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withOpacity(0.22) : theme.colorScheme.outline,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? EnterpriseDarkTheme.primaryAccent : theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 2),
                            
                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  context.go('/forgot-password');
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark 
                                      ? EnterpriseDarkTheme.primaryAccent
                                      : theme.colorScheme.primary,
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Modern Login Button
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark ? [
                                    const Color(0xFF58A6FF),
                                    const Color(0xFF0969DA),
                                  ] : [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [],
                              ),
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Test Credentials Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF58A6FF).withOpacity(0.1)
                          : theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark 
                            ? const Color(0xFF58A6FF).withOpacity(0.3)
                            : theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: isDark 
                                  ? const Color(0xFF58A6FF)
                                  : theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Test Credentials',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark 
                                    ? const Color(0xFF58A6FF)
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTestCredential('User/Seeker', 'user@test.com', 'user123'),
                        const SizedBox(height: 4),
                        _buildTestCredential('Property Owner', 'owner@test.com', 'owner123'),
                        const SizedBox(height: 4),
                        _buildTestCredential('Demo', 'demo@rentally.com', 'demo123'),
                        
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Login Form Container
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or continue with',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Social Login Options
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          'Google',
                          Icons.g_mobiledata,
                          () {
                            // Handle Google login
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSocialButton(
                          'Apple',
                          Icons.apple,
                          () {
                            // Handle Apple login
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Biometric Authentication removed
                  
                  const SizedBox(height: 16),
                  
                  // Sign Up Option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/register');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: isDark 
                              ? EnterpriseDarkTheme.primaryAccent
                              : theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon, VoidCallback onPressed) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark 
            ? EnterpriseDarkTheme.inputBackground
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? EnterpriseDarkTheme.primaryBorder
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark 
                    ? EnterpriseDarkTheme.primaryAccent
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestCredential(String role, String email, String password) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  password,
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _emailController.text = email;
              _passwordController.text = password;
            },
            icon: Icon(
              Icons.copy,
              size: 16,
              color: isDark 
                  ? const Color(0xFF58A6FF)
                  : theme.colorScheme.primary,
            ),
            tooltip: 'Use these credentials',
          ),
        ],
      ),
    );
  }
}
