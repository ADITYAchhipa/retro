import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_state.dart';

class RouteGuard {
  static String? redirectLogic(BuildContext context, GoRouterState state, WidgetRef ref) {
    final authState = ref.read(authProvider);
    final onboardingComplete = ref.read(onboardingCompleteProvider);
    final selectedCountry = ref.read(countryProvider);
    
    final currentPath = state.uri.path;
    
    // Public routes that don't require authentication
    final publicRoutes = [
      '/',
      '/onboarding',
      '/country',
      '/auth',
      '/register',
    ];
    
    // Check if current route is public
    final isPublicRoute = publicRoutes.contains(currentPath);
    
    // If user is authenticated
    if (authState.status == AuthStatus.authenticated) {
      // If trying to access public routes while authenticated, redirect to appropriate home
      if (isPublicRoute) {
        final userRole = authState.user?.role ?? UserRole.seeker;
        return userRole == UserRole.owner ? '/owner-dashboard' : '/home';
      }
      
      // Allow access to protected routes
      return null;
    }
    
    // If user is not authenticated
    if (authState.status == AuthStatus.unauthenticated || authState.status == AuthStatus.initial) {
      // Allow access to public routes
      if (isPublicRoute) {
        // Check onboarding flow
        if (!onboardingComplete && currentPath != '/' && currentPath != '/onboarding') {
          return '/onboarding';
        }
        
        // Check country selection
        if (onboardingComplete && selectedCountry == null && currentPath != '/country') {
          return '/country';
        }
        
        // Check authentication
        if (onboardingComplete && selectedCountry != null && currentPath != '/auth' && currentPath != '/register') {
          return '/auth';
        }
        
        return null;
      }
      
      // Redirect to auth for protected routes
      return '/auth';
    }
    
    // Loading state - stay on current route
    return null;
  }
}

class AuthGuardWidget extends ConsumerWidget {
  final Widget child;
  
  const AuthGuardWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Show loading indicator during auth operations
    if (authState.status == AuthStatus.loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }
    
    return child;
  }
}

// Custom redirect for GoRouter
class AuthRedirect {
  static String? redirect(BuildContext context, GoRouterState state) {
    // We need access to WidgetRef, so we'll handle this in the router configuration
    return null;
  }
}
