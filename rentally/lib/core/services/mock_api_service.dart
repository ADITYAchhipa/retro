import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

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
  
  Future<List<Map<String, dynamic>>> getFeaturedProperties({String? category}) async {
    try {
      // Build URL with optional category parameter
      String url = '${ApiConstants.baseUrl}/property/featured';
      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        url += '?category=$category';
      }
      
      debugPrint('🔍 Fetching featured properties from: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final results = (data['results'] as List).cast<Map<String, dynamic>>();
          debugPrint('✅ Fetched ${results.length} featured properties');
          return results;
        }
      }
      debugPrint('❌ Failed to fetch featured properties: ${response.statusCode}');
      // Fallback: return mock properties for offline/dev usage
      return await getProperties();
    } catch (e) {
      debugPrint('❌ Error fetching featured properties: $e');
      // Fallback: return mock properties for offline/dev usage
      return await getProperties();
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
}

// Compatibility class name
class RealApiService extends MockApiService {}
