import 'package:flutter/material.dart';
import '../../../core/theme/enterprise_dark_theme.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;
  final Color? backgroundColor;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark 
            ? EnterpriseDarkTheme.inputBackground
            : theme.colorScheme.surface),
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
                color: iconColor ?? theme.colorScheme.onSurface.withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
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

class SocialLoginSection extends StatelessWidget {
  final VoidCallback onGoogleLogin;
  final VoidCallback onAppleLogin;
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
        // Divider with text
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
        
        const SizedBox(height: 24),
        
        // Social login buttons
        Row(
          children: [
            Expanded(
              child: SocialLoginButton(
                label: 'Google',
                icon: Icons.g_mobiledata,
                onPressed: onGoogleLogin,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SocialLoginButton(
                label: 'Apple',
                icon: Icons.apple,
                onPressed: onAppleLogin,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SocialLoginButton(
                label: 'Facebook',
                icon: Icons.facebook,
                onPressed: onFacebookLogin,
                iconColor: const Color(0xFF1877F2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
