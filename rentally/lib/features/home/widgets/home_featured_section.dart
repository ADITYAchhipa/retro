import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart' as pv;
import 'package:go_router/go_router.dart';
import '../../../app/auth_router.dart';
import '../../../core/theme/enterprise_dark_theme.dart';
import '../../../core/theme/enterprise_light_theme.dart';
import '../../../core/providers/property_provider.dart';
import '../../../core/database/models/property_model.dart';
import '../../../core/widgets/loading_states.dart';
import '../../../core/providers/vehicle_provider.dart';
import '../../../core/widgets/listing_card.dart';
import '../../../core/widgets/listing_badges.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/hover_scale.dart';

/// Featured section widget showing highlighted properties/vehicles
class HomeFeaturedSection extends StatefulWidget {
  const HomeFeaturedSection({
    super.key,
    required this.theme,
    required this.isDark,
    required this.tabController,
    required this.selectedCategory,
  });

  final ThemeData theme;
  final bool isDark;
  final TabController tabController;
  final String selectedCategory;

  @override
  State<HomeFeaturedSection> createState() => _HomeFeaturedSectionState();
}

class _HomeFeaturedSectionState extends State<HomeFeaturedSection> with TickerProviderStateMixin {
  // Responsive page controllers with dynamic viewport fractions
  late PageController _propertyPageController;
  late PageController _vehiclePageController;
  Timer? _autoScrollTimer;
  Timer? _resumeTimer;
  // Track current page indices for pop-up effects
  int _currentPropertyIndex = 0;
  int _currentVehicleIndex = 0;
  // Removed infinite paging + auto-scroll configuration

  @override
  void initState() {
    super.initState();
    // Initialize with default viewport fraction, will be updated in didChangeDependencies
    _propertyPageController = PageController(viewportFraction: 0.86, initialPage: 0);
    _vehiclePageController = PageController(viewportFraction: 0.86, initialPage: 0);
    widget.tabController.addListener(_onTabChanged);
    // Load featured properties when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pv.Provider.of<PropertyProvider>(context, listen: false).loadFeaturedProperties();
      // Ensure vehicles are loaded too so the vehicle tab has data
      final vp = pv.Provider.of<VehicleProvider>(context, listen: false);
      vp.loadVehicles();
      vp.loadFeaturedVehicles();
      // Ensure any previously running timers from hot-reload are cancelled
      _startAutoScroll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateControllers();
    // Defensive: cancel any legacy auto-scroll timers after dependency changes
    _startAutoScroll();
  }

  void _updateControllers() {
    final screenWidth = MediaQuery.of(context).size.width;
    final viewportFraction = _getViewportFraction(screenWidth);
    
    // Only update if viewport fraction has changed significantly
    if ((_propertyPageController.viewportFraction - viewportFraction).abs() > 0.05) {
      _propertyPageController.dispose();
      _vehiclePageController.dispose();
      _propertyPageController = PageController(viewportFraction: viewportFraction, initialPage: 0);
      _vehiclePageController = PageController(viewportFraction: viewportFraction, initialPage: 0);
    }
  }

  double _getViewportFraction(double screenWidth) {
    if (screenWidth > 1400) return 0.18; // Large desktop: show ~5.5 cards
    if (screenWidth > 1200) return 0.22; // Desktop: show ~4.5 cards
    if (screenWidth > 900) return 0.28;  // Medium desktop: show ~3.5 cards
    if (screenWidth > 700) return 0.42;  // Tablet: show ~2.4 cards
    if (screenWidth > 500) return 0.75;  // Large phone: show main card prominently
    return 0.8;                         // Small phone: show main card prominently
  }

  double _getCardWidth(double screenWidth) {
    if (screenWidth > 1400) return 220;  // Large desktop: larger cards
    if (screenWidth > 1200) return 240;  // Desktop: larger cards
    if (screenWidth > 900) return 260;   // Medium desktop: larger cards
    if (screenWidth > 700) return 280;   // Tablet: larger cards
    if (screenWidth > 500) return 300;   // Large phone: much larger cards
    return 260;                          // Small phone: much larger cards
  }

