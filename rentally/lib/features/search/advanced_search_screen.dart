import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/auth_router.dart';
import '../../widgets/responsive_layout.dart';
import '../../core/widgets/loading_states.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/listing_card_list.dart';
import '../../core/widgets/listing_card.dart' show ListingViewModel, ListingMetaItem, ListingCard;
import '../../core/widgets/listing_badges.dart' show ListingBadgeType;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/advanced_map_widget.dart';

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
  // Filters open in a centered dialog; no inline animations
  
  // Search state
  String _searchQuery = '';
  bool _showFilters = false;
  bool _isSearching = false;
  List<PropertyResult> _searchResults = [];
  String? _categoryKeyword; // optional keyword hint for vehicle sub-categories like SUV, Sedan
  bool _isVehicleMode = false;
  bool _isGridView = true; // toggles between list and grid view (default: grid)
  bool _showMapView = false; // toggles between list/grid vs map view
  String _sortOption = 'relevance'; // relevance | price_asc | price_desc | rating_desc
  
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
  
  // Available options
  final List<String> _propertyTypes = [
    'all', 'apartment', 'house', 'villa', 'studio', 'room', 'vehicle'
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Setup listeners
    _searchController.addListener(_onSearchChanged);

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
    // No inline filter animation to dispose
    super.dispose();
  }
  
  void _onSearchChanged() {
    if (_searchController.text != _searchQuery) {
      _debounceSearch();
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
        if (!_isVehicleMode && t != 'all') {
          results = results.where((r) => r.type.toLowerCase() == t).toList();
        }
        // Apply simple text filter
        if (_searchQuery.isNotEmpty) {
          results = results.where((r) => r.title.toLowerCase().contains(_searchQuery.toLowerCase()) || r.location.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
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
    return List.generate(20, (index) => PropertyResult(
      id: 'prop_$index',
      title: 'Modern ${_propertyTypes[index % _propertyTypes.length]} in City Center',
      price: 50.0 + (index * 10),
      rating: 4.0 + (index % 10) / 10,
      imageUrl: 'https://picsum.photos/400/300?random=$index',
      location: 'Downtown, City',
      type: _propertyTypes[index % _propertyTypes.length],
      bedrooms: (index % 4) + 1,
      bathrooms: (index % 3) + 1,
      isVerified: index % 2 == 0,
      instantBooking: index % 3 == 0,
      latitude: baseLat + (index % 10) * 0.0015,
      longitude: baseLng + (index % 10) * 0.0015,
    ));
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
      if (_searchQuery.isNotEmpty) count++;
      return count;
    } else {
      if (_propertyType != 'all') count++;
      if (_priceRange.start > 0 || _priceRange.end < 5000) count++;
      if (_bedrooms > 0) count++;
      if (_bathrooms > 0) count++;
      if (_instantBooking) count++;
      if (_verifiedOnly) count++;
      if (_searchQuery.isNotEmpty) count++;
      return count;
    }
  }

  Widget _buildModeControlsRow(ThemeData theme, bool isDark) {
    Widget buildIconToggle({required IconData icon, required bool selected, required VoidCallback onTap, String? tooltip}) {
      return Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: selected
              ? theme.primaryColor
              : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.primaryColor
                : (isDark ? Colors.white24 : theme.primaryColor.withOpacity(0.6)),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.35),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: tooltip,
              icon: Icon(
                icon,
                size: selected ? 24 : 22,
                color: selected ? Colors.white : (isDark ? Colors.white70 : theme.primaryColor),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              visualDensity: VisualDensity.compact,
              splashRadius: 22,
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
      );
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
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: _isGridView
                ? theme.primaryColor
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isGridView
                  ? theme.primaryColor
                  : (isDark ? Colors.white24 : theme.primaryColor.withOpacity(0.6)),
              width: _isGridView ? 2 : 1,
            ),
            boxShadow: _isGridView
                ? [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.35),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: _isGridView ? 'Grid view' : 'List view',
                icon: Icon(
                  _isGridView ? Icons.grid_view : Icons.view_list,
                  size: _isGridView ? 24 : 22,
                  color: _isGridView ? Colors.white : (isDark ? Colors.white70 : theme.primaryColor),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                visualDensity: VisualDensity.compact,
                splashRadius: 22,
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
        // Map toggle
        Expanded(child: Center(child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: _showMapView
                ? theme.primaryColor
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _showMapView
                  ? theme.primaryColor
                  : (isDark ? Colors.white24 : theme.primaryColor.withOpacity(0.6)),
              width: _showMapView ? 2 : 1,
            ),
            boxShadow: _showMapView
                ? [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.35),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Map view',
                icon: Icon(
                  Icons.map,
                  size: 22,
                  color: _showMapView ? Colors.white : (isDark ? Colors.white70 : theme.primaryColor),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                visualDensity: VisualDensity.compact,
                splashRadius: 22,
                onPressed: () { setState(() => _showMapView = !_showMapView); },
              ),
              if (_showMapView)
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
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white24 : theme.primaryColor.withOpacity(0.6)),
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
          ),
          child: PopupMenuButton<String>(
            tooltip: 'Sort',
            onSelected: (value) { setState(() { _sortOption = value; }); _performSearch(); },
            position: PopupMenuPosition.under,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'relevance', child: ListTile(leading: Icon(Icons.auto_awesome, size: 18), title: Text('Relevance'))),
              PopupMenuItem(value: 'price_asc', child: ListTile(leading: Icon(Icons.south_east, size: 18), title: Text('Price: Low to High'))),
              PopupMenuItem(value: 'price_desc', child: ListTile(leading: Icon(Icons.north_east, size: 18), title: Text('Price: High to Low'))),
              PopupMenuItem(value: 'rating_desc', child: ListTile(leading: Icon(Icons.star_rate, size: 18), title: Text('Rating: High to Low'))),
            ],
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(child: Icon(Icons.sort_rounded, size: 22, color: isDark ? Colors.white70 : theme.primaryColor)),
            ),
          ),
        ))),
      ],
    );
  }
  
  Widget _buildMapView(ThemeData theme) {
    final props = _searchResults.map((p) => MapProperty(
      id: p.id,
      title: p.title,
      imageUrl: p.imageUrl,
      price: p.price,
      rating: p.rating,
      position: LatLng(p.latitude, p.longitude),
      propertyType: p.type,
    )).toList();
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
    setState(() => _showFilters = true);
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(dialogContext).size.width - 40,
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _buildModernFilterPanel(theme, dialogContext),
            ),
          ),
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
        backgroundColor: isDark ? theme.colorScheme.background : const Color(0xFFF3F4F6),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildSearchHeader(theme, isDark),
              const SizedBox.shrink(),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.background : const Color(0xFFF3F4F6),
        boxShadow: const [],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(Routes.home);
                  }
                },
              ),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search properties, locations...',
                      hintStyle: const TextStyle(fontSize: 14),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: _showFilters
                      ? theme.primaryColor
                      : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _showFilters
                        ? theme.primaryColor
                        : (isDark ? Colors.white24 : theme.primaryColor.withOpacity(0.6)),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        size: 22,
                        color: _showFilters ? Colors.white : (isDark ? Colors.white : theme.primaryColor),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      visualDensity: VisualDensity.compact,
                      splashRadius: 28,
                      onPressed: _toggleFilters,
                    ),
                    Builder(builder: (_) {
                      final fc = _countActiveFilters();
                      if (fc <= 0) return const SizedBox.shrink();
                      return Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            fc > 9 ? '9+' : '$fc',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          // Saved search button removed
          const SizedBox(height: 14),
              _buildModeControlsRow(theme, isDark),
              const SizedBox(height: 8),
            ],
          ),
        );
  }

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
                    'Reset All',
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Apply Filters',
                        style: TextStyle(fontWeight: FontWeight.w600),
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
        : const Color(0xFFF3F4F6);
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
                    const double horizontalPaddingLocal = horizontalPadding; // keep in sync with GridView padding
                    const double spacingLocal = spacing;
                    final bool isPhoneWidthLocal = availableWidth < 600;
                    final int crossAxisCountLocal = isPhoneWidthLocal ? 1 : 3;
                    final double usableWidthLocal = availableWidth - (horizontalPaddingLocal * 2);
                    final double tileWidthLocal = (usableWidthLocal - spacingLocal * (crossAxisCountLocal - 1)) / crossAxisCountLocal;
                    const double detailsHeightCompact = 126;
                    const double detailsHeightRegular = 168;
                    final double estimatedDetailsHeightLocal = tileWidthLocal > 280 ? detailsHeightRegular : detailsHeightCompact;
                    double computedChildAspectRatioLocal = tileWidthLocal / (tileWidthLocal / 2 + estimatedDetailsHeightLocal);
                    if (crossAxisCountLocal == 1) {
                      computedChildAspectRatioLocal = computedChildAspectRatioLocal.clamp(0.80, 1.05);
                    } else {
                      // Allow taller aspect ratio (wider/shorter tiles) on desktop to reduce card height
                      computedChildAspectRatioLocal = computedChildAspectRatioLocal.clamp(0.90, 1.20);
                    }

                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(horizontalPaddingLocal, 0, horizontalPaddingLocal, bottomPad),
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
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, bottomPad),
                  itemCount: 5,
                  itemBuilder: (context, index) => LoadingStates.propertyCardShimmer(context),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                  const double horizontalPaddingLocal = horizontalPadding; // keep in sync with GridView padding
                  const double spacingLocal = spacing;
                  final bool isPhoneWidthLocal = availableWidth < 600;
                  final int crossAxisCountLocal = isPhoneWidthLocal ? 1 : 3;
                  final double usableWidthLocal = availableWidth - (horizontalPaddingLocal * 2);
                  final double tileWidthLocal = (usableWidthLocal - spacingLocal * (crossAxisCountLocal - 1)) / crossAxisCountLocal;
                  // Estimate details height to derive stable aspect ratio across widths
                  const double detailsHeightCompact = 126;
                  const double detailsHeightRegular = 168;
                  final double estimatedDetailsHeightLocal = tileWidthLocal > 280 ? detailsHeightRegular : detailsHeightCompact;
                  double computedChildAspectRatioLocal = tileWidthLocal / (tileWidthLocal / 2 + estimatedDetailsHeightLocal);
                  if (crossAxisCountLocal == 1) {
                    computedChildAspectRatioLocal = computedChildAspectRatioLocal.clamp(0.80, 1.05);
                  } else {
                    // Allow taller aspect ratio (wider/shorter tiles) on desktop to reduce card height
                    computedChildAspectRatioLocal = computedChildAspectRatioLocal.clamp(0.90, 1.20);
                  }

                  return RefreshIndicator(
                    onRefresh: _performSearch,
                    child: _isGridView
                        ? GridView.builder(
                            padding: EdgeInsets.fromLTRB(horizontalPaddingLocal, 0, horizontalPaddingLocal, bottomPad),
                            itemCount: _searchResults.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCountLocal,
                              mainAxisSpacing: spacingLocal,
                              crossAxisSpacing: spacingLocal,
                              childAspectRatio: computedChildAspectRatioLocal,
                            ),
                            itemBuilder: (context, index) {
                              final p = _searchResults[index];
                              final vm = ListingViewModel(
                                id: p.id,
                                title: p.title,
                                location: p.location,
                                priceLabel: CurrencyFormatter.formatPricePerUnit(p.price, 'night'),
                                imageUrl: p.imageUrl,
                                rating: p.rating,
                                chips: [p.type],
                                metaItems: [
                                  ListingMetaItem(icon: Icons.bed, text: '${p.bedrooms} bd'),
                                  ListingMetaItem(icon: Icons.bathtub, text: '${p.bathrooms} ba'),
                                ],
                                fallbackIcon: Icons.home,
                                isVehicle: false,
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
                            padding: EdgeInsets.fromLTRB(horizontalPaddingLocal, 0, horizontalPaddingLocal, bottomPad),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final p = _searchResults[index];
                              final vm = ListingViewModel(
                                id: p.id,
                                title: p.title,
                                location: p.location,
                                priceLabel: CurrencyFormatter.formatPricePerUnit(p.price, 'night'),
                                imageUrl: p.imageUrl,
                                rating: p.rating,
                                chips: [p.type],
                                metaItems: [
                                  ListingMetaItem(icon: Icons.bed, text: '${p.bedrooms} bd'),
                                  ListingMetaItem(icon: Icons.bathtub, text: '${p.bathrooms} ba'),
                                ],
                                fallbackIcon: Icons.home,
                                isVehicle: false,
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
  });
}
