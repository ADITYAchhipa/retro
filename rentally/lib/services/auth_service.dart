import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app/app_state.dart';
import '../core/constants/api_constants.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String role; // 'seeker' or 'owner'

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.role,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
    );
  }
}

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Make API call to backend
      final url = Uri.parse('${ApiConstants.authBaseUrl}/login');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (data['success'] == true && data['user'] != null) {
        // Create user from backend response
        final user = User(
          id: data['user']['email'], // Use email as ID if no ID returned
          name: data['user']['name'] ?? 'User',
          email: data['user']['email'],
          role: 'seeker',
          profileImageUrl: null,
        );
        
        state = state.copyWith(user: user, isLoading: false);
      } else {
        // Login failed
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> signUp(String name, String email, String password, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        role: role,
      );
      
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      state = AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updateProfile(User updatedUser) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void switchRole(UserRole newRole) {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(role: newRole.name);
      state = state.copyWith(user: updatedUser);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
