import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/snackbar_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/api_constants.dart';

class ModernForgotPasswordScreen extends ConsumerStatefulWidget {
  const ModernForgotPasswordScreen({super.key});

  @override
  ConsumerState<ModernForgotPasswordScreen> createState() => _ModernForgotPasswordScreenState();
}

class _ModernForgotPasswordScreenState extends ConsumerState<ModernForgotPasswordScreen> {
  // ========================================
  // 📝 FORM CONTROLLERS AND STATE
  // ========================================
  
  /// Form key for validation management
  final _formKey = GlobalKey<FormState>();
  
  /// Email input controller
  final _emailController = TextEditingController();
  
  /// Loading state for form submission
  bool _isLoading = false;
  
  /// Email sent confirmation state
  bool _emailSent = false;

  // ========================================
  // 🧹 CLEANUP AND DISPOSAL
  // ========================================
  
  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _emailController.dispose();
    super.dispose();
  }

  // ========================================
  // 🔄 ACTION METHODS
  // ========================================
  
  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${ApiConstants.authBaseUrl}/ForgotPassword');
      final response = await http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (!mounted) return;
      
      if (data['success'] == true) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
        SnackBarUtils.showSuccess(context, data['message']?.toString() ?? 'Reset link sent to email');
      } else {
        setState(() => _isLoading = false);
        SnackBarUtils.showError(context, data['message']?.toString() ?? 'Failed to send reset email');
      }
      
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarUtils.showError(context, 'Failed to send reset email: ${e.toString()}');
      }
    }
  }

  Future<void> _handleResendEmail() async {
    setState(() => _isLoading = true);
    
    try {
      final url = Uri.parse('${ApiConstants.authBaseUrl}/ForgotPassword');
      final response = await http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      if (data['success'] == true) {
        SnackBarUtils.showSuccess(context, data['message']?.toString() ?? 'Reset email sent again');
      } else {
        SnackBarUtils.showError(context, data['message']?.toString() ?? 'Failed to resend email');
      }
      
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarUtils.showError(context, 'Failed to resend email: ${e.toString()}');
      }
    }
  }

  // ========================================
  // 🎨 UI BUILD METHOD
  // ========================================
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [
              const Color(0xFF0D1117),
              const Color(0xFF161B22),
              const Color(0xFF21262D),
            ] : [
              const Color(0xFF667EEA),
              const Color(0xFF764BA2),
              const Color(0xFFF093FB),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: size.width > 600 ? 450 : size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 450),
                child: Card(
                  elevation: isDark ? 8 : 12,
                  shadowColor: isDark 
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: isDark 
                      ? const Color(0xFF21262D)
                      : Colors.white.withValues(alpha: 0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? const Color(0xFF30363D)
                                  : const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () {
                                context.go('/auth');
                              },
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: isDark 
                                    ? const Color(0xFF58A6FF)
                                    : const Color(0xFF1565C0),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Logo
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark ? [
                                const Color(0xFF58A6FF),
                                const Color(0xFF79C0FF),
                              ] : [
                                const Color(0xFF1565C0),
                                const Color(0xFF1976D2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark 
                                    ? const Color(0xFF58A6FF)
                                    : const Color(0xFF1565C0)).withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Title
                        Text(
                          _emailSent ? 'Check Your Email' : 'Forgot Password?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark 
                                ? const Color(0xFFF0F6FC)
                                : const Color(0xFF0D1117),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Subtitle
                        Text(
                          _emailSent 
                              ? 'We\'ve sent a password reset link to your email'
                              : 'Enter your email to receive a password reset link',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark 
                                ? const Color(0xFF8B949E)
                                : const Color(0xFF656D76),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Content
                        if (!_emailSent) ...[
                          _buildEmailForm(theme, isDark),
                        ] else ...[
                          _buildEmailSentContent(theme, isDark),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Back to login
                        _buildBackToLoginLink(theme, isDark),
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

  // ========================================
  // 🔧 HELPER WIDGETS
  // ========================================
  
  Widget _buildEmailForm(ThemeData theme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: isDark 
                  ? const Color(0xFFF0F6FC)
                  : const Color(0xFF0D1117),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your registered email',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: isDark 
                    ? const Color(0xFF58A6FF)
                    : const Color(0xFF1565C0),
                size: 20,
              ),
              labelStyle: TextStyle(
                color: isDark 
                    ? const Color(0xFF8B949E)
                    : const Color(0xFF656D76),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              hintStyle: TextStyle(
                color: isDark 
                    ? const Color(0xFF6E7681)
                    : const Color(0xFF8C959F),
                fontSize: 14,
              ),
              filled: true,
              fillColor: isDark 
                  ? const Color(0xFF0D1117)
                  : const Color(0xFFF6F8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark 
                      ? const Color(0xFF30363D)
                      : const Color(0xFFD0D7DE),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark 
                      ? const Color(0xFF30363D)
                      : const Color(0xFFD0D7DE),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark 
                      ? const Color(0xFF58A6FF)
                      : const Color(0xFF1565C0),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFDA3633),
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
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
          
          const SizedBox(height: 24),
          
          // Send reset email button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark 
                    ? const Color(0xFF238636)
                    : const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Send Reset Email',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSentContent(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Success icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark ? [
                const Color(0xFF238636),
                const Color(0xFF2EA043),
              ] : [
                const Color(0xFF1565C0),
                const Color(0xFF1976D2),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark 
                    ? const Color(0xFF238636)
                    : const Color(0xFF1565C0)).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 32,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Email sent message
        Text(
          'Reset email sent to:',
          style: TextStyle(
            fontSize: 14,
            color: isDark 
                ? const Color(0xFF8B949E)
                : const Color(0xFF656D76),
          ),
        ),
        
        const SizedBox(height: 4),
        
        Text(
          _emailController.text,
          style: TextStyle(
            fontSize: 16,
            color: isDark 
                ? const Color(0xFF58A6FF)
                : const Color(0xFF1565C0),
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF0D1117)
                : const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark 
                  ? const Color(0xFF30363D)
                  : const Color(0xFFD0D7DE),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next Steps:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark 
                      ? const Color(0xFFF0F6FC)
                      : const Color(0xFF0D1117),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Check your email inbox\n'
                '2. Click the reset link in the email\n'
                '3. Create a new password\n'
                '4. Sign in with your new password',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark 
                      ? const Color(0xFF8B949E)
                      : const Color(0xFF656D76),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Resend email button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _handleResendEmail,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: isDark 
                    ? const Color(0xFF58A6FF)
                    : const Color(0xFF1565C0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark 
                            ? const Color(0xFF58A6FF)
                            : const Color(0xFF1565C0),
                      ),
                    ),
                  )
                : Text(
                    'Resend Email',
                    style: TextStyle(
                      color: isDark 
                          ? const Color(0xFF58A6FF)
                          : const Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Didn't receive email help
        Text(
          'Didn\'t receive the email? Check your spam folder.',
          style: TextStyle(
            fontSize: 13,
            color: isDark 
                ? const Color(0xFF6E7681)
                : const Color(0xFF8C959F),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBackToLoginLink(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Remember your password? ',
          style: TextStyle(
            fontSize: 14,
            color: isDark 
                ? const Color(0xFF8B949E)
                : const Color(0xFF656D76),
          ),
        ),
        TextButton(
          onPressed: () {
            context.go('/auth');
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign In',
            style: TextStyle(
              fontSize: 14,
              color: isDark 
                  ? const Color(0xFF58A6FF)
                  : const Color(0xFF1565C0),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
