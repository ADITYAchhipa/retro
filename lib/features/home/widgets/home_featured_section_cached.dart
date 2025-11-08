import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/auth_router.dart';
import '../../../core/theme/enterprise_dark_theme.dart';
import '../../../core/theme/enterprise_light_theme.dart';
import '../../../core/widgets/loading_states.dart';
import '../../../core/widgets/listing_card.dart';
import '../../../core/widgets/listing_vm_factory.dart';
import '../../../core/widgets/hover_scale.dart';
import '../../../core/providers/featured_provider.dart';

/// Featured section widget with caching - fetches data only once
class HomeFeaturedSectionCached extends ConsumerStatefulWidget {
  const HomeFeaturedSectionCached({
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
  ConsumerState<HomeFeaturedSectionCached> createState() => _HomeFeaturedSectionCachedState();
}

class _HomeFeaturedSectionCachedState extends ConsumerState<HomeFeaturedSectionCached>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.86, initialPage: 0);
    widget.tabController.addListener(_onTabChanged);
    
    // Initialize with properties by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(featuredProvider.notifier).loadFeaturedItems(FeaturedCategory.property);
    });
  }

  void _onTabChanged() {
    setState(() {});
    // Switch category based on tab index
    final category = widget.tabController.index == 0
        ? FeaturedCategory.property
        : FeaturedCategory.vehicle;
    ref.read(featuredProvider.notifier).switchCategory(category);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateController();
  }

  void _updateController() {
    final screenWidth = MediaQuery.of(context).size.width;
    final viewportFraction = _getViewportFraction(screenWidth);
    
    if ((_pageController.viewportFraction - viewportFraction).abs() > 0.005) {
      _pageController.dispose();
      _pageController = PageController(
        viewportFraction: viewportFraction,
        initialPage: 0,
      );
    }
  }

  double _getViewportFraction(double screenWidth) {
    if (screenWidth > 1400) return 0.18;
    if (screenWidth > 1200) return 0.22;
    if (screenWidth > 900) return 0.28;
    if (screenWidth > 700) return 0.42;
    if (screenWidth > 500) return 0.78;
    return 0.89;
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featuredState = ref.watch(featuredProvider);
    final isPropertyTab = widget.tabController.index == 0;
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    
    _updateController();
    
    final sectionHeight = _getSectionHeight(screenWidth);
    final vp = _pageController.viewportFraction;
    final perItemPadding = screenWidth <= 600 ? 6.0 : 8.0;
    final startPadding = screenWidth <= 600 ? 14.0 : perItemPadding / 2;
    final cardWidth = (screenWidth * vp) - (perItemPadding * 2);
    final isCompactWidth = cardWidth <= 280;
    final featuredImageAspect = isCompactWidth ? 2.5 : 2.3;

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
                  color: widget.isDark
                      ? EnterpriseDarkTheme.primaryText
                      : EnterpriseLightTheme.primaryText,
                ),
              ),
              // Cache indicator (optional - for debugging)
              if (featuredState.category == FeaturedCategory.property &&
                  featuredState.items.isNotEmpty &&
                  !featuredState.isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green.withOpacity(0.6),
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
                    final type = isPropertyTab ? 'property' : 'vehicle';
                    final cat = Uri.encodeComponent(widget.selectedCategory);
                    context.push('${Routes.search}?type=$type&category=$cat');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark
                          ? EnterpriseDarkTheme.primaryAccent
                          : EnterpriseLightTheme.primaryAccent,
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
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          clipBehavior: Clip.none,
          child: _buildContent(
            featuredState,
            screenWidth,
            cardWidth,
            startPadding,
            perItemPadding,
            featuredImageAspect,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    FeaturedState featuredState,
    double screenWidth,
    double cardWidth,
    double startPadding,
    double perItemPadding,
    double featuredImageAspect,
  ) {
    if (featuredState.isLoading && featuredState.items.isEmpty) {
      return _buildLoadingState(screenWidth, cardWidth);
    }

    if (featuredState.error != null && featuredState.items.isEmpty) {
      return _buildErrorState(featuredState.error!);
    }

    if (featuredState.items.isEmpty) {
      return _buildEmptyState();
    }

    final useList = screenWidth > 700;

    if (useList) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: EdgeInsets.only(left: startPadding, right: perItemPadding),
        itemCount: featuredState.items.length,
        itemBuilder: (context, index) {
          final listing = featuredState.items[index];
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
                  listing: listing,
                  imageAspectRatio: featuredImageAspect,
                ),
              ),
            ),
          );
        },
      );
    }

    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      padEnds: false,
      clipBehavior: Clip.none,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemCount: featuredState.items.length,
      itemBuilder: (context, index) {
        final listing = featuredState.items[index];
        final isActive = index == _currentIndex;
        final isFirstOrLast = index == 0 || index == featuredState.items.length - 1;
        final shouldPopUp = isActive && !isFirstOrLast;
        
        return Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          margin: EdgeInsets.only(
            left: index == 0 ? startPadding : 0,
            right: perItemPadding,
          ),
          child: AnimatedScale(
            scale: shouldPopUp ? 1.05 : (isActive ? 1.0 : 0.95),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: widget.isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.white,
                          blurRadius: 10,
                          offset: const Offset(-5, -5),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: (widget.isDark
                                  ? EnterpriseDarkTheme.primaryAccent
                                  : EnterpriseLightTheme.primaryAccent)
                              .withOpacity(widget.isDark ? 0.18 : 0.12),
                          blurRadius: 10,
                          offset: const Offset(5, 5),
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: HoverScale(
                scale: 1.02,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                enableOnTouch: true,
                child: ListingCard(
                  listing: listing,
                  imageAspectRatio: featuredImageAspect,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(double screenWidth, double cardWidth) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: cardWidth,
          margin: EdgeInsets.only(right: screenWidth > 600 ? 16 : 12),
          decoration: BoxDecoration(
            color: widget.isDark
                ? EnterpriseDarkTheme.cardBackground
                : EnterpriseLightTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark
                  ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.6)
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(
                width: double.infinity,
                height: 110,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
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
            color: widget.isDark
                ? EnterpriseDarkTheme.secondaryText
                : EnterpriseLightTheme.secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load featured items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.isDark
                  ? EnterpriseDarkTheme.primaryText
                  : EnterpriseLightTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: widget.isDark
                  ? EnterpriseDarkTheme.secondaryText
                  : EnterpriseLightTheme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(featuredProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isPropertyTab = widget.tabController.index == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No featured ${isPropertyTab ? 'properties' : 'vehicles'} available',
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

  double _getSectionHeight(double screenWidth) {
    final vp = _pageController.viewportFraction;
    final perItemPadding = screenWidth <= 600 ? 6.0 : 8.0;
    final cardWidth = (screenWidth * vp) - (perItemPadding * 2);
    final isCompactWidth = cardWidth <= 280;
    final imageAspect = isCompactWidth ? 2.7 : 2.6;
    final imageHeight = cardWidth / imageAspect;

    double infoBase;
    if (cardWidth >= 260) {
      infoBase = 70.0;
    } else if (cardWidth >= 220) {
      infoBase = 66.0;
    } else {
      infoBase = 60.0;
    }

    const ratingAllowance = 10.0;
    const contentAllowance = 10.0;
    const extra = 2.0;
    final mobileBoost = screenWidth <= 600 ? 12.0 : 10.0;
    final textScaler = MediaQuery.textScalerOf(context);
    final scaleFactor = textScaler.scale(16.0) / 16.0;
    final textScalePad = scaleFactor > 1.0 ? (scaleFactor - 1.0) * 22.0 : 0.0;
    const popupAllowance = 24.0;
    const safetyPad = 12.0;
    const containerVerticalPadding = 20.0;

    return imageHeight +
        infoBase +
        ratingAllowance +
        contentAllowance +
        extra +
        mobileBoost +
        popupAllowance +
        textScalePad +
        safetyPad +
        containerVerticalPadding;
  }
}
