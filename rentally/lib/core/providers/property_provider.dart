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
  List<PropertyModel> _recommendedProperties = []; // Personalized recommendations
  List<PropertyModel> _searchResults = [];
  PropertyModel? _selectedProperty;
  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  bool _isLoadingMore = false; // Separate flag for pagination
  bool _isRecommendedLoading = false; // For recommendations
  bool _isSearching = false;
  String? _error;
  PropertyType? _filterType;

  // Getters
  List<PropertyModel> get properties => _properties;
  List<PropertyModel> get featuredProperties => _featuredProperties;
  List<PropertyModel> get recommendedProperties => _recommendedProperties; // Recommendations getter
  List<PropertyModel> get searchResults => _searchResults;
  PropertyModel? get selectedProperty => _selectedProperty;
  bool get isLoading => _isLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;
  bool get isLoadingMore => _isLoadingMore; // Getter for pagination loading
  bool get isRecommendedLoading => _isRecommendedLoading; // Getter for recommendations loading
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

  // Pagination state
  int _currentPage = 1;
  bool _hasMoreProperties = true;
  final Set<String> _loadedPropertyIds = {};
  
  // Getters for pagination
  bool get hasMoreProperties => _hasMoreProperties;
  int get currentPage => _currentPage;
  Set<String> get loadedPropertyIds => _loadedPropertyIds;

  /// Load featured properties for home screen with infinite scroll support
  Future<void> loadFeaturedProperties({
    String category = 'all',
    bool loadMore = false,
  }) async {
    
    // If loading more, just append. Otherwise, reset everything
    if (!loadMore) {
      _currentPage = 1;
      _loadedPropertyIds.clear();
      _featuredProperties = [];
      _hasMoreProperties = true;
    }
    
    // Don't load if already loading or no more data
    if (_isFeaturedLoading || (!loadMore && _hasMoreProperties == false)) {
      return;
    }
    
    // Check cache first (only on initial load, not on load more)
    if (!loadMore && _cacheProvider != null) {
      final cached = _cacheProvider!.getPropertyCache(category);
      if (cached != null && cached.isNotEmpty) {
        debugPrint('📦 Loading properties from cache for category: $category');
        _featuredProperties = cached.map((p) => PropertyModel.fromJson(p)).toList();
        _loadedPropertyIds.addAll(_featuredProperties.map((p) => p.id));
        notifyListeners();
        return;
      }
    }
    
    // Fetch from backend
    if (loadMore) {
      _isLoadingMore = true; // Use separate flag for pagination
    } else {
      _isFeaturedLoading = true; // Use main flag for initial load
    }
    _error = null;
    notifyListeners();

    try {
      debugPrint('🌐 Fetching properties from backend (page: $_currentPage, category: $category)');
      
      final response = await _realApiService.getFeaturedProperties(
        category: category,
        page: _currentPage,
        limit: 10,
        excludeIds: _loadedPropertyIds.toList(),
      );
      
      if (response.isEmpty) {
        _hasMoreProperties = false;
        debugPrint('📭 No more properties available');
      } else {
        final newProperties = response.map((p) => PropertyModel.fromJson(p)).toList();
        
        if (loadMore) {
          // Append to existing list
          _featuredProperties.addAll(newProperties);
        } else {
          // Replace list on initial load
          _featuredProperties = newProperties;
        }
        
        // Track loaded IDs
        _loadedPropertyIds.addAll(newProperties.map((p) => p.id));
        
        // Increment page for next load
        _currentPage++;
        
        debugPrint('✅ Loaded ${newProperties.length} properties (total: ${_featuredProperties.length})');
        
        // Cache the initial result (only on first page)
        if (_currentPage == 2 && _cacheProvider != null) {
          _cacheProvider!.setPropertyCache(category, response);
        }
      }
    } catch (e) {
      _error = 'Failed to load featured properties: $e';
      debugPrint('❌ Error loading featured properties: $e');
    } finally {
      _isFeaturedLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Load personalized recommended properties
  Future<void> loadRecommendedProperties({String category = 'all'}) async {
    _isRecommendedLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🎯 Fetching recommended properties from backend (category: $category)');
      
      final response = await _realApiService.getRecommendedProperties(
        category: category,
      );
      
      final newProperties = response.map((p) => PropertyModel.fromJson(p)).toList();
      _recommendedProperties = newProperties;
      
      debugPrint('✅ Loaded ${newProperties.length} recommended properties');
    } catch (e) {
      debugPrint('❌ Error loading recommended properties: $e');
      _error = 'Failed to load recommended properties';
      _recommendedProperties = []; // Empty list on error
    } finally {
      _isRecommendedLoading = false;
      notifyListeners();
    }
  }
  
  /// Reset pagination state (call when changing category)
  void resetPagination() {
    _currentPage = 1;
    _hasMoreProperties = true;
    _loadedPropertyIds.clear();
    _featuredProperties = [];
    notifyListeners();
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
