import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../services/token_storage_service.dart';

/// Mock API Service for development
class MockApiService {
  MockApiService();
  
  // Authentication
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'token': 'mock_jwt_token_12345',
      'user': {
        'id': '1',
        'email': email,
        'name': 'Test User',
        'role': 'seeker',
      }
    };
  }

  // Nearby: Properties from real backend
  Future<List<Map<String, dynamic>>> getNearbyProperties({
    double? latitude,
    double? longitude,
    String? city,
    double maxDistanceKm = 10,
    bool debug = false,
  }) async {
    try {
      final params = <String, String>{
        'maxDistance': maxDistanceKm.toString(),
      };
      if (latitude != null && longitude != null) {
        params['latitude'] = latitude.toString();
        params['longitude'] = longitude.toString();
      }
      if (city != null && city.isNotEmpty) params['city'] = city;
      if (debug) params['debug'] = '1';

      final uri = Uri.parse('${ApiConstants.baseUrl}/nearby/properties').replace(queryParameters: params);
      debugPrint('📍 Fetching nearby properties: $uri');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>?;
          final list = (data?['properties'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
          debugPrint('✅ Nearby properties fetched: ${list.length}');
          return list;
        }
      }
      debugPrint('❌ Nearby properties request failed: ${response.statusCode}\n${response.body}');
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('💥 Error fetching nearby properties: $e');
      return <Map<String, dynamic>>[];
    }
  }

  // Nearby: Vehicles from real backend
  Future<List<Map<String, dynamic>>> getNearbyVehicles({
    double? latitude,
    double? longitude,
    String? city,
    double maxDistanceKm = 10,
    bool debug = false,
  }) async {
    try {
      final params = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'maxDistance': maxDistanceKm.toString(),
      };
      if (city != null && city.isNotEmpty) params['city'] = city;
      if (debug) params['debug'] = '1';

      final uri = Uri.parse('${ApiConstants.baseUrl}/nearby/vehicles').replace(queryParameters: params);
      debugPrint('🚗 Fetching nearby vehicles: $uri');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>?;
          final list = (data?['vehicles'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
          debugPrint('✅ Nearby vehicles fetched: ${list.length}');
          return list;
        }
      }
      debugPrint('❌ Nearby vehicles request failed: ${response.statusCode}\n${response.body}');
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('💥 Error fetching nearby vehicles: $e');
      return <Map<String, dynamic>>[];
    }
  }
  
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'success': true,
      'message': 'Registration successful',
    };
  }
  
  // Properties
  Future<List<Map<String, dynamic>>> getProperties() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': '1',
        'title': 'Modern Apartment in Downtown',
        'price': 1200,
        'location': 'Downtown, City',
        'imageUrl': 'https://picsum.photos/400/300?random=1',
        'rating': 4.5,
        'type': 'apartment',
        'latitude': 37.7749,
        'longitude': -122.4194,
      },
      {
        'id': '2',
        'title': 'Cozy Studio Near University',
        'price': 800,
        'location': 'University District',
        'imageUrl': 'https://picsum.photos/400/300?random=2',
        'rating': 4.2,
        'type': 'studio',
        'latitude': 37.7849,
        'longitude': -122.4094,
      },
    ];
  }
  
  // Bookings
  Future<List<Map<String, dynamic>>> getBookings() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': 'B001',
        'propertyId': '1',
        'propertyTitle': 'Modern Apartment',
        'checkIn': DateTime.now().add(const Duration(days: 7)),
        'checkOut': DateTime.now().add(const Duration(days: 14)),
        'status': 'confirmed',
        'totalAmount': 8400,
      },
    ];
  }
  
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'success': true,
      'bookingId': 'B${DateTime.now().millisecondsSinceEpoch}',
      'message': 'Booking confirmed',
    };
  }
  
  // User
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'id': userId,
      'name': 'John Doe',
      'email': 'john@example.com',
      'phone': '+1234567890',
      'avatar': 'https://picsum.photos/200/200?random=user',
      'role': 'seeker',
    };
  }
  
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'success': true,
      'message': 'Profile updated successfully',
    };
  }

  // Extended API methods
  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    return getBookings();
  }
  
  Future<List<Map<String, dynamic>>> getFeaturedProperties({
    String? category,
    int page = 1,
    int limit = 10,
    List<String> excludeIds = const [],
  }) async {
    try {
      // Build URL with pagination and duplicate prevention
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      // Add category filter if provided and not 'all'
      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        params['category'] = category; // Send as-is, backend handles normalization
      }
      
      // Add excludeIds for duplicate prevention
      if (excludeIds.isNotEmpty) {
        params['excludeIds'] = excludeIds.join(',');
      }
      
      final uri = Uri.parse('${ApiConstants.baseUrl}/featured/properties')
          .replace(queryParameters: params);
      
      debugPrint('🔍 Fetching featured properties: $uri');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final results = (data['results'] as List).cast<Map<String, dynamic>>();
          debugPrint('✅ Fetched ${results.length} featured properties (page $page)');
          return results;
        }
      }
      debugPrint('❌ Failed to fetch featured properties: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching featured properties: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> searchProperties(Map<String, dynamic> filters) async {
    final properties = await getProperties();
    return {
      'success': true,
      'data': properties,
      'total': properties.length,
    };
  }
  
  Future<Map<String, dynamic>> getPropertyById(String id) async {
    final properties = await getProperties();
    return {
      'success': true,
      'data': properties.firstWhere((p) => p['id'] == id, orElse: () => properties.first),
    };
  }

  // Vehicles (mock-first)
  Future<List<Map<String, dynamic>>> getVehicles() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      {
        'id': 'v1',
        'title': 'BMW X5 SUV',
        'location': 'Airport District',
        'price': 85.0,
        'imageUrl': 'https://picsum.photos/400/300?random=10',
        'rating': 4.8,
        'reviews': 128,
        'category': 'SUV',
        'seats': 5,
        'transmission': 'Auto',
        'fuel': 'Petrol',
        'isFeatured': true,
        'latitude': 37.6152,
        'longitude': -122.3899,
      },
      {
        'id': 'v2',
        'title': 'Tesla Model 3',
        'location': 'Tech District',
        'price': 75.0,
        'imageUrl': 'https://picsum.photos/400/300?random=11',
        'rating': 4.9,
        'reviews': 210,
        'category': 'Electric',
        'seats': 5,
        'transmission': 'Auto',
        'fuel': 'Electric',
        'isFeatured': true,
        'latitude': 37.3875,
        'longitude': -122.0575,
      },
      {
        'id': 'v3',
        'title': 'Mercedes C-Class',
        'location': 'Business District',
        'price': 90.0,
        'imageUrl': 'https://picsum.photos/400/300?random=12',
        'rating': 4.7,
        'reviews': 86,
        'category': 'Sedan',
        'seats': 5,
        'transmission': 'Auto',
        'fuel': 'Petrol',
        'isFeatured': true,
        'latitude': 37.7936,
        'longitude': -122.3965,
      },
    ];
  }

  // Personalized Recommendations
  Future<List<Map<String, dynamic>>> getRecommendedProperties({
    String category = 'all',
  }) async {
    try {
      final params = <String, String>{
        'category': category,
      };

      final uri = Uri.parse('${ApiConstants.baseUrl}/recommended/properties').replace(queryParameters: params);
      debugPrint('🎯 Fetching recommended properties: $uri');
      
      // Get JWT token from storage
      final token = await TokenStorageService.getToken();
      debugPrint('🔑 Token available: ${token != null}');
      
      // Include Authorization header with token
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(uri, headers: headers);
      
      debugPrint('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        
        if (body['success'] == true) {
          final list = (body['results'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
          debugPrint('✅ Recommended properties fetched: ${list.length}');
          return list;
        } else {
          debugPrint('⚠️ Backend returned success=false: ${body['message'] ?? 'No message'}');
        }
      }
      debugPrint('❌ Recommended properties request failed: ${response.statusCode}');
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('💥 Error fetching recommended properties: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> getRecommendedVehicles({
    String category = 'all',
  }) async {
    try {
      final params = <String, String>{
        'category': category,
      };

      final uri = Uri.parse('${ApiConstants.baseUrl}/recommended/vehicles').replace(queryParameters: params);
      debugPrint('🎯 Fetching recommended vehicles: $uri');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final list = (body['results'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
          debugPrint('✅ Recommended vehicles fetched: ${list.length}');
          return list;
        }
      }
      debugPrint('❌ Recommended vehicles request failed: ${response.statusCode}\n${response.body}');
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('💥 Error fetching recommended vehicles: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> getFeaturedVehicles() async {
    return getVehicles();
  }

  Future<Map<String, dynamic>> searchVehicles(Map<String, dynamic> filters) async {
    final vehicles = await getVehicles();
    return {
      'success': true,
      'data': vehicles,
      'total': vehicles.length,
    };
  }

  Future<Map<String, dynamic>> getVehicleById(String id) async {
    final vehicles = await getVehicles();
    return {
      'success': true,
      'data': vehicles.firstWhere((v) => v['id'] == id, orElse: () => vehicles.first),
    };
  }

  /// Get user's visited properties from backend
  Future<List<Map<String, dynamic>>> getVisitedProperties({int limit = 10}) async {
    try {
      final token = await TokenStorageService.getToken();
      if (token == null) {
        debugPrint('⚠️ No token - cannot fetch visited properties');
        return <Map<String, dynamic>>[];
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/user/visited?limit=$limit');
      debugPrint('📍 Fetching visited properties: $uri');
      
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final results = (body['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          debugPrint('✅ Visited properties fetched: ${results.length}');
          return results;
        }
      }
      debugPrint('❌ Visited properties request failed: ${response.statusCode}');
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('💥 Error fetching visited properties: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Add property to user's visited list
  Future<bool> addToVisited(String propertyId) async {
    try {
      final token = await TokenStorageService.getToken();
      if (token == null) return false;

      final uri = Uri.parse('${ApiConstants.baseUrl}/user/visited/$propertyId');
      final response = await http.post(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('💥 Error adding to visited: $e');
      return false;
    }
  }
}

// Compatibility class name
class RealApiService extends MockApiService {}
