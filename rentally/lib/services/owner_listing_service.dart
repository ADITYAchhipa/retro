// Owner Listing Service
// Fetches owner's properties and vehicles from backend

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'token_storage_service.dart';

class OwnerListingService {
  /// Fetch all listings (properties + vehicles) for the logged-in owner
  static Future<Map<String, dynamic>> getOwnerListings() async {
    try {
      final token = await TokenStorageService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/owner/listings');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📦 [OwnerService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'listings': List<Map<String, dynamic>>.from(data['listings'] ?? []),
            'counts': Map<String, dynamic>.from(data['counts'] ?? {}),
          };
        }
        throw Exception(data['message'] ?? 'Failed to fetch listings');
      } else {
        throw Exception('Failed to fetch listings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [OwnerService] Error: $e');
      rethrow;
    }
  }

  /// Sort listings based on sort key
  static List<Map<String, dynamic>> sortListings(
    List<Map<String, dynamic>> listings,
    String sortKey,
  ) {
    final sorted = List<Map<String, dynamic>>.from(listings);
    
    switch (sortKey) {
      case 'price_low':
        sorted.sort((a, b) => ((a['price'] ?? 0) as num).compareTo((b['price'] ?? 0) as num));
        break;
      case 'price_high':
        sorted.sort((a, b) => ((b['price'] ?? 0) as num).compareTo((a['price'] ?? 0) as num));
        break;
      case 'rating':
        sorted.sort((a, b) => ((b['rating'] ?? 0) as num).compareTo((a['rating'] ?? 0) as num));
        break;
      case 'bookings':
        sorted.sort((a, b) => ((b['bookings'] ?? 0) as num).compareTo((a['bookings'] ?? 0) as num));
        break;
      case 'recent':
      default:
        sorted.sort((a, b) {
          final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(2000);
          final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        break;
    }
    
    return sorted;
  }

  /// Filter listings by status
  static List<Map<String, dynamic>> filterByStatus(
    List<Map<String, dynamic>> listings,
    String statusFilter,
  ) {
    if (statusFilter == 'all') {
      return listings;
    }
    
    // Map frontend filter keys to backend status values
    String backendStatus;
    switch (statusFilter) {
      case 'active':
        backendStatus = 'active';
        break;
      case 'inactive':
        backendStatus = 'inactive';
        break;
      case 'pending':
        backendStatus = 'suspended';
        break;
      default:
        return listings;
    }
    
    return listings.where((l) => l['status'] == backendStatus).toList();
  }
}
