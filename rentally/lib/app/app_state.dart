import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/config/dev_config.dart';
import '../services/token_storage_service.dart';

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
  AuthNotifier() : super(const AuthState(status: AuthStatus.initial)) {
    _restoreSession();
  }

  static const _authUserKey = 'auth_user';
  static const _authStatusKey = 'auth_status';

  Future<void> _restoreSession() async {
    // Start in loading state while we check for a persisted session
    state = state.copyWith(status: AuthStatus.loading);

    try {
      // Check if JWT token exists in secure storage
      final token = await TokenStorageService.getToken();
      
      if (token != null && token.isNotEmpty) {
        // Validate token with backend
        try {
          final url = Uri.parse('${ApiConstants.authBaseUrl}/is-auth');
          final response = await http.get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            
            if (data['success'] == true && data['user'] != null) {
              // Token is valid, restore user from backend response
              final userData = data['user'];
              final roleString = userData['role'] as String? ?? 'seeker';
              final role = roleString == 'owner' ? UserRole.owner : UserRole.seeker;

              final user = User(
                id: userData['_id'] ?? userData['email'] ?? '',
                email: userData['email'] as String? ?? '',
                name: userData['name'] as String? ?? 'User',
                phone: userData['phone'] as String?,
                role: role,
                profileImageUrl: userData['profileImageUrl'] as String?,
                isKycVerified: userData['isKycVerified'] as bool? ?? false,
              );

              state = state.copyWith(
                status: AuthStatus.authenticated,
                user: user,
                error: null,
              );
              
              // Persist session to SharedPreferences as well
              await _persistSession();
              
              debugPrint('✅ Token validated successfully, user authenticated');
              return;
            }
          }
        } catch (e) {
          debugPrint('❌ Token validation failed: $e');
        }
        
        // Invalid token, clear storage
        await TokenStorageService.deleteToken();
      }
      
      // No valid token, check SharedPreferences as fallback
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_authUserKey);
      final statusIndex = prefs.getInt(_authStatusKey);

      if (userJson != null && statusIndex != null &&
          AuthStatus.values[statusIndex] == AuthStatus.authenticated) {
        final data = jsonDecode(userJson) as Map<String, dynamic>;
        final roleString = data['role'] as String? ?? 'seeker';
        final role = roleString == 'owner' ? UserRole.owner : UserRole.seeker;

        final user = User(
          id: data['id'] as String? ?? '',
          email: data['email'] as String? ?? '',
          name: data['name'] as String? ?? 'User',
          phone: data['phone'] as String?,
          role: role,
          profileImageUrl: data['profileImageUrl'] as String?,
          isKycVerified: data['isKycVerified'] as bool? ?? false,
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          error: null,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('❌ Error restoring session: $e');
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (state.status == AuthStatus.authenticated && state.user != null) {
        final user = state.user!;
        final payload = <String, dynamic>{
          'id': user.id,
          'email': user.email,
          'name': user.name,
          'phone': user.phone,
          'role': user.role.name,
          'profileImageUrl': user.profileImageUrl,
          'isKycVerified': user.isKycVerified,
        };

        await prefs.setString(_authUserKey, jsonEncode(payload));
        await prefs.setInt(_authStatusKey, AuthStatus.authenticated.index);
      } else {
        await prefs.remove(_authUserKey);
        await prefs.remove(_authStatusKey);
      }
    } catch (_) {
      // Ignore persistence errors to avoid blocking auth flow
    }
  }

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
        // Store JWT token from response
        if (data['token'] != null) {
          await TokenStorageService.saveToken(data['token']);
          debugPrint('✅ JWT token saved on login');
        }
        
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
        await _persistSession();
      } else {
        throw Exception(data['message'] ?? 'Invalid email or password');
      }
    } catch (e) {
      // No fallback - always use backend authentication
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Login failed: ${e.toString()}',
      );
      await _persistSession();
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
        // Store JWT token from response
        if (data['token'] != null) {
          await TokenStorageService.saveToken(data['token']);
          debugPrint('✅ JWT token saved on registration');
        }
        
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
        await _persistSession();
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
      
      // Keep status as initial (not unauthenticated) to prevent redirect to login page
      state = state.copyWith(
        status: AuthStatus.initial,
        error: errorMessage,
      );
      // Don't persist session on registration failure
      // Rethrow error so registration screen can display toast notification
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    // Always clear tokens and set unauthenticated state, even if there are errors
    try {
      // Try to clear JWT tokens from secure storage
      try {
        await TokenStorageService.clearAllTokens();
        debugPrint('✅ JWT tokens cleared on logout');
      } catch (tokenError) {
        debugPrint('⚠️ Error clearing tokens (non-critical): $tokenError');
        // Continue with logout even if token deletion fails
      }
      
      // Try to call backend API
      try {
        final url = Uri.parse('${ApiConstants.authBaseUrl}/logout');
        await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        debugPrint('✅ Backend logout successful');
      } catch (backendError) {
        debugPrint('⚠️ Backend logout error (non-critical): $backendError');
        // Continue with logout even if backend call fails
      }
    } finally {
      // ALWAYS set unauthenticated status, no matter what
      state = const AuthState(status: AuthStatus.unauthenticated);
      await _persistSession();
      debugPrint('✅ Logout complete - redirecting to login');
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
    } finally {
      await _persistSession();
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
