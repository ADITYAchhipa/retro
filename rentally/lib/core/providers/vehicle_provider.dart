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
  List<VehicleModel> _searchResults = [];

  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  bool _isSearching = false;
  String? _error;

  String? _filterCategory; // e.g., All, SUV, Sedan, Electric, Luxury

  // Getters
  List<VehicleModel> get vehicles => _vehicles;
  List<VehicleModel> get featuredVehicles => _featuredVehicles;
  List<VehicleModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String? get filterCategory => _filterCategory;

  List<VehicleModel> get filteredVehicles => _applyCategoryFilter(_vehicles);
  // If no featured list is present, gracefully fall back to the full vehicle list
  List<VehicleModel> get filteredFeaturedVehicles => _applyCategoryFilter(
        _featuredVehicles.isNotEmpty ? _featuredVehicles : _vehicles,
      );

  List<VehicleModel> _applyCategoryFilter(List<VehicleModel> list) {
    final cat = _filterCategory?.trim().toLowerCase();
    if (cat == null || cat.isEmpty || cat == 'all' || cat == 'cars') return list;
    return list.where((v) {
      final c = v.category.toString().trim().toLowerCase();
      final title = v.title.toLowerCase();
      if (cat == 'electric') return c == 'electric';
      if (cat == 'suv') return c == 'suv';
      if (cat == 'sedan') return c == 'sedan';
      if (cat == 'luxury') return c == 'luxury' || title.contains('luxury');
      if (cat == 'hatchback') return title.contains('hatch');
      if (cat == 'trucks' || cat == 'truck') return title.contains('truck') || c == 'truck';
      if (cat == 'vans' || cat == 'van') return title.contains('van') || c == 'van';
      if (cat == 'convertible') return title.contains('convertible') || c == 'convertible';
      if (cat == 'bikes' || cat == 'bike') return title.contains('bike');
      if (cat == 'scooters' || cat == 'scooter') return title.contains('scooter');
      return true;
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

  Future<void> loadFeaturedVehicles() async {
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
