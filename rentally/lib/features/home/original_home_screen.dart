import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/error_boundary.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';
import '../../core/providers/property_provider.dart';
import '../../core/database/models/property_model.dart';
import 'widgets/home_header.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/home_tab_section.dart';
import 'widgets/home_category_navigation.dart';
import 'widgets/home_featured_section.dart';
import 'widgets/home_promo_banner.dart';
import 'widgets/home_recommended_section.dart';
// import 'widgets/home_nearby_section.dart'; // Removed: Nearby Rentals section
import 'widgets/home_recently_viewed_section.dart';
import '../../core/widgets/tab_back_handler.dart';

/// **Original Home Screen**
/// 
/// Restored original home screen with all specialized widget components
/// 
/// **Features:**
/// - Responsive design for all screen sizes
/// - Error boundaries with crash protection
/// - Specialized widget components for each section
/// - Tab-based navigation between Properties and Vehicles
/// - Category navigation with icons
/// - Featured, recommended, nearby, and recently viewed sections
/// - Promotional banners and search functionality
class OriginalHomeScreen extends StatefulWidget {
  const OriginalHomeScreen({super.key});

  @override
  State<OriginalHomeScreen> createState() => _OriginalHomeScreenState();
}

class _OriginalHomeScreenState extends State<OriginalHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  
  bool _isLoading = false;
  int _selectedCategoryIndex = 0;
  
  // Category data
  // Property categories
  final List<String> _propertyCategories = const [
    'All',
    'Apartments',
    'Houses',
    'Villas',
    'Condos',
    'Studios',
    'Lofts',
    'Cabins',
    'Cottages',
    'Penthouse',
    'Townhouses',
  ];
  
  final List<IconData> _propertyCategoryIcons = const [
    Icons.apps,
    Icons.apartment,
    Icons.house,
    Icons.villa,
    Icons.business,
    Icons.meeting_room,
    Icons.stairs,
    Icons.cabin,
    Icons.cottage,
    Icons.apartment,
    Icons.home_work,
  ];

  // Vehicle categories
  final List<String> _vehicleCategories = const [
    'All',
    'Cars',
    'SUV',
    'Sedan',
    'Hatchback',
    'Bikes',
    'Scooters',
    'Trucks',
    'Vans',
    'Luxury',
    'Electric',
    'Convertible',
  ];

  final List<IconData> _vehicleCategoryIcons = const [
    Icons.apps,
    Icons.directions_car,
    Icons.sports_motorsports, // SUV icon substitute
    Icons.directions_car_filled_outlined,
    Icons.directions_car_outlined,
    Icons.pedal_bike,
    Icons.electric_scooter,
    Icons.local_shipping,
    Icons.airport_shuttle,
    Icons.diamond_outlined,
    Icons.electric_car,
    Icons.time_to_leave, // convertible substitute
  ];

  // Removed unused _currentCategories and _currentCategoryIcons

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();

    // Update categories when tab changes
    _tabController.addListener(_onTabChanged);
    // Defer initial load to the next frame to avoid scheduling rebuilds during build/layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Load properties using provider
      await context.read<PropertyProvider>().loadProperties();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadInitialData();
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
    // Apply provider filter for Properties tab only
    final isProperties = _tabController.index == 0;
    if (isProperties) {
      final selected = _propertyCategories[_selectedCategoryIndex];
      context.read<PropertyProvider>().setFilterType(_mapPropertyCategoryToType(selected));
    } else {
      context.read<PropertyProvider>().setFilterType(null);
    }
  }

  void _onTabChanged() {
    if (!mounted) return;
    // 0 = Properties, 1 = Vehicles
    final isProperties = _tabController.index == 0;
    setState(() {
      _selectedCategoryIndex = 0; // reset selection on tab change
    });
    // Reset or apply provider filter based on active tab
    if (isProperties) {
      context.read<PropertyProvider>().setFilterType(null); // 'All' by default
    } else {
      context.read<PropertyProvider>().setFilterType(null);
    }
  }

  PropertyType? _mapPropertyCategoryToType(String category) {
    switch (category) {
      case 'Apartments':
        return PropertyType.apartment;
      case 'Houses':
        return PropertyType.house;
      case 'Villas':
        return PropertyType.villa;
      case 'Condos':
        return PropertyType.condo;
      case 'Studios':
        return PropertyType.studio;
      case 'Lofts':
        return PropertyType.loft;
      case 'Cabins':
        return PropertyType.cabin;
      case 'Cottages':
        return PropertyType.cottage;
      case 'Penthouse':
        return PropertyType.penthouse;
      case 'Townhouses':
        return PropertyType.townhouse;
      default:
        return null; // 'All' or unrecognized -> no filter
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ErrorBoundary(
      onError: (details) {
        debugPrint('Home screen error: ${details.exception}');
      },
      child: TabBackHandler(
        tabController: _tabController,
        child: Scaffold(
        backgroundColor: isDark ? EnterpriseDarkTheme.primaryBackground : EnterpriseLightTheme.primaryBackground,
        body: _buildBody(theme, isDark),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Derive categories from current tab at build time for reliability
    final bool isPropertiesTab = _tabController.index == 0;
    final List<String> derivedCategories = isPropertiesTab ? _propertyCategories : _vehicleCategories;
    // derivedCategoryIcons removed - not used

    return SafeArea(
      child: RefreshIndicator(
        key: const ValueKey('original_home_refresh'),
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: HomeHeader(isDark: isDark),
          ),
          
          // Search Bar Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: HomeSearchBar(theme: theme, isDark: isDark),
            ),
          ),
          
          // Tab Section (Properties/Vehicles)
          SliverToBoxAdapter(
            child: HomeTabSection(
              tabController: _tabController,
              theme: theme,
              isDark: isDark,
              onTabChanged: (index) {
                final isProperties = index == 0;
                setState(() {
                  _selectedCategoryIndex = 0;
                });
                // Reset or apply provider filter based on active tab
                if (isProperties) {
                  context.read<PropertyProvider>().setFilterType(null); // 'All' by default
                } else {
                  context.read<PropertyProvider>().setFilterType(null);
                }
              },
            ),
          ),
          
          // Category Navigation
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final bool isProps = _tabController.index == 0;
                final cats = isProps ? _propertyCategories : _vehicleCategories;
                final catIcons = isProps ? _propertyCategoryIcons : _vehicleCategoryIcons;
                return Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 2),
                  child: HomeCategoryNavigation(
                    categories: cats,
                    categoryIcons: catIcons,
                    selectedIndex: _selectedCategoryIndex,
                    onCategorySelected: _onCategorySelected,
                    onClearFilter: () {
                      setState(() {
                        _selectedCategoryIndex = 0; // 'All'
                      });
                      // Clear provider filter regardless; only matters on Properties tab
                      context.read<PropertyProvider>().setFilterType(null);
                    },
                    theme: theme,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
          
          // Promotional Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: HomePromoBanner(theme: theme, isDark: isDark),
            ),
          ),
          
          // Featured Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: HomeFeaturedSection(
                theme: theme,
                isDark: isDark,
                tabController: _tabController,
                selectedCategory: derivedCategories[_selectedCategoryIndex],
              ),
            ),
          ),
          
          // Recommended Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: HomeRecommendedSection(
                theme: theme,
                isDark: isDark,
                tabController: _tabController,
                selectedCategory: derivedCategories[_selectedCategoryIndex],
              ),
            ),
          ),
          
          // Nearby Section (removed per request)
          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(vertical: 16),
          //     child: HomeNearbySection(
          //       theme: theme,
          //       isDark: isDark,
          //       tabController: _tabController,
          //       selectedCategory: derivedCategories[_selectedCategoryIndex],
          //     ),
          //   ),
          // ),
          
          // Recently Viewed Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: HomeRecentlyViewedSection(
                theme: theme,
                isDark: isDark,
                tabController: _tabController,
                selectedCategory: derivedCategories[_selectedCategoryIndex],
              ),
            ),
          ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
      ),
    );
  }
}
