import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { seeker, owner }

enum AuthStatus { 
  initial, 
  unauthenticated, 
  authenticated, 
  loading 
}

class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final String? profileImageUrl;
  final bool isKycVerified;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.profileImageUrl,
    this.isKycVerified = false,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    String? profileImageUrl,
    bool? isKycVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isKycVerified: isKycVerified ?? this.isKycVerified,
    );
  }
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(status: AuthStatus.initial));

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Test credentials for different user types
      User? user;
      
      if (email == 'user@test.com' && password == 'user123') {
        user = const User(
          id: 'user_001',
          email: 'user@test.com',
          name: 'Test User (Seeker)',
          phone: '+1234567890',
          role: UserRole.seeker,
        );
      } else if (email == 'owner@test.com' && password == 'owner123') {
        user = const User(
          id: 'owner_001',
          email: 'owner@test.com',
          name: 'Test Owner',
          phone: '+1234567891',
          role: UserRole.owner,
        );
      } else if (email == 'demo@rentally.com' && password == 'demo123') {
        user = const User(
          id: 'demo_001',
          email: 'demo@rentally.com',
          name: 'Demo User',
          phone: '+1234567893',
          role: UserRole.seeker,
        );
      } else {
        throw Exception('Invalid email or password');
      }
      
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<void> signUp(String name, String email, String password, UserRole role) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock successful registration
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        name: name,
        role: role,
      );
      
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Registration failed: ${e.toString()}',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        error: 'Logout failed: ${e.toString()}',
      );
    }
  }

  Future<void> updateProfile(User updatedUser) async {
    if (state.user == null) return;
    
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: updatedUser,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        error: 'Profile update failed: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void switchRole(UserRole newRole) {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(role: newRole);
      state = state.copyWith(user: updatedUser);
    }
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final roleProvider = StateProvider<UserRole>((ref) => UserRole.seeker);
final countryProvider = StateProvider<String?>((ref) => null);
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

class AppNotifiers {
  static final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
  // Holds the current app locale. When null, system locale is used.
  static final localeProvider = StateProvider<Locale?>((ref) => null);
}
