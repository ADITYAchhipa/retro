import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants/api_constants.dart';

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
      // Call backend API
      final url = Uri.parse('${ApiConstants.authBaseUrl}/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (data['success'] == true && data['user'] != null) {
        // Create user from backend response
        final user = User(
          id: data['user']['email'],
          email: data['user']['email'],
          name: data['user']['name'] ?? 'User',
          phone: null,
          role: UserRole.seeker, // Default role, can be determined from backend
        );
        
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          error: null,
        );
      } else {
        throw Exception(data['message'] ?? 'Invalid email or password');
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<void> signUp(String name, String email, String password, UserRole role, {String? phone}) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      // Call backend API
      final url = Uri.parse('${ApiConstants.authBaseUrl}/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone ?? '0000000000', // Use provided phone or default
        }),
      );

      final data = jsonDecode(response.body);
      
      if (data['success'] == true && data['user'] != null) {
        // Create user from backend response
        final user = User(
          id: data['user']['email'],
          email: data['user']['email'],
          name: data['user']['name'] ?? name,
          phone: phone,
          role: role,
        );
        
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          error: null,
        );
      } else {
        // Preserve the exact error message from backend
        final errorMsg = data['message'] ?? 'Registration failed';
        throw Exception(errorMsg);
      }
    } catch (e) {
      // Extract the actual error message without "Exception:" prefix
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: errorMessage,
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      // Call backend API
      final url = Uri.parse('${ApiConstants.authBaseUrl}/logout');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      
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
