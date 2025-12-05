import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/auth_router.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/responsive_layout.dart';
import '../../core/widgets/loading_states.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/listing_card.dart' show ListingMetaItem, ListingCard;
import '../../core/widgets/listing_card_list.dart';
import '../../core/widgets/listing_badges.dart' show ListingBadgeType;
import '../../core/widgets/listing_vm_factory.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/advanced_map_widget.dart';
import '../../l10n/app_localizations.dart';
import '../../services/listing_service.dart' as ls;
import '../../core/neo/neo.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';
import '../../core/services/mock_api_service.dart' show RealApiService;
import '../../core/providers/ui_visibility_provider.dart';
import '../../services/token_storage_service.dart';

/// Quick filter model for search screen
class QuickFilter {
  final String label;
  final bool Function() isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  QuickFilter({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });
}

/// Industrial-grade advanced search with filters and sorting
class AdvancedSearchScreen extends ConsumerStatefulWidget {
  final String? initialType;      // 'property' | 'vehicle' | null
  final String? initialCategory;  // e.g., 'SUV', 'Apartments'
  const AdvancedSearchScreen({super.key, this.initialType, this.initialCategory});
  
  @override
  ConsumerState<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  
  // Controllers
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  double _lastScrollOffset = 0;
  // Filters open in a centered dialog; no inline animations
  
  // Search state
  String _searchQuery = '';
  bool _showFilters = false;
  bool _showQuickControls = true;
  bool _isSearching = false;
  List<PropertyResult> _searchResults = [];
  String? _categoryKeyword; // optional keyword hint for vehicle sub-categories like SUV, Sedan
  bool _isVehicleMode = false;
  bool _isGridView = true; // toggles between list and grid view (default: grid)
  final bool _showMapView = false; // toggles between list/grid vs map view
  String _sortOption = 'relevance'; // relevance | price_asc | price_desc | rating_desc | distance_asc
  
  // Pagination state for infinite scroll
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Set<String> _fetchedIds = {};
  static const int _initialLimit = 20;
  static const int _loadMoreLimit = 10;
  static const int _loadMoreThreshold = 4; // Load more when 4 items from end
  
  // Filter values
  String _propertyType = 'all';
  RangeValues _priceRange = const RangeValues(0, 100000); // Default to high range to not filter
  int _bedrooms = 0;
  int _bathrooms = 0;
  bool _instantBooking = false;
  bool _verifiedOnly = false;
  // Vehicle filters
  String _vehicleCategory = 'all'; // suv/sedan/hatchback/electric/bikes/vans
  String _vehicleFuel = 'any';     // any/electric/petrol/diesel
  String _vehicleTransmission = 'any'; // any/automatic/manual
  int _vehicleSeats = 4;
  
  // Additional filters inspired by reference screenshots
  bool _imagesOnly = false;
  int _builtUpMinSqFt = 0; // 0 = Any
  int _builtUpMaxSqFt = 0; // 0 = Any / 4000+ etc.
  String _toRentCategory = 'residential'; // residential | commercial | venue (UI only)
  String _furnishType = 'any'; // any | full | semi | unfurnished
  String _preferredTenant = 'any'; // any | family | bachelors | students | male | female | others
  String _pgGender = 'any'; // any | male | female | mixed
  // Venue-specific filters (only applied when _toRentCategory == 'venue')
  Set<String> _venueEventTypes = <String>{}; // slugs like wedding, birthday_party, workshop_training
  String _venueAvailability = 'any'; // any | full_venue | partial_areas | rooms_+_venue
  int _venueMinSeating = 0; // 0 = Any
  int _venueMinFloating = 0; // 0 = Any
  int _venueMinIndoorArea = 0; // 0 = Any
  int _venueMinOutdoorArea = 0; // 0 = Any
  String _venueParkingRange = 'any'; // any | 0-10 | 10-50 | 50-100 | 100+
  Set<String> _amenities = <String>{}; // wifi, parking, ac, heating, pets, kitchen, balcony, elevator, venue features
  // Location radius filter (km) and reference center (placeholder)
  double _radiusKm = 0; // 0 = Any
  final double _centerLat = 37.4219999;
  final double _centerLng = -122.0840575;
  
