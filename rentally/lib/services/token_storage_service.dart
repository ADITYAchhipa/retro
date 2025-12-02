import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for securely storing and retrieving JWT authentication tokens
/// 
/// Uses platform-specific secure storage:
/// - iOS: Keychain
/// - Android: KeyStore (AES encryption)
/// - Web: SharedPreferences (flutter_secure_storage has issues on web)
/// - Desktop: Platform-specific secure storage
class TokenStorageService {
  // Private constructor to prevent instantiation
  TokenStorageService._();

  /// Singleton instance of FlutterSecureStorage (for mobile/desktop)
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Storage key for JWT token
  static const String _tokenKey = 'jwt_auth_token';

  /// Storage key for refresh token (future use)
  static const String _refreshTokenKey = 'jwt_refresh_token';

  /// Check if running on web platform
  static bool get _isWeb => kIsWeb;

  /// Save JWT token to secure storage
  /// 
  /// [token] The JWT token string to save
  /// 
  /// Example:
  /// ```dart
  /// await TokenStorageService.saveToken('eyJhbGciOiJIUzI1NiIs...');
  /// ```
  static Future<void> saveToken(String token) async {
    try {
      if (_isWeb) {
        // Use SharedPreferences for web
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
      } else {
        // Use secure storage for mobile/desktop
        await _storage.write(key: _tokenKey, value: token);
      }
      
      if (kDebugMode) {
        debugPrint('✅ JWT token saved successfully');
      }
    } catch (e) {
      debugPrint('❌ Error saving JWT token: $e');
      rethrow;
    }
  }

  /// Retrieve JWT token from secure storage
  /// 
  /// Returns the JWT token string or null if not found
  /// 
  /// Example:
  /// ```dart
  /// final token = await TokenStorageService.getToken();
  /// if (token != null) {
  ///   // Use token for API requests
  /// }
  /// ```
  static Future<String?> getToken() async {
    try {
      String? token;
      
      if (_isWeb) {
        // Use SharedPreferences for web
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString(_tokenKey);
      } else {
        // Use secure storage for mobile/desktop
        token = await _storage.read(key: _tokenKey);
      }
      
      if (kDebugMode) {
        if (token != null) {
          debugPrint('✅ JWT token retrieved successfully');
        } else {
          debugPrint('⚠️ No JWT token found in storage');
        }
      }
      return token;
    } catch (e) {
      debugPrint('❌ Error retrieving JWT token: $e');
      return null;
    }
  }

  /// Delete JWT token from secure storage
  /// 
  /// Called during logout to clear authentication
  /// 
  /// Example:
  /// ```dart
  /// await TokenStorageService.deleteToken();
  /// ```
  static Future<void> deleteToken() async {
    try {
      if (_isWeb) {
        // Use SharedPreferences for web
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
      } else {
        // Use secure storage for mobile/desktop
        await _storage.delete(key: _tokenKey);
      }
      
      if (kDebugMode) {
        debugPrint('✅ JWT token deleted successfully');
      }
    } catch (e) {
      debugPrint('❌ Error deleting JWT token: $e');
      rethrow;
    }
  }

  /// Save refresh token to secure storage (for future implementation)
  /// 
  /// [refreshToken] The refresh token string to save
  static Future<void> saveRefreshToken(String refreshToken) async {
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_refreshTokenKey, refreshToken);
      } else {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }
      
      if (kDebugMode) {
        debugPrint('✅ Refresh token saved successfully');
      }
    } catch (e) {
      debugPrint('❌ Error saving refresh token: $e');
      rethrow;
    }
  }

  /// Retrieve refresh token from secure storage
  /// 
  /// Returns the refresh token string or null if not found
  static Future<String?> getRefreshToken() async {
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_refreshTokenKey);
      } else {
        return await _storage.read(key: _refreshTokenKey);
      }
    } catch (e) {
      debugPrint('❌ Error retrieving refresh token: $e');
      return null;
    }
  }

  /// Delete refresh token from secure storage
  static Future<void> deleteRefreshToken() async {
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_refreshTokenKey);
      } else {
        await _storage.delete(key: _refreshTokenKey);
      }
      
      if (kDebugMode) {
        debugPrint('✅ Refresh token deleted successfully');
      }
    } catch (e) {
      debugPrint('❌ Error deleting refresh token: $e');
      rethrow;
    }
  }

  /// Clear all stored tokens (logout)
  /// 
  /// Deletes both JWT token and refresh token
  /// 
  /// Example:
  /// ```dart
  /// await TokenStorageService.clearAllTokens();
  /// ```
  static Future<void> clearAllTokens() async {
    try {
      await Future.wait([
        deleteToken(),
        deleteRefreshToken(),
      ]);
      if (kDebugMode) {
        debugPrint('✅ All tokens cleared successfully');
      }
    } catch (e) {
      debugPrint('❌ Error clearing tokens: $e');
      rethrow;
    }
  }

  /// Check if a valid token exists
  /// 
  /// Returns true if a token is stored, false otherwise
  /// Note: This only checks if token exists, not if it's valid
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

