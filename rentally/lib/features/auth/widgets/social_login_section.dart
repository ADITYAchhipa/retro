import 'package:flutter/material.dart';
import 'social_login_button.dart';

class SocialLoginSection extends StatelessWidget {
  /// Callback for Google login
  final VoidCallback onGoogleLogin;
  
  /// Callback for Apple login
  final VoidCallback onAppleLogin;
  
  /// Callback for Facebook login
  final VoidCallback onFacebookLogin;

  const SocialLoginSection({
    super.key,
    required this.onGoogleLogin,
    required this.onAppleLogin,
    required this.onFacebookLogin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // ========================================
        // ➖ DIVIDER WITH TEXT
        // ========================================
        _buildDivider(theme),
        
        const SizedBox(height: 24),
        
        // ========================================
        // 🔗 SOCIAL LOGIN BUTTONS
        // ========================================
        _buildSocialButtons(),
      ],
    );
  }

  /// ========================================
  /// 🔧 HELPER METHODS
  /// ========================================
  
  /// Builds the "or continue with" divider
  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: theme.colorScheme.outline.withOpacity(0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: theme.colorScheme.outline.withOpacity(0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  /// Builds the row of social login buttons
  Widget _buildSocialButtons() {
    return Row(
      children: [
        // Google Login Button
        Expanded(
          child: SocialLoginButton(
            label: 'Google',
            icon: Icons.g_mobiledata,
            onPressed: onGoogleLogin,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Apple Login Button
        Expanded(
          child: SocialLoginButton(
            label: 'Apple',
            icon: Icons.apple,
            onPressed: onAppleLogin,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Facebook Login Button
        Expanded(
          child: SocialLoginButton(
            label: 'Facebook',
            icon: Icons.facebook,
            onPressed: onFacebookLogin,
            iconColor: const Color(0xFF1877F2),
          ),
        ),
      ],
    );
  }
}
