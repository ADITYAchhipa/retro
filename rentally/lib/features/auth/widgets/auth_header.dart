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
  
  /// Whether to center the logo/title/subtitle content (back button stays left)
  final bool centered;
  
  /// Use tighter vertical spacing between logo, title, and subtitle
  final bool compact;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLogo = true,
    this.showBackButton = false,
    this.onBackPressed,
    this.centered = false,
    this.compact = false,
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
              ),
            ],
          ),
          SizedBox(height: compact ? 4 : 8),
        ],
        
        if (showLogo) ...[
          // App Logo
          Align(
            alignment: centered ? Alignment.center : Alignment.centerLeft,
            child: Container(
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
          ),
          SizedBox(height: compact ? 12 : 32),
        ],
        
        // Welcome Title
        Align(
          alignment: centered ? Alignment.center : Alignment.centerLeft,
          child: Text(
            title,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        
        SizedBox(height: compact ? 2 : 8),
        
        // Subtitle
        Align(
          alignment: centered ? Alignment.center : Alignment.centerLeft,
          child: Text(
            subtitle,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: (compact ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
