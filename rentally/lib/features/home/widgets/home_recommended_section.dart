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
// import '../../../core/utils/price_unit_helper.dart';
import '../../../core/widgets/hover_scale.dart';

/// Recommended section widget showing personalized property/vehicle recommendations
class HomeRecommendedSection extends StatefulWidget {
  const HomeRecommendedSection({
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
  State<HomeRecommendedSection> createState() => _HomeRecommendedSectionState();
}

class _HomeRecommendedSectionState extends State<HomeRecommendedSection> {
  late PageController _recPageController;

  @override
  void initState() {
    super.initState();
    // Initialize with default viewport fraction, will be updated in didChangeDependencies
    _recPageController = PageController(viewportFraction: 0.86);
    widget.tabController.addListener(_onTabChanged);
    // Ensure featured data is loaded for both domains
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Vehicles are needed for the vehicles tab of this section
      pv.Provider.of<VehicleProvider>(context, listen: false).loadFeaturedVehicles();
    });
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateController();
  }

  void _updateController() {
    final screenWidth = MediaQuery.of(context).size.width;
    final viewportFraction = _getViewportFraction(screenWidth);
    
    // Only update if viewport fraction has changed significantly
    if ((_recPageController.viewportFraction - viewportFraction).abs() > 0.05) {
      _recPageController.dispose();
      _recPageController = PageController(viewportFraction: viewportFraction);
    }
  }

  double _getViewportFraction(double screenWidth) {
    if (screenWidth > 1400) return 0.14; // Large desktop: ~7 cards
    if (screenWidth > 1200) return 0.18; // Desktop: ~5.5 cards
    if (screenWidth > 900) return 0.22;  // Medium desktop: ~4.5 cards
    if (screenWidth > 700) return 0.36;  // Tablet: ~2.8 cards
    if (screenWidth > 500) return 0.65;  // Large phone: show 1.3 cards (second card partially visible)
    return 0.7;                          // Small phone: show 1.25 cards (second card partially visible)
  }

  double _getCardWidth(double screenWidth) {
    if (screenWidth > 1400) return 170;  // Large desktop: extra compact
    if (screenWidth > 1200) return 190;  // Desktop: extra compact
    if (screenWidth > 900) return 210;   // Medium desktop: compact
    if (screenWidth > 700) return 230;   // Tablet: compact
    if (screenWidth > 500) return 180;   // Large phone: compact
    return 150;                          // Small phone: minimal
  }

  double _getSectionHeight(double screenWidth) {
    // Compute dynamically from the ACTUAL page item width (viewportFraction),
    // not the heuristic _getCardWidth. This keeps image + info fully visible.
    final vp = _recPageController.viewportFraction;
    // Use same per-item padding as build() for consistency
    final perItemPadding = screenWidth <= 600 ? 4.0 : 2.0;
    final cardWidth = (screenWidth * vp) - (perItemPadding * 2);
    // Taller images: reduce aspect ratio (width:height)
    final isCompactWidth = cardWidth <= 280;
    final imageAspect = isCompactWidth ? 2.7 : 2.6; // keep in sync with build()
    final imageHeight = cardWidth / imageAspect; // height = width / aspect

    // Account for ListingCard's title + rating row + location + meta paddings
    double infoBase;
    if (cardWidth >= 260) {
      infoBase = 66.0; // compact a touch more
    } else if (cardWidth >= 220) {
      infoBase = 60.0;
    } else {
      infoBase = 54.0;
    }

    // Allowances: rating row, content spacing, borders/rounding,  and mobile safety boost
    const ratingAllowance = 12.0;     // star + number row (tighter)
    const contentAllowance = 10.0;    // chip/meta spacing (tighter)
    const extra = 6.0;                // borders + rounding
    const mobileBoost = 6.0;          // extra headroom for small phones
    final textScaler = MediaQuery.textScalerOf(context);
    final scaleFactor = textScaler.scale(16.0) / 16.0; // normalized against 16px baseline
    final textScalePad = scaleFactor > 1.0 ? (scaleFactor - 1.0) * 18.0 : 0.0;
    // Add a small safety pad to avoid occasional overflows
    const safetyPad = 22.0;
    return imageHeight + infoBase + ratingAllowance + contentAllowance + extra + mobileBoost + textScalePad + safetyPad;
  }

