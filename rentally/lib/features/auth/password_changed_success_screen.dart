import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/responsive_layout.dart';

class PasswordChangedSuccessScreen extends ConsumerStatefulWidget {
  const PasswordChangedSuccessScreen({super.key});

  @override
  ConsumerState<PasswordChangedSuccessScreen> createState() => _PasswordChangedSuccessScreenState();
}

class _PasswordChangedSuccessScreenState extends ConsumerState<PasswordChangedSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _checkmarkController;
  late Animation<double> _checkmarkAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _checkmarkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkmarkController, curve: Curves.easeOut),
    );
    
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkmarkController.forward();
    });
    
    // Auto navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/auth');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _checkmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    Color(0xFF0D1117),
                    Color(0xFF161B22),
                    Color(0xFF21262D),
                    Color(0xFF30363D),
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.background,
                    theme.colorScheme.surface.withOpacity(0.8),
                    theme.colorScheme.background,
                  ],
                ),
        ),
        child: ResponsiveLayout(
          maxWidth: 480,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon with Animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green,
                              Colors.green.withOpacity(0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.green.withOpacity(0.4)
                                  : Colors.green.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          animation: _checkmarkAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: CheckmarkPainter(_checkmarkAnimation.value),
                              child: const SizedBox.expand(),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Success Title
                    Text(
                      'Password Changed!',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Success Message
                    Text(
                      'Your password has been successfully changed.\nYou can now sign in with your new password.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Success Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.green.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.security_rounded,
                            size: 48,
                            color: Colors.green,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Text(
                            'Your account is now secure',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            'We recommend using a strong, unique password for better security.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Continue Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF58A6FF),
                                  const Color(0xFF79C0FF),
                                ]
                              : [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withOpacity(0.8),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [],
                      ),
                      child: ElevatedButton(
                        onPressed: () => context.go('/auth'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Continue to Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Auto redirect info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF58A6FF).withOpacity(0.1)
                            : theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF58A6FF).withOpacity(0.2)
                              : theme.colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: isDark ? const Color(0xFF58A6FF) : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Redirecting to sign in automatically...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? const Color(0xFF58A6FF) : theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress;
  
  CheckmarkPainter(this.progress);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final center = Offset(size.width / 2, size.height / 2);
    final checkmarkPath = Path();
    
    // Define checkmark points
    final startPoint = Offset(center.dx - 15, center.dy);
    final middlePoint = Offset(center.dx - 5, center.dy + 10);
    final endPoint = Offset(center.dx + 15, center.dy - 10);
    
    if (progress > 0) {
      checkmarkPath.moveTo(startPoint.dx, startPoint.dy);
      
      if (progress <= 0.5) {
        // First half: draw to middle point
        final currentPoint = Offset.lerp(startPoint, middlePoint, progress * 2)!;
        checkmarkPath.lineTo(currentPoint.dx, currentPoint.dy);
      } else {
        // Second half: draw to end point
        checkmarkPath.lineTo(middlePoint.dx, middlePoint.dy);
        final currentPoint = Offset.lerp(middlePoint, endPoint, (progress - 0.5) * 2)!;
        checkmarkPath.lineTo(currentPoint.dx, currentPoint.dy);
      }
      
      canvas.drawPath(checkmarkPath, paint);
    }
  }
  
  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
