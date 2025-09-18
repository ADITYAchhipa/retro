import 'package:flutter/foundation.dart';
import '../services/mock_api_service.dart';
import '../database/models/user_model.dart';

/// Provider for managing user data and authentication state
class UserProvider with ChangeNotifier {
  final RealApiService _realApiService = RealApiService();

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize the provider
  Future<void> initialize() async {
    // In a real app, you'd check for stored auth tokens here
    await _loadStoredUser();
  }

  /// Update core profile fields (first/last name, phone, email, avatar)
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    String? avatar,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API latency
      await Future.delayed(const Duration(milliseconds: 600));

      _currentUser = _currentUser!.copyWith(
        firstName: firstName ?? _currentUser!.firstName,
        lastName: lastName ?? _currentUser!.lastName,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        email: email ?? _currentUser!.email,
        avatar: avatar ?? _currentUser!.avatar,
        updatedAt: DateTime.now(),
      );

      await _storeUserData(_currentUser!, null);
      return true;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Authenticate user with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _realApiService.login(email, password);
      if (response['token'] != null && response['user'] != null) {
        _currentUser = UserModel.fromJson(response['user']);
        _isAuthenticated = true;
        return true;
      } else {
        _isAuthenticated = false;
        return false;
      }
    } catch (e) {
      _error = 'Login failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user (simulated)
  Future<bool> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate registration delay
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // In a real app, this would call the registration API
      // For now, we'll simulate a successful registration
      final newUser = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: UserRole.guest,
        isVerified: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        preferences: UserPreferences(
          currency: 'USD',
          language: 'en',
          darkMode: false,
          notifications: true,
          emailUpdates: true,
        ),
        stats: UserStats(
          totalBookings: 0,
          totalProperties: 0,
          totalEarnings: 0,
          averageRating: 0,
          reviewCount: 0,
          referralCount: 0,
          tokenBalance: 100, // Welcome bonus
        ),
      );

      _currentUser = newUser;
      _isAuthenticated = true;
      _error = null;
      
      await _storeUserData(newUser, 'mock_token_${newUser.id}');
      
      return true;
    } catch (e) {
      _error = 'Registration failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user profile
  Future<void> loadUserProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _realApiService.getUserProfile(userId);
      if (response['id'] != null) {
        _currentUser = UserModel.fromJson(response);
      } else {
        _error = response['message'] ?? 'Failed to load profile';
      }
    } catch (e) {
      _error = 'Failed to load user profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user preferences
  Future<bool> updatePreferences(UserPreferences preferences) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentUser = _currentUser!.copyWith(
        preferences: preferences,
        updatedAt: DateTime.now(),
      );
      
      await _storeUserData(_currentUser!, null);
      
      return true;
    } catch (e) {
      _error = 'Failed to update preferences: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switch user role
  Future<bool> switchRole(UserRole newRole) async {
    // Frontend-only fallback: if there's no user yet, create a lightweight guest user
    if (_currentUser == null) {
      _currentUser = UserModel(
        id: 'guest',
        email: 'user@example.com',
        firstName: 'User',
        lastName: 'Guest',
        role: newRole,
        isVerified: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        preferences: UserPreferences(
          currency: 'USD',
          language: 'en',
          darkMode: false,
          notifications: true,
          emailUpdates: true,
        ),
        stats: UserStats(
          totalBookings: 0,
          totalProperties: 0,
          totalEarnings: 0,
          averageRating: 0,
          reviewCount: 0,
          referralCount: 0,
          tokenBalance: 0,
        ),
      );
      notifyListeners();
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentUser = _currentUser!.copyWith(
        role: newRole,
        updatedAt: DateTime.now(),
      );
      
      await _storeUserData(_currentUser!, null);
      
      return true;
    } catch (e) {
      _error = 'Failed to switch role: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout user
  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    _error = null;
    
    // In a real app, you'd clear stored tokens here
    await _clearStoredData();
    
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private methods for data persistence (simulated)
  Future<void> _loadStoredUser() async {
    // In a real app, you'd load from secure storage
    // For demo purposes, we'll simulate having a stored user
    await Future.delayed(const Duration(milliseconds: 200));
    
    // In a real app, check for stored auth tokens and validate with backend
    try {
      final response = await _realApiService.getUserProfile('stored_user_id');
      if (response['id'] != null) {
        _currentUser = UserModel.fromJson(response);
      } else {
        _error = response['message'] ?? 'Failed to load profile';
      }
    } catch (e) {
      // No stored user found
    }
  }

  Future<void> _storeUserData(UserModel user, String? token) async {
    // In a real app, you'd store in secure storage
    await Future.delayed(const Duration(milliseconds: 100));
    // Simulate storing user data and auth token
  }

  Future<void> _clearStoredData() async {
    // In a real app, you'd clear from secure storage
    await Future.delayed(const Duration(milliseconds: 100));
    // Simulate clearing stored data
  }
}