  // Available options
  final List<String> _propertyTypes = [
    'all',
    // Residential types (from fixed_add_listing_screen)
    'apartment', 'house', 'villa', 'studio', 'townhouse', 'condo', 'room',
    'pg', 'hostel', 'duplex', 'penthouse', 'bungalow',
    // Commercial basics (actual types from fixed_add_commercial_listing_screen)
    'office', 'shop', 'warehouse', 'coworking', 'showroom', 'clinic', 'restaurant', 'industrial',
    // Venue types (from VenueListingFormScreen)
    'venue_banquet_hall',
    'venue_wedding_venue',
    'venue_party_hall',
    'venue_conference_room',
    'venue_meeting_room',
    'venue_auditorium_theatre',
    'venue_outdoor_lawn_garden',
    'venue_rooftop_venue',
    'venue_hotel_ballroom',
    'venue_resort_venue',
    'venue_farmhouse_villa_event_space',
    'venue_studio_(photo_video_music)',
    'venue_exhibition_center',
    'venue_club_lounge_event_space',
    'venue_private_dining_room',
    'venue_co-working_event_lounge',
    'venue_retreat_site_campground',
    // vehicles
    'vehicle'
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Setup listeners
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {}); // rebuild to update active border state
    });

    // Seed filters from initial route params
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final map = _normalizeInitial(widget.initialType, widget.initialCategory);
      setState(() {
        _propertyType = map.$1;      // normalized type
        _categoryKeyword = map.$2;   // optional keyword for subcategory searches
        _isVehicleMode = widget.initialType?.toLowerCase() == 'vehicle' || _propertyType == 'vehicle';
        if (_isVehicleMode && _categoryKeyword != null && _categoryKeyword!.isNotEmpty) {
          _vehicleCategory = _categoryKeyword!;
        }
        // Default to list view on phones
        final bool isPhoneWidth = MediaQuery.of(context).size.width < 600;
        if (isPhoneWidth) {
          _isGridView = false;
        }
      });
      _performSearch();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    // No inline filter animation to dispose
    super.dispose();
  }
  
  void _onSearchChanged() {
  // Rebuild immediately to reflect UI changes (e.g., hide/show suffix search icon)
  if (mounted) setState(() {});
  if (_searchController.text != _searchQuery) {
    _debounceSearch();
  }
}

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final currentOffset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;
    
    // Infinite scroll: load more when near the end
    if (!_isLoadingMore && _hasMore && currentOffset > maxScroll - 300) {
      _loadMore();
    }
    
    // Always show controls when near the top (extended comfort zone)
    if (currentOffset < 100) {
      if (!_showQuickControls) {
        setState(() {
          _showQuickControls = true;
        });
      }
      _lastScrollOffset = currentOffset;
      return;
    }
    
    final delta = currentOffset - _lastScrollOffset;
    
    // Ultra-responsive threshold (6px) with smooth triggering
    // Finely balanced to avoid jitter while remaining fluid
    if (delta.abs() > 6) {
      // Scrolling down (offset increasing) = gracefully hide controls
      // Scrolling up (offset decreasing) = instantly reveal controls
      final shouldShow = delta < 0;
      
      // Only trigger state change if needed (prevents unnecessary rebuilds)
      if (shouldShow != _showQuickControls) {
        setState(() {
          _showQuickControls = shouldShow;
        });
      }
      
      // Continuous offset tracking for buttery-smooth transitions
      _lastScrollOffset = currentOffset;
    }
  }
  
  Timer? _debounceTimer;
  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }
  
  /// Load more items for infinite scroll
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final type = _isVehicleMode ? 'vehicle' : 'property';
      final excludeIds = _fetchedIds.join(',');
      
      // Map frontend sort option to backend sort parameter
      String backendSort;
      switch (_sortOption) {
        case 'price_asc':
          backendSort = 'price_asc';
          break;
        case 'price_desc':
          backendSort = 'price_desc';
          break;
        case 'rating_desc':
          backendSort = 'rating';
          break;
        case 'distance_asc':
          backendSort = 'nearest';
          break;
        case 'relevance':
        default:
          backendSort = 'relevance';
          break;
      }
      
      // Get JWT token for relevance sorting (optional)
      final token = await TokenStorageService.getToken();
      
      // Build query parameters
      final queryParams = <String, String>{
        'type': type,
        'page': (_currentPage + 1).toString(),
        'limit': _loadMoreLimit.toString(),
        'exclude': excludeIds,
        'query': _searchQuery,
        'sort': backendSort,
      };
      
      // Add coordinates for nearest sorting
      if (_centerLat != 0 && _centerLng != 0) {
        queryParams['lat'] = _centerLat.toString();
        queryParams['lng'] = _centerLng.toString();
      }
      
      final uri = Uri.parse('${ApiConstants.baseUrl}/search/paginated')
          .replace(queryParameters: queryParams);

      // Include auth header for relevance sorting
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final results = body['data']['results'] as List;
          final pagination = body['data']['pagination'];
          
          final newResults = results.map<PropertyResult>((item) {
            return _mapApiItemToPropertyResult(item);
          }).toList();
          
          // Track new IDs
          for (final r in newResults) {
            _fetchedIds.add(r.id);
          }
          
          setState(() {
            _searchResults.addAll(newResults);
            _currentPage++;
            _hasMore = pagination['hasMore'] ?? false;
            _isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading more: $e');
    }
    
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }
  
  /// Convert API response item to PropertyResult
  PropertyResult _mapApiItemToPropertyResult(Map<String, dynamic> item) {
    final String id = item['id']?.toString() ?? item['_id']?.toString() ?? '';
    final String title = item['title']?.toString() ?? 'Untitled';
    final String itemType = item['itemType']?.toString() ?? 'property';
    final bool isVehicle = itemType == 'vehicle';
    
    // Extract price
    double price = 0;
    final priceRaw = item['price'];
    if (priceRaw is num) {
      price = priceRaw.toDouble();
    } else if (priceRaw is Map) {
      price = (priceRaw['perMonth'] ?? priceRaw['perDay'] ?? 0).toDouble();
    }
    
    // Extract rating
    double rating = 0;
    final ratingRaw = item['rating'];
    if (ratingRaw is num) {
      rating = ratingRaw.toDouble();
    } else if (ratingRaw is Map) {
      rating = (ratingRaw['avg'] ?? 0).toDouble();
    }
    
    // Extract imageUrl with fallback placeholder
    String imageUrl = '';
    if (item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty) {
      imageUrl = item['imageUrl'].toString();
    } else if (item['images'] is List && (item['images'] as List).isNotEmpty) {
      imageUrl = (item['images'] as List).first.toString();
    }
    // Use placeholder if empty
    if (imageUrl.isEmpty) {
      imageUrl = isVehicle 
          ? 'https://via.placeholder.com/400x300?text=Vehicle'
          : 'https://via.placeholder.com/400x300?text=Property';
    }
    final String location = item['location']?.toString() ?? 
        '${item['city'] ?? ''}, ${item['state'] ?? ''}'.trim();
    
    return PropertyResult(
      id: id,
      title: title,
      price: price,
      rating: rating,
      imageUrl: imageUrl,
      location: location,
      type: isVehicle ? 'vehicle' : (item['category']?.toString() ?? 'property'),
      bedrooms: (item['bedrooms'] is num) ? (item['bedrooms'] as num).toInt() : 0,
      bathrooms: (item['bathrooms'] is num) ? (item['bathrooms'] as num).toInt() : 0,
      isVerified: item['isVerified'] == true,
      instantBooking: item['instantBooking'] == true,
      latitude: _centerLat,
      longitude: _centerLng,
      vehicleCategory: item['category']?.toString() ?? '',
      vehicleFuel: item['fuel']?.toString() ?? '',
      vehicleTransmission: item['transmission']?.toString() ?? '',
      seats: (item['seats'] is num) ? (item['seats'] as num).toInt() : 0,
    );
  }
  
  /// Apply client-side filters to results
  List<PropertyResult> _applyClientSideFilters(List<PropertyResult> results) {
    return results.where((r) {
      // Price filter
      final bool priceOk = r.price >= _priceRange.start && r.price <= _priceRange.end;
      
      // Verified filter
      final bool verifiedOk = !_verifiedOnly || r.isVerified;
      
      // Instant booking filter
      final bool instantOk = !_instantBooking || r.instantBooking;
      
      if (_isVehicleMode) {
        // Vehicle-specific filters
        bool categoryOk = true;
        if (_vehicleCategory != 'all' && r.vehicleCategory.isNotEmpty) {
          categoryOk = r.vehicleCategory.toLowerCase().contains(_vehicleCategory.toLowerCase());
        }
        
        bool fuelOk = true;
        if (_vehicleFuel != 'any') {
          fuelOk = r.vehicleFuel.toLowerCase() == _vehicleFuel.toLowerCase();
        }
        
        bool transOk = true;
        if (_vehicleTransmission != 'any') {
          transOk = r.vehicleTransmission.toLowerCase() == _vehicleTransmission.toLowerCase();
        }
        
        bool seatsOk = true;
        if (_vehicleSeats > 0) {
          seatsOk = r.seats >= _vehicleSeats;
        }
        
        return priceOk && verifiedOk && instantOk && categoryOk && fuelOk && transOk && seatsOk;
      } else {
        // Property-specific filters
        final bool bedsOk = _bedrooms == 0 || r.bedrooms >= _bedrooms;
        final bool bathsOk = _bathrooms == 0 || r.bathrooms >= _bathrooms;
        
        return priceOk && verifiedOk && instantOk && bedsOk && bathsOk;
      }
    }).toList();
  }
  
  /// Apply sorting to results
  List<PropertyResult> _applySorting(List<PropertyResult> results) {
    switch (_sortOption) {
      case 'price_asc':
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating_desc':
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'distance_asc':
        results.sort((a, b) {
          final da = _distanceKm(_centerLat, _centerLng, a.latitude, a.longitude);
          final db = _distanceKm(_centerLat, _centerLng, b.latitude, b.longitude);
          return da.compareTo(db);
        });
        break;
      case 'relevance':
      default:
        // Keep API ordering (featured first)
        break;
    }
    return results;
  }
  
  Future<void> _performSearch() async {
    setState(() {
      _searchQuery = _searchController.text;
      _isSearching = true;
      _currentPage = 1;
      _hasMore = true;
      _fetchedIds.clear();
      _searchResults.clear();
    });

    try {
      final type = _isVehicleMode ? 'vehicle' : 'property';
      
      // Map frontend sort option to backend sort parameter
      String backendSort;
      switch (_sortOption) {
        case 'price_asc':
          backendSort = 'price_asc';
          break;
        case 'price_desc':
          backendSort = 'price_desc';
          break;
        case 'rating_desc':
          backendSort = 'rating';
          break;
        case 'distance_asc':
          backendSort = 'nearest';
          break;
        case 'relevance':
        default:
          backendSort = 'relevance';
          break;
      }
      
      // Get JWT token for relevance sorting (optional)
      final token = await TokenStorageService.getToken();
      
      // Build query parameters
      final queryParams = <String, String>{
        'type': type,
        'page': '1',
        'limit': _initialLimit.toString(),
        'query': _searchQuery,
        'sort': backendSort,
      };
      
      // Add coordinates for nearest sorting
      if (_centerLat != 0 && _centerLng != 0) {
        queryParams['lat'] = _centerLat.toString();
        queryParams['lng'] = _centerLng.toString();
      }
      
      final uri = Uri.parse('${ApiConstants.baseUrl}/search/paginated')
          .replace(queryParameters: queryParams);

      debugPrint('🔍 [Search] Fetching: $uri');
      
      // Include auth header for relevance sorting
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(uri, headers: headers);
      debugPrint('🔍 [Search] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        debugPrint('🔍 [Search] Body success: ${body['success']}, data: ${body['data'] != null}');
        if (body['success'] == true && body['data'] != null) {
          final results = body['data']['results'] as List;
          final pagination = body['data']['pagination'];
          debugPrint('🔍 [Search] Got ${results.length} results from API');
          
          List<PropertyResult> apiResults = results.map<PropertyResult>((item) {
            return _mapApiItemToPropertyResult(item);
          }).toList();
          debugPrint('🔍 [Search] Mapped ${apiResults.length} PropertyResult items');
          
          // Track fetched IDs
          for (final r in apiResults) {
            _fetchedIds.add(r.id);
          }
          
          // Apply client-side filters (price range, verified, etc.)
          apiResults = _applyClientSideFilters(apiResults);
          debugPrint('🔍 [Search] After filters: ${apiResults.length} items');
          
          // Note: Sorting is handled by backend, no client-side sorting needed
          
          debugPrint('🔍 [Search] Final results: ${apiResults.length} items, setting state...');
          if (mounted) {
            setState(() {
              _searchResults = apiResults;
              _hasMore = pagination['hasMore'] ?? false;
              _isSearching = false;
            });
          }
          debugPrint('🔍 [Search] State updated, _searchResults.length: ${_searchResults.length}');
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching from API: $e');
    }

    // Fallback: Use featured properties/vehicles API which works on web
    debugPrint('🔍 [Search] Using featured fallback...');
    List<PropertyResult> baseResults;
    try {
      final api = RealApiService();
      if (_isVehicleMode) {
        // Use getFeaturedVehicles which calls the real backend
        final vehicles = await api.getFeaturedVehicles(limit: _initialLimit);
        debugPrint('🔍 [Search] Fetched ${vehicles.length} featured vehicles');
        baseResults = vehicles.map<PropertyResult>((v) {
          final id = (v['_id'] ?? v['id'] ?? '').toString();
          final title = (v['name'] ?? v['title'] ?? '').toString();
          // Handle nested price structure
          double price = 0;
          if (v['price'] is num) {
            price = (v['price'] as num).toDouble();
          } else if (v['price'] is Map) {
            price = (v['price']['perDay'] ?? v['price']['perMonth'] ?? 0).toDouble();
          }
          // Handle nested rating structure
          double rating = 0;
          if (v['rating'] is num) {
            rating = (v['rating'] as num).toDouble();
          } else if (v['rating'] is Map) {
            rating = (v['rating']['avg'] ?? 0).toDouble();
          }
          // Handle images array
          String imageUrl = '';
          if (v['images'] is List && (v['images'] as List).isNotEmpty) {
            imageUrl = (v['images'] as List).first.toString();
          } else if (v['imageUrl'] != null && v['imageUrl'].toString().isNotEmpty) {
            imageUrl = v['imageUrl'].toString();
          }
          // Use placeholder if empty
          if (imageUrl.isEmpty) {
            imageUrl = 'https://via.placeholder.com/400x300?text=Vehicle';
          }
          // Handle location from city/state
          String location = '';
          if (v['city'] != null) {
            location = '${v['city']}, ${v['state'] ?? ''}'.trim();
          } else if (v['location'] != null) {
            location = v['location'].toString();
          }
          final seats = (v['seatCapacity'] ?? v['seats']) is num ? ((v['seatCapacity'] ?? v['seats']) as num).toInt() : 0;
          final rawCategory = (v['category'] ?? '').toString().toLowerCase();
          final rawTrans = (v['transmission'] ?? '').toString().toLowerCase();
          final rawFuel = (v['fuel'] ?? '').toString().toLowerCase();

          // Normalize category/fuel/transmission to match filter values
          String normCategory;
          if (rawCategory.contains('suv')) {
            normCategory = 'suv';
          } else if (rawCategory.contains('sedan')) {
            normCategory = 'sedan';
          } else if (rawCategory.contains('hatch')) {
            normCategory = 'hatchback';
          } else if (rawCategory.contains('bike') || rawCategory.contains('motor')) {
            normCategory = 'bikes';
          } else if (rawCategory.contains('van')) {
            normCategory = 'vans';
          } else if (rawCategory.contains('electric') || rawCategory.contains('ev') || rawCategory.contains('tesla')) {
            normCategory = 'electric';
          } else {
            normCategory = 'all';
          }

          String normTrans;
          if (rawTrans.contains('auto')) {
            normTrans = 'automatic';
          } else if (rawTrans.contains('manual')) {
            normTrans = 'manual';
          } else {
            normTrans = 'any';
          }

          String normFuel;
          if (rawFuel.contains('electric')) {
            normFuel = 'electric';
          } else if (rawFuel.contains('diesel')) {
            normFuel = 'diesel';
          } else if (rawFuel.contains('petrol') || rawFuel.contains('gasoline')) {
            normFuel = 'petrol';
          } else {
            normFuel = 'any';
          }

          final lat = (v['latitude'] is num) ? (v['latitude'] as num).toDouble() : _centerLat;
          final lng = (v['longitude'] is num) ? (v['longitude'] as num).toDouble() : _centerLng;
          return PropertyResult(
            id: id,
            title: title,
            price: price,
            rating: rating,
            imageUrl: imageUrl,
            location: location,
            type: 'vehicle',
            bedrooms: seats,
            bathrooms: 0,
            isVerified: false,
            instantBooking: false,
            latitude: lat,
            longitude: lng,
            vehicleCategory: normCategory,
            vehicleFuel: normFuel,
            vehicleTransmission: normTrans,
            seats: seats,
          );
        }).toList();
      } else {
        // Use getFeaturedProperties which calls the real backend
        final properties = await api.getFeaturedProperties(limit: _initialLimit);
        debugPrint('🔍 [Search] Fetched ${properties.length} featured properties');
        baseResults = properties.map<PropertyResult>((p) {
          final id = (p['_id'] ?? p['id'] ?? '').toString();
          final title = (p['title'] ?? '').toString();
          // Handle nested price structure
          double price = 0;
          if (p['price'] is num) {
            price = (p['price'] as num).toDouble();
          } else if (p['price'] is Map) {
            price = (p['price']['perMonth'] ?? p['price']['perDay'] ?? 0).toDouble();
          }
          // Handle nested rating structure
          double rating = 0;
          if (p['rating'] is num) {
            rating = (p['rating'] as num).toDouble();
          } else if (p['rating'] is Map) {
            rating = (p['rating']['avg'] ?? 0).toDouble();
          }
          // Handle images array
          String imageUrl = '';
          if (p['images'] is List && (p['images'] as List).isNotEmpty) {
            imageUrl = (p['images'] as List).first.toString();
          } else if (p['imageUrl'] != null && p['imageUrl'].toString().isNotEmpty) {
            imageUrl = p['imageUrl'].toString();
          }
          // Use placeholder if empty
          if (imageUrl.isEmpty) {
            imageUrl = 'https://via.placeholder.com/400x300?text=Property';
          }
          // Handle location from city/state
          String location = '';
          if (p['city'] != null) {
            location = '${p['city']}, ${p['state'] ?? ''}'.trim();
          } else if (p['location'] != null) {
            location = p['location'].toString();
          }
          final type = (p['category'] ?? p['type'] ?? 'apartment').toString();
          final lat = (p['latitude'] is num) ? (p['latitude'] as num).toDouble() : _centerLat;
          final lng = (p['longitude'] is num) ? (p['longitude'] as num).toDouble() : _centerLng;
          return PropertyResult(
            id: id,
            title: title,
            price: price,
            rating: rating,
            imageUrl: imageUrl,
            location: location,
            type: type,
            bedrooms: (p['bedrooms'] is num) ? (p['bedrooms'] as num).toInt() : 0,
            bathrooms: (p['bathrooms'] is num) ? (p['bathrooms'] as num).toInt() : 0,
            isVerified: p['isVerified'] == true,
            instantBooking: p['instantBooking'] == true,
            latitude: lat,
            longitude: lng,
          );
        }).toList();
      }
    } catch (_) {
      // Fall back to local mock generators if API fails
      baseResults = _isVehicleMode ? _generateVehicleResults() : _generateMockResults();
    }

    // Merge owner-created listings (userListings) for properties/venues/commercial
    if (!_isVehicleMode) {
      try {
        final listingsState = ref.read(ls.listingProvider);
        final ownerListings = listingsState.userListings.where((l) => l.isActive).toList();
        final existingIds = baseResults.map((r) => r.id).toSet();

        final ownerResults = ownerListings
            .where((l) => !existingIds.contains(l.id))
            .map<PropertyResult>((l) {
          final rating = l.rating ?? 0.0;
          final imageUrl = l.images.isNotEmpty ? l.images.first : '';
          final locCity = l.city.trim();
          final locState = l.state.trim();
          String location;
          if (locCity.isNotEmpty && locState.isNotEmpty) {
            location = '$locCity, $locState';
          } else if (locCity.isNotEmpty) {
            location = locCity;
          } else if (locState.isNotEmpty) {
            location = locState;
          } else {
            location = l.address;
          }

          // Use the owner listing type as-is (lowercased). Venue listings use
          // values like 'venue_banquet_hall', which we treat as commercial
          // when applying top-level filters.
          final type = l.type.toLowerCase();

          // Map boolean amenities (e.g., wifi, parking, ac) into simple keys
          // so existing amenity filters work.
          final amenityKeys = <String>{};
          l.amenities.forEach((key, value) {
            if (value == true) {
              amenityKeys.add(key.toString());
            }
          });

          return PropertyResult(
            id: l.id,
            title: l.title,
            price: l.price,
            rating: rating,
            imageUrl: imageUrl,
            location: location,
            type: type,
            bedrooms: 0,
            bathrooms: 0,
            isVerified: false,
            instantBooking: false,
            latitude: _centerLat,
            longitude: _centerLng,
            amenities: amenityKeys,
          );
        }).toList();

        baseResults = [...baseResults, ...ownerResults];
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      List<PropertyResult> results = baseResults;
      final t = _propertyType.toLowerCase();
      final bool knownPropertyType = _propertyTypes.contains(t);
      if (!_isVehicleMode && t != 'all' && knownPropertyType) {
        results = results.where((r) => r.type.toLowerCase() == t).toList();
      }
      // Apply simple text filter
      if (_searchQuery.isNotEmpty) {
        results = results
            .where((r) => r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                r.location.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }

      // Preload owner listings into a map for fast amenity lookups (PG, venue filters, etc.)
      Map<String, ls.Listing> listingMap = {};
      try {
        final listingsState = ref.read(ls.listingProvider);
        final allListings = [...listingsState.listings, ...listingsState.userListings];
        listingMap = {for (final l in allListings) l.id: l};
      } catch (_) {}

      // Apply top-level category filter (Residential / Commercial / Venue)
      if (!_isVehicleMode) {
        const residentialTypes = {
          'apartment', 'house', 'villa', 'studio', 'room',
          // extended residential types from fixed_add_listing_screen
          'townhouse', 'condo', 'pg', 'hostel', 'duplex', 'penthouse', 'bungalow',
        };
        const commercialBaseTypes = {
          'office', 'shop', 'warehouse', 'coworking', 'showroom', 'clinic', 'restaurant', 'industrial',
        };

        bool isResidentialType(String t) => residentialTypes.contains(t);

        bool isCommercialType(String t) {
          if (commercialBaseTypes.contains(t)) return true;
          // Fallback heuristics for other commercial-like types
          if (t.contains('office') ||
              t.contains('shop') ||
              t.contains('clinic') ||
              t.contains('restaurant') ||
              t.contains('cowork') ||
              t.contains('industrial')) {
            return true;
          }
          return false;
        }

        bool isVenueType(String t) {
          // All dedicated venue types are modeled as 'venue_*' or 'venue'
          if (t.startsWith('venue_') || t == 'venue') return true;
          return false;
        }

        final category = _toRentCategory.toLowerCase();
        if (category == 'residential') {
          results = results.where((r) => isResidentialType(r.type.toLowerCase())).toList();
        } else if (category == 'commercial') {
          results = results.where((r) => isCommercialType(r.type.toLowerCase())).toList();
        } else if (category == 'venue') {
          results = results.where((r) => isVenueType(r.type.toLowerCase())).toList();
        }
      }

      // Apply property-specific filters from the filter sheet
      if (!_isVehicleMode) {
        results = results.where((r) {
          final bool isResidential = _toRentCategory == 'residential';
          final bool isVenue = _toRentCategory == 'venue';
          final bool priceOk = r.price >= _priceRange.start && r.price <= _priceRange.end;
          final bool bedsOk = !isResidential || _bedrooms == 0 || r.bedrooms >= _bedrooms;
          final bool bathsOk = !isResidential || _bathrooms == 0 || r.bathrooms >= _bathrooms;
          final bool instantOk = !_instantBooking || r.instantBooking;
          final bool verifiedOk = !_verifiedOnly || r.isVerified;
          final bool imagesOk = !_imagesOnly || (r.imageUrl.trim().isNotEmpty);
          bool builtMinOk = true;
          bool builtMaxOk = true;
          if (!isVenue) {
            builtMinOk = _builtUpMinSqFt == 0 || r.builtUpArea >= _builtUpMinSqFt;
            builtMaxOk = (_builtUpMaxSqFt == 0 || _builtUpMaxSqFt == 4000)
                ? true
                : r.builtUpArea <= _builtUpMaxSqFt;
          }
          final bool furnishOk = _furnishType == 'any' || r.furnishType == _furnishType;
          final bool tenantOk = !isResidential || _preferredTenant == 'any' || r.preferredTenant == _preferredTenant;
          final bool amenityOk = _amenities.isEmpty || _amenities.every((a) => r.amenities.contains(a));

          // Pull backing Listing for PG/venue filters when needed
          ls.Listing? backing;
          final bool needsPg = isResidential && _pgGender != 'any';
          final bool needsVenue = isVenue && (
            _venueEventTypes.isNotEmpty ||
            _venueAvailability != 'any' ||
            _venueMinSeating > 0 ||
            _venueMinFloating > 0 ||
            _venueMinIndoorArea > 0 ||
            _venueMinOutdoorArea > 0 ||
            _venueParkingRange != 'any'
          );
          if ((needsPg || needsVenue) && listingMap.isNotEmpty) {
            backing = listingMap[r.id];
          }

          // PG / Hostel gender filter (amenities['pg_gender'])
          bool pgGenderOk = true;
          if (needsPg && backing != null) {
            final pgG = backing.amenities['pg_gender'];
            String? pgGenderValue;
            if (pgG is String && pgG.trim().isNotEmpty) {
              pgGenderValue = pgG.toLowerCase();
            }
            if (pgGenderValue != null) {
              if (_pgGender == 'mixed') {
                pgGenderOk = true; // any non-empty value allowed
              } else {
                pgGenderOk = pgGenderValue == _pgGender;
              }
            }
          }

          // Venue-specific filters
          bool venueEventsOk = true;
          bool venueAvailabilityOk = true;
          bool venueCapacityOk = true;
          bool venueAreaOk = true;
          bool venueParkingOk = true;

          if (isVenue && needsVenue && backing != null) {
            final amenities = backing.amenities;

            // Event types: intersection with amenities['event_types_allowed'] (slugified list)
            if (_venueEventTypes.isNotEmpty) {
              final rawEvents = amenities['event_types_allowed'];
              Set<String> stored = {};
              if (rawEvents is List) {
                stored = rawEvents.map((e) => e.toString()).toSet();
              }
              venueEventsOk = stored.isNotEmpty && _venueEventTypes.any(stored.contains);
            }

            // Availability type: amenities['availability_type'] is slugified
            if (_venueAvailability != 'any') {
              final availRaw = amenities['availability_type'];
              if (availRaw is String && availRaw.trim().isNotEmpty) {
                final availSlug = availRaw.toLowerCase();
                venueAvailabilityOk = availSlug == _venueAvailability;
              } else {
                venueAvailabilityOk = false;
              }
            }

            // Capacities
            if (_venueMinSeating > 0) {
              final s1 = amenities['seating_capacity'];
              final s2 = amenities['venue_seated_capacity'];
              final val = s1 is num
                  ? s1.toInt()
                  : (s2 is num ? s2.toInt() : null);
              if (val != null) {
                venueCapacityOk = venueCapacityOk && val >= _venueMinSeating;
              } else {
                venueCapacityOk = false;
              }
            }
            if (_venueMinFloating > 0) {
              final f = amenities['floating_capacity'];
              final val = f is num ? f.toInt() : null;
              if (val != null) {
                venueCapacityOk = venueCapacityOk && val >= _venueMinFloating;
              } else {
                venueCapacityOk = false;
              }
            }

            // Areas
            if (_venueMinIndoorArea > 0) {
              final a = amenities['indoor_area_sqft'];
              final val = a is num ? a.toInt() : null;
              if (val != null) {
                venueAreaOk = venueAreaOk && val >= _venueMinIndoorArea;
              } else {
                venueAreaOk = false;
              }
            }
            if (_venueMinOutdoorArea > 0) {
              final a = amenities['outdoor_area_sqft'];
              final val = a is num ? a.toInt() : null;
              if (val != null) {
                venueAreaOk = venueAreaOk && val >= _venueMinOutdoorArea;
              } else {
                venueAreaOk = false;
              }
            }

            // Parking range: exact match on stored string
            if (_venueParkingRange != 'any') {
              final p = amenities['parking_range'];
              if (p is String && p.trim().isNotEmpty) {
                venueParkingOk = p == _venueParkingRange;
              } else {
                venueParkingOk = false;
              }
            }
          }

          return priceOk && bedsOk && bathsOk && instantOk && verifiedOk && imagesOk && builtMinOk && builtMaxOk &&
              furnishOk && tenantOk && amenityOk && pgGenderOk &&
              venueEventsOk && venueAvailabilityOk && venueCapacityOk && venueAreaOk && venueParkingOk;
        }).toList();
      } else {
        // Apply vehicle-specific filters
        results = results.where((r) {
          final bool priceOk = r.price >= _priceRange.start && r.price <= _priceRange.end;
          final bool instantOk = !_instantBooking || r.instantBooking;
          final bool verifiedOk = !_verifiedOnly || r.isVerified;

          // Category (SUV/Sedan/Hatchback/Bikes/Vans/Electric)
          bool categoryOk = true;
          if (_vehicleCategory != 'all' && r.vehicleCategory.isNotEmpty) {
            final cat = r.vehicleCategory.toLowerCase();
            if (_vehicleCategory == 'electric') {
              categoryOk = cat.contains('electric');
            } else if (_vehicleCategory == 'bikes') {
              categoryOk = cat.contains('bike') || cat.contains('motor');
            } else if (_vehicleCategory == 'vans') {
              categoryOk = cat.contains('van');
            } else if (_vehicleCategory == 'hatchback') {
              categoryOk = cat.contains('hatch');
            } else if (_vehicleCategory == 'suv') {
              categoryOk = cat.contains('suv');
            } else if (_vehicleCategory == 'sedan') {
              categoryOk = cat.contains('sedan');
            }
          }

          // Fuel
          bool fuelOk = true;
          if (_vehicleFuel != 'any') {
            fuelOk = r.vehicleFuel == _vehicleFuel;
          }

          // Transmission
          bool transOk = true;
          if (_vehicleTransmission != 'any') {
            transOk = r.vehicleTransmission == _vehicleTransmission;
          }

          // Seats (min)
          bool seatsOk = true;
          if (_vehicleSeats > 0) {
            final seatCount = r.seats > 0 ? r.seats : r.bedrooms;
            seatsOk = seatCount >= _vehicleSeats;
          }

          return priceOk && instantOk && verifiedOk && categoryOk && fuelOk && transOk && seatsOk;
        }).toList();
      }
      // Apply radius filter (if any)
      if (_radiusKm > 0) {
        results = results.where((r) {
          final d = _distanceKm(_centerLat, _centerLng, r.latitude, r.longitude);
          return d <= _radiusKm;
        }).toList();
      }
      // Apply sorting
      switch (_sortOption) {
        case 'price_asc':
          results.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_desc':
          results.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'rating_desc':
          results.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'distance_asc':
          results.sort((a, b) {
            final da = _distanceKm(_centerLat, _centerLng, a.latitude, a.longitude);
            final db = _distanceKm(_centerLat, _centerLng, b.latitude, b.longitude);
            return da.compareTo(db);
          });
          break;
        case 'relevance':
        default:
          // keep current ordering
          break;
      }
      _searchResults = results;
      _isSearching = false;
    });

    // Saved search notifications removed
  }

  // Distance helpers (Haversine)
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180.0);

  // Normalize initial (type, category) coming from Home screen
  // Returns (normalizedType, optionalKeyword)
  (String, String?) _normalizeInitial(String? initialType, String? initialCategory) {
    final t = (initialType ?? '').toLowerCase();
    final c = (initialCategory ?? '').toLowerCase();

    // Vehicle categories -> type 'vehicle' and keep keyword hint
    const vehicleCats = {
      'cars','suv','sedan','hatchback','bikes','scooters','trucks','vans','luxury','electric','convertible'
    };
    if (t == 'vehicle' || vehicleCats.contains(c)) {
      return ('vehicle', vehicleCats.contains(c) ? c : null);
    }

    // Property categories -> map to our supported types
    if (c.isNotEmpty) {
      final mapped = switch (c) {
        'apartments' => 'apartment',
        'apartment' => 'apartment',
        'houses' => 'house',
        'house' => 'house',
        'villas' => 'villa',
        'villa' => 'villa',
        'condos' => 'apartment',
        'condo' => 'apartment',
        'studios' => 'studio',
        'studio' => 'studio',
        'lofts' => 'apartment',
        'loft' => 'apartment',
        'cabins' => 'house',
        'cabin' => 'house',
        'cottages' => 'house',
        'cottage' => 'house',
        'penthouse' => 'apartment',
        'townhouses' => 'house',
        'townhouse' => 'house',
        _ => 'all',
      };
      return (mapped, null);
    }

    if (t == 'property') {
      return ('all', null);
    }
    return (t.isEmpty ? 'all' : t, null);
  }
  
  
  
  List<PropertyResult> _generateMockResults() {
    // Base coordinate near San Francisco for mock positions
    const double baseLat = 37.7749;
    const double baseLng = -122.4194;
    final furnishings = ['full','semi','unfurnished'];
    final tenants = ['family','bachelors','students','male','female','others'];
    
    final amenityPool = ['wifi','parking','ac','heating','pets','kitchen','balcony','elevator'];
    // Property-only mock pool (exclude 'all' and 'vehicle')
    final propertyTypesPool = ['apartment','house','villa','studio','room','office','retail','showroom','warehouse'];
    return List.generate(20, (index) {
      final type = propertyTypesPool[index % propertyTypesPool.length];
      final int builtArea = 100 + (index % 50) * 100; // 100..5000 for all property types
      final int beds = (index % 4) + 1;
      final int baths = (index % 3) + 1;
      
      return PropertyResult(
        id: 'prop_$index',
        title: 'Modern $type in City Center',
        price: 50.0 + (index * 10),
        rating: 4.0 + (index % 10) / 10,
        imageUrl: 'https://picsum.photos/400/300?random=$index',
        location: 'Downtown, City',
        type: type,
        bedrooms: beds,
        bathrooms: baths,
        isVerified: index % 2 == 0,
        instantBooking: index % 3 == 0,
        latitude: baseLat + (index % 10) * 0.0015,
        longitude: baseLng + (index % 10) * 0.0015,
        builtUpArea: builtArea,
        furnishType: furnishings[index % furnishings.length],
        preferredTenant: tenants[index % tenants.length],
        amenities: {
          amenityPool[index % amenityPool.length],
          amenityPool[(index + 2) % amenityPool.length],
        },
      );
    });
  }

  List<PropertyResult> _generateVehicleResults() {
    final categories = ['suv','sedan','hatchback','electric','bikes','vans'];
    // Base coordinate near San Francisco for mock positions
    const double baseLat = 37.7749;
    const double baseLng = -122.4194;
    return List.generate(20, (i) {
      final cat = categories[i % categories.length];
      // Apply quick filters crudely in generator
      if (_vehicleCategory != 'all' && cat != _vehicleCategory) {
        // skip by returning a cheap entry filtered later
      }
      final seats = 2 + (i % 5); // 2..6
      final isAutomatic = i % 2 == 0;
      final transLabel = isAutomatic ? 'Automatic' : 'Manual';
      return PropertyResult(
        id: 'veh_$i',
        title: '${cat.toUpperCase()} $transLabel Rental — Comfortable & Clean',
        price: 30.0 + (i * 7),
        rating: 4.2 + (i % 7) / 10,
        imageUrl: 'https://picsum.photos/seed/vehicle$i/400/300',
        location: 'Tech District',
        type: 'vehicle',
        bedrooms: seats, // reuse as seats for display
        bathrooms: 0,
        isVerified: i % 2 == 0,
        instantBooking: i % 3 == 0,
        latitude: baseLat + (i % 10) * 0.0012,
        longitude: baseLng - (i % 10) * 0.0012,
      );
    }).where((r) {
      final title = r.title.toLowerCase();
      // category
      if (_vehicleCategory != 'all' && !title.contains(_vehicleCategory)) return false;
      // fuel
      if (_vehicleFuel == 'electric' && !title.contains('electric')) return false;
      // transmission
      if (_vehicleTransmission == 'automatic' && !title.contains('automatic')) return false;
      if (_vehicleTransmission == 'manual' && !title.contains('manual')) return false;
      // seats (bedrooms field reused)
      if (r.bedrooms < _vehicleSeats) return false;
      return true;
    }).toList();
  }

  
  int _countActiveFilters() {
    int count = 0;
    if (_isVehicleMode) {
      if (_vehicleCategory != 'all') count++;
      if (_vehicleFuel != 'any') count++;
      if (_vehicleTransmission != 'any') count++;
      if (_vehicleSeats != 4) count++;
      return count;
    } else {
      final bool isResidential = _toRentCategory == 'residential';
      final bool isVenue = _toRentCategory == 'venue';

      if (_propertyType != 'all') count++;
      if (_priceRange.start > 0 || _priceRange.end < 5000) count++;
      if (isResidential && _bedrooms > 0) count++;
      if (isResidential && _bathrooms > 0) count++;
      if (_instantBooking) count++;
      if (_verifiedOnly) count++;
      if (_imagesOnly) count++;
      if (!isVenue && (_builtUpMinSqFt > 0 || _builtUpMaxSqFt > 0)) count++;
      if (!isVenue && _furnishType != 'any') count++;
      if (isResidential && _preferredTenant != 'any') count++;
      if (isResidential && _pgGender != 'any') count++;
      if (isVenue && _venueEventTypes.isNotEmpty) count++;
      if (isVenue && _venueAvailability != 'any') count++;
      if (isVenue && (_venueMinSeating > 0 || _venueMinFloating > 0)) count++;
      if (isVenue && (_venueMinIndoorArea > 0 || _venueMinOutdoorArea > 0)) count++;
      if (isVenue && _venueParkingRange != 'any') count++;
      if (_amenities.isNotEmpty) count++;
      if (_radiusKm > 0) count++;
      return count;
    }
  }

  Widget _buildModeControlsRow(ThemeData theme, bool isDark) {
    Widget buildIconToggle({required IconData icon, required bool selected, required VoidCallback onTap, String? tooltip}) {
      return AnimatedScale(
        scale: selected ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: selected 
              ? theme.primaryColor 
              : (isDark ? theme.colorScheme.surface.withValues(alpha: 0.08) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.primaryColor
                : (isDark
                    ? EnterpriseDarkTheme.primaryBorder.withValues(alpha: 0.5)
                    : theme.colorScheme.outline.withValues(alpha: 0.2)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
              blurRadius: 10,
              offset: const Offset(-5, -5),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: (isDark
                      ? EnterpriseDarkTheme.primaryAccent
                      : EnterpriseLightTheme.primaryAccent)
                  .withValues(alpha: isDark ? 0.18 : 0.12),
              blurRadius: 10,
              offset: const Offset(5, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: tooltip,
              icon: Icon(
                icon,
                size: selected ? 22 : 20,
                color: selected ? Colors.white : (isDark ? Colors.white70 : theme.primaryColor),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              visualDensity: VisualDensity.compact,
              splashRadius: 20,
              onPressed: onTap,
            ),
            if (selected)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 3,
                  width: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ));
    }

    return Row(
      children: [
        // Properties
        Expanded(child: Center(child: buildIconToggle(
          icon: Icons.home_rounded,
          selected: !_isVehicleMode,
          tooltip: 'Properties',
          onTap: () { setState(() { _isVehicleMode = false; _propertyType = 'all'; }); _performSearch(); },
        ))),
        // Vehicles
        Expanded(child: Center(child: buildIconToggle(
          icon: Icons.directions_car_rounded,
          selected: _isVehicleMode,
          tooltip: 'Vehicles',
          onTap: () { setState(() { _isVehicleMode = true; _propertyType = 'vehicle'; }); _performSearch(); },
        ))),
        // Grid/List toggle
        Expanded(child: Center(child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: _isGridView
                ? theme.primaryColor
                : (isDark ? theme.colorScheme.surface.withValues(alpha: 0.08) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isGridView
                  ? theme.primaryColor
                  : (isDark
                      ? EnterpriseDarkTheme.primaryBorder.withValues(alpha: 0.5)
                      : theme.colorScheme.outline.withValues(alpha: 0.2)),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                blurRadius: 10,
                offset: const Offset(-5, -5),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: (isDark
                        ? EnterpriseDarkTheme.primaryAccent
                        : EnterpriseLightTheme.primaryAccent)
                    .withValues(alpha: isDark ? 0.18 : 0.12),
                blurRadius: 10,
                offset: const Offset(5, 5),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: _isGridView ? 'Grid view' : 'List view',
                icon: Icon(
                  _isGridView ? Icons.grid_view : Icons.view_list,
                  size: _isGridView ? 22 : 20,
                  color: _isGridView ? Colors.white : (isDark ? Colors.white70 : theme.primaryColor),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                visualDensity: VisualDensity.compact,
                splashRadius: 20,
                onPressed: () { setState(() => _isGridView = !_isGridView); },
              ),
              if (_isGridView)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 3,
                    width: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ))),
        // Sort menu
        Expanded(child: Center(child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? EnterpriseDarkTheme.primaryBorder.withValues(alpha: 0.5)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                blurRadius: 10,
                offset: const Offset(-5, -5),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: (isDark
                        ? EnterpriseDarkTheme.primaryAccent
                        : theme.primaryColor)
                    .withValues(alpha: isDark ? 0.18 : 0.12),
                blurRadius: 10,
                offset: const Offset(5, 5),
                spreadRadius: 0,
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            tooltip: AppLocalizations.of(context)!.sortBy,
            onSelected: (value) { setState(() { _sortOption = value; }); _performSearch(); },
            position: PopupMenuPosition.under,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'relevance', child: ListTile(leading: Icon(Icons.auto_awesome, size: 18), title: Text('Relevance'))),
              PopupMenuItem(value: 'price_asc', child: ListTile(leading: Icon(Icons.south_east, size: 18), title: Text('Price: Low to High'))),
              PopupMenuItem(value: 'price_desc', child: ListTile(leading: Icon(Icons.north_east, size: 18), title: Text('Price: High to Low'))),
              PopupMenuItem(value: 'rating_desc', child: ListTile(leading: Icon(Icons.star_rate, size: 18), title: Text('Rating: High to Low'))),
              PopupMenuItem(value: 'distance_asc', child: ListTile(leading: Icon(Icons.near_me, size: 18), title: Text('Nearest'))),
            ],
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(child: Icon(Icons.sort_rounded, size: 20, color: isDark ? Colors.white70 : theme.primaryColor)),
            ),
          ),
        ))),
      ],
    );
  }

  Widget _buildQuickFilters(ThemeData theme, bool isDark) {
    List<QuickFilter> filters = _isVehicleMode ? _getVehicleQuickFilters() : _getPropertyQuickFilters();
    
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter.isSelected();
          
          return GestureDetector(
            onTap: () {
              filter.onTap();
              _performSearch();
            },
            child: NeoGlass(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              borderRadius: BorderRadius.circular(14),
              blur: isSelected ? 12 : 16,
              backgroundColor: isSelected
                  ? _getFilterBackgroundColor(filter.icon, theme.primaryColor)
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.50)),
              borderColor: isSelected
                  ? _getFilterBorderColor(filter.icon, theme.primaryColor)
                  : (isDark ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.85)),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: isDark ? 0.2 : 0.3,
                ),
              ],
              borderWidth: isSelected ? 1.4 : 1.1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filter.icon != null) ...[
                    Icon(
                      filter.icon,
                      size: 12,
                      color: isSelected 
                          ? _getSelectedIconColor(filter.icon!)
                          : _getIconColor(filter.icon!, isDark),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    filter.label,
                    style: TextStyle(
                      color: isSelected 
                          ? _getSelectedTextColor(filter.icon)
                          : (isDark ? Colors.white70 : Colors.grey[700]),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<QuickFilter> _getPropertyQuickFilters() {
    return [
      QuickFilter(
        label: 'Instant Book',
        icon: Icons.flash_on,
        isSelected: () => _instantBooking,
        onTap: () => setState(() => _instantBooking = !_instantBooking),
      ),
      QuickFilter(
        label: 'Verified',
        icon: Icons.verified,
        isSelected: () => _verifiedOnly,
        onTap: () => setState(() => _verifiedOnly = !_verifiedOnly),
      ),
      QuickFilter(
        label: 'Under £100',
        isSelected: () => _priceRange.end <= 100,
        onTap: () => setState(() {
          if (_priceRange.start == 0 && _priceRange.end == 100) {
            _priceRange = const RangeValues(0, 5000);
          } else {
            _priceRange = const RangeValues(0, 100);
          }
        }),
      ),
      QuickFilter(
        label: '£100-£200',
        isSelected: () => _priceRange.start >= 100 && _priceRange.end <= 200,
        onTap: () => setState(() {
          if (_priceRange.start == 100 && _priceRange.end == 200) {
            _priceRange = const RangeValues(0, 5000);
          } else {
            _priceRange = const RangeValues(100, 200);
          }
        }),
      ),
      QuickFilter(
        label: '1+ Bedroom',
        isSelected: () => _bedrooms >= 1,
        onTap: () => setState(() => _bedrooms = _bedrooms >= 1 ? 0 : 1),
      ),
      QuickFilter(
        label: '2+ Bedrooms',
        isSelected: () => _bedrooms >= 2,
        onTap: () => setState(() => _bedrooms = _bedrooms >= 2 ? 0 : 2),
      ),
    ];
  }

  List<QuickFilter> _getVehicleQuickFilters() {
    return [
      QuickFilter(
        label: 'Instant Book',
        icon: Icons.flash_on,
        isSelected: () => _instantBooking,
        onTap: () => setState(() => _instantBooking = !_instantBooking),
      ),
      QuickFilter(
        label: 'Verified',
        icon: Icons.verified,
        isSelected: () => _verifiedOnly,
        onTap: () => setState(() => _verifiedOnly = !_verifiedOnly),
      ),
      QuickFilter(
        label: 'Under £50',
        isSelected: () => _priceRange.end <= 50,
        onTap: () => setState(() {
          if (_priceRange.start == 0 && _priceRange.end == 50) {
            _priceRange = const RangeValues(0, 5000);
          } else {
            _priceRange = const RangeValues(0, 50);
          }
        }),
      ),
      QuickFilter(
        label: '£50-£100',
        isSelected: () => _priceRange.start >= 50 && _priceRange.end <= 100,
        onTap: () => setState(() {
          if (_priceRange.start == 50 && _priceRange.end == 100) {
            _priceRange = const RangeValues(0, 5000);
          } else {
            _priceRange = const RangeValues(50, 100);
          }
        }),
      ),
      QuickFilter(
        label: 'SUV',
        isSelected: () => _vehicleCategory == 'suv',
        onTap: () => setState(() => _vehicleCategory = _vehicleCategory == 'suv' ? 'all' : 'suv'),
      ),
      QuickFilter(
        label: 'Sedan',
        isSelected: () => _vehicleCategory == 'sedan',
        onTap: () => setState(() => _vehicleCategory = _vehicleCategory == 'sedan' ? 'all' : 'sedan'),
      ),
      QuickFilter(
        label: 'Electric',
        icon: Icons.electric_bolt,
        isSelected: () => _vehicleFuel == 'electric',
        onTap: () => setState(() => _vehicleFuel = _vehicleFuel == 'electric' ? 'any' : 'electric'),
      ),
      QuickFilter(
        label: 'Automatic',
        icon: Icons.settings,
        isSelected: () => _vehicleTransmission == 'automatic',
        onTap: () => setState(() => _vehicleTransmission = _vehicleTransmission == 'automatic' ? 'any' : 'automatic'),
      ),
    ];
  }

  Color _getIconColor(IconData icon, bool isDark) {
    switch (icon) {
      case Icons.flash_on:
        return Colors.orange; // Instant Book - energetic orange
      case Icons.verified:
        return Colors.green; // Verified - trustworthy green
      case Icons.electric_bolt:
        return Colors.blue; // Electric - electric blue
      case Icons.settings:
        return Colors.purple; // Automatic - tech purple
      default:
        return isDark ? Colors.white70 : Colors.grey[700]!;
    }
  }

  Color _getFilterBackgroundColor(IconData? icon, Color defaultColor) {
    if (icon == null) return defaultColor;
    
    switch (icon) {
      case Icons.flash_on:
        return Colors.orange.withValues(alpha: 0.15); // Light orange background
      case Icons.verified:
        return Colors.green.withValues(alpha: 0.15); // Light green background
      case Icons.electric_bolt:
        return Colors.blue.withValues(alpha: 0.15); // Light blue background
      case Icons.settings:
        return Colors.purple.withValues(alpha: 0.15); // Light purple background
      default:
        return defaultColor; // Use theme primary color for other filters
    }
  }

  Color _getFilterBorderColor(IconData? icon, Color defaultColor) {
    if (icon == null) return defaultColor;
    
    switch (icon) {
      case Icons.flash_on:
        return Colors.orange.withValues(alpha: 0.4); // Orange border
      case Icons.verified:
        return Colors.green.withValues(alpha: 0.4); // Green border
      case Icons.electric_bolt:
        return Colors.blue.withValues(alpha: 0.4); // Blue border
      case Icons.settings:
        return Colors.purple.withValues(alpha: 0.4); // Purple border
      default:
        return defaultColor; // Use theme primary color for other filters
    }
  }

  Color _getSelectedIconColor(IconData icon) {
    switch (icon) {
      case Icons.flash_on:
        return Colors.orange; // Keep orange icon on light orange background
      case Icons.verified:
        return Colors.green; // Keep green icon on light green background
      case Icons.electric_bolt:
        return Colors.blue; // Keep blue icon on light blue background
      case Icons.settings:
        return Colors.purple; // Keep purple icon on light purple background
      default:
        return Colors.white; // White for other filters with primary color background
    }
  }

  Color _getSelectedTextColor(IconData? icon) {
    if (icon == null) return Colors.white;
    
    switch (icon) {
      case Icons.flash_on:
      case Icons.verified:
      case Icons.electric_bolt:
      case Icons.settings:
        return Colors.black87; // Dark text on light colored backgrounds
      default:
        return Colors.white; // White text on primary color background
    }
  }
  
  Widget _buildMapView(ThemeData theme) {
    final props = _searchResults.map((p) {
      final isVehicle = p.type.toLowerCase() == 'vehicle';
      String unit = isVehicle ? 'hour' : 'day';
      try {
        final listingsState = ref.read(ls.listingProvider);
        final allListings = [...listingsState.listings, ...listingsState.userListings];
        final found = allListings.where((l) => l.id == p.id).cast<ls.Listing?>().firstOrNull;
        if (found?.rentalUnit != null && (found!.rentalUnit!.trim().isNotEmpty)) {
          unit = found.rentalUnit!.trim().toLowerCase();
        }
      } catch (_) {}
      return MapProperty(
        id: p.id,
        title: p.title,
        imageUrl: p.imageUrl,
        price: p.price,
        rating: p.rating,
        position: LatLng(p.latitude, p.longitude),
        propertyType: p.type,
        rentalUnit: unit,
      );
    }).toList();
    return AdvancedMapWidget(
      properties: props,
      initialPosition: LatLng(props.first.position.latitude, props.first.position.longitude),
      initialZoom: 12.0,
      onPropertyTapped: (mp) {
        context.push('${Routes.listing}/${mp.id}');
      },
    );
  }

  // Saved search feature removed
  
  void _toggleFilters() {
    final theme = Theme.of(context);
    setState(() => _showFilters = true);
    // Hide bottom navigation bar while filters are open
    ref.read(immersiveRouteOpenProvider.notifier).state = true;
    // For vehicles, use the modern filter panel which already exposes
    // category, fuel, transmission and seat count filters.
    if (_isVehicleMode) {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: SizedBox(
              width: double.infinity,
              height: MediaQuery.of(dialogContext).size.height * 0.8,
              child: _buildModernFilterPanel(theme, dialogContext),
            ),
          );
        },
      ).whenComplete(() {
        if (!mounted) return;
        setState(() => _showFilters = false);
        ref.read(immersiveRouteOpenProvider.notifier).state = false;
      });
      return;
    }

    // Properties & commercial listings keep the tailored bottom sheet UX
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        // Local editable copies
        String localToRent = _toRentCategory;
        String localPropertyType = _propertyType;
        double localMinBudget = _priceRange.start;
        double localMaxBudget = _priceRange.end;
        int localBuiltMin = _builtUpMinSqFt;
        int localBuiltMax = _builtUpMaxSqFt;
        bool localImagesOnly = _imagesOnly;
        String localFurnish = _furnishType; // any|full|semi|unfurnished
        String localTenant = _preferredTenant; // any|family|male|female|others
        int localBhk = _bedrooms; // 0 for Any, else 1..5
        int localBaths = _bathrooms; // 0 = Any
        String localPgGender = _pgGender; // any|male|female|mixed
        Set<String> localVenueEventTypes = {..._venueEventTypes};
        String localVenueAvailability = _venueAvailability; // any or slugified
        int localVenueMinSeating = _venueMinSeating;
        int localVenueMinFloating = _venueMinFloating;
        int localVenueMinIndoor = _venueMinIndoorArea;
        int localVenueMinOutdoor = _venueMinOutdoorArea;
        String localVenueParkingRange = _venueParkingRange;
        final Set<String> localAmenities = {..._amenities};
        // Plot-specific locals removed; Plots is no longer a top-level category

        const List<String> propertyTypesResidential = [
          'all',
          'apartment', 'house', 'villa', 'studio', 'townhouse', 'condo', 'room',
          'pg', 'hostel', 'duplex', 'penthouse', 'bungalow',
        ];
        const List<String> propertyTypesCommercial = [
          'all',
          'office', 'shop', 'warehouse', 'coworking', 'showroom', 'clinic', 'restaurant', 'industrial',
        ];
        const List<String> propertyTypesVenue = [
          'all',
          'venue_banquet_hall',
          'venue_wedding_venue',
          'venue_party_hall',
          'venue_conference_room',
          'venue_meeting_room',
          'venue_auditorium_theatre',
          'venue_outdoor_lawn_garden',
          'venue_rooftop_venue',
          'venue_hotel_ballroom',
          'venue_resort_venue',
          'venue_farmhouse_villa_event_space',
          'venue_studio_(photo_video_music)',
          'venue_exhibition_center',
          'venue_club_lounge_event_space',
          'venue_private_dining_room',
          'venue_co-working_event_lounge',
          'venue_retreat_site_campground',
        ];
        final List<double> budgetOptions = [0, 100, 200, 300, 400, 500, 750, 1000, 1500, 2000, 3000, 4000, 5000];
        final List<int> builtUpOptions = [0, 100, 200, 400, 600, 800, 1000, 1500, 2000, 3000, 4000];
        final List<int> venueCapacityOptions = [0, 50, 100, 200, 300, 500, 1000];
        final List<int> venueAreaOptions = [0, 500, 1000, 2000, 5000, 10000];

        String typeLabel(String t) {
          switch (t) {
            case 'apartment': return 'Apartment';
            case 'house': return 'Independent House';
            case 'villa': return 'Independent Villa';
            case 'studio': return '1RK/Studio House';
            case 'room': return 'Room';
            case 'townhouse': return 'Townhouse';
            case 'condo': return 'Condo';
            case 'pg': return 'PG / Co-living';
            case 'hostel': return 'Hostel';
            case 'duplex': return 'Duplex';
            case 'penthouse': return 'Penthouse';
            case 'bungalow': return 'Bungalow';
            case 'office': return 'Office';
            case 'shop': return 'Shop';
            case 'showroom': return 'Showroom';
            case 'warehouse': return 'Warehouse';
            case 'coworking': return 'Co-working Space';
            case 'clinic': return 'Clinic / Healthcare';
            case 'restaurant': return 'Restaurant / Café';
            case 'industrial': return 'Industrial / Factory';
            case 'venue_banquet_hall': return 'Banquet Hall';
            case 'venue_wedding_venue': return 'Wedding Venue';
            case 'venue_party_hall': return 'Party Hall';
            case 'venue_conference_room': return 'Conference Room';
            case 'venue_meeting_room': return 'Meeting Room';
            case 'venue_auditorium_theatre': return 'Auditorium / Theatre';
            case 'venue_outdoor_lawn_garden': return 'Outdoor Lawn / Garden';
            case 'venue_rooftop_venue': return 'Rooftop Venue';
            case 'venue_hotel_ballroom': return 'Hotel Ballroom';
            case 'venue_resort_venue': return 'Resort Venue';
            case 'venue_farmhouse_villa_event_space': return 'Farmhouse / Villa Event Space';
            case 'venue_studio_(photo_video_music)': return 'Studio (Photo / Video / Music)';
            case 'venue_exhibition_center': return 'Exhibition Center';
            case 'venue_club_lounge_event_space': return 'Club / Lounge Event Space';
            case 'venue_private_dining_room': return 'Private Dining Room';
            case 'venue_co-working_event_lounge': return 'Co-working Event Lounge';
            case 'venue_retreat_site_campground': return 'Retreat Site / Campground';
            case 'all':
            default: return 'All';
          }
        }

        Widget dropdownLabel(String title) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        );

        InputDecoration ddDecoration() => InputDecoration(
          filled: true,
          isDense: true,
          fillColor: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.06) : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2))),
        );

        return StatefulBuilder(
          builder: (context, setLocal) {
            final types = localToRent == 'commercial'
                ? propertyTypesCommercial
                : (localToRent == 'venue' ? propertyTypesVenue : propertyTypesResidential);
            final List<String> propertyAmenityKeys = ['wifi','parking','ac','heating','pets','kitchen','balcony','elevator'];
            final List<String> venueAmenityKeys = [
              'fire_safety_compliant',
              'outside_catering_allowed',
              'veg_available',
              'non_veg_available',
              'buffet_available',
              'live_counters_available',
              'dj_allowed',
              'alcohol_service_allowed',
            ];
            final List<String> amenityKeys = localToRent == 'venue' ? venueAmenityKeys : propertyAmenityKeys;
            final Map<String, String> venueEventTypeLabels = {
              'wedding': 'Wedding',
              'reception': 'Reception',
              'birthday_party': 'Birthday Party',
              'corporate_event': 'Corporate Event',
              'workshop_training': 'Workshop / Training',
              'concert_performance': 'Concert / Performance',
              'exhibition': 'Exhibition',
              'photoshoot_filming': 'Photoshoot / Filming',
              'private_dinner': 'Private Dinner',
              'religious_event': 'Religious Event',
              'festival_event': 'Festival Event',
              'engagement_anniversary': 'Engagement / Anniversary',
              'others': 'Others',
            };
            double floorBudget(double t) { double sel = budgetOptions.first; for (final v in budgetOptions) { if (v <= t) sel = v; } return sel; }
            double ceilBudget(double t) { double sel = budgetOptions.last; for (final v in budgetOptions) { if (v >= t) { sel = v; break; } } return sel; }
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.88,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Modern drag handle with glow
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor.withValues(alpha: 0.3),
                          theme.primaryColor.withValues(alpha: 0.5),
                          theme.primaryColor.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Modern Glassmorphism Header
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.fromLTRB(20, 22, 16, 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.85),
                          theme.colorScheme.secondary.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Animated icon container
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) => Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Filter Properties',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Active filter count badge
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.bounceOut,
                                    builder: (context, scale, child) => Transform.scale(
                                      scale: scale,
                                      child: child,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${_countActiveFilters()} active',
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Find your perfect space',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Close button with ripple
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(sheetContext).pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Card - now scrollable with other sections
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : theme.primaryColor.withValues(alpha: 0.08),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.black.withValues(alpha: 0.2)
                                      : theme.primaryColor.withValues(alpha: 0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.primaryColor.withValues(alpha: 0.15),
                                            theme.colorScheme.secondary.withValues(alpha: 0.1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.primaryColor.withValues(alpha: 0.15),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(Icons.home_work_outlined, size: 20, color: theme.primaryColor),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Category chips inside the card
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                  child: Row(
                                    children: [
                                      _buildCategoryChip('Residential', Icons.home_rounded, localToRent == 'residential', theme, () => setLocal(() => localToRent = 'residential')),
                                      const SizedBox(width: 10),
                                      _buildCategoryChip('Commercial', Icons.business_rounded, localToRent == 'commercial', theme, () => setLocal(() {
                                        localToRent = 'commercial';
                                        localBhk = 0;
                                        localTenant = 'any';
                                        localBaths = 0;
                                      })),
                                      const SizedBox(width: 10),
                                      _buildCategoryChip('Venue', Icons.celebration_rounded, localToRent == 'venue', theme, () => setLocal(() {
                                        localToRent = 'venue';
                                        localBhk = 0;
                                        localTenant = 'any';
                                        localBaths = 0;
                                        localPropertyType = 'all';
                                      })),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Property Type section
                          _buildPropertyFilterSection(
                            'Property Type',
                            Icons.apartment_rounded,
                            theme,
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: types.asMap().entries.map((entry) {
                                  final t = entry.value;
                                  final sel = localPropertyType == t;
                                  return Padding(
                                    padding: EdgeInsets.only(right: entry.key < types.length - 1 ? 8 : 0),
                                    child: _buildPropertyChip(typeLabel(t), sel, theme, () => setLocal(() => localPropertyType = t)),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          // Budget section
                          _buildPropertyFilterSection(
                            'Budget',
                            Icons.currency_rupee_rounded,
                            theme,
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      dropdownLabel('Min'),
                                      DropdownButtonFormField<double>(
                                        initialValue: floorBudget(localMinBudget),
                                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                        items: budgetOptions.map((v) => DropdownMenuItem<double>(
                                          value: v,
                                          child: Text(CurrencyFormatter.formatPrice(v), style: const TextStyle(fontSize: 12)),
                                        )).toList(),
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setLocal(() => localMinBudget = v);
                                        },
                                        decoration: ddDecoration(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      dropdownLabel('Max'),
                                      DropdownButtonFormField<double>(
                                        initialValue: ceilBudget(localMaxBudget),
                                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                        items: budgetOptions.map((v) => DropdownMenuItem<double>(
                                          value: v,
                                          child: Text(CurrencyFormatter.formatPrice(v), style: const TextStyle(fontSize: 12)),
                                        )).toList(),
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setLocal(() => localMaxBudget = v);
                                        },
                                        decoration: ddDecoration(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (localToRent != 'venue') ...[ 
                            // Built-up area section
                            _buildPropertyFilterSection(
                              'Built-up Area',
                              Icons.square_foot_rounded,
                              theme,
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        dropdownLabel('Min'),
                                        DropdownButtonFormField<int>(
                                          initialValue: builtUpOptions.contains(localBuiltMin) ? localBuiltMin : 0,
                                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                          items: builtUpOptions.map((v) => DropdownMenuItem<int>(
                                            value: v,
                                            child: Text(v == 0 ? 'Any' : '$v sq ft', style: const TextStyle(fontSize: 12)),
                                          )).toList(),
                                          onChanged: (v) => setLocal(() => localBuiltMin = v ?? 0),
                                          decoration: ddDecoration(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        dropdownLabel('Max'),
                                        DropdownButtonFormField<int>(
                                          initialValue: builtUpOptions.contains(localBuiltMax) ? localBuiltMax : 0,
                                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                          items: builtUpOptions.map((v) => DropdownMenuItem<int>(
                                            value: v,
                                            child: Text(v == 0 ? 'Any' : (v == 4000 ? '4000+ sq ft' : '$v sq ft'), style: const TextStyle(fontSize: 12)),
                                          )).toList(),
                                          onChanged: (v) => setLocal(() => localBuiltMax = v ?? 0),
                                          decoration: ddDecoration(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (localToRent == 'venue') ...[
                            // Event Types section
                            _buildPropertyFilterSection(
                              'Event Types',
                              Icons.celebration_rounded,
                              theme,
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: venueEventTypeLabels.entries.toList().asMap().entries.map((outerEntry) {
                                    final entry = outerEntry.value;
                                    final slug = entry.key;
                                    final sel = localVenueEventTypes.contains(slug);
                                    return Padding(
                                      padding: EdgeInsets.only(right: outerEntry.key < venueEventTypeLabels.length - 1 ? 8 : 0),
                                      child: _buildPropertyChip(entry.value, sel, theme, () => setLocal(() {
                                        if (sel) {
                                          localVenueEventTypes.remove(slug);
                                        } else {
                                          localVenueEventTypes.add(slug);
                                        }
                                      })),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            // Availability section
                            _buildPropertyFilterSection(
                              'Availability',
                              Icons.event_available_rounded,
                              theme,
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: ['any','full_venue','partial_areas','rooms_+_venue'].asMap().entries.map((entry) {
                                    final v = entry.value;
                                    final sel = localVenueAvailability == v;
                                    String label;
                                    switch (v) {
                                      case 'full_venue': label = 'Full Venue'; break;
                                      case 'partial_areas': label = 'Partial Areas'; break;
                                      case 'rooms_+_venue': label = 'Rooms + Venue'; break;
                                      default: label = 'Any';
                                    }
                                    return Padding(
                                      padding: EdgeInsets.only(right: entry.key < 3 ? 8 : 0),
                                      child: _buildPropertyChip(label, sel, theme, () => setLocal(() => localVenueAvailability = v)),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            // Capacity section
                            _buildPropertyFilterSection(
                              'Capacity',
                              Icons.people_rounded,
                              theme,
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        dropdownLabel('Min seating'),
                                        DropdownButtonFormField<int>(
                                          initialValue: venueCapacityOptions.contains(localVenueMinSeating) ? localVenueMinSeating : 0,
                                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                          items: venueCapacityOptions.map((v) => DropdownMenuItem<int>(
                                            value: v,
                                            child: Text(v == 0 ? 'Any' : '$v+', style: const TextStyle(fontSize: 12)),
                                          )).toList(),
                                          onChanged: (v) => setLocal(() => localVenueMinSeating = v ?? 0),
                                          decoration: ddDecoration(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        dropdownLabel('Min floating'),
                                        DropdownButtonFormField<int>(
                                          initialValue: venueCapacityOptions.contains(localVenueMinFloating) ? localVenueMinFloating : 0,
                                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                          items: venueCapacityOptions.map((v) => DropdownMenuItem<int>(
                                            value: v,
                                            child: Text(v == 0 ? 'Any' : '$v+', style: const TextStyle(fontSize: 12)),
                                          )).toList(),
                                          onChanged: (v) => setLocal(() => localVenueMinFloating = v ?? 0),
                                          decoration: ddDecoration(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Indoor / Outdoor area section
                            _buildPropertyFilterSection(
                              'Indoor / Outdoor Area',
                              Icons.home_rounded,
                              theme,
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        dropdownLabel('Indoor min'),
                                        DropdownButtonFormField<int>(
                                          initialValue: venueAreaOptions.contains(localVenueMinIndoor) ? localVenueMinIndoor : 0,
                                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                          items: venueAreaOptions.map((v) => DropdownMenuItem<int>(
                                            value: v,
                                            child: Text(v == 0 ? 'Any' : '$v sq ft', style: const TextStyle(fontSize: 12)),
                                          )).toList(),
                                          onChanged: (v) => setLocal(() => localVenueMinIndoor = v ?? 0),
                                          decoration: ddDecoration(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        dropdownLabel('Outdoor min'),
                                        DropdownButtonFormField<int>(
                                          initialValue: venueAreaOptions.contains(localVenueMinOutdoor) ? localVenueMinOutdoor : 0,
                                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                          items: venueAreaOptions.map((v) => DropdownMenuItem<int>(
                                            value: v,
                                            child: Text(v == 0 ? 'Any' : '$v sq ft', style: const TextStyle(fontSize: 12)),
                                          )).toList(),
                                          onChanged: (v) => setLocal(() => localVenueMinOutdoor = v ?? 0),
                                          decoration: ddDecoration(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Parking capacity section
                            _buildPropertyFilterSection(
                              'Parking Capacity',
                              Icons.local_parking_rounded,
                              theme,
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: ['any','0-10','10-50','50-100','100+'].asMap().entries.map((entry) {
                                    final v = entry.value;
                                    final sel = localVenueParkingRange == v;
                                    String label;
                                    switch (v) {
                                      case '0-10': label = '0-10'; break;
                                      case '10-50': label = '10-50'; break;
                                      case '50-100': label = '50-100'; break;
                                      case '100+': label = '100+'; break;
                                      default: label = 'Any';
                                    }
                                    return Padding(
                                      padding: EdgeInsets.only(right: entry.key < 4 ? 8 : 0),
                                      child: _buildPropertyChip(label, sel, theme, () => setLocal(() => localVenueParkingRange = v)),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                          if (localToRent == 'residential') ...[
                            // Preferred Tenant section
                            _buildPropertyFilterSection(
                              'Preferred Tenant',
                              Icons.people_outline_rounded,
                              theme,
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: ['any','family','bachelors','students','male','female','others'].asMap().entries.map((entry) {
                                    final t = entry.value;
                                    final sel = localTenant == t;
                                    String label;
                                    switch (t) {
                                      case 'family': label = 'Family'; break;
                                      case 'bachelors': label = 'Bachelors'; break;
                                      case 'students': label = 'Students'; break;
                                      case 'male': label = 'Male'; break;
                                      case 'female': label = 'Female'; break;
                                      case 'others': label = 'Others'; break;
                                      default: label = 'Any';
                                    }
                                    return Padding(
                                      padding: EdgeInsets.only(right: entry.key < 6 ? 8 : 0),
                                      child: _buildPropertyChip(label, sel, theme, () => setLocal(() => localTenant = t)),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            if (localPropertyType == 'pg' || localPropertyType == 'hostel') ...[
                              // PG Gender Preference section
                              _buildPropertyFilterSection(
                                'PG Gender Preference',
                                Icons.wc_rounded,
                                theme,
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: ['any','male','female','mixed'].asMap().entries.map((entry) {
                                      final g = entry.value;
                                      final sel = localPgGender == g;
                                      String label;
                                      switch (g) {
                                        case 'male': label = 'Male'; break;
                                        case 'female': label = 'Female'; break;
                                        case 'mixed': label = 'Mixed'; break;
                                        default: label = 'Any';
                                      }
                                      return Padding(
                                        padding: EdgeInsets.only(right: entry.key < 3 ? 8 : 0),
                                        child: _buildPropertyChip(label, sel, theme, () => setLocal(() => localPgGender = g)),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                            // Bedrooms & Bathrooms section
                            _buildPropertyFilterSection(
                              'Bedrooms & Bathrooms',
                              Icons.bed_rounded,
                              theme,
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        dropdownLabel('Bedrooms (max)'),
                                        DropdownButtonFormField<int>(
                                          initialValue: [0,1,2,3,4,5].contains(localBhk) ? localBhk : 0,
                                          isDense: true,
                                          decoration: ddDecoration(),
                                          items: [0,1,2,3,4,5]
                                              .map((b) => DropdownMenuItem<int>(
                                                value: b,
                                                child: Text(b == 0 ? 'Any' : '$b', style: const TextStyle(fontSize: 12)),
                                              ))
                                              .toList(),
                                          onChanged: (v) => setLocal(() => localBhk = v ?? 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        dropdownLabel('Bathrooms (min)'),
                                        DropdownButtonFormField<int>(
                                          initialValue: [0,1,2,3,4,5].contains(localBaths) ? localBaths : 0,
                                          isDense: true,
                                          decoration: ddDecoration(),
                                          items: [0,1,2,3,4,5]
                                              .map((b) => DropdownMenuItem<int>(
                                                value: b,
                                                child: Text(b == 0 ? 'Any' : '$b+', style: const TextStyle(fontSize: 12)),
                                              ))
                                              .toList(),
                                          onChanged: (v) => setLocal(() => localBaths = v ?? 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (localToRent != 'venue') ...[
                            // Furnish Type section
                            _buildPropertyFilterSection(
                              'Furnish Type',
                              Icons.chair_rounded,
                              theme,
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: ['any','full','semi','unfurnished'].asMap().entries.map((entry) {
                                    final f = entry.value;
                                    final sel = localFurnish == f;
                                    String label;
                                    switch (f) {
                                      case 'full': label = 'Fully Furnished'; break;
                                      case 'semi': label = 'Semi Furnished'; break;
                                      case 'unfurnished': label = 'Unfurnished'; break;
                                      default: label = 'Any';
                                    }
                                    return Padding(
                                      padding: EdgeInsets.only(right: entry.key < 3 ? 8 : 0),
                                      child: _buildPropertyChip(label, sel, theme, () => setLocal(() => localFurnish = f)),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                          // Essential Amenities / Venue features section
                          _buildPropertyFilterSection(
                            localToRent == 'venue' ? 'Venue Features' : 'Essential Amenities',
                            Icons.checklist_rounded,
                            theme,
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: amenityKeys.asMap().entries.map((entry) {
                                  final k = entry.value;
                                  final sel = localAmenities.contains(k);
                                  String label;
                                  switch (k) {
                                    case 'wifi': label = 'WiFi'; break;
                                    case 'parking': label = 'Parking'; break;
                                    case 'ac': label = 'AC'; break;
                                    case 'heating': label = 'Heating'; break;
                                    case 'pets': label = 'Pets'; break;
                                    case 'kitchen': label = 'Kitchen'; break;
                                    case 'balcony': label = 'Balcony'; break;
                                    case 'elevator': label = 'Elevator'; break;
                                    case 'fire_safety_compliant': label = 'Fire Safety'; break;
                                    case 'outside_catering_allowed': label = 'Catering'; break;
                                    case 'veg_available': label = 'Veg'; break;
                                    case 'non_veg_available': label = 'Non-Veg'; break;
                                    case 'buffet_available': label = 'Buffet'; break;
                                    case 'live_counters_available': label = 'Live Counters'; break;
                                    case 'dj_allowed': label = 'DJ'; break;
                                    case 'alcohol_service_allowed': label = 'Alcohol'; break;
                                    default: label = k;
                                  }
                                  IconData icon;
                                  switch (k) {
                                    case 'wifi': icon = Icons.wifi; break;
                                    case 'parking': icon = Icons.local_parking; break;
                                    case 'ac': icon = Icons.ac_unit; break;
                                    case 'heating': icon = Icons.whatshot; break;
                                    case 'pets': icon = Icons.pets; break;
                                    case 'kitchen': icon = Icons.kitchen; break;
                                    case 'balcony': icon = Icons.deck; break;
                                    case 'elevator': icon = Icons.elevator; break;
                                    case 'fire_safety_compliant': icon = Icons.local_fire_department; break;
                                    case 'outside_catering_allowed': icon = Icons.restaurant; break;
                                    case 'veg_available': icon = Icons.eco; break;
                                    case 'non_veg_available': icon = Icons.set_meal; break;
                                    case 'buffet_available': icon = Icons.restaurant_menu; break;
                                    case 'live_counters_available': icon = Icons.local_dining; break;
                                    case 'dj_allowed': icon = Icons.music_note; break;
                                    case 'alcohol_service_allowed': icon = Icons.wine_bar; break;
                                    default: icon = Icons.check_box_outline_blank; break;
                                  }
                                  return Padding(
                                    padding: EdgeInsets.only(right: entry.key < amenityKeys.length - 1 ? 8 : 0),
                                    child: _buildAmenityChip(label, icon, sel, theme, () => setLocal(() {
                                      if (sel) {
                                        localAmenities.remove(k);
                                      } else {
                                        localAmenities.add(k);
                                      }
                                    })),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                  // Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08))),
                      boxShadow: [
                        BoxShadow(
                          color: (theme.brightness == Brightness.dark
                                  ? EnterpriseDarkTheme.primaryAccent
                                  : EnterpriseLightTheme.primaryAccent)
                              .withValues(alpha: theme.brightness == Brightness.dark ? 0.16 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
                              foregroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              backgroundColor: theme.brightness == Brightness.dark
                                  ? theme.colorScheme.surface.withValues(alpha: 0.05)
                                  : Colors.white,
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            onPressed: () {
                              setState(() {
                                _propertyType = 'all';
                                _priceRange = const RangeValues(0, 5000);
                                _bedrooms = 0;
                                _bathrooms = 0;
                                _instantBooking = false;
                                _verifiedOnly = false;
                                _imagesOnly = false;
                                _toRentCategory = 'residential';
                                _furnishType = 'any';
                                _preferredTenant = 'any';
                                _pgGender = 'any';
                                _venueEventTypes = <String>{};
                                _venueAvailability = 'any';
                                _venueMinSeating = 0;
                                _venueMinFloating = 0;
                                _venueMinIndoorArea = 0;
                                _venueMinOutdoorArea = 0;
                                _venueParkingRange = 'any';
                                _amenities = <String>{};
                              });
                              _performSearch();
                              Navigator.of(sheetContext).pop();
                            },
                            label: Text(AppLocalizations.of(context)!.reset),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _toRentCategory = localToRent;
                                _propertyType = localPropertyType;
                                // normalize min<=max
                                final double minB = localMinBudget <= localMaxBudget ? localMinBudget : localMaxBudget;
                                final double maxB = localMaxBudget >= localMinBudget ? localMaxBudget : localMinBudget;
                                _priceRange = RangeValues(minB, maxB);
                                _builtUpMinSqFt = localBuiltMin;
                                _builtUpMaxSqFt = localBuiltMax;
                                _imagesOnly = localImagesOnly;
                                _furnishType = localFurnish;
                                _preferredTenant = localTenant;
                                _bedrooms = localBhk;
                                _bathrooms = localBaths;
                                _pgGender = localPgGender;
                                _venueEventTypes = {...localVenueEventTypes};
                                _venueAvailability = localVenueAvailability;
                                _venueMinSeating = localVenueMinSeating;
                                _venueMinFloating = localVenueMinFloating;
                                _venueMinIndoorArea = localVenueMinIndoor;
                                _venueMinOutdoorArea = localVenueMinOutdoor;
                                _venueParkingRange = localVenueParkingRange;
                                _amenities = {...localAmenities};
                              });
                              _applyFilters();
                              Navigator.of(sheetContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 2,
                              shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_rounded, size: 20),
                                const SizedBox(width: 10),
                                Text(AppLocalizations.of(context)!.applyFilters),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (!mounted) return;
      setState(() => _showFilters = false);
      ref.read(immersiveRouteOpenProvider.notifier).state = false;
    });
  }
  
  void _resetFilters() {
    setState(() {
      _propertyType = 'all';
      _priceRange = const RangeValues(0, 5000);
      _bedrooms = 0;
      _bathrooms = 0;
      _instantBooking = false;
      _verifiedOnly = false;
      _imagesOnly = false;
      _builtUpMinSqFt = 0;
      _builtUpMaxSqFt = 0;
      _toRentCategory = 'residential';
      _furnishType = 'any';
      _preferredTenant = 'any';
      _amenities = <String>{};
    });
    _performSearch();
  }
  
  void _applyFilters() {
    _performSearch();
  }

  // Modern category chip builder for property filter
  Widget _buildCategoryChip(String label, IconData icon, bool selected, ThemeData theme, VoidCallback onTap) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.colorScheme.secondary.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade600),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern property filter section builder
  Widget _buildPropertyFilterSection(String title, IconData icon, ThemeData theme, Widget content) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08)
              : theme.primaryColor.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.15)
                : theme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withValues(alpha: 0.12),
                      theme.colorScheme.secondary.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: theme.primaryColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  // Modern property chip builder (like vehicle filter chips)
  Widget _buildPropertyChip(String label, bool selected, ThemeData theme, VoidCallback onTap) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.colorScheme.secondary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected 
                ? Colors.transparent
                : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Modern amenity chip builder with icon
  Widget _buildAmenityChip(String label, IconData icon, bool selected, ThemeData theme, VoidCallback onTap) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.colorScheme.secondary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected 
                ? Colors.transparent
                : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade600),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.home);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildSearchHeader(theme, isDark),
              // 1px seam mask matching page background to eliminate any anti-aliased line
              Container(
                height: 1,
                color: isDark ? theme.colorScheme.surface : Colors.white,
              ),
              Expanded(
                child: _buildSearchResults(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSearchHeader(ThemeData theme, bool isDark) {
    final borderRadius = BorderRadius.circular(24);
    final bool isActive = _searchFocusNode.hasFocus;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      color: Colors.transparent,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      // Match filter button fill: solid white in light mode
                      // and slightly elevated surface in dark mode
                      color: isDark
                          ? theme.colorScheme.surface.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: isActive
                            ? theme.colorScheme.primary
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.grey[300]!),
                        width: isActive ? 1.6 : 1.2,
                      ),
                      // Reuse the same dual-shadow style as the filter button
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.white,
                          blurRadius: 10,
                          offset: const Offset(-5, -5),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: (isDark
                                  ? EnterpriseDarkTheme.primaryAccent
                                  : EnterpriseLightTheme.primaryAccent)
                              .withValues(alpha: isDark ? 0.18 : 0.12),
                          blurRadius: 10,
                          offset: const Offset(5, 5),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Expanded(
                          child: Theme(
                            data: theme.copyWith(
                              textSelectionTheme: theme.textSelectionTheme.copyWith(
                                selectionColor: Colors.transparent,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              cursorColor: isDark
                                  ? EnterpriseDarkTheme.primaryAccent
                                  : theme.primaryColor,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.searchHint,
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.grey[500],
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                filled: true,
                                fillColor: Colors.transparent,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: isDark ? 0.2 : 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch();
                                },
                                tooltip: 'Clear search',
                                padding: EdgeInsets.zero,
                                splashRadius: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _toggleFilters,
                child: AnimatedScale(
                  scale: _showFilters ? 1.03 : 1.0,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _showFilters
                              ? theme.primaryColor
                              : (isDark
                                  ? theme.colorScheme.surface
                                      .withValues(alpha: 0.08)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _showFilters
                                ? theme.primaryColor
                                : (isDark
                                    ? EnterpriseDarkTheme.primaryBorder
                                        .withValues(alpha: 0.5)
                                    : theme.colorScheme.outline
                                        .withValues(alpha: 0.2)),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white,
                              blurRadius: 10,
                              offset: const Offset(-5, -5),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: (isDark
                                      ? EnterpriseDarkTheme.primaryAccent
                                      : EnterpriseLightTheme.primaryAccent)
                                  .withValues(alpha: isDark ? 0.18 : 0.12),
                              blurRadius: 10,
                              offset: const Offset(5, 5),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: _showFilters
                              ? Colors.white
                              : (isDark ? Colors.white70 : theme.primaryColor),
                          size: 22,
                        ),
                      ),
                      if (_countActiveFilters() > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _countActiveFilters() > 9
                                  ? '9+'
                                  : '${_countActiveFilters()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOutCubicEmphasized,
              alignment: Alignment.topCenter,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                offset:
                    _showQuickControls ? Offset.zero : const Offset(0, -0.2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  opacity: _showQuickControls ? 1.0 : 0.0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    scale: _showQuickControls ? 1.0 : 0.97,
                    alignment: Alignment.topCenter,
                    child: _showQuickControls
                        ? Column(
                            children: [
                              const SizedBox(height: 12),
                              _buildModeControlsRow(theme, isDark),
                              const SizedBox(height: 8),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
          _buildQuickFilters(theme, isDark),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildModernFilterPanel(ThemeData theme, BuildContext dialogContext) {
    final isDark = theme.brightness == Brightness.dark;
    final activeCount = _countActiveFilters();
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Glassmorphism Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.85),
                  theme.colorScheme.secondary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Animated Filter Icon Container
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Filter Vehicles',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (activeCount > 0) ...[
                            const SizedBox(width: 10),
                            // Active filter badge
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.bounceOut,
                              builder: (context, scale, child) => Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$activeCount active',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find your perfect ride',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button with ripple
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Filter Content with subtle gradient background
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                      : [Colors.grey.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                physics: const BouncingScrollPhysics(),
                child: _isVehicleMode ? _buildVehicleFilterContent(theme) : _buildPropertyFilterContent(theme),
              ),
            ),
          ),
          // Modern Action Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Reset button
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _resetFilters();
                        Navigator.of(dialogContext).pop();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded, size: 18, color: theme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.reset,
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Apply button with gradient
                Expanded(
                  flex: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _applyFilters();
                        Navigator.of(dialogContext).pop();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor,
                              theme.colorScheme.secondary,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_rounded, size: 20, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)!.applyFilters,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyFilterContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernFilterSection(
          'Property Type',
          Icons.home_rounded,
          theme,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _propertyTypes.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildModernChoiceChip(
                  type.replaceAll('_', ' ').toUpperCase(),
                  _propertyType == type,
                  () => setState(() => _propertyType = type),
                  theme,
                ),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildModernFilterSection(
          'Price Range',
          Icons.attach_money_rounded,
          theme,
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.formatPrice(_priceRange.start),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatPrice(_priceRange.end),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                ),
                child: RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 5000,
                  divisions: 50,
                  activeColor: theme.primaryColor,
                  onChanged: (values) => setState(() => _priceRange = values),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildModernFilterSection(
          'Search Radius',
          Icons.place_rounded,
          theme,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _radiusKm <= 0 ? 'Any distance' : 'Within ${_radiusKm.toStringAsFixed(0)} km',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                  Text(
                    'From current area',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                ),
                child: Slider(
                  value: _radiusKm,
                  min: 0,
                  max: 50,
                  divisions: 50,
                  activeColor: theme.primaryColor,
                  onChanged: (v) => setState(() => _radiusKm = v),
                  onChangeEnd: (_) => _performSearch(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Column(
          children: [
            _buildModernFilterSection(
              'Bedrooms',
              Icons.bed_rounded,
              theme,
              _buildModernNumberSelector(_bedrooms, (value) => setState(() => _bedrooms = value), theme),
            ),
            const SizedBox(height: 16),
            _buildModernFilterSection(
              'Bathrooms',
              Icons.bathtub_rounded,
              theme,
              _buildModernNumberSelector(_bathrooms, (value) => setState(() => _bathrooms = value), theme),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildModernFilterSection(
          'Quick Filters',
          Icons.flash_on_rounded,
          theme,
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildModernToggleChip('Verified Only', _verifiedOnly, (value) => setState(() => _verifiedOnly = value), theme),
              _buildModernToggleChip('Instant Book', _instantBooking, (value) => setState(() => _instantBooking = value), theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleFilterContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernFilterSection(
          'Vehicle Category',
          Icons.directions_car_rounded,
          theme,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'suv', 'sedan', 'hatchback', 'bikes', 'vans', 'electric']
                  .map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildModernChoiceChip(
                          category.toUpperCase(),
                          _vehicleCategory == category,
                          () => setState(() => _vehicleCategory = category),
                          theme,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildModernFilterSection(
          'Fuel Type',
          Icons.local_gas_station_rounded,
          theme,
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: ['any', 'electric', 'petrol', 'diesel']
                .map((fuel) => _buildModernChoiceChip(
                      fuel.toUpperCase(),
                      _vehicleFuel == fuel,
                      () => setState(() => _vehicleFuel = fuel),
                      theme,
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        _buildModernFilterSection(
          'Transmission',
          Icons.settings_rounded,
          theme,
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: ['any', 'automatic', 'manual']
                .map((transmission) => _buildModernChoiceChip(
                      transmission.toUpperCase(),
                      _vehicleTransmission == transmission,
                      () => setState(() => _vehicleTransmission = transmission),
                      theme,
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        _buildModernFilterSection(
          'Seats',
          Icons.event_seat_rounded,
          theme,
          _buildModernNumberSelector(_vehicleSeats, (value) => setState(() => _vehicleSeats = value), theme, min: 2, max: 10),
        ),
      ],
    );
  }

  Widget _buildModernFilterSection(String title, IconData icon, ThemeData theme, Widget content) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08)
              : theme.primaryColor.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.2)
                : theme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Gradient icon container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withValues(alpha: 0.15),
                      theme.colorScheme.secondary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: theme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          content,
        ],
      ),
    );
  }

  Widget _buildModernChoiceChip(String label, bool selected, VoidCallback onTap, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: selected ? 1.0 : 1.0),
        duration: const Duration(milliseconds: 150),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.colorScheme.secondary.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: selected 
                  ? Colors.transparent
                  : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300),
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernToggleChip(String label, bool selected, ValueChanged<bool> onChanged, ThemeData theme) {
    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.primaryColor : theme.dividerColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? theme.primaryColor : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernNumberSelector(int value, ValueChanged<int> onChanged, ThemeData theme, {int min = 0, int max = 10}) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus button with gradient
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: value > min ? () => onChanged(value - 1) : null,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: value > min
                      ? LinearGradient(
                          colors: [
                            theme.primaryColor.withValues(alpha: 0.15),
                            theme.colorScheme.secondary.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: value > min ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: value > min 
                        ? theme.primaryColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.remove_rounded,
                  color: value > min ? theme.primaryColor : theme.disabledColor,
                  size: 20,
                ),
              ),
            ),
          ),
          // Value display
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              value == 0 ? 'Any' : value.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          // Plus button with gradient
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: value < max ? () => onChanged(value + 1) : null,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: value < max
                      ? LinearGradient(
                          colors: [
                            theme.primaryColor.withValues(alpha: 0.15),
                            theme.colorScheme.secondary.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: value < max ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: value < max 
                        ? theme.primaryColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: value < max ? theme.primaryColor : theme.disabledColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final Color listBg = isDark
        ? theme.colorScheme.surface
        : Colors.white;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomPad = bottomInset + 72; // account for bottom nav + spacing

    // Responsive grid layout constants (actual sizing computed via LayoutBuilder below)
    const double horizontalPadding = 24; // keep in sync with GridView padding
    const double spacing = 12;

    if (_showMapView && _searchResults.isNotEmpty) {
      return _buildMapView(theme);
    }

    if (_isSearching) {
      return Container(
        color: listBg,
        child: _isGridView
            ? ResponsiveLayout(
                padding: EdgeInsets.zero,
                maxWidth: 1280,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableWidth = constraints.maxWidth;
                    final bool isPhoneWidthLocal = availableWidth < 600;
                    final double horizontalPaddingLocal = isPhoneWidthLocal ? 16 : horizontalPadding; // Reduced padding for phones
                    const double spacingLocal = spacing;
                    final int crossAxisCountLocal = isPhoneWidthLocal ? 1 : 3;
                    final double usableWidthLocal = availableWidth - (horizontalPaddingLocal * 2);
                    final double tileWidthLocal = (usableWidthLocal - spacingLocal * (crossAxisCountLocal - 1)) / crossAxisCountLocal;
                    const double detailsHeightCompact = 88; // slightly tighter info height
                    const double detailsHeightRegular = 114; // slightly tighter info height
                    final double estimatedDetailsHeightLocal = tileWidthLocal > 280 ? detailsHeightRegular : detailsHeightCompact;
                    const double imageAspectLocal = 3.8; // slightly taller image section
                    final double textScale = MediaQuery.textScalerOf(context).scale(16.0) / 16.0;
                    final double fudge = 3.0 + (textScale > 1.0 ? (textScale - 1.0) * 18.0 : 0.0);
                    double computedChildAspectRatioLocal = tileWidthLocal / (tileWidthLocal / imageAspectLocal + estimatedDetailsHeightLocal + fudge);
                    if (crossAxisCountLocal == 1) {
                      computedChildAspectRatioLocal = computedChildAspectRatioLocal.clamp(1.25, 1.38).toDouble();
                    } else {
                      // Allow taller aspect ratio (wider/shorter tiles) on desktop to reduce card height
                      computedChildAspectRatioLocal = computedChildAspectRatioLocal.clamp(1.35, 1.55).toDouble();
                    }

                    return GridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(horizontalPaddingLocal, 12, horizontalPaddingLocal, bottomPad),
                      itemCount: 6,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCountLocal,
                        mainAxisSpacing: spacingLocal,
                        crossAxisSpacing: spacingLocal,
                        childAspectRatio: computedChildAspectRatioLocal,
                      ),
                      itemBuilder: (context, index) => LoadingStates.propertyCardShimmer(context),
                    );
                  },
                ),
              )
            : ResponsiveLayout(
                padding: EdgeInsets.zero,
                maxWidth: 1280,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableWidth = constraints.maxWidth;
                    final bool isPhoneWidthLocal = availableWidth < 600;
                    final double horizontalPaddingLocal = isPhoneWidthLocal ? 16 : horizontalPadding; // Reduced padding for phones
                    
                    return ListView.separated(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(horizontalPaddingLocal, 12, horizontalPaddingLocal, bottomPad),
                      itemCount: 5,
                      itemBuilder: (context, index) => LoadingStates.propertyCardShimmer(context),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                    );
                  },
                ),
              ),
      );
    }
    if (_searchResults.isEmpty) {
      return Container(
        color: listBg,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text('No Results Found', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or search terms.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _resetFilters,
                child: const Text('Reset Filters'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      color: listBg,
      child: Column(
        children: [
          // grid/list toggle moved to mode controls row in header
          Expanded(
            child: ResponsiveLayout(
              padding: EdgeInsets.zero,
              maxWidth: 1280,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Compute grid params from actual available width inside ResponsiveLayout
                  final double availableWidth = constraints.maxWidth;
                  final bool isPhoneWidthLocal = availableWidth < 600;
                  final double horizontalPaddingLocal = isPhoneWidthLocal ? 16 : horizontalPadding; // Reduced padding for phones
                  const double spacingLocal = spacing;
                  final int crossAxisCountLocal = isPhoneWidthLocal ? 1 : 3;
                  final double usableWidthLocal = availableWidth - (horizontalPaddingLocal * 2);
                  final double tileWidthLocal = (usableWidthLocal - spacingLocal * (crossAxisCountLocal - 1)) / crossAxisCountLocal;
                  // Estimate details height to derive stable aspect ratio across widths
                  const double detailsHeightCompact = 88; // slightly tighter info height
                  const double detailsHeightRegular = 114; // slightly tighter info height
                  final double estimatedDetailsHeightLocal = tileWidthLocal > 280 ? detailsHeightRegular : detailsHeightCompact;
                  const double imageAspectLocal = 3.3; // slightly taller image section
                  final double textScale = MediaQuery.textScalerOf(context).scale(16.0) / 16.0;
                  // Slightly increase fudge to give cards a bit more vertical space
                  final double fudge = 9.0 + (textScale > 1.0 ? (textScale - 1.0) * 18.0 : 0.0);
                  double computedChildAspectRatioLocal = tileWidthLocal / (tileWidthLocal / imageAspectLocal + estimatedDetailsHeightLocal + fudge);
                  if (crossAxisCountLocal == 1) {
                    computedChildAspectRatioLocal = computedChildAspectRatioLocal.clamp(1.28, 1.38).toDouble();
                  } else {
                    // Allow taller aspect ratio (wider/shorter tiles) on desktop to reduce card height
                    computedChildAspectRatioLocal = computedChildAspectRatioLocal.clamp(1.38, 1.55).toDouble();
                  }

                  return RefreshIndicator(
                    onRefresh: _performSearch,
                    child: _isGridView
                        ? GridView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(horizontalPaddingLocal, 12, horizontalPaddingLocal, bottomPad),
                            // Add 1 extra for loading indicator when loading more
                            itemCount: _searchResults.length + (_isLoadingMore ? 1 : 0),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCountLocal,
                              mainAxisSpacing: spacingLocal,
                              crossAxisSpacing: spacingLocal,
                              childAspectRatio: computedChildAspectRatioLocal,
                            ),
                            itemBuilder: (context, index) {
                              // Show loading shimmer for last item when loading more
                              if (_isLoadingMore && index >= _searchResults.length) {
                                return LoadingStates.propertyCardShimmer(context);
                              }
                              final p = _searchResults[index];
                              final bool isVehicle = p.type.toLowerCase() == 'vehicle';
                              // Resolve unit via ListingService if available, else fallback by type
                              String unit = isVehicle ? 'hour' : 'month';
                              ls.Listing? backing;
                              try {
                                final listingsState = ref.read(ls.listingProvider);
                                final allListings = [...listingsState.listings, ...listingsState.userListings];
                                final found = allListings.where((l) => l.id == p.id).cast<ls.Listing?>().firstOrNull;
                                if (found?.rentalUnit != null && (found!.rentalUnit!.trim().isNotEmpty)) {
                                  unit = found.rentalUnit!.trim().toLowerCase();
                                }
                                backing = found;
                              } catch (_) {}
                              // Derive Category tag and mode badge for clarity
                              final String typeLower = p.type.toLowerCase();
                              final bool isVenueType = typeLower.startsWith('venue_') || typeLower == 'venue';
                              final String categoryTag = isVehicle
                                  ? 'Vehicle'
                                  : (isVenueType
                                      ? 'Venue'
                                      : (({
                                            'office', 'retail', 'showroom', 'warehouse'
                                          }.contains(typeLower))
                                      ? 'Commercial'
                                      : (typeLower == 'plot' ? 'Plot' : 'Residential')));
                              const String modeBadge = 'Rent';

                              // Build category-specific meta items
                              List<ListingMetaItem> metaItems;
                              if (isVehicle) {
                                final int seats = p.seats > 0 ? p.seats : (p.bedrooms > 0 ? p.bedrooms : 0);
                                final String trans = (p.vehicleTransmission).toLowerCase();
                                final String fuel = (p.vehicleFuel).toLowerCase();
                                final String transLabel = trans.isEmpty || trans == 'any'
                                    ? ''
                                    : (trans[0].toUpperCase() + trans.substring(1));
                                final String fuelLabel = fuel.isEmpty || fuel == 'any'
                                    ? ''
                                    : (fuel[0].toUpperCase() + fuel.substring(1));
                                metaItems = [];
                                if (seats > 0) {
                                  metaItems.add(ListingMetaItem(icon: Icons.airline_seat_recline_normal, text: '$seats'));
                                }
                                if (transLabel.isNotEmpty) {
                                  metaItems.add(ListingMetaItem(icon: Icons.settings, text: transLabel));
                                }
                                if (fuelLabel.isNotEmpty) {
                                  final fuelIcon = fuel == 'electric' ? Icons.electric_bolt : Icons.local_gas_station;
                                  metaItems.add(ListingMetaItem(icon: fuelIcon, text: fuelLabel));
                                }
                              } else if (isVenueType) {
                                int seating = 0;
                                int maxGuests = 0;
                                if (backing != null) {
                                  final am = backing.amenities;
                                  final s1 = am['seating_capacity'];
                                  final s2 = am['venue_seated_capacity'];
                                  final mg = am['max_guests'];
                                  if (s1 is num) seating = s1.toInt();
                                  if (seating == 0 && s2 is num) seating = s2.toInt();
                                  if (mg is num) maxGuests = mg.toInt();
                                }
                                metaItems = [];
                                if (seating > 0) {
                                  metaItems.add(ListingMetaItem(icon: Icons.event_seat, text: '$seating seating'));
                                }
                                if (maxGuests > 0) {
                                  metaItems.add(ListingMetaItem(icon: Icons.groups, text: '$maxGuests guests'));
                                }
                              } else {
                                // Residential & Commercial: keep classic beds/baths
                                metaItems = [
                                  ListingMetaItem(icon: Icons.bed, text: '${p.bedrooms} bd'),
                                  ListingMetaItem(icon: Icons.bathtub, text: '${p.bathrooms} ba'),
                                ];
                              }

                              final vm = ListingViewModelFactory.fromRaw(
                                ref,
                                id: p.id,
                                title: p.title,
                                location: p.location,
                                price: p.price,
                                rentalUnit: unit,
                                imageUrl: p.imageUrl,
                                rating: p.rating,
                                reviewCount: null,
                                chips: [categoryTag, modeBadge],
                                metaItems: metaItems,
                                fallbackIcon: isVehicle ? Icons.directions_car_rounded : Icons.home,
                                isVehicle: isVehicle,
                                badges: p.isVerified ? const [ListingBadgeType.verified] : const [],
                              );
                              return ListingCard(
                                model: vm,
                                isDark: isDark,
                                width: tileWidthLocal,
                                margin: const EdgeInsets.only(bottom: 0),
                                chipOnImage: false,
                                showInfoChip: false,
                                chipInRatingRowRight: true,
                                priceBottomLeft: true,
                                shareBottomRight: true,
                              );
                            },
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(horizontalPaddingLocal, 12, horizontalPaddingLocal, bottomPad),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final p = _searchResults[index];
                              final bool isVehicle = p.type.toLowerCase() == 'vehicle';
                              String unit = isVehicle ? 'day' : 'month';
                              ls.Listing? backing;
                              try {
                                final listingsState = ref.read(ls.listingProvider);
                                final allListings = [...listingsState.listings, ...listingsState.userListings];
                                final found = allListings.where((l) => l.id == p.id).cast<ls.Listing?>().firstOrNull;
                                if (found?.rentalUnit != null && (found!.rentalUnit!.trim().isNotEmpty)) {
                                  unit = found.rentalUnit!.trim().toLowerCase();
                                }
                                backing = found;
                              } catch (_) {}
                              // Derive Category tag and mode badge (same as grid)
                              final String typeLower = p.type.toLowerCase();
                              final bool isVenueType = typeLower.startsWith('venue_') || typeLower == 'venue';
                              final String categoryTag = isVehicle
                                  ? 'Vehicle'
                                  : (isVenueType
                                      ? 'Venue'
                                      : (({
                                        'office', 'retail', 'showroom', 'warehouse'
                                      }.contains(typeLower))
                                      ? 'Commercial'
                                      : (typeLower == 'plot' ? 'Plot' : 'Residential')));
                              const String modeBadge = 'Rent';

                              // Build category-specific meta items (same logic as grid)
                              List<ListingMetaItem> metaItems;
                              if (isVehicle) {
                                final int seats = p.seats > 0 ? p.seats : (p.bedrooms > 0 ? p.bedrooms : 0);
                                final String trans = (p.vehicleTransmission).toLowerCase();
                                final String fuel = (p.vehicleFuel).toLowerCase();
                                final String transLabel = trans.isEmpty || trans == 'any'
                                    ? ''
                                    : (trans[0].toUpperCase() + trans.substring(1));
                                final String fuelLabel = fuel.isEmpty || fuel == 'any'
                                    ? ''
                                    : (fuel[0].toUpperCase() + fuel.substring(1));
                                metaItems = [];
                                if (seats > 0) {
                                  metaItems.add(ListingMetaItem(icon: Icons.airline_seat_recline_normal, text: '$seats'));
                                }
                                if (transLabel.isNotEmpty) {
                                  metaItems.add(ListingMetaItem(icon: Icons.settings, text: transLabel));
                                }
                                if (fuelLabel.isNotEmpty) {
                                  final fuelIcon = fuel == 'electric' ? Icons.electric_bolt : Icons.local_gas_station;
                                  metaItems.add(ListingMetaItem(icon: fuelIcon, text: fuelLabel));
                                }
                              } else if (isVenueType) {
                                int seating = 0;
                                int maxGuests = 0;
                                if (backing != null) {
                                  final am = backing.amenities;
                                  final s1 = am['seating_capacity'];
                                  final s2 = am['venue_seated_capacity'];
                                  final mg = am['max_guests'];
                                  if (s1 is num) seating = s1.toInt();
                                  if (seating == 0 && s2 is num) seating = s2.toInt();
                                  if (mg is num) maxGuests = mg.toInt();
                                }
                                metaItems = [];
                                if (seating > 0) {
                                  metaItems.add(ListingMetaItem(icon: Icons.event_seat, text: '$seating seating'));
                                }
                                if (maxGuests > 0) {
                                  metaItems.add(ListingMetaItem(icon: Icons.groups, text: '$maxGuests guests'));
                                }
                              } else {
                                metaItems = [
                                  ListingMetaItem(icon: Icons.bed, text: '${p.bedrooms} bd'),
                                  ListingMetaItem(icon: Icons.bathtub, text: '${p.bathrooms} ba'),
                                ];
                              }

                              final vm = ListingViewModelFactory.fromRaw(
                                ref,
                                id: p.id,
                                title: p.title,
                                location: p.location,
                                price: p.price,
                                rentalUnit: unit,
                                imageUrl: p.imageUrl,
                                rating: p.rating,
                                reviewCount: null,
                                chips: [categoryTag, modeBadge],
                                metaItems: metaItems,
                                fallbackIcon: isVehicle ? Icons.directions_car_rounded : Icons.home,
                                isVehicle: isVehicle,
                                badges: p.isVerified ? const [ListingBadgeType.verified] : const [],
                              );
                              return ListingListCard(
                                model: vm,
                                isDark: isDark,
                                margin: EdgeInsets.zero,
                                chipOnImage: false,
                                showInfoChip: false,
                                chipBelowImage: true,
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  
}

class PropertyResult {
  final String id;
  final String title;
  final double price;
  final double rating;
  final String imageUrl;
  final String location;
  final String type;
  final int bedrooms;
  final int bathrooms;
  final bool isVerified;
  final bool instantBooking;
  final double latitude;
  final double longitude;
  // New optional attributes for advanced filtering
  final int builtUpArea; // in sq ft
  final String furnishType; // full | semi | unfurnished
  final String preferredTenant; // family | male | female | others | any
  final Set<String> amenities; // essential amenities keys
  // Plot-specific attributes
  final int plotSize; // sq ft
  final String plotUsage; // any | agriculture | commercial | events | construction
  // Vehicle-specific attributes
  final String vehicleCategory; // suv | sedan | hatchback | bikes | vans | electric | all
  final String vehicleFuel; // any | electric | petrol | diesel
  final String vehicleTransmission; // any | automatic | manual
  final int seats; // dedicated seat count (fallback to bedrooms when 0)
  
  PropertyResult({
    required this.id,
    required this.title,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.location,
    required this.type,
    required this.bedrooms,
    required this.bathrooms,
    required this.isVerified,
    required this.instantBooking,
    required this.latitude,
    required this.longitude,
    this.builtUpArea = 0,
    this.furnishType = 'unfurnished',
    this.preferredTenant = 'any',
    this.amenities = const <String>{},
    this.plotSize = 0,
    this.plotUsage = 'any',
    this.vehicleCategory = '',
    this.vehicleFuel = 'any',
    this.vehicleTransmission = 'any',
    this.seats = 0,
  });
}
