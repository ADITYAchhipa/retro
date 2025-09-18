import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';


// Modular auth widgets
import 'widgets/auth_header.dart';
import 'widgets/auth_button.dart';

// Services
import '../../widgets/responsive_layout.dart';
import '../../utils/snackbar_utils.dart';

class ModularOtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final bool isPasswordReset;

  const ModularOtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.isPasswordReset = false,
  });

  @override
  ConsumerState<ModularOtpVerificationScreen> createState() => _ModularOtpVerificationScreenState();
}

class _ModularOtpVerificationScreenState extends ConsumerState<ModularOtpVerificationScreen> {
  // ========================================
  // 📝 FORM STATE & CONTROLLERS
  // ========================================
  
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _timer;
  String _otpCode = '';

  // ========================================
  // 🔄 LIFECYCLE METHODS
  // ========================================
  
  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  // ========================================
  // 🎯 BUSINESS LOGIC METHODS
  // ========================================
  
  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerifyOtp() async {
    _otpCode = _otpControllers.map((controller) => controller.text).join();
    
    if (_otpCode.length != 6) {
      _showSnackBar('Please enter the complete 6-digit code', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement actual OTP verification logic with UserProvider
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (!mounted) return;
      
      _showSnackBar('Verification successful!');
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Navigate based on verification type
      if (widget.isPasswordReset) {
        context.pushReplacement('/reset-password', extra: {'email': widget.phoneNumber});
      } else {
        context.go('/role-selection');
      }
      
    } catch (e) {
      if (mounted) {
        _showSnackBar('Invalid verification code. Please try again.', isError: true);
        _clearOtpFields();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0) return;
    
    setState(() => _isResending = true);

    try {
      // TODO: Implement actual resend OTP logic
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      
      _showSnackBar('Verification code sent again!');
      _startResendCountdown();
      _clearOtpFields();
      
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to resend code: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _clearOtpFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto-verify when all fields are filled
    if (index == 5 && value.isNotEmpty) {
      final otpCode = _otpControllers.map((controller) => controller.text).join();
      if (otpCode.length == 6) {
        _handleVerifyOtp();
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      SnackBarUtils.showError(context, message);
    } else {
      SnackBarUtils.showSuccess(context, message);
    }
  }

  String get _getVerificationMessage {
    return widget.isPasswordReset 
        ? 'We sent a verification code to ${widget.phoneNumber} to reset your password'
        : 'We sent a verification code to ${widget.phoneNumber}';
  }

  String get _getTitle {
    return widget.isPasswordReset ? 'Enter Reset Code' : 'Verify Phone Number';
  }

  // ========================================
  // 🎨 UI BUILD METHOD
  // ========================================
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ResponsiveLayout(
      maxWidth: 480,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.background,
                theme.colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ========================================
                      // 📱 HEADER SECTION
                      // ========================================
                      AuthHeader(
                        title: _getTitle,
                        subtitle: _getVerificationMessage,
                        showBackButton: true,
                        onBackPressed: () => context.pop(),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // ========================================
                      // 🔢 OTP INPUT SECTION
                      // ========================================
                      _buildOtpInputSection(theme),
                      
                      const SizedBox(height: 32),
                      
                      // ========================================
                      // ✅ VERIFY BUTTON
                      // ========================================
                      SizedBox(
                        width: double.infinity,
                        child: AuthButton(
                          text: 'Verify Code',
                          onPressed: _isLoading ? null : _handleVerifyOtp,
                          isLoading: _isLoading,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // ========================================
                      // 🔄 RESEND SECTION
                      // ========================================
                      _buildResendSection(theme),
                      
                      const SizedBox(height: 24),
                      
                      // ========================================
                      // ℹ️ HELP SECTION
                      // ========================================
                      _buildHelpSection(theme),
                    ],
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
  
  Widget _buildOtpInputSection(ThemeData theme) {
    return Column(
      children: [
        // OTP input fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 50,
              height: 60,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: theme.colorScheme.surface.withOpacity(0.5),
                  border: OutlineInputBorder(
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
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                ),
                onChanged: (value) => _onOtpChanged(value, index),
              ),
            );
          }),
        ),
        
        const SizedBox(height: 16),
        
        // Auto-verification hint
        Text(
          'Enter the 6-digit code • Auto-verifies when complete',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResendSection(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Didn\'t receive the code? ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        if (_resendCountdown > 0) ...[
          Text(
            'Resend in ${_resendCountdown}s',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ] else ...[
          TextButton(
            onPressed: _isResending ? null : _handleResendOtp,
            child: _isResending
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                )
              : Text(
                  'Resend Code',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildHelpSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Having trouble?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Check your spam/junk folder\n'
            '• Ensure you entered the correct phone number\n'
            '• Code expires in 10 minutes\n'
            '• Contact support if issues persist',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
