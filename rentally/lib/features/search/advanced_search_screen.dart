import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/auth_router.dart';
import '../../widgets/responsive_layout.dart';
import '../../core/widgets/loading_states.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/listing_card.dart' show ListingMetaItem, ListingCard;
import '../../core/widgets/listing_card_list.dart';
import '../../core/widgets/listing_badges.dart' show ListingBadgeType;
import '../../core/widgets/listing_vm_factory.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/advanced_map_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/listing_service.dart' as ls;
import '../../core/neo/neo.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';

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
  
  // Filter values
  String _propertyType = 'all';
  RangeValues _priceRange = const RangeValues(0, 5000);
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
  String _toRentCategory = 'residential'; // residential | commercial | plot (UI only)
  String _furnishType = 'any'; // any | full | semi | unfurnished
  String _preferredTenant = 'any'; // any | family | bachelors | students | male | female | others
  Set<String> _amenities = <String>{}; // wifi, parking, ac, heating, pets, kitchen, balcony, elevator
  // Plots filters
  int _plotMinSize = 0; // sq ft, 0 = Any
  int _plotMaxSize = 0; // 0 = Any / 50000+ etc.
  String _plotUsage = 'any'; // any | agriculture | commercial | events | construction
  // Location radius filter (km) and reference center (placeholder)
  double _radiusKm = 0; // 0 = Any
  final double _centerLat = 37.4219999;
  final double _centerLng = -122.0840575;
  
  // Available options
  final List<String> _propertyTypes = [
    'all', 'apartment', 'house', 'villa', 'studio', 'room',
    // commercial basics for mock typing
    'office', 'retail', 'showroom', 'warehouse',
    // plots and vehicles
    'plot', 'vehicle'
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Setup listeners
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);

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
  
  
  
  Future<void> _performSearch() async {
    setState(() {
      _searchQuery = _searchController.text;
      _isSearching = true;
    });
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        List<PropertyResult> results = _isVehicleMode ? _generateVehicleResults() : _generateMockResults();
        final t = _propertyType.toLowerCase();
        final bool knownPropertyType = _propertyTypes.contains(t);
        if (!_isVehicleMode && t != 'all' && knownPropertyType) {
          results = results.where((r) => r.type.toLowerCase() == t).toList();
        }
        // Apply simple text filter
        if (_searchQuery.isNotEmpty) {
          results = results.where((r) => r.title.toLowerCase().contains(_searchQuery.toLowerCase()) || r.location.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }
        // Apply top-level category filter (Residential / Commercial / Plots)
        if (!_isVehicleMode) {
          const residentialTypes = {'apartment','house','villa','studio','room'};
          const commercialTypes = {'office','retail','showroom','warehouse'};
          if (_toRentCategory == 'residential') {
            results = results.where((r) => residentialTypes.contains(r.type.toLowerCase())).toList();
          } else if (_toRentCategory == 'commercial') {
            results = results.where((r) => commercialTypes.contains(r.type.toLowerCase())).toList();
          } else if (_toRentCategory == 'plot') {
            results = results.where((r) => r.type.toLowerCase() == 'plot').toList();
          }
        }
        // Apply property-specific filters from the filter sheet
        if (!_isVehicleMode) {
          results = results.where((r) {
            final bool isResidential = _toRentCategory == 'residential';
            final bool isPlot = _toRentCategory == 'plot';
            final bool priceOk = r.price >= _priceRange.start && r.price <= _priceRange.end;
            final bool bedsOk = !isResidential || _bedrooms == 0 || r.bedrooms >= _bedrooms; // apply only for residential
            final bool bathsOk = !isResidential || _bathrooms == 0 || r.bathrooms >= _bathrooms; // apply only for residential
            final bool instantOk = !_instantBooking || r.instantBooking;
            final bool verifiedOk = !_verifiedOnly || r.isVerified;
            final bool imagesOk = !_imagesOnly || (r.imageUrl.trim().isNotEmpty);
            // Built-up ignored for plots; add plot filters
            final bool builtMinOk = isPlot || _builtUpMinSqFt == 0 || r.builtUpArea >= _builtUpMinSqFt;
            final bool builtMaxOk = isPlot ? true : ((_builtUpMaxSqFt == 0 || _builtUpMaxSqFt == 4000) ? true : r.builtUpArea <= _builtUpMaxSqFt);
            final bool plotMinOk = !isPlot || _plotMinSize == 0 || r.plotSize >= _plotMinSize;
            final bool plotMaxOk = !isPlot || _plotMaxSize == 0 || r.plotSize <= _plotMaxSize;
            final bool plotUsageOk = !isPlot || _plotUsage == 'any' || r.plotUsage == _plotUsage;
            final bool furnishOk = isPlot ? true : (_furnishType == 'any' || r.furnishType == _furnishType);
            final bool tenantOk = !isResidential || _preferredTenant == 'any' || r.preferredTenant == _preferredTenant; // apply only for residential
            final bool amenityOk = _amenities.isEmpty || _amenities.every((a) => r.amenities.contains(a));
            return priceOk && bedsOk && bathsOk && instantOk && verifiedOk && imagesOk && builtMinOk && builtMaxOk && plotMinOk && plotMaxOk && plotUsageOk && furnishOk && tenantOk && amenityOk;
          }).toList();
        }
        // Apply vehicle-specific filters
        else {
          results = results.where((r) {
            final bool priceOk = r.price >= _priceRange.start && r.price <= _priceRange.end;
            final bool instantOk = !_instantBooking || r.instantBooking;
            final bool verifiedOk = !_verifiedOnly || r.isVerified;
            return priceOk && instantOk && verifiedOk;
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
    final propertyTypesPool = ['apartment','house','villa','studio','room','office','retail','showroom','warehouse','plot'];
    final plotUsages = ['agriculture','commercial','events','construction'];
    return List.generate(20, (index) {
      final type = propertyTypesPool[index % propertyTypesPool.length];
      final isPlot = type == 'plot';
      final int builtArea = isPlot ? 0 : (100 + (index % 50) * 100); // 0 for plots; 100..5000 for others
      final int beds = isPlot ? 0 : ((index % 4) + 1);
      final int baths = isPlot ? 0 : ((index % 3) + 1);
      final int pSize = isPlot ? (1000 + (index % 20) * 500) : 0; // 1000..11500 sq ft
      final String pUsage = isPlot ? plotUsages[index % plotUsages.length] : 'any';
      
      return PropertyResult(
        id: 'prop_$index',
        title: '${isPlot ? 'Open ' : 'Modern '}$type in City Center',
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
        plotSize: pSize,
        plotUsage: pUsage,
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
      final bool isPlot = _toRentCategory == 'plot';
      if (_propertyType != 'all') count++;
      if (_priceRange.start > 0 || _priceRange.end < 5000) count++;
      if (isResidential && _bedrooms > 0) count++;
      if (isResidential && _bathrooms > 0) count++;
      if (_instantBooking) count++;
      if (_verifiedOnly) count++;
      if (_imagesOnly) count++;
      if (_builtUpMinSqFt > 0 || _builtUpMaxSqFt > 0) count++;
      if (_furnishType != 'any') count++;
      if (isResidential && _preferredTenant != 'any') count++;
      if (_amenities.isNotEmpty) count++;
      if (isPlot && (_plotMinSize > 0 || _plotMaxSize > 0)) count++;
      if (isPlot && _plotUsage != 'any') count++;
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
              : (isDark ? theme.colorScheme.surface.withOpacity(0.08) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.primaryColor
                : (isDark
                    ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.5)
                    : theme.colorScheme.outline.withOpacity(0.2)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
              blurRadius: 10,
              offset: const Offset(-5, -5),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: (isDark
                      ? EnterpriseDarkTheme.primaryAccent
                      : EnterpriseLightTheme.primaryAccent)
                  .withOpacity(isDark ? 0.18 : 0.12),
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
                : (isDark ? theme.colorScheme.surface.withOpacity(0.08) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isGridView
                  ? theme.primaryColor
                  : (isDark
                      ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.5)
                      : theme.colorScheme.outline.withOpacity(0.2)),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                blurRadius: 10,
                offset: const Offset(-5, -5),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: (isDark
                        ? EnterpriseDarkTheme.primaryAccent
                        : EnterpriseLightTheme.primaryAccent)
                    .withOpacity(isDark ? 0.18 : 0.12),
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
            color: isDark ? theme.colorScheme.surface.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.5)
                  : theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                blurRadius: 10,
                offset: const Offset(-5, -5),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: (isDark
                        ? EnterpriseDarkTheme.primaryAccent
                        : theme.primaryColor)
                    .withOpacity(isDark ? 0.18 : 0.12),
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
                  : (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.50)),
              borderColor: isSelected
                  ? _getFilterBorderColor(filter.icon, theme.primaryColor)
                  : (isDark ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.85)),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(isDark ? 0.14 : 0.10),
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
        return Colors.orange.withOpacity(0.15); // Light orange background
      case Icons.verified:
        return Colors.green.withOpacity(0.15); // Light green background
      case Icons.electric_bolt:
        return Colors.blue.withOpacity(0.15); // Light blue background
      case Icons.settings:
        return Colors.purple.withOpacity(0.15); // Light purple background
      default:
        return defaultColor; // Use theme primary color for other filters
    }
  }

  Color _getFilterBorderColor(IconData? icon, Color defaultColor) {
    if (icon == null) return defaultColor;
    
    switch (icon) {
      case Icons.flash_on:
        return Colors.orange.withOpacity(0.4); // Orange border
      case Icons.verified:
        return Colors.green.withOpacity(0.4); // Green border
      case Icons.electric_bolt:
        return Colors.blue.withOpacity(0.4); // Blue border
      case Icons.settings:
        return Colors.purple.withOpacity(0.4); // Purple border
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
        final Set<String> localAmenities = {..._amenities};
        int localPlotMin = _plotMinSize;
        int localPlotMax = _plotMaxSize;
        String localPlotUsage = _plotUsage;

        const List<String> propertyTypesResidential = ['all','apartment','house','villa','studio','room'];
        const List<String> propertyTypesCommercial = ['all','office','retail','showroom','warehouse'];
        const List<String> propertyTypesPlot = ['all','plot'];
        final List<double> budgetOptions = [0, 100, 200, 300, 400, 500, 750, 1000, 1500, 2000, 3000, 4000, 5000];
        final List<int> builtUpOptions = [0, 100, 200, 400, 600, 800, 1000, 1500, 2000, 3000, 4000];
        final List<int> plotSizeOptions = [0, 1000, 2000, 5000, 10000, 20000, 50000];

        String typeLabel(String t) {
          switch (t) {
            case 'apartment': return 'Apartment';
            case 'house': return 'Independent House';
            case 'villa': return 'Independent Villa';
            case 'studio': return '1RK/Studio House';
            case 'room': return 'Room';
            case 'office': return 'Ready to use Office Space';
            case 'retail': return 'Retail Shop';
            case 'showroom': return 'Showroom';
            case 'warehouse': return 'Warehouse';
            case 'plot': return 'Plot / Land';
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
          fillColor: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.06) : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2))),
        );

        return StatefulBuilder(
          builder: (context, setLocal) {
            final types = localToRent == 'commercial'
                ? propertyTypesCommercial
                : (localToRent == 'plot' ? propertyTypesPlot : propertyTypesResidential);
            double floorBudget(double t) { double sel = budgetOptions.first; for (final v in budgetOptions) { if (v <= t) sel = v; } return sel; }
            double ceilBudget(double t) { double sel = budgetOptions.last; for (final v in budgetOptions) { if (v >= t) { sel = v; break; } } return sel; }
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.88,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Modern Header
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Search Filters',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Refine your search results',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // To Rent segment in card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? theme.colorScheme.surface.withOpacity(0.3)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (theme.brightness == Brightness.dark
                                  ? EnterpriseDarkTheme.primaryAccent
                                  : EnterpriseLightTheme.primaryAccent)
                              .withOpacity(theme.brightness == Brightness.dark ? 0.18 : 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.home_work_outlined, size: 18, color: theme.primaryColor),
                            const SizedBox(width: 8),
                            Text('Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              showCheckmark: false,
                              label: Text('Residential', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: localToRent == 'residential' ? Colors.white : theme.colorScheme.onSurface)),
                              selected: localToRent == 'residential',
                              selectedColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              onSelected: (v) => setLocal(() => localToRent = 'residential'),
                            ),
                            ChoiceChip(
                              showCheckmark: false,
                              label: Text('Commercial', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: localToRent == 'commercial' ? Colors.white : theme.colorScheme.onSurface)),
                              selected: localToRent == 'commercial',
                              selectedColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              onSelected: (v) => setLocal(() {
                                localToRent = 'commercial';
                                localBhk = 0;
                                localTenant = 'any';
                                localBaths = 0;
                              }),
                            ),
                            ChoiceChip(
                              showCheckmark: false,
                              label: Text('Plots', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: localToRent == 'plot' ? Colors.white : theme.colorScheme.onSurface)),
                              selected: localToRent == 'plot',
                              selectedColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              onSelected: (v) => setLocal(() {
                                localToRent = 'plot';
                                localBhk = 0;
                                localTenant = 'any';
                                localBaths = 0;
                                localBuiltMin = 0;
                                localBuiltMax = 0;
                              }),
                            ),
                            ChoiceChip(
                              showCheckmark: false,
                              label: Text('Vehicles', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                              selected: false,
                              selectedColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              onSelected: (v) {
                                setState(() { _isVehicleMode = true; _propertyType = 'vehicle'; });
                                _performSearch();
                                Navigator.of(sheetContext).pop();
                                Future.delayed(const Duration(milliseconds: 120), _toggleFilters);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Property Type chips
                          Text('Property Type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: types.map((t) {
                              final sel = localPropertyType == t;
                              return ChoiceChip(
                                showCheckmark: false,
                                selected: sel,
                                selectedColor: theme.colorScheme.primary,
                                shape: const StadiumBorder(),
                                label: Text(
                                  typeLabel(t),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : theme.colorScheme.onSurface),
                                ),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) => setLocal(() => localPropertyType = t),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          // Budget
                          Text('Budget', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    dropdownLabel('Min'),
                                    DropdownButtonFormField<double>(
                                      value: floorBudget(localMinBudget),
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    dropdownLabel('Max'),
                                    DropdownButtonFormField<double>(
                                      value: ceilBudget(localMaxBudget),
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
                          const SizedBox(height: 16),
                          // Built-up area
                          Text('Built up area', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    dropdownLabel('Min'),
                                    DropdownButtonFormField<int>(
                                      value: builtUpOptions.contains(localBuiltMin) ? localBuiltMin : 0,
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    dropdownLabel('Max'),
                                    DropdownButtonFormField<int>(
                                      value: builtUpOptions.contains(localBuiltMax) ? localBuiltMax : 0,
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
                          const SizedBox(height: 16),
                          // Plot Size & Usage (visible when Plots selected)
                          if (localToRent == 'plot') ...[
                            Text('Plot Size', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      dropdownLabel('Min'),
                                      DropdownButtonFormField<int>(
                                        value: plotSizeOptions.contains(localPlotMin) ? localPlotMin : 0,
                                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                        items: plotSizeOptions.map((v) => DropdownMenuItem<int>(
                                          value: v,
                                          child: Text(v == 0 ? 'Any' : '$v sq ft', style: const TextStyle(fontSize: 12)),
                                        )).toList(),
                                        onChanged: (v) => setLocal(() => localPlotMin = v ?? 0),
                                        decoration: ddDecoration(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      dropdownLabel('Max'),
                                      DropdownButtonFormField<int>(
                                        value: plotSizeOptions.contains(localPlotMax) ? localPlotMax : 0,
                                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                        items: plotSizeOptions.map((v) => DropdownMenuItem<int>(
                                          value: v,
                                          child: Text(v == 0 ? 'Any' : '$v sq ft', style: const TextStyle(fontSize: 12)),
                                        )).toList(),
                                        onChanged: (v) => setLocal(() => localPlotMax = v ?? 0),
                                        decoration: ddDecoration(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Plot Usage', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: ['any','agriculture','commercial','events','construction'].map((u) {
                                final sel = localPlotUsage == u;
                                String label;
                                switch (u) {
                                  case 'agriculture': label = 'Agriculture'; break;
                                  case 'commercial': label = 'Commercial'; break;
                                  case 'events': label = 'Events'; break;
                                  case 'construction': label = 'Construction'; break;
                                  default: label = 'Any';
                                }
                                return ChoiceChip(
                                  showCheckmark: false,
                                  selected: sel,
                                  selectedColor: theme.colorScheme.primary,
                                  shape: const StadiumBorder(),
                                  label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : theme.colorScheme.onSurface)),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (_) => setLocal(() => localPlotUsage = u),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (localToRent == 'residential') ...[
                            // Preferred Tenant
                            Text('Preferred Tenant', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: ['any','family','bachelors','students','male','female','others'].map((t) {
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
                                return ChoiceChip(
                                  showCheckmark: false,
                                  selected: sel,
                                  selectedColor: theme.colorScheme.primary,
                                  shape: const StadiumBorder(),
                                  label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : theme.colorScheme.onSurface)),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (_) => setLocal(() => localTenant = t),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            // Bedrooms & Bathrooms
                            Text('Bedrooms & Bathrooms', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      dropdownLabel('Bedrooms (max)'),
                                      DropdownButtonFormField<int>(
                                        value: [0,1,2,3,4,5].contains(localBhk) ? localBhk : 0,
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      dropdownLabel('Bathrooms (min)'),
                                      DropdownButtonFormField<int>(
                                        value: [0,1,2,3,4,5].contains(localBaths) ? localBaths : 0,
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
                            const SizedBox(height: 16),
                          ],
                          // Furnish Type
                          Text('Furnish Type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: ['any','full','semi','unfurnished'].map((f) {
                              final sel = localFurnish == f;
                              String label;
                              switch (f) {
                                case 'full': label = 'Fully Furnished'; break;
                                case 'semi': label = 'Semi Furnished'; break;
                                case 'unfurnished': label = 'Unfurnished'; break;
                                default: label = 'Any';
                              }
                              return ChoiceChip(
                                showCheckmark: false,
                                selected: sel,
                                selectedColor: theme.colorScheme.primary,
                                shape: const StadiumBorder(),
                                label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : theme.colorScheme.onSurface)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) => setLocal(() => localFurnish = f),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          // Essential Amenities
                          Text('Essential Amenities', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: ['wifi','parking','ac','heating','pets','kitchen','balcony','elevator'].map((k) {
                              final sel = localAmenities.contains(k);
                              String label;
                              switch (k) {
                                case 'wifi': label = 'High-Speed WiFi'; break;
                                case 'parking': label = 'Parking'; break;
                                case 'ac': label = 'Air Conditioning'; break;
                                case 'heating': label = 'Heating'; break;
                                case 'pets': label = 'Pets Allowed'; break;
                                case 'kitchen': label = 'Full Kitchen'; break;
                                case 'balcony': label = 'Balcony/Patio'; break;
                                case 'elevator': label = 'Elevator'; break;
                                default: label = k;
                              }
                              return FilterChip(
                                showCheckmark: false,
                                selected: sel,
                                avatar: Icon(
                                  () {
                                    switch (k) {
                                      case 'wifi': return Icons.wifi;
                                      case 'parking': return Icons.local_parking;
                                      case 'ac': return Icons.ac_unit;
                                      case 'heating': return Icons.whatshot;
                                      case 'pets': return Icons.pets;
                                      case 'kitchen': return Icons.kitchen;
                                      case 'balcony': return Icons.deck;
                                      case 'elevator': return Icons.elevator;
                                      default: return Icons.check_box_outline_blank;
                                    }
                                  }(),
                                  size: 16,
                                  color: sel ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.85),
                                ),
                                label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : theme.colorScheme.onSurface)),
                                selectedColor: theme.colorScheme.primary,
                                shape: const StadiumBorder(),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                onSelected: (v) => setLocal(() {
                                  if (v) {
                                    localAmenities.add(k);
                                  } else {
                                    localAmenities.remove(k);
                                  }
                                }),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          // Toggles
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: Text('View Only Properties with Images', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                            value: localImagesOnly,
                            onChanged: (v) => setLocal(() => localImagesOnly = v),
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
                      border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.08))),
                      boxShadow: [
                        BoxShadow(
                          color: (theme.brightness == Brightness.dark
                                  ? EnterpriseDarkTheme.primaryAccent
                                  : EnterpriseLightTheme.primaryAccent)
                              .withOpacity(theme.brightness == Brightness.dark ? 0.16 : 0.08),
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
                              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3), width: 1.5),
                              foregroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              backgroundColor: theme.brightness == Brightness.dark
                                  ? theme.colorScheme.surface.withOpacity(0.05)
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
                                _builtUpMinSqFt = 0;
                                _builtUpMaxSqFt = 0;
                                _toRentCategory = 'residential';
                                _furnishType = 'any';
                                _preferredTenant = 'any';
                                _amenities = <String>{};
                                _plotMinSize = 0;
                                _plotMaxSize = 0;
                                _plotUsage = 'any';
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
                                _amenities = {...localAmenities};
                                _plotMinSize = localPlotMin;
                                _plotMaxSize = localPlotMax;
                                _plotUsage = localPlotUsage;
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
                              shadowColor: theme.colorScheme.primary.withOpacity(0.4),
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
      if (mounted) setState(() => _showFilters = false);
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
      _plotMinSize = 0;
      _plotMaxSize = 0;
      _plotUsage = 'any';
    });
    _performSearch();
  }
  
  void _applyFilters() {
    _performSearch();
  }
  
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.home);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? theme.colorScheme.background : Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildSearchHeader(theme, isDark),
              // 1px seam mask matching page background to eliminate any anti-aliased line
              Container(
                height: 1,
                color: isDark ? theme.colorScheme.background : Colors.white,
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
    return NeoGlass(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.zero,
      backgroundColor: isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.white, // distinct from results background (0xFFF3F4F6)
      borderColor: Colors.transparent,
      borderWidth: 0,
      blur: isDark ? 12 : 0,
      boxShadow: isDark
          ? [
              ...NeoDecoration.shadows(
                context,
                distance: 5,
                blur: 14,
                spread: 0.2,
              ),
              BoxShadow(
                color: (isDark
                        ? EnterpriseDarkTheme.primaryAccent
                        : EnterpriseLightTheme.primaryAccent)
                    .withOpacity(isDark ? 0.16 : 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
                spreadRadius: 0.1,
              ),
            ]
          : const [],
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? EnterpriseDarkTheme.primaryBackground : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.35)
                          : EnterpriseLightTheme.secondaryBorder,
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                        blurRadius: 10,
                        offset: const Offset(-5, -5),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: (isDark
                                ? EnterpriseDarkTheme.primaryAccent
                                : EnterpriseLightTheme.primaryAccent)
                            .withOpacity(isDark ? 0.18 : 0.12),
                        blurRadius: 10,
                        offset: const Offset(5, 5),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchHint,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? EnterpriseDarkTheme.tertiaryText
                            : EnterpriseLightTheme.tertiaryText,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 10),
                        child: Icon(
                          Icons.search,
                          size: 18,
                          color: isDark
                              ? EnterpriseDarkTheme.primaryAccent
                              : EnterpriseLightTheme.secondaryText,
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child:
                              IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                  color: isDark ? Colors.white60 : Colors.grey[600],
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch();
                                },
                                splashRadius: 15,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              ),
                            )
                          : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 10,
                    ),
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
                            : (isDark ? theme.colorScheme.surface.withOpacity(0.08) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showFilters
                              ? theme.primaryColor
                              : (isDark
                                  ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.5)
                                  : theme.colorScheme.outline.withOpacity(0.2)),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                            blurRadius: 10,
                            offset: const Offset(-5, -5),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: (isDark
                                    ? EnterpriseDarkTheme.primaryAccent
                                    : EnterpriseLightTheme.primaryAccent)
                                .withOpacity(isDark ? 0.18 : 0.12),
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
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _countActiveFilters() > 9 ? '9+' : '${_countActiveFilters()}',
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
            const SizedBox(width: 12),
          ],
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOutCubicEmphasized,
              alignment: Alignment.topCenter,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                offset: _showQuickControls ? Offset.zero : const Offset(0, -0.2),
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
    return Column(
      children: [
        // Modern Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Options',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Customize your search preferences',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Filter Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _isVehicleMode ? _buildVehicleFilterContent(theme) : _buildPropertyFilterContent(theme),
          ),
        ),
        // Modern Action Buttons
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _resetFilters();
                    Navigator.of(dialogContext).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: theme.primaryColor),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.reset,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.applyFilters,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildModernChoiceChip(String label, bool selected, VoidCallback onTap, ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.primaryColor : theme.dividerColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : theme.textTheme.bodyMedium?.color,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
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
          color: selected ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.primaryColor : theme.dividerColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? theme.primaryColor : theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
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
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: value > min ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.remove_rounded,
                color: value > min ? theme.primaryColor : theme.disabledColor,
                size: 18,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: theme.primaryColor,
              ),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: value < max ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.add_rounded,
                color: value < max ? theme.primaryColor : theme.disabledColor,
                size: 18,
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
        ? theme.colorScheme.background
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
              Icon(Icons.search_off, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text('No Results Found', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or search terms.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                  final double fudge = 3.0 + (textScale > 1.0 ? (textScale - 1.0) * 18.0 : 0.0);
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
                            itemCount: _searchResults.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCountLocal,
                              mainAxisSpacing: spacingLocal,
                              crossAxisSpacing: spacingLocal,
                              childAspectRatio: computedChildAspectRatioLocal,
                            ),
                            itemBuilder: (context, index) {
                              final p = _searchResults[index];
                              final bool isVehicle = p.type.toLowerCase() == 'vehicle';
                              // Resolve unit via ListingService if available, else fallback by type
                              String unit = isVehicle ? 'hour' : 'month';
                              try {
                                final listingsState = ref.read(ls.listingProvider);
                                final allListings = [...listingsState.listings, ...listingsState.userListings];
                                final found = allListings.where((l) => l.id == p.id).cast<ls.Listing?>().firstOrNull;
                                if (found?.rentalUnit != null && (found!.rentalUnit!.trim().isNotEmpty)) {
                                  unit = found.rentalUnit!.trim().toLowerCase();
                                }
                              } catch (_) {}
                              // Derive Category tag and mode badge for clarity
                              final String categoryTag = isVehicle
                                  ? 'Vehicle'
                                  : (({
                                            'office', 'retail', 'showroom', 'warehouse'
                                          }.contains(p.type.toLowerCase()))
                                      ? 'Commercial'
                                      : (p.type.toLowerCase() == 'plot' ? 'Plot' : 'Residential'));
                              const String modeBadge = 'Rent';

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
                                metaItems: isVehicle
                                    ? [
                                        ListingMetaItem(icon: Icons.event_seat, text: '${p.bedrooms} seats'),
                                      ]
                                    : [
                                        ListingMetaItem(icon: Icons.bed, text: '${p.bedrooms} bd'),
                                        ListingMetaItem(icon: Icons.bathtub, text: '${p.bathrooms} ba'),
                                      ],
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
                              try {
                                final listingsState = ref.read(ls.listingProvider);
                                final allListings = [...listingsState.listings, ...listingsState.userListings];
                                final found = allListings.where((l) => l.id == p.id).cast<ls.Listing?>().firstOrNull;
                                if (found?.rentalUnit != null && (found!.rentalUnit!.trim().isNotEmpty)) {
                                  unit = found.rentalUnit!.trim().toLowerCase();
                                }
                              } catch (_) {}
                              // Derive Category tag and mode badge (same as grid)
                              final String categoryTag = isVehicle
                                  ? 'Vehicle'
                                  : (({
                                        'office', 'retail', 'showroom', 'warehouse'
                                      }.contains(p.type.toLowerCase()))
                                      ? 'Commercial'
                                      : (p.type.toLowerCase() == 'plot' ? 'Plot' : 'Residential'));
                              const String modeBadge = 'Rent';

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
                                metaItems: isVehicle
                                    ? [
                                        ListingMetaItem(icon: Icons.event_seat, text: '${p.bedrooms} seats'),
                                      ]
                                    : [
                                        ListingMetaItem(icon: Icons.bed, text: '${p.bedrooms} bd'),
                                        ListingMetaItem(icon: Icons.bathtub, text: '${p.bathrooms} ba'),
                                      ],
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
  });
}
