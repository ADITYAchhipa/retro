import 'package:flutter/foundation.dart';
import '../services/mock_api_service.dart';
import '../database/models/vehicle_model.dart';

/// ========================================
/// 🚗 VEHICLE PROVIDER - BACKEND READY
/// ========================================
/// Handles all vehicle related state and API calls.
class VehicleProvider with ChangeNotifier {
  final RealApiService _realApiService = RealApiService();

  List<VehicleModel> _vehicles = [];
  List<VehicleModel> _featuredVehicles = [];
  List<VehicleModel> _recommendedVehicles = [];
  List<VehicleModel> _nearbyVehicles = [];
  List<VehicleModel> _searchResults = [];

  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  bool _isRecommendedLoading = false;
  bool _isNearbyLoading = false;
  bool _isSearching = false;
  String? _error;

  String? _filterCategory; // e.g., All, SUV, Sedan, Electric, Luxury

  // Getters
  List<VehicleModel> get vehicles => _vehicles;
  List<VehicleModel> get featuredVehicles => _featuredVehicles;
  List<VehicleModel> get recommendedVehicles => _recommendedVehicles;
  List<VehicleModel> get nearbyVehicles => _nearbyVehicles;
  List<VehicleModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;
  bool get isRecommendedLoading => _isRecommendedLoading;
  bool get isNearbyLoading => _isNearbyLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String? get filterCategory => _filterCategory;

  List<VehicleModel> get filteredVehicles => _applyCategoryFilter(_vehicles);
  List<VehicleModel> get filteredFeaturedVehicles => _applyCategoryFilter(
        _featuredVehicles.isNotEmpty ? _featuredVehicles : _vehicles,
      );
  List<VehicleModel> get filteredRecommendedVehicles => _applyCategoryFilter(_recommendedVehicles);
  List<VehicleModel> get filteredNearbyVehicles => _applyCategoryFilter(_nearbyVehicles);

  List<VehicleModel> _applyCategoryFilter(List<VehicleModel> list) {
    final cat = _filterCategory?.trim().toLowerCase();
    if (cat == null || cat.isEmpty || cat == 'all') return list;
    
    // Filter by category field (VehicleModel uses category, not vehicleType)
    // Backend uses vehicleType but frontend model uses category
    return list.where((v) {
      final vehicleCat = v.category.trim().toLowerCase();
      
      // Handle plural forms: 'cars' -> 'car', 'bikes' -> 'bike'
      String normalizedCat = cat;
      if (cat.endsWith('s')) {
        normalizedCat = cat.substring(0, cat.length - 1);
      }
      
      return vehicleCat == normalizedCat || vehicleCat == cat;
    }).toList();
  }

  void setFilterCategory(String? category) {
    _filterCategory = category;
    notifyListeners();
  }

  Future<void> initialize() async {
    await loadFeaturedVehicles();
  }

  Future<void> loadVehicles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _realApiService.getVehicles();
      _vehicles = response.map((v) => VehicleModel.fromJson(v)).toList();
    } catch (e) {
      _error = 'Failed to load vehicles: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFeaturedVehicles({String? category}) async {
    _isFeaturedLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _realApiService.getFeaturedVehicles();
      _featuredVehicles = response.map((v) => VehicleModel.fromJson(v)).toList();
    } catch (e) {
      _error = 'Failed to load featured vehicles: $e';
    } finally {
      _isFeaturedLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecommendedVehicles({String? category}) async {
    _isRecommendedLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _realApiService.getRecommendedVehicles();
      _recommendedVehicles = response.map((v) => VehicleModel.fromJson(v)).toList();
    } catch (e) {
      _error = 'Failed to load recommended vehicles: $e';
    } finally {
      _isRecommendedLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNearbyVehicles({String? category, double? latitude, double? longitude, double? maxDistance}) async {
    _isNearbyLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _realApiService.getNearbyVehicles(
        latitude: latitude,
        longitude: longitude,
        maxDistanceKm: maxDistance ?? 30, // 30km default
      );
      _nearbyVehicles = response.map((v) => VehicleModel.fromJson(v)).toList();
    } catch (e) {
      _error = 'Failed to load nearby vehicles: $e';
    } finally {
      _isNearbyLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchVehicles({String? query, String? category}) async {
    _isSearching = true;
    _error = null;
    notifyListeners();
    try {
      final filters = {
        'query': query,
        'category': category,
      };
      final response = await _realApiService.searchVehicles(filters);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        _searchResults = data.map((v) => VehicleModel.fromJson(v)).toList();
      } else {
        _error = response['message'] ?? 'Search failed';
      }
    } catch (e) {
      _error = 'Search failed: $e';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await Future.wait([
      loadVehicles(),
      loadFeaturedVehicles(),
    ]);
  }
}
