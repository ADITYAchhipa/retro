import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/error_boundary.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/providers/property_provider.dart';
import '../../core/database/models/property_model.dart';
import 'widgets/home_header.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/home_tab_section.dart';
import 'widgets/home_category_navigation.dart';
import 'widgets/home_featured_section.dart';
import 'widgets/home_promo_banner.dart';
import 'widgets/home_recommended_section.dart';
import 'widgets/home_nearby_section.dart';
import '../../core/widgets/tab_back_handler.dart';
import 'package:go_router/go_router.dart';
import '../../services/recently_viewed_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/listing_card.dart';

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
/// - Featured, recommended, and nearby sections
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
  List<RecentlyViewedItem> _recentlyViewed = const [];
  
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
        _loadRecentlyViewed();
      }
    });
  }

  Future<void> _loadRecentlyViewed() async {
    try {
      final items = await RecentlyViewedService.list();
      if (!mounted) return;
      setState(() {
        _recentlyViewed = items;
      });
    } catch (_) {
      // ignore failures
    }
  }

  Widget _buildRecentlyViewedSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recently Viewed',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_recentlyViewed.length >= 5)
                TextButton(
                  onPressed: _showAllRecentlyViewed,
                  child: const Text('See All'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 232,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: _recentlyViewed.length.clamp(0, 10),
            separatorBuilder: (context, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _recentlyViewed[index];
              return _buildRecentCard(item, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCard(RecentlyViewedItem item, ThemeData theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // RecentlyViewedItem doesn't carry type; default to property unit for display consistency
    const unit = 'month';
    final vm = ListingViewModel(
      id: item.id,
      title: item.title,
      location: item.location,
      priceLabel: CurrencyFormatter.formatPricePerUnit(item.price, unit),
      rentalUnit: unit,
      imageUrl: item.imageUrl,
      rating: 0,
      chips: const [],
      metaItems: const [],
      fallbackIcon: Icons.home,
      isVehicle: false,
    );
    return SizedBox(
      width: 260,
      child: ListingCard(
        model: vm,
        isDark: isDark,
        width: 260,
        margin: EdgeInsets.zero,
        onTap: () => context.push('/listing/${item.id}'),
        chipOnImage: false,
        showInfoChip: false,
        chipInRatingRowRight: true,
        priceBottomLeft: true,
        shareBottomRight: true,
      ),
    );
  }

  void _showAllRecentlyViewed() {
    // Placeholder for a full-screen Recently Viewed list
    // For now, no-op or could navigate to '/search?recentlyViewed=true'
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Load properties using provider
      await context.read<PropertyProvider>().loadProperties();
    } catch (_) {
      // ignore for now
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadInitialData();
    await _loadRecentlyViewed();
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
        backgroundColor: isDark ? EnterpriseDarkTheme.primaryBackground : Colors.white,
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
          clipBehavior: Clip.none,
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
              padding: const EdgeInsets.only(top: 6, bottom: 4),
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
                  padding: const EdgeInsets.only(top: 16, bottom: 2),
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
              padding: const EdgeInsets.only(top: 0, bottom: 8),
              child: HomePromoBanner(theme: theme, isDark: isDark),
            ),
          ),
          
          
          // Featured Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 10),
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
              padding: const EdgeInsets.only(top: 6, bottom: 14),
              child: HomeRecommendedSection(
                theme: theme,
                isDark: isDark,
                tabController: _tabController,
                selectedCategory: derivedCategories[_selectedCategoryIndex],
              ),
            ),
          ),
          
          // Nearby Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: HomeNearbySection(
                theme: theme,
                isDark: isDark,
                tabController: _tabController,
                selectedCategory: derivedCategories[_selectedCategoryIndex],
              ),
            ),
          ),

          // Recently Viewed Section (if any)
          if (_recentlyViewed.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: _buildRecentlyViewedSection(theme),
              ),
            ),
          
          // Bottom padding (reduced)
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      ),
    );
  }
}
