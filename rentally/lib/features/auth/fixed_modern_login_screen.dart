import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Services and utilities
import '../../services/error_handling_service.dart';
import '../../services/loading_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../utils/snackbar_utils.dart';

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
  String? _serverError;

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
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        const message = 'Please enter a valid email and password';
        setState(() {
          _serverError = message;
        });
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
        setState(() {
          _serverError = null;
        });
        // Mark onboarding as complete once the user has successfully signed in,
        // so subsequent unauthenticated sessions (e.g., after logout) land on
        // the login screen instead of the marketing splash/onboarding flow.
        ref.read(onboardingCompleteProvider.notifier).state = true;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('onboardingComplete', true);
        } catch (_) {
          // Ignore persistence errors to avoid blocking login UX
        }
        // ignore: use_build_context_synchronously
        context.showSuccess('Successfully signed in!');
        // Let the router handle navigation automatically via redirect logic
        // No manual navigation needed - router will redirect based on auth state
      } else {
        final message = authState.error ?? 'Login failed. Please check your email or password and try again.';
        if (mounted) {
          setState(() {
            _serverError = message;
          });
          _showTopSnackBar(message, Theme.of(context).colorScheme.error);
        }
      }
    } catch (e) {
      if (mounted) {
        final fallback = e.toString();
        final message = fallback.isNotEmpty ? fallback : 'Login failed. Please try again.';
        setState(() {
          _serverError = message;
        });
        _showTopSnackBar(message, Theme.of(context).colorScheme.error);
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
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isDark 
                                ? EnterpriseDarkTheme.primaryAccent.withValues(alpha: 0.22)
                                : theme.colorScheme.primary.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
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
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                          const Color(0xFF21262D).withValues(alpha: 0.9),
                          const Color(0xFF30363D),
                        ],
                      ) : null,
                      color: isDark ? null : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark 
                            ? const Color(0xFF58A6FF).withValues(alpha: 0.4)
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark 
                              ? const Color(0xFF58A6FF).withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
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
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? EnterpriseDarkTheme.primaryAccent.withValues(alpha: 0.1)
                                        : theme.colorScheme.primary.withValues(alpha: 0.1),
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
                                    color: isDark ? Colors.white.withValues(alpha: 0.22) : theme.colorScheme.outline,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withValues(alpha: 0.22) : theme.colorScheme.outline,
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
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? EnterpriseDarkTheme.primaryAccent.withValues(alpha: 0.1)
                                        : theme.colorScheme.primary.withValues(alpha: 0.1),
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
                                    color: isDark ? Colors.white.withValues(alpha: 0.22) : theme.colorScheme.outline,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withValues(alpha: 0.22) : theme.colorScheme.outline,
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
                            
                            if (_serverError != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  _serverError!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            
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
                                    theme.colorScheme.primary.withValues(alpha: 0.8),
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
                  
                  const SizedBox(height: 16),
                  
                  // Login Form Container
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or continue with',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
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
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

  void _showTopSnackBar(String message, Color color) {
    // Use the global overlay-based snackbar utility so the bar appears
    // at the top of the screen (below the system/status bar) instead of
    // the default bottom-anchored Material SnackBar.
    SnackBarUtils.showFloatingSnackBar(
      context,
      message: message,
      backgroundColor: color,
      foregroundColor: Colors.white,
      icon: Icons.error_outline,
      type: SnackBarType.error,
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
              : theme.colorScheme.outline.withValues(alpha: 0.3),
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

}
