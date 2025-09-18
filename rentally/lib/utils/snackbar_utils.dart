import 'package:flutter/material.dart';
import 'dart:ui';

/// Global utility class for professional overlay snackbars that don't shift content
class SnackBarUtils {
  static OverlayEntry? _currentOverlay;

  /// Shows a professional floating snackbar that overlays content without shifting layout
  static void showFloatingSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color foregroundColor,
    Duration? duration,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onActionPressed,
    SnackBarType type = SnackBarType.info,
  }) {
    // Remove any existing overlay
    _removeCurrentOverlay();

    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _currentOverlay = OverlayEntry(
      builder: (context) => _ProfessionalSnackBar(
        message: message,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        icon: icon,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
        onDismiss: _removeCurrentOverlay,
        type: type,
        isDark: isDark,
      ),
    );

    overlay.insert(_currentOverlay!);

    // Auto-hide after duration
    Future.delayed(duration ?? const Duration(seconds: 4), () {
      _removeCurrentOverlay();
    });
  }

  static void _removeCurrentOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Shows a success snackbar with professional styling
  static void showSuccess(BuildContext context, String message) {
    showFloatingSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFF10B981),
      foregroundColor: Colors.white,
      icon: Icons.check_circle_outline,
      type: SnackBarType.success,
    );
  }

  /// Shows a warning snackbar with professional styling
  static void showWarning(BuildContext context, String message) {
    showFloatingSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFFF59E0B),
      foregroundColor: Colors.white,
      icon: Icons.warning_outlined,
      type: SnackBarType.warning,
    );
  }

  /// Shows an error snackbar with professional styling
  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    showFloatingSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFFEF4444),
      foregroundColor: Colors.white,
      icon: Icons.error_outline,
      duration: const Duration(seconds: 4),
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      type: SnackBarType.error,
    );
  }

  /// Shows an info snackbar with professional styling
  static void showInfo(BuildContext context, String message) {
    showFloatingSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFF3B82F6),
      foregroundColor: Colors.white,
      icon: Icons.info_outline,
      type: SnackBarType.info,
    );
  }
}

/// Enum for different snackbar types
enum SnackBarType { success, warning, error, info }

/// Professional snackbar widget with glassmorphism and animations
class _ProfessionalSnackBar extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final VoidCallback onDismiss;
  final SnackBarType type;
  final bool isDark;

  const _ProfessionalSnackBar({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    this.actionLabel,
    this.onActionPressed,
    required this.onDismiss,
    required this.type,
    required this.isDark,
  });

  @override
  State<_ProfessionalSnackBar> createState() => _ProfessionalSnackBarState();
}

class _ProfessionalSnackBarState extends State<_ProfessionalSnackBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _slideController.reverse();
    await _fadeController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    return Positioned(
      top: mediaQuery.padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.backgroundColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(widget.isDark ? 0.4 : 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.backgroundColor.withOpacity(0.9),
                          widget.backgroundColor.withOpacity(0.8),
                        ],
                      ),
                      border: Border.all(
                        color: widget.backgroundColor.withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          if (widget.icon != null) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                widget.icon,
                                color: widget.foregroundColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              widget.message,
                              style: TextStyle(
                                color: widget.foregroundColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (widget.actionLabel != null) ...[
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () {
                                widget.onActionPressed?.call();
                                _dismiss();
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                foregroundColor: widget.foregroundColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                widget.actionLabel!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _dismiss,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.close,
                                color: widget.foregroundColor,
                                size: 16,
                              ),
                            ),
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
      ),
    );
  }
}
