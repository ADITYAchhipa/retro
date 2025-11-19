import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart';
import '../features/splash/splash_screen.dart';
import '../features/home/original_home_screen.dart';
import '../features/owner/clean_owner_dashboard_screen.dart';

/// Auth wrapper that handles immediate routing based on auth state
/// This prevents the splash screen from showing for authenticated users
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Immediately show appropriate screen based on auth state
    switch (authState.status) {
      case AuthStatus.authenticated:
        final userRole = authState.user?.role ?? UserRole.seeker;
        switch (userRole) {
          case UserRole.owner:
            return const CleanOwnerDashboardScreen();
          case UserRole.seeker:
            return const OriginalHomeScreen();
        }
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      case AuthStatus.unauthenticated:
      case AuthStatus.initial:
        return const SplashScreen();
    }
  }
}