  void _onTabChanged() {
    setState(() {});
    // When switching to Vehicles tab, make sure data is present
    if (widget.tabController.index == 1) {
      final vp = pv.Provider.of<VehicleProvider>(context, listen: false);
      if (!vp.isFeaturedLoading && vp.filteredFeaturedVehicles.isEmpty) {
        vp.loadFeaturedVehicles();
      }
    }
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    _autoScrollTimer?.cancel();
    _resumeTimer?.cancel();
    _propertyPageController.dispose();
    _vehiclePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPropertyTab = widget.tabController.index == 0;
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    
    // Responsive section height based on screen size
    final sectionHeight = _getSectionHeight(screenWidth);
    // Derive cardWidth from viewportFraction so section height and card size match exactly
    final vp = _propertyPageController.viewportFraction;
    final perItemPadding = screenWidth <= 600 ? 8.0 : 8.0; // increased padding for better spacing
    // Slightly reduce initial left padding for the first card only
    final startPadding = perItemPadding / 2;
    final cardWidth = (screenWidth * vp) - (perItemPadding * 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                isPropertyTab ? 'Featured Properties' : 'Featured Vehicles',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? EnterpriseDarkTheme.primaryText : EnterpriseLightTheme.primaryText,
                ),
              ),
              const Spacer(),
              HoverScale(
                enableOnTouch: true,
                scale: 1.05,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: TextButton(
                  onPressed: () {
                    final isPropertyTab = widget.tabController.index == 0;
                    final type = isPropertyTab ? 'property' : 'vehicle';
                    final cat = Uri.encodeComponent(widget.selectedCategory);
                    // Pass type, include category hint (search may ignore if unsupported)
                    context.push('${Routes.search}?type=$type&category=$cat');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ).copyWith(
                    overlayColor: MaterialStateProperty.resolveWith((states) {
                      final c = widget.isDark
                          ? EnterpriseDarkTheme.primaryAccent
                          : EnterpriseLightTheme.primaryAccent;
                      return c.withOpacity(0.12);
                    }),
                  ),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark ? EnterpriseDarkTheme.primaryAccent : EnterpriseLightTheme.primaryAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: sectionHeight,
          padding: const EdgeInsets.only(top: 8, bottom: 20), // Reduced top padding for tighter spacing
          clipBehavior: Clip.none, // Allow overflow for pop-up effect
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isPropertyTab
                ? pv.Consumer<PropertyProvider>(
                    key: ValueKey('properties_${widget.tabController.index}'),
                    builder: (context, propertyProvider, child) {
                      if (propertyProvider.isFeaturedLoading) {
                        return _buildLoadingState();
                      }
                      if (propertyProvider.error != null) {
                        return _buildErrorState(propertyProvider.error!);
                      }
                      final items = propertyProvider.filteredFeaturedProperties;
                      if (items.isEmpty) {
                        // If filtering yields no items, show an empty state instead of a loading shimmer
                        return _buildEmptyState(widget.selectedCategory);
                      }
                      // no-op: item count not needed without auto-scroll
                      final useList = screenWidth > 700; // On desktop/tablet, left-align with a simple list
                      if (useList) {
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(left: startPadding, right: perItemPadding),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final property = items[index];
                            final vm = ListingViewModel(
                              id: property.id,
                              title: property.title,
                              location: property.location,
                              priceLabel: CurrencyFormatter.formatPricePerUnit(property.pricePerNight, 'night'),
                              imageUrl: _getPropertyImageUrl(property),
                              rating: property.rating,
                              reviewCount: property.reviewCount,
                              chips: [property.type.displayName, if (property.amenities.isNotEmpty) property.amenities.first],
                              metaItems: [
                                ListingMetaItem(icon: Icons.bed, text: '${property.bedrooms} bd'),
                                ListingMetaItem(icon: Icons.bathtub, text: '${property.bathrooms} ba'),
                                ListingMetaItem(icon: Icons.person, text: '${property.maxGuests} guests'),
                              ],
                              fallbackIcon: _getPropertyIcon(property.type),
                              badges: [
                                if (property.isFeatured) ListingBadgeType.featured,
                                if (property.rating >= 4.7 && property.reviewCount > 25) ListingBadgeType.topRated,
                                if (DateTime.now().difference(property.createdAt).inDays <= 30) ListingBadgeType.newListing,
                              ],
                            );
                            return Padding(
                              padding: EdgeInsets.only(
                                left: index == 0 ? 0 : perItemPadding,
                                right: perItemPadding,
                              ),
                              child: SizedBox(
                                width: cardWidth,
                                child: HoverScale(
                                  scale: 1.02,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  enableOnTouch: true,
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
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return PageView.builder(
                        controller: _propertyPageController,
                        physics: const BouncingScrollPhysics(),
                        padEnds: true, // Enable padding to center cards
                        clipBehavior: Clip.none, // Allow cards to overflow
                        onPageChanged: (index) {
                          setState(() {
                            _currentPropertyIndex = index;
                          });
                        },
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final property = items[index];
                          final vm = ListingViewModel(
                              id: property.id,
                              title: property.title,
                              location: property.location,
                              priceLabel: CurrencyFormatter.formatPricePerUnit(property.pricePerNight, 'night'),
                              imageUrl: _getPropertyImageUrl(property),
                              rating: property.rating,
                              reviewCount: property.reviewCount,
                              chips: [property.type.displayName, if (property.amenities.isNotEmpty) property.amenities.first],
                              metaItems: [
                                ListingMetaItem(icon: Icons.bed, text: '${property.bedrooms} bd'),
                                ListingMetaItem(icon: Icons.bathtub, text: '${property.bathrooms} ba'),
                                ListingMetaItem(icon: Icons.person, text: '${property.maxGuests} guests'),
                              ],
                              fallbackIcon: _getPropertyIcon(property.type),
                              badges: [
                                if (property.isFeatured) ListingBadgeType.featured,
                                if (property.rating >= 4.7 && property.reviewCount > 25) ListingBadgeType.topRated,
                                if (DateTime.now().difference(property.createdAt).inDays <= 30) ListingBadgeType.newListing,
                              ],
                            );
                          final isActive = index == _currentPropertyIndex;
                          final isFirstOrLast = index == 0 || index == items.length - 1;
                          final shouldPopUp = isActive && !isFirstOrLast;
                          
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: perItemPadding),
                            child: Center(
                              child: AnimatedScale(
                                scale: shouldPopUp ? 1.05 : (isActive ? 1.0 : 0.95),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    // Apply background shadow for the active visible card on phone
                                    boxShadow: isActive ? [
                                      BoxShadow(
                                        color: widget.isDark 
                                            ? Colors.blue.withOpacity(0.3)
                                            : Colors.black.withOpacity(0.2),
                                        blurRadius: 22,
                                        offset: const Offset(0, 8),
                                        spreadRadius: 2,
                                      ),
                                    ] : null,
                                  ),
                                  child: HoverScale(
                                    scale: 1.02,
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeOut,
                                    enableOnTouch: true,
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
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                : Container(
                    key: ValueKey('vehicles_${widget.tabController.index}_${widget.selectedCategory}'),
                    child: _buildVehiclesList(widget.selectedCategory),
                  ),
          ),
        ),
      ],
    );
  }

  // Filtering now handled by PropertyProvider.filteredFeaturedProperties

  Widget _buildVehiclesList(String category) {
    return pv.Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, child) {
        // Sync selected category into provider filter
        if (vehicleProvider.filterCategory != category) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            vehicleProvider.setFilterCategory(category);
          });
        }

        // Proactively load featured vehicles if we have none
        if (!vehicleProvider.isFeaturedLoading && vehicleProvider.error == null && vehicleProvider.filteredFeaturedVehicles.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            vehicleProvider.loadFeaturedVehicles();
          });
        }

        if (vehicleProvider.isFeaturedLoading) {
          return _buildLoadingState();
        }
        if (vehicleProvider.error != null) {
          return _buildErrorState(vehicleProvider.error!);
        }

        // Prefer filtered featured vehicles; if empty, fall back to all featured vehicles
        var items = vehicleProvider.filteredFeaturedVehicles;
        if (items.isEmpty && vehicleProvider.featuredVehicles.isNotEmpty) {
          items = vehicleProvider.featuredVehicles;
        }
        if (items.isEmpty) {
          return _buildEmptyState(category);
        }

        // no-op: item count not needed without auto-scroll
        final screenWidth = MediaQuery.of(context).size.width;
        // Derive vehicle card width from vehicle page controller viewportFraction
        final vp = _vehiclePageController.viewportFraction;
        final perItemPadding = screenWidth <= 600 ? 8.0 : 8.0; // consistent with property section
        final startPadding = perItemPadding / 2; // reduce initial left padding for first card only
        final cardWidth = (screenWidth * vp) - (perItemPadding * 2);

        final useList = screenWidth > 700; // On desktop/tablet, left-align with a simple list
        if (useList) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(left: startPadding, right: perItemPadding),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final v = items[index];
              final vm = ListingViewModel(
                id: v.id,
                title: v.title,
                location: v.location,
                priceLabel: CurrencyFormatter.formatPricePerUnit(v.pricePerDay, 'day'),
                imageUrl: v.images.isNotEmpty ? v.images.first : null,
                rating: v.rating,
                reviewCount: v.reviewCount,
                chips: ['${v.category} • ${v.seats} seats'],
                metaItems: [
                  ListingMetaItem(icon: Icons.airline_seat_recline_normal, text: '${v.seats}'),
                  ListingMetaItem(icon: Icons.settings, text: v.transmission),
                  ListingMetaItem(icon: v.fuel.toLowerCase() == 'electric' ? Icons.electric_bolt : Icons.local_gas_station, text: v.fuel),
                ],
                fallbackIcon: Icons.directions_car,
                isVehicle: true,
                badges: [
                  if (v.isFeatured) ListingBadgeType.featured,
                  if (v.rating >= 4.7 && v.reviewCount > 25) ListingBadgeType.topRated,
                ],
              );
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : perItemPadding,
                  right: perItemPadding,
                ),
                child: SizedBox(
                  width: cardWidth,
                  child: HoverScale(
                    scale: 1.02,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    enableOnTouch: true,
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
                  ),
                ),
              );
            },
          );
        }
        return PageView.builder(
          controller: _vehiclePageController,
          physics: const BouncingScrollPhysics(),
          padEnds: true, // Enable padding to center cards
          clipBehavior: Clip.none, // Allow cards to overflow
          onPageChanged: (index) {
            setState(() {
              _currentVehicleIndex = index;
            });
          },
          itemCount: items.length,
          itemBuilder: (context, index) {
            final v = items[index];
            final vm = ListingViewModel(
                id: v.id,
                title: v.title,
                location: v.location,
                priceLabel: CurrencyFormatter.formatPricePerUnit(v.pricePerDay, 'day'),
                imageUrl: v.images.isNotEmpty ? v.images.first : null,
                rating: v.rating,
                reviewCount: v.reviewCount,
                chips: ['${v.category} • ${v.seats} seats'],
                metaItems: [
                  ListingMetaItem(icon: Icons.airline_seat_recline_normal, text: '${v.seats}'),
                  ListingMetaItem(icon: Icons.settings, text: v.transmission),
                  ListingMetaItem(icon: v.fuel.toLowerCase() == 'electric' ? Icons.electric_bolt : Icons.local_gas_station, text: v.fuel),
                ],
                fallbackIcon: Icons.directions_car,
                isVehicle: true,
                badges: [
                  if (v.isFeatured) ListingBadgeType.featured,
                  if (v.rating >= 4.7 && v.reviewCount > 25) ListingBadgeType.topRated,
                ],
              );
            final isActive = index == _currentVehicleIndex;
            final isFirstOrLast = index == 0 || index == items.length - 1;
            final shouldPopUp = isActive && !isFirstOrLast;
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: perItemPadding),
              child: Center(
                child: AnimatedScale(
                  scale: shouldPopUp ? 1.05 : (isActive ? 1.0 : 0.95),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      // Apply background shadow for the active visible card on phone
                      boxShadow: isActive ? [
                        BoxShadow(
                          color: widget.isDark 
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.black.withOpacity(0.2),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                    child: HoverScale(
                      scale: 1.02,
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      enableOnTouch: true,
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
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String category) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No items found for "$category"',
          style: TextStyle(
            color: widget.isDark
                ? EnterpriseDarkTheme.secondaryText
                : EnterpriseLightTheme.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }


  Widget _buildLoadingState() {
    final isDark = widget.isDark;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = _getCardWidth(screenWidth);
        return Container(
          width: cardWidth,
          margin: EdgeInsets.only(right: screenWidth > 600 ? 16 : 12),
          decoration: BoxDecoration(
            color: isDark ? EnterpriseDarkTheme.cardBackground : EnterpriseLightTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.6) : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child:const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image skeleton
              SkeletonLoader(
                width: double.infinity,
                height: 110,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              // Details skeleton
              Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 160, height: 16),
                    SizedBox(height: 6),
                    SkeletonLoader(width: 120, height: 14),
                    SizedBox(height: 10),
                    SkeletonLoader(width: 100, height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: widget.isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load featured properties',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? EnterpriseDarkTheme.primaryText : EnterpriseLightTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: widget.isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              pv.Provider.of<PropertyProvider>(context, listen: false).loadFeaturedProperties();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }


  // Auto-scroll helpers (PageView)
  void _startAutoScroll() {
    // Auto-scroll disabled by request: cancel any timers and do nothing
    _autoScrollTimer?.cancel();
    _resumeTimer?.cancel();
  }

  // _pauseAutoScrollFor and _autoPageOnceFixed removed (auto-scroll disabled)

  // Helpers (restored)
  String? _getPropertyImageUrl(PropertyModel p) {
    if (p.images.isEmpty) return null;
    final url = p.images.first;
    return url.isEmpty ? null : url;
  }

  double _getSectionHeight(double screenWidth) {
    // Compute dynamically from the ACTUAL page item width (viewportFraction),
    // not the heuristic _getCardWidth. This keeps image + info fully visible.
    final isPropertyTab = widget.tabController.index == 0;
    final vp = (isPropertyTab ? _propertyPageController : _vehiclePageController).viewportFraction;
    const horizontalPadding = 4.0; // reduced padding for tighter spacing
    final cardWidth = (screenWidth * vp) - (horizontalPadding * 2);
    final imageHeight = cardWidth * 0.5; // 2:1 image (height = width / 2)

    // Match ListingCard info rows but in a compact form
    double infoBase;
    if (cardWidth >= 260) {
      infoBase = 85.0; // slight increase for more info breathing room
    } else if (cardWidth >= 220) {
      infoBase = 82.0;
    } else {
      infoBase = 76.0;
    }

    // Allowances: include rating row height and extra padding variance on small screens
    const ratingAllowance = 18.0;  // star + number row
    const contentAllowance = 18.0; // chip/meta spacing + small variability
    const extra = 2.0;            // border + rounding safety
    final mobileBoost = screenWidth <= 600 ? 22.0 : 16.0; // more room on phones
    
    // Add extra space for pop-up effect (5% scale increase + shadow)
    const popupAllowance = 40.0; // Extra space for 1.05 scale and shadow
    
    return imageHeight + infoBase + ratingAllowance + contentAllowance + extra + mobileBoost + popupAllowance;
  }

  IconData _getPropertyIcon(PropertyType type) {
    switch (type) {
      case PropertyType.apartment:
        return Icons.apartment;
      case PropertyType.house:
        return Icons.house;
      case PropertyType.villa:
        return Icons.villa;
      case PropertyType.condo:
        return Icons.business;
      case PropertyType.studio:
        return Icons.meeting_room;
      case PropertyType.loft:
        return Icons.stairs;
      case PropertyType.cabin:
        return Icons.cabin;
      case PropertyType.cottage:
        return Icons.cottage;
      case PropertyType.penthouse:
        return Icons.apartment;
      case PropertyType.townhouse:
        return Icons.home_work;
    }
  }
}
