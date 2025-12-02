import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import 'package:go_router/go_router.dart';
import '../../../core/theme/enterprise_dark_theme.dart';
import '../../../core/theme/enterprise_light_theme.dart';
import '../../../core/widgets/loading_states.dart';
import '../../../core/widgets/listing_card.dart';
import '../../../core/widgets/listing_vm_factory.dart';
import '../../../core/providers/property_provider.dart';
import '../../../core/providers/vehicle_provider.dart';
import '../../../core/widgets/hover_scale.dart';
// import '../../../core/utils/price_unit_helper.dart';
import '../../../services/location_service.dart';
import '../../../core/database/models/property_model.dart';
import '../../../core/database/models/vehicle_model.dart';
import '../../../core/services/mock_api_service.dart';

/// Nearby section widget showing nearby properties/vehicles based on location
class HomeNearbySection extends StatefulWidget {
  const HomeNearbySection({
    super.key,
    required this.tabController,
    required this.theme,
    required this.isDark,
    required this.selectedCategory,
  });

  final TabController tabController;
  final ThemeData theme;
  final bool isDark;
  final String selectedCategory;

  @override
  State<HomeNearbySection> createState() => _HomeNearbySectionState();
}

class _HomeNearbySectionState extends State<HomeNearbySection> {
  final LocationService _locationService = LocationService();
  double? _userLatitude;
  double? _userLongitude;
  final RealApiService _api = RealApiService();
  List<PropertyModel> _nearbyProperties = [];
  List<VehicleModel> _nearbyVehicles = [];
  bool _nearbyLoading = false;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
    // Ensure nearby data is loaded for both domains
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load nearby properties and vehicles
      pv.Provider.of<PropertyProvider>(context, listen: false).loadFeaturedProperties();
      pv.Provider.of<VehicleProvider>(context, listen: false).loadFeaturedVehicles();
      _loadUserLocation();
    });
  }

  Future<void> _loadUserLocation() async {
    try {
      final pos = await _locationService.getCurrentLocation();
      if (!mounted || pos == null) return;
      setState(() {
        _userLatitude = pos.latitude;
        _userLongitude = pos.longitude;
      });
      // DEBUG: trigger backend nearby fetch once we have coordinates
      await _fetchNearby(lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      // Silent fail - nearby section will fall back to unfiltered data
    }
  }

  Future<void> _fetchNearby({required double lat, required double lng}) async {
    try {
      setState(() => _nearbyLoading = true);
      // DEBUG: request nearby from backend with strict 10km cap and debug=1
      final propsJson = await _api.getNearbyProperties(
        latitude: lat,
        longitude: lng,
        maxDistanceKm: 10,
        debug: true,
      );
      final vehsJson = await _api.getNearbyVehicles(
        latitude: lat,
        longitude: lng,
        maxDistanceKm: 10,
        debug: true,
      );
      final props = propsJson.map((e) => PropertyModel.fromJson(e)).toList();
      final vehs = vehsJson.map((e) => VehicleModel.fromJson(e)).toList();
      // DEBUG: log counts
      debugPrint('Nearby properties from backend: ${props.length}, vehicles: ${vehs.length}');
      setState(() {
        _nearbyProperties = props;
        _nearbyVehicles = vehs;
      });
    } catch (e) {
      debugPrint('Failed to fetch nearby: $e');
    } finally {
      if (mounted) setState(() => _nearbyLoading = false);
    }
  }

  Widget _buildEmptyState(String category) {
    final bool isProperties = widget.tabController.index == 0;
    final String itemType = isProperties ? 'properties' : 'vehicles';
    final IconData iconData = isProperties ? Icons.location_on : Icons.directions_car;

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.isDark 
            ? EnterpriseDarkTheme.cardBackground.withValues(alpha: 0.3)
            : EnterpriseLightTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark 
              ? EnterpriseDarkTheme.primaryBorder.withValues(alpha: 0.2)
              : EnterpriseLightTheme.primaryBorder.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 48,
            color: widget.theme.primaryColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'No nearby $itemType found',
            style: widget.theme.textTheme.titleMedium?.copyWith(
              color: widget.isDark 
                  ? EnterpriseDarkTheme.primaryText
                  : EnterpriseLightTheme.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enable location services to see $itemType near you',
            style: widget.theme.textTheme.bodyMedium?.copyWith(
              color: widget.isDark 
                  ? EnterpriseDarkTheme.secondaryText
                  : EnterpriseLightTheme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<PropertyModel> _filterNearbyProperties(List<PropertyModel> items) {
    if (_userLatitude == null || _userLongitude == null) return items;
    final lat = _userLatitude!;
    final lon = _userLongitude!;

    final List<MapEntry<PropertyModel, double>> withDistance = [];
    for (final p in items) {
      // Skip items without valid coordinates
      if (p.latitude == 0.0 && p.longitude == 0.0) continue;
      final d = _locationService.calculateDistance(
        lat,
        lon,
        p.latitude,
        p.longitude,
      );
      withDistance.add(MapEntry(p, d));
    }

    if (withDistance.isEmpty) return items;

    withDistance.sort((a, b) => a.value.compareTo(b.value));

    const maxDistanceMeters = 50000.0; // ~50 km radius
    final nearby = withDistance
        .where((e) => e.value <= maxDistanceMeters)
        .map((e) => e.key)
        .toList();

    // If filtering removes everything, fall back to the original list
    return nearby.isNotEmpty ? nearby : items;
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: widget.theme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Nearby',
                        style: widget.theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.isDark 
                              ? EnterpriseDarkTheme.primaryText
                              : EnterpriseLightTheme.primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.tabController.index == 0 
                        ? 'Properties near your location'
                        : 'Vehicles available nearby',
                    style: widget.theme.textTheme.bodyMedium?.copyWith(
                      color: widget.isDark 
                          ? EnterpriseDarkTheme.secondaryText
                          : EnterpriseLightTheme.secondaryText,
                    ),
                  ),
                ],
              ),
              HoverScale(
                enableOnTouch: true,
                scale: 1.05,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: TextButton(
                  onPressed: () {
                    final searchType = widget.tabController.index == 0 ? 'properties' : 'vehicles';
                    context.push('/search?type=$searchType&nearby=true');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      final c = widget.isDark
                          ? EnterpriseDarkTheme.primaryAccent
                          : widget.theme.primaryColor;
                      return c.withValues(alpha: 0.12);
                    }),
                  ),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark ? EnterpriseDarkTheme.primaryAccent : widget.theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        
        // Content
        Builder(builder: (context) {
          final bool isProperties = widget.tabController.index == 0;
          
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isProperties
                  ? pv.Consumer<PropertyProvider>(
                      key: ValueKey('nearby_properties_${widget.tabController.index}'),
                      builder: (context, propertyProvider, child) {
                        if (propertyProvider.isLoading) {
                          return _buildLoadingState();
                        }
                        final source = _nearbyProperties.isNotEmpty
                            ? _nearbyProperties
                            : propertyProvider.featuredProperties;
                        if (source.isEmpty) {
                          return _buildEmptyState(widget.selectedCategory);
                        }
                        // If backend nearby available, use it; else client-side filter as fallback
                        final properties = _nearbyProperties.isNotEmpty
                            ? _nearbyProperties
                            : _filterNearbyProperties(source);
                        final screenWidth = MediaQuery.of(context).size.width;
                        final cardWidth = screenWidth < 600 ? 240.0 : 280.0;
                        final sectionHeight = screenWidth < 600 ? 210.0 : 220.0;
                        return SizedBox(
                          height: sectionHeight,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: properties.length,
                            itemBuilder: (context, index) {
                              final property = properties[index];
                              final vm = ListingViewModelFactory.fromProperty(property);
                              return Padding(
                                padding: EdgeInsets.only(right: index == properties.length - 1 ? 0 : 12),
                                child: ListingCard(
                                  model: vm,
                                  isDark: widget.isDark,
                                  width: cardWidth,
                                  margin: EdgeInsets.zero,
                                  chipOnImage: false,
                                  showInfoChip: false,
                                  chipInRatingRowRight: true,
                                  priceBottomLeft: true,
                                  shareBottomRight: true,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    )
                  : pv.Consumer<VehicleProvider>(
                      key: ValueKey('nearby_vehicles_${widget.tabController.index}_${widget.selectedCategory}'),
                      builder: (context, vehicleProvider, child) {
                        if (vehicleProvider.isLoading) {
                          return _buildLoadingState();
                        }
                        final vehicles = _nearbyVehicles.isNotEmpty
                            ? _nearbyVehicles
                            : vehicleProvider.featuredVehicles;
                        if (vehicles.isEmpty) {
                          return _buildEmptyState(widget.selectedCategory);
                        }
                        final screenWidth = MediaQuery.of(context).size.width;
                        final cardWidth = screenWidth < 600 ? 240.0 : 280.0;
                        final sectionHeight = screenWidth < 600 ? 210.0 : 220.0;
                        return SizedBox(
                          height: sectionHeight,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: vehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = vehicles[index];
                              final vm = ListingViewModelFactory.fromVehicle(vehicle);
                              return Padding(
                                padding: EdgeInsets.only(right: index == vehicles.length - 1 ? 0 : 12),
                                child: ListingCard(
                                  model: vm,
                                  isDark: widget.isDark,
                                  width: cardWidth,
                                  margin: EdgeInsets.zero,
                                  chipOnImage: false,
                                  showInfoChip: false,
                                  chipInRatingRowRight: true,
                                  priceBottomLeft: true,
                                  shareBottomRight: true,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
          );
        }),
      ],
    );
  }
  
  

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LoadingStates.listShimmer(context, itemCount: 3),
    );
  }
}
