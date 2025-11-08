import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/listing.dart';

/// Service to cache featured properties and vehicles
/// Fetches data once and stores it until app refresh
class FeaturedCacheService {
  static final FeaturedCacheService _instance = FeaturedCacheService._internal();
  factory FeaturedCacheService() => _instance;
  FeaturedCacheService._internal();

  // Cache storage
  List<Listing>? _cachedProperties;
  List<Listing>? _cachedVehicles;

  // Loading states
  bool _isLoadingProperties = false;
  bool _isLoadingVehicles = false;

  // API base URL - update this to match your backend
  static const String baseUrl = 'http://localhost:3000/api';

  /// Get featured properties (cached)
  Future<List<Listing>> getFeaturedProperties({bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (_cachedProperties != null && !forceRefresh) {
      return _cachedProperties!;
    }

    // Prevent multiple simultaneous requests
    if (_isLoadingProperties) {
      // Wait for existing request to complete
      while (_isLoadingProperties) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedProperties ?? [];
    }

    _isLoadingProperties = true;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/property/featured'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _cachedProperties = data.map((json) => Listing.fromJson(json)).toList();
        return _cachedProperties!;
      } else {
        throw Exception('Failed to load featured properties: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching featured properties: $e');
      return _cachedProperties ?? [];
    } finally {
      _isLoadingProperties = false;
    }
  }

  /// Get featured vehicles (cached)
  Future<List<Listing>> getFeaturedVehicles({bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (_cachedVehicles != null && !forceRefresh) {
      return _cachedVehicles!;
    }

    // Prevent multiple simultaneous requests
    if (_isLoadingVehicles) {
      // Wait for existing request to complete
      while (_isLoadingVehicles) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedVehicles ?? [];
    }

    _isLoadingVehicles = true;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicle/featured'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _cachedVehicles = data.map((json) => Listing.fromJson(json)).toList();
        return _cachedVehicles!;
      } else {
        throw Exception('Failed to load featured vehicles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching featured vehicles: $e');
      return _cachedVehicles ?? [];
    } finally {
      _isLoadingVehicles = false;
    }
  }

  /// Check if properties are cached
  bool get hasPropertyCache => _cachedProperties != null;

  /// Check if vehicles are cached
  bool get hasVehicleCache => _cachedVehicles != null;

  /// Clear all cache
  void clearCache() {
    _cachedProperties = null;
    _cachedVehicles = null;
  }

  /// Clear property cache only
  void clearPropertyCache() {
    _cachedProperties = null;
  }

  /// Clear vehicle cache only
  void clearVehicleCache() {
    _cachedVehicles = null;
  }

  /// Get cache status for debugging
  Map<String, dynamic> getCacheStatus() {
    return {
      'properties': {
        'cached': hasPropertyCache,
        'count': _cachedProperties?.length ?? 0,
      },
      'vehicles': {
        'cached': hasVehicleCache,
        'count': _cachedVehicles?.length ?? 0,
      },
    };
  }
}
