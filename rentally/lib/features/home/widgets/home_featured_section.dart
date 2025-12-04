import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart' as pv;
import 'package:go_router/go_router.dart';
import '../../../app/auth_router.dart';
import '../../../core/theme/enterprise_dark_theme.dart';
import '../../../core/theme/enterprise_light_theme.dart';
import '../../../core/providers/property_provider.dart';
import '../../../core/widgets/loading_states.dart';
import '../../../core/providers/vehicle_provider.dart';
import '../../../core/database/models/vehicle_model.dart';
import '../../../core/widgets/listing_card.dart';
import '../../../core/widgets/listing_vm_factory.dart';
import '../../../core/widgets/hover_scale.dart';
// import '../../../core/utils/price_unit_helper.dart';

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
    // keepPage: true ensures scroll position is maintained when items are added
    _propertyPageController = PageController(viewportFraction: 0.86, initialPage: 0, keepPage: true);
    _vehiclePageController = PageController(viewportFraction: 0.86, initialPage: 0, keepPage: true);
    widget.tabController.addListener(_onTabChanged);
    // Load featured properties when widget initializes with default category 'all'
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pv.Provider.of<PropertyProvider>(context, listen: false)
          .loadFeaturedProperties(category: widget.selectedCategory);
      // Load featured vehicles from backend (not all vehicles)
      pv.Provider.of<VehicleProvider>(context, listen: false)
          .loadFeaturedVehicles();
      // Ensure any previously running timers from hot-reload are cancelled
      _startAutoScroll();
    });
  }

  @override
  void didUpdateWidget(HomeFeaturedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if category changed
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      final isPropertyTab = widget.tabController.index == 0;
      if (isPropertyTab) {
        pv.Provider.of<PropertyProvider>(context, listen: false)
            .loadFeaturedProperties(category: widget.selectedCategory);
      } else {
        final vp = pv.Provider.of<VehicleProvider>(context, listen: false);
        vp.setFilterCategory(widget.selectedCategory);
      }
    }
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
    
    // Only update if viewport fraction has changed noticeably
    if ((_propertyPageController.viewportFraction - viewportFraction).abs() > 0.005) {
      // Save current page positions before recreating controllers
      final currentPropertyPage = _propertyPageController.hasClients 
          ? _propertyPageController.page?.round() ?? 0 
          : 0;
      final currentVehiclePage = _vehiclePageController.hasClients 
          ? _vehiclePageController.page?.round() ?? 0 
          : 0;
      
      _propertyPageController.dispose();
      _vehiclePageController.dispose();
      
      // Recreate with saved positions and keepPage: true to preserve scroll position
      _propertyPageController = PageController(
        viewportFraction: viewportFraction,
        initialPage: currentPropertyPage,
        keepPage: true,
      );
      _vehiclePageController = PageController(
        viewportFraction: viewportFraction,
        initialPage: currentVehiclePage,
        keepPage: true,
      );
    }
  }

  double _getViewportFraction(double screenWidth) {
    if (screenWidth > 1400) return 0.18; // Large desktop: show ~5.5 cards
    if (screenWidth > 1200) return 0.22; // Desktop: show ~4.5 cards
    if (screenWidth > 900) return 0.28;  // Medium desktop: show ~3.5 cards
    if (screenWidth > 700) return 0.42;  // Tablet: show ~2.4 cards
    if (screenWidth > 500) return 0.78;   // Large phone: slightly larger while keeping next card peek
    return 0.89;                          // Small phone: slightly larger while keeping next card peek
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
    // Ensure controllers reflect the latest viewport fraction at build time
    _updateControllers();
    
    // Responsive section height based on screen size
    final sectionHeight = _getSectionHeight(screenWidth);
    // Derive cardWidth from viewportFraction so section height and card size match exactly
    final vp = _propertyPageController.viewportFraction;
    final perItemPadding = screenWidth <= 600 ? 6.0 : 8.0; // slightly increased gap on phones
    // Slightly increase initial left padding for the first card on phones
    final startPadding = screenWidth <= 600 ? 14.0 : perItemPadding / 2;
    final cardWidth = (screenWidth * vp) - (perItemPadding * 2);
    // Taller image for Featured cards: lower aspect ratio => more height
    final isCompactWidth = cardWidth <= 280;
    final featuredImageAspect = isCompactWidth ? 2.5 : 2.3; // was ~3.0/2.9 in height calc and 3.8/3.2 in card

    // Check if items are empty BEFORE rendering the section
    // This wraps the entire section to hide header + content when no items
    return isPropertyTab
        ? pv.Consumer<PropertyProvider>(
            builder: (context, propertyProvider, _) {
              // Don't hide during loading
              if (propertyProvider.isFeaturedLoading && !propertyProvider.isLoadingMore) {
                return _buildSectionWithContent(
                  isPropertyTab, screenWidth, sectionHeight, perItemPadding, 
                  startPadding, cardWidth, featuredImageAspect, _buildLoadingState(),
                );
              }
              // If no items after loading, hide entire section
              if (!propertyProvider.isFeaturedLoading && propertyProvider.filteredFeaturedProperties.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildSectionWithContent(
                isPropertyTab, screenWidth, sectionHeight, perItemPadding,
                startPadding, cardWidth, featuredImageAspect, 
                _buildPropertyContent(propertyProvider, screenWidth, perItemPadding, startPadding, cardWidth, featuredImageAspect),
              );
            },
          )
        : pv.Consumer<VehicleProvider>(
            builder: (context, vehicleProvider, _) {
              // Don't hide during loading
              if (vehicleProvider.isFeaturedLoading) {
                return _buildSectionWithContent(
                  isPropertyTab, screenWidth, sectionHeight, perItemPadding,
                  startPadding, cardWidth, featuredImageAspect, _buildLoadingState(),
                );
              }
              // If no items after loading, hide entire section
              final items = vehicleProvider.filteredFeaturedVehicles;
              if (!vehicleProvider.isFeaturedLoading && items.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildSectionWithContent(
                isPropertyTab, screenWidth, sectionHeight, perItemPadding,
                startPadding, cardWidth, featuredImageAspect,
                _buildVehicleContent(vehicleProvider, items, screenWidth, perItemPadding, startPadding, cardWidth, featuredImageAspect),
              );
            },
          );
  }

  Widget _buildSectionWithContent(
    bool isPropertyTab, double screenWidth, double sectionHeight, 
    double perItemPadding, double startPadding, double cardWidth, 
    double featuredImageAspect, Widget content,
  ) {
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
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      final c = widget.isDark
                          ? EnterpriseDarkTheme.primaryAccent
                          : EnterpriseLightTheme.primaryAccent;
                      return c.withValues(alpha: 0.12);
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
        const SizedBox(height: 4),
        Container(
          height: sectionHeight,
          padding: const EdgeInsets.only(top: 8, bottom: 12), // keep in sync with _getSectionHeight containerVerticalPadding
          clipBehavior: Clip.none, // Allow overflow for pop-up effect
          child: content,
        ),
      ],
    );
  }

  /// Build property cards content (ListView or PageView)
  Widget _buildPropertyContent(
    PropertyProvider propertyProvider, double screenWidth, 
    double perItemPadding, double startPadding, double cardWidth, 
    double featuredImageAspect,
  ) {
    final items = propertyProvider.filteredFeaturedProperties;
    if (items.isEmpty) return const SizedBox.shrink();
    
    final useList = screenWidth > 700;
    if (useList) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: EdgeInsets.only(left: startPadding, right: perItemPadding),
        itemCount: items.length,
        itemBuilder: (context, index) {
          if (index == items.length - 3 && 
              !propertyProvider.isLoadingMore && 
              propertyProvider.hasMoreProperties) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              propertyProvider.loadFeaturedProperties(
                category: widget.selectedCategory,
                loadMore: true,
              );
            });
          }
          
          final property = items[index];
          final vm = ListingViewModelFactory.fromProperty(property);
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
                  imageAspectRatio: featuredImageAspect,
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
      padEnds: false,
      clipBehavior: Clip.none,
      onPageChanged: (index) {
        if (_currentPropertyIndex != index) {
          setState(() { _currentPropertyIndex = index; });
        }
        if (index >= items.length - 3 && 
            !propertyProvider.isLoadingMore && 
            propertyProvider.hasMoreProperties) {
          propertyProvider.loadFeaturedProperties(
            category: widget.selectedCategory,
            loadMore: true,
          );
        }
      },
      itemCount: items.length,
      itemBuilder: (context, index) {
        final property = items[index];
        final vm = ListingViewModelFactory.fromProperty(property);
        final isActive = index == _currentPropertyIndex;
        final isFirstOrLast = index == 0 || index == items.length - 1;
        final shouldPopUp = isActive && !isFirstOrLast;
        
        return Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          margin: EdgeInsets.only(left: index == 0 ? startPadding : 0, right: perItemPadding),
          child: AnimatedScale(
            scale: shouldPopUp ? 1.05 : (isActive ? 1.0 : 0.95),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: widget.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                    blurRadius: 10,
                    offset: const Offset(-5, -5),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: (widget.isDark
                            ? EnterpriseDarkTheme.primaryAccent
                            : EnterpriseLightTheme.primaryAccent)
                        .withValues(alpha: widget.isDark ? 0.18 : 0.12),
                    blurRadius: 10,
                    offset: const Offset(5, 5),
                    spreadRadius: 0,
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
                  imageAspectRatio: featuredImageAspect,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build vehicle cards content
  Widget _buildVehicleContent(
    VehicleProvider vehicleProvider, List<VehicleModel> items,
    double screenWidth, double perItemPadding, double startPadding,
    double cardWidth, double featuredImageAspect,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    // Sync selected category into provider filter
    if (vehicleProvider.filterCategory != widget.selectedCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vehicleProvider.setFilterCategory(widget.selectedCategory);
      });
    }
    
    final useList = screenWidth > 700;
    if (useList) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: EdgeInsets.only(left: startPadding, right: perItemPadding),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final v = items[index];
          final vm = ListingViewModelFactory.fromVehicle(v);
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
                  imageAspectRatio: featuredImageAspect,
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
      padEnds: false,
      clipBehavior: Clip.none,
      onPageChanged: (index) {
        setState(() { _currentVehicleIndex = index; });
      },
      itemCount: items.length,
      itemBuilder: (context, index) {
        final v = items[index];
        final vm = ListingViewModelFactory.fromVehicle(v);
        final isActive = index == _currentVehicleIndex;
        final isFirstOrLast = index == 0 || index == items.length - 1;
        final shouldPopUp = isActive && !isFirstOrLast;
        
        return Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          margin: EdgeInsets.only(left: index == 0 ? startPadding : 0, right: perItemPadding),
          child: AnimatedScale(
            scale: shouldPopUp ? 1.05 : (isActive ? 1.0 : 0.95),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: widget.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                    blurRadius: 10,
                    offset: const Offset(-5, -5),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: (widget.isDark
                            ? EnterpriseDarkTheme.primaryAccent
                            : EnterpriseLightTheme.primaryAccent)
                        .withValues(alpha: widget.isDark ? 0.18 : 0.12),
                    blurRadius: 10,
                    offset: const Offset(5, 5),
                    spreadRadius: 0,
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
        );
      },
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
          return const SizedBox.shrink();
        }

        // no-op: item count not needed without auto-scroll
        final screenWidth = MediaQuery.of(context).size.width;
        // Derive vehicle card width from vehicle page controller viewportFraction
        final vp = _vehiclePageController.viewportFraction;
        final perItemPadding = screenWidth <= 600 ? 6.0 : 8.0; // slightly increased gap on phones
        final startPadding = screenWidth <= 600 ? 14.0 : perItemPadding / 2; // slight left gap on phones
        final cardWidth = (screenWidth * vp) - (perItemPadding * 2);
        final isCompactWidth = cardWidth <= 280;
        final featuredImageAspect = isCompactWidth ? 2.7 : 2.6;

        final useList = screenWidth > 700; // On desktop/tablet, left-align with a simple list
        if (useList) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            padding: EdgeInsets.only(left: startPadding, right: perItemPadding),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final v = items[index];
              final vm = ListingViewModelFactory.fromVehicle(v);
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
                      imageAspectRatio: featuredImageAspect, // added imageAspectRatio
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
          padEnds: false, // Align first card to left so next card peeks on the right
          clipBehavior: Clip.none, // Allow cards to overflow
          onPageChanged: (index) {
            setState(() {
              _currentVehicleIndex = index;
            });
          },
          itemCount: items.length,
          itemBuilder: (context, index) {
            final v = items[index];
            final vm = ListingViewModelFactory.fromVehicle(v);
            final isActive = index == _currentVehicleIndex;
            final isFirstOrLast = index == 0 || index == items.length - 1;
            final shouldPopUp = isActive && !isFirstOrLast;
            
            return Container(
              width: double.infinity,
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.only(left: index == 0 ? startPadding : 0, right: perItemPadding),
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
                          color: widget.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                          blurRadius: 10,
                          offset: const Offset(-5, -5),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: (widget.isDark
                                  ? EnterpriseDarkTheme.primaryAccent
                                  : EnterpriseLightTheme.primaryAccent)
                              .withValues(alpha: widget.isDark ? 0.18 : 0.12),
                          blurRadius: 10,
                          offset: const Offset(5, 5),
                          spreadRadius: 0,
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
              color: isDark ? EnterpriseDarkTheme.primaryBorder.withValues(alpha: 0.6) : Colors.grey.withValues(alpha: 0.3),
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

  double _getSectionHeight(double screenWidth) {
    // Compute dynamically from the ACTUAL page item width (viewportFraction),
    // not the heuristic _getCardWidth. This keeps image + info fully visible.
    final isPropertyTab = widget.tabController.index == 0;
    final vp = (isPropertyTab ? _propertyPageController : _vehiclePageController).viewportFraction;
    // Use same padding heuristic as build() to derive exact card width
    final perItemPadding = screenWidth <= 600 ? 6.0 : 8.0;
    final cardWidth = (screenWidth * vp) - (perItemPadding * 2);
    // Match ListingCard image aspect override for Featured
    final isCompactWidth = cardWidth <= 280;
    final imageAspect = isCompactWidth ? 2.7 : 2.6; // keep in sync with featuredImageAspect in build()
    final imageHeight = cardWidth / imageAspect; // height = width / aspect

    // Match ListingCard info rows but in a compact form
    double infoBase;
    if (cardWidth >= 260) {
      infoBase = 70.0; // compacted further
    } else if (cardWidth >= 220) {
      infoBase = 66.0;
    } else {
      infoBase = 60.0;
    }

    // Allowances: include rating row height and extra padding variance on small screens
    const ratingAllowance = 10.0;  // star + number row (tighter)
    const contentAllowance = 10.0; // chip/meta spacing (tighter)
    const extra = 2.0;             // border + rounding safety
    final mobileBoost = screenWidth <= 600 ? 12.0 : 10.0; // compact extra room on phones
    // Account for system text scale to prevent overflow on larger accessibility settings
    final textScaler = MediaQuery.textScalerOf(context);
    final scaleFactor = textScaler.scale(16.0) / 16.0; // normalized scale at 16px baseline
    final textScalePad = scaleFactor > 1.0 ? (scaleFactor - 1.0) * 22.0 : 0.0;
    
    // Add extra space for pop-up effect (5% scale increase + shadow)
    const popupAllowance = 24.0; // Extra space for 1.05 scale and shadow (slightly reduced)
    const safetyPad = 12.0; // small cushion to avoid occasional overflow
    const containerVerticalPadding = 20.0; // Container padding: top 8 + bottom 12 in build()

    return imageHeight
        + infoBase
        + ratingAllowance
        + contentAllowance
        + extra
        + mobileBoost
        + popupAllowance
        + textScalePad
        + safetyPad
        + containerVerticalPadding;
  }

}
