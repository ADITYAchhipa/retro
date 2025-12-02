import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import 'token_storage_service.dart';

/// Centralized API service for making HTTP requests with automatic JWT token injection
/// 
/// Automatically adds Authorization headers to all requests
/// Handles common HTTP methods: GET, POST, PUT, DELETE
class ApiService {
  ApiService._();

  /// Get default headers including JWT token if available
  static Future<Map<String, String>> _getHeaders({Map<String, String>? extraHeaders}) async {
    final headers = Map<String, String>.from(ApiConstants.defaultHeaders);
    
    // Add JWT token if available
    final token = await TokenStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    // Add any extra headers
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    
    return headers;
  }

  /// Make a GET request
  /// 
  /// [endpoint] API endpoint (relative to baseUrl)
  /// [headers] Optional additional headers
  /// 
  /// Returns the response or throws an exception
  /// 
  /// Example:
  /// ```dart
  /// final response = await ApiService.get('/properties');
  /// ```
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final requestHeaders = await _getHeaders(extraHeaders: headers);
      
      if (kDebugMode) {
        debugPrint('📡 GET $url');
      }
      
      final response = await http.get(url, headers: requestHeaders);
      
      if (kDebugMode) {
        debugPrint('📥 Response ${response.statusCode}');
      }
      
      _handleErrorResponse(response);
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ GET request failed: $e');
      }
      rethrow;
    }
  }

  /// Make a POST request
  /// 
  /// [endpoint] API endpoint (relative to baseUrl)
  /// [body] Request body (will be JSON encoded)
  /// [headers] Optional additional headers
  /// 
  /// Returns the response or throws an exception
  /// 
  /// Example:
  /// ```dart
  /// final response = await ApiService.post('/login', body: {
  ///   'email': 'user@example.com',
  ///   'password': 'password123',
  /// });
  /// ```
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final requestHeaders = await _getHeaders(extraHeaders: headers);
      
      if (kDebugMode) {
        debugPrint('📡 POST $url');
        if (body != null) {
          debugPrint('📤 Body: ${jsonEncode(body)}');
        }
      }
      
      final response = await http.post(
        url,
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      
      if (kDebugMode) {
        debugPrint('📥 Response ${response.statusCode}');
      }
      
      _handleErrorResponse(response);
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ POST request failed: $e');
      }
      rethrow;
    }
  }

  /// Make a PUT request
  /// 
  /// [endpoint] API endpoint (relative to baseUrl)
  /// [body] Request body (will be JSON encoded)
  /// [headers] Optional additional headers
  /// 
  /// Returns the response or throws an exception
  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final requestHeaders = await _getHeaders(extraHeaders: headers);
      
      if (kDebugMode) {
        debugPrint('📡 PUT $url');
      }
      
      final response = await http.put(
        url,
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      
      if (kDebugMode) {
        debugPrint('📥 Response ${response.statusCode}');
      }
      
      _handleErrorResponse(response);
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PUT request failed: $e');
      }
      rethrow;
    }
  }

  /// Make a DELETE request
  /// 
  /// [endpoint] API endpoint (relative to baseUrl)
  /// [headers] Optional additional headers
  /// 
  /// Returns the response or throws an exception
  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final requestHeaders = await _getHeaders(extraHeaders: headers);
      
      if (kDebugMode) {
        debugPrint('📡 DELETE $url');
      }
      
      final response = await http.delete(url, headers: requestHeaders);
      
      if (kDebugMode) {
        debugPrint('📥 Response ${response.statusCode}');
      }
      
      _handleErrorResponse(response);
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ DELETE request failed: $e');
      }
      rethrow;
    }
  }

  /// Handle error responses
  /// 
  /// Throws appropriate exceptions for error status codes
  static void _handleErrorResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return; // Success
    }

    // Handle error responses
    switch (response.statusCode) {
      case 401:
        throw Exception('Unauthorized: Please login again');
      case 403:
        throw Exception('Forbidden: You don\'t have permission to access this resource');
      case 404:
        throw Exception('Not Found: The requested resource was not found');
      case 500:
        throw Exception('Server Error: Please try again later');
      default:
        throw Exception('Request failed with status ${response.statusCode}');
    }
  }
}
