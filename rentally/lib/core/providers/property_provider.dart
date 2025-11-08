import 'package:flutter/foundation.dart';
import '../services/mock_api_service.dart';
import '../database/models/property_model.dart';
import 'featured_cache_provider.dart';

/// ========================================
/// 🏠 PROPERTY PROVIDER - REAL BACKEND INTEGRATION
/// ========================================
/// 
/// This provider handles all property-related operations using your real backend API.
/// Make sure your backend implements all required endpoints before using this provider.
/// 
/// REQUIRED BACKEND ENDPOINTS:
/// - GET /properties?page=1&limit=10 - Get paginated properties
/// - GET /properties/featured - Get featured properties
/// - GET /properties/search?query=... - Search properties
/// - GET /properties/{id} - Get property details
/// 
class PropertyProvider with ChangeNotifier {
  final RealApiService _realApiService = RealApiService();
  final FeaturedCacheProvider? _cacheProvider;
  
  PropertyProvider({FeaturedCacheProvider? cacheProvider}) 
      : _cacheProvider = cacheProvider;

  List<PropertyModel> _properties = [];
  List<PropertyModel> _featuredProperties = [];
  List<PropertyModel> _searchResults = [];
  PropertyModel? _selectedProperty;
  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  bool _isSearching = false;
  String? _error;
  PropertyType? _filterType;
  String _currentCategory = 'all'; // Track current category

  // Getters
  List<PropertyModel> get properties => _properties;
  List<PropertyModel> get featuredProperties => _featuredProperties;
  List<PropertyModel> get searchResults => _searchResults;
  PropertyModel? get selectedProperty => _selectedProperty;
  bool get isLoading => _isLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  PropertyType? get filterType => _filterType;

  // Filtered views
  List<PropertyModel> get filteredProperties =>
      _filterType == null ? _properties : _properties.where((p) => p.type == _filterType).toList();

  // Featured properties are already filtered by category on backend, so return as-is
  List<PropertyModel> get filteredFeaturedProperties => _featuredProperties;

  void setFilterType(PropertyType? type) {
    _filterType = type;
    notifyListeners();
  }

  /// Initialize the provider
  Future<void> initialize() async {
    await loadFeaturedProperties();
  }

  /// Load properties with pagination from real backend
  Future<void> loadProperties({int page = 1, int limit = 10}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _realApiService.getProperties();
      _properties = response.map((p) => PropertyModel.fromJson(p)).toList();
      // Pagination removed as fields were unused
        } catch (e) {
      _error = 'Failed to load properties: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load featured properties for home screen from real backend with caching
  Future<void> loadFeaturedProperties({String category = 'all'}) async {
    _currentCategory = category;
    
    // Check cache first
    if (_cacheProvider != null) {
      final cached = _cacheProvider!.getPropertyCache(category);
      if (cached != null) {
        debugPrint('📦 Loading properties from cache for category: $category');
        _featuredProperties = cached.map((p) => PropertyModel.fromJson(p)).toList();
        notifyListeners();
        return;
      }
    }
    
    // Cache miss - load from backend
    _isFeaturedLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🌐 Fetching properties from backend for category: $category');
      final response = await _realApiService.getFeaturedProperties(category: category);
      _featuredProperties = response.map((p) => PropertyModel.fromJson(p)).toList();
      
      // Cache the result
      if (_cacheProvider != null) {
        _cacheProvider!.setPropertyCache(category, response);
      }
    } catch (e) {
      _error = 'Failed to load featured properties: $e';
      debugPrint('❌ Error loading featured properties: $e');
    } finally {
      _isFeaturedLoading = false;
      notifyListeners();
    }
  }

  /// Search properties using real backend
  Future<void> searchProperties({
    String? query,
    String? location,
    double? minPrice,
    double? maxPrice,
    PropertyType? type,
    int? minBedrooms,
  }) async {
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final filters = {
        'query': query,
        'location': location,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'type': type,
      };
      final response = await _realApiService.searchProperties(filters);
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        _searchResults = data.map((p) => PropertyModel.fromJson(p)).toList();
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

  /// Load property details from real backend
  Future<void> loadPropertyDetails(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _realApiService.getPropertyById(id);
      if (response['success'] == true && response['data'] != null) {
        _selectedProperty = PropertyModel.fromJson(response['data']);
      } else {
        _error = response['message'] ?? 'Property not found';
      }
    } catch (e) {
      _error = 'Failed to load property details: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  /// Clear selected property
  void clearSelectedProperty() {
    _selectedProperty = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      loadProperties(),
      loadFeaturedProperties(),
    ]);
  }
}
