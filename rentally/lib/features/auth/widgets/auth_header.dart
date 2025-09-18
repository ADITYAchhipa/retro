import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  /// Main heading text displayed prominently
  final String title;
  
  /// Supporting description text below the title
  final String subtitle;
  
  /// Whether to display the app logo at the top
  final bool showLogo;
  
  /// Whether to show a back navigation button
  final bool showBackButton;
  
  /// Callback function when back button is pressed
  final VoidCallback? onBackPressed;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLogo = true,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button (if enabled)
        if (showBackButton) ...[
          Row(
            children: [
              IconButton(
                onPressed: onBackPressed,
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: theme.colorScheme.onSurface,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        if (showLogo) ...[
          // App Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 32),
        ],
        
        // Welcome Title
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