  void _onTabChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    _recPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Derive sizes from actual viewport so card + section heights match exactly
    final vp = _recPageController.viewportFraction;
    final perItemPadding = screenWidth <= 600 ? 4.0 : 2.0;
    final cardWidth = (screenWidth * vp) - (perItemPadding * 2);
    final sectionHeight = _getSectionHeight(screenWidth);
    final isCompactWidth = cardWidth <= 280;
    final recImageAspect = isCompactWidth ? 2.7 : 2.6; // keep in sync with _getSectionHeight
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.tabController.index == 0 ? 'Recommended for You' : 'Recommended Vehicles',
                style: TextStyle(
                  fontSize: screenWidth > 600 ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? EnterpriseDarkTheme.primaryText : EnterpriseLightTheme.primaryText,
                ),
              ),
              HoverScale(
                enableOnTouch: true,
                scale: 1.05,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: TextButton(
                  onPressed: () {
                    // Navigate to dedicated AI Recommendations screen (root-level)
                    context.push('/recommendations');
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
        const SizedBox(height: 8),
        Builder(builder: (context) {
          final isPropertyTab = widget.tabController.index == 0;
          return SizedBox(
            height: sectionHeight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isPropertyTab
                  ? pv.Consumer<PropertyProvider>(
                      key: ValueKey('rec_properties_${widget.tabController.index}'),
                      builder: (context, propertyProvider, _) {
                        if (propertyProvider.isFeaturedLoading) {
                          return _buildShimmerList();
                        }
                        final items = propertyProvider.filteredFeaturedProperties;
                        if (items.isEmpty) {
                          return _buildEmptyState(widget.selectedCategory);
                        }
                        return _buildRecommendedPager(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final p = items[index];
                            final vm = ListingViewModelFactory.fromProperty(p);
                            return ListingCard(
                              model: vm, 
                              isDark: widget.isDark, 
                              width: cardWidth, 
                              margin: EdgeInsets.only(right: screenWidth > 600 ? 16 : 12),
                              chipOnImage: false,
                              showInfoChip: false,
                              chipInRatingRowRight: true,
                              priceBottomLeft: true,
                              shareBottomRight: true,
                              imageAspectRatio: recImageAspect,
                            );
                          },
                        );
                      },
                    )
                  : pv.Consumer<VehicleProvider>(
                      key: ValueKey('rec_vehicles_${widget.tabController.index}_${widget.selectedCategory}'),
                      builder: (context, vehicleProvider, _) {
                        // filter by selectedCategory
                        if (vehicleProvider.filterCategory != widget.selectedCategory) {
                          WidgetsBinding.instance.addPostFrameCallback((_) => vehicleProvider.setFilterCategory(widget.selectedCategory));
                        }
                        if (vehicleProvider.isFeaturedLoading) {
                          return _buildShimmerList();
                        }
                        final items = vehicleProvider.filteredFeaturedVehicles;
                        if (!vehicleProvider.isFeaturedLoading && vehicleProvider.error == null && items.isEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) => vehicleProvider.loadFeaturedVehicles());
                        }
                        if (items.isEmpty) {
                          return _buildEmptyState(widget.selectedCategory);
                        }
                        return _buildRecommendedPager(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final v = items[index];
                            final vm = ListingViewModelFactory.fromVehicle(v);
                            return ListingCard(
                              model: vm, 
                              isDark: widget.isDark, 
                              width: cardWidth, 
                              margin: EdgeInsets.only(right: screenWidth > 600 ? 16 : 12),
                              chipOnImage: false,
                              showInfoChip: false,
                              chipInRatingRowRight: true,
                              priceBottomLeft: true,
                              shareBottomRight: true,
                              imageAspectRatio: recImageAspect,
                            );
                          },
                        );
                      },
                    ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecommendedPager({required int itemCount, required Widget Function(BuildContext, int) itemBuilder}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final vp = _recPageController.viewportFraction;
    const perItemPadding = 4.0;
    final cardWidth = (screenWidth * vp) - (perItemPadding * 2);

    // On desktop/tablet, use a simple horizontal list so items are left-aligned to the section origin
    if (screenWidth > 700) {
      final startPadding = screenWidth > 1200 ? 24.0 : 16.0;
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: EdgeInsets.only(left: startPadding, right: perItemPadding),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final card = itemBuilder(context, index);
          return SizedBox(
            width: cardWidth,
            child: HoverScale(
              scale: 1.02,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              enableOnTouch: true,
              child: card,
            ),
          );
        },
      );
    }

    // Phones: keep PageView but remove end padding and left-align the items
    final startPadding = screenWidth > 400 ? 16.0 : 12.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(left: startPadding, bottom: 6),
          child: PageView.builder(
            controller: _recPageController,
            physics: const BouncingScrollPhysics(),
            padEnds: false,
            clipBehavior: Clip.none,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final card = itemBuilder(context, index);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: perItemPadding),
                child: Align(
                  alignment: Alignment.topLeft,
                  heightFactor: 1.0,
                  child: HoverScale(
                    scale: 1.02,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    enableOnTouch: true,
                    child: card,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // (legacy) removed unused bespoke card builder and empty state

  Widget _buildShimmerList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = _getCardWidth(screenWidth);
        return Container(
          width: cardWidth,
          height: _getSectionHeight(screenWidth),
          margin: EdgeInsets.only(right: screenWidth > 600 ? 16 : 12),
          decoration: BoxDecoration(
            color: widget.isDark ? EnterpriseDarkTheme.cardBackground : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark 
                  ? EnterpriseDarkTheme.primaryBorder.withValues(alpha: 0.6)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image skeleton
              SkeletonLoader(
                width: double.infinity,
                height: 120,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              // Details skeleton
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 140, height: 16),
                    SizedBox(height: 6),
                    SkeletonLoader(width: 100, height: 14),
                    SizedBox(height: 12),
                    SkeletonLoader(width: 80, height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
