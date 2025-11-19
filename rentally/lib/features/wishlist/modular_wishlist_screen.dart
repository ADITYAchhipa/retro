import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/loading_states.dart';
import '../../widgets/responsive_layout.dart';
import '../../services/wishlist_service.dart';
import '../../services/listing_service.dart';
import '../../core/widgets/listing_vm_factory.dart';
import '../../core/widgets/listing_card.dart';
import '../../core/widgets/listing_card_list.dart';
import '../../core/neo/neo.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';
import '../../l10n/app_localizations.dart';

/// Modular Wishlist Screen with Industrial-Grade Features
class ModularWishlistScreen extends ConsumerStatefulWidget {
  const ModularWishlistScreen({super.key});

  @override
  ConsumerState<ModularWishlistScreen> createState() =>
      _ModularWishlistScreenState();
}

class _ModularWishlistScreenState
    extends ConsumerState<ModularWishlistScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _staggerController;
  
  bool _isLoading = true;
  String? _error;
  bool _isGridView = true; // default to grid view
  String _sortBy = 'recent';
  bool _showControls = true;
  double _lastScrollOffset = 0;
  
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();
  final _scrollController = ScrollController();
  
  final Set<String> _selectedItems = {};
  String _category = 'all'; // all, apartment, house, villa
  final String _query = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scrollController.addListener(_onScroll);
    // Ensure listings are refreshed once the screen mounts
    Future.microtask(() => ref.read(listingProvider.notifier).refreshListings());
    // Loading is managed by providers; ensure local flag does not block UI
    _isLoading = false;
    // Default to list view on phones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bool isPhoneWidth = MediaQuery.of(context).size.width < 600;
      if (isPhoneWidth && mounted) {
        setState(() {
          _isGridView = false;
        });
      }
    });
  }

  ListingViewModel _toViewModel(Map<String, dynamic> item) {
    String type = (item['type']?.toString() ?? 'property');
    String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    final Map<String, dynamic> am = (item['amenities'] as Map<String, dynamic>? ) ?? const {};
    final metas = <ListingMetaItem>[];
    if ((am['wifi'] ?? false) == true) metas.add(const ListingMetaItem(icon: Icons.wifi, text: 'WiFi'));
    if ((am['parking'] ?? false) == true) metas.add(const ListingMetaItem(icon: Icons.local_parking, text: 'Parking'));
    if ((am['pool'] ?? false) == true) metas.add(const ListingMetaItem(icon: Icons.pool, text: 'Pool'));

    // Pick a primary image from supported keys
    String? pickImage(Map<String, dynamic> it) {
      String? url;
      // Common keys
      final keys = [
        'image', 'imageUrl', 'image_url', 'thumbnail', 'thumb', 'cover', 'coverImage', 'cover_image',
        'photo', 'picture', 'img'
      ];
      for (final k in keys) {
        final v = it[k];
        if (v is String && v.trim().isNotEmpty) {
          url = v.trim();
          break;
        }
      }
      // From arrays
      if (url == null) {
        final arrayKeys = ['images', 'photos', 'pictures', 'thumbnails'];
        for (final ak in arrayKeys) {
          final arr = it[ak];
          if (arr is List && arr.isNotEmpty) {
            final first = arr.first;
            if (first is String && first.trim().isNotEmpty) {
              url = first.trim();
              break;
            }
          }
        }
      }
      if (url == null) return null;
      // Return original URL; display layer will attempt https fallback if needed
      return url;
    }

    // Location fallback
    String pickLocation(Map<String, dynamic> it) {
      final loc = (it['location']?.toString() ?? '').trim();
      if (loc.isNotEmpty) return loc;
      final city = (it['city']?.toString() ?? '').trim();
      final state = (it['state']?.toString() ?? '').trim();
      if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
      if (city.isNotEmpty) return city;
      return state;
    }

    // Determine proper unit based on owner-selected unit (from ListingService.Listing)
    final bool isVehicle = (type == 'vehicle');
    final String ru = (item['rentalUnit']?.toString().toLowerCase() ?? '').trim();
    final String unit = isVehicle ? (ru.isNotEmpty ? ru : 'day') : (ru.isNotEmpty ? ru : 'month');
    final double amount = (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;

    return ListingViewModelFactory.fromRaw(
      ref,
      id: item['id'] as String,
      title: item['title']?.toString() ?? '',
      location: pickLocation(item),
      price: amount,
      rentalUnit: unit,
      imageUrl: pickImage(item),
      rating: (item['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (item['reviews'] ?? item['reviewCount']) as int?,
      chips: [cap(type)],
      metaItems: metas,
      fallbackIcon: isVehicle ? Icons.directions_car : Icons.home,
      isVehicle: isVehicle,
      isFavorite: true,
    );
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeController.forward();
    _staggerController.forward();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final currentOffset = _scrollController.offset;
    
    // Always show controls when near the top (extended comfort zone)
    if (currentOffset < 100) {
      if (!_showControls) {
        setState(() {
          _showControls = true;
        });
      }
      _lastScrollOffset = currentOffset;
      return;
    }
    
    final delta = currentOffset - _lastScrollOffset;
    
    // Ultra-responsive threshold (6px) with smooth triggering
    if (delta.abs() > 6) {
      // Scrolling down (offset increasing) = gracefully hide controls
      // Scrolling up (offset decreasing) = instantly reveal controls
      final shouldShow = delta < 0;
      
      // Only trigger state change if needed (prevents unnecessary rebuilds)
      if (shouldShow != _showControls) {
        setState(() {
          _showControls = shouldShow;
        });
      }
      
      // Continuous offset tracking for buttery-smooth transitions
      _lastScrollOffset = currentOffset;
    }
  }

  // _loadWishlist() removed: wishlist now derives from providers (listingProvider, wishlistProvider)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildModernHeader(theme, isDark),
            Container(
              height: 1,
              color: isDark ? theme.colorScheme.surface : Colors.white,
            ),
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedItems.isNotEmpty
          ? _buildSelectionBar(theme)
          : null,
    );
  }

  Widget _buildModernHeader(ThemeData theme, bool isDark) {
    final wishlistCount = ref.watch(wishlistProvider).wishlistIds.length;
    // Compute counts to render filter chips inside the pinned header
    final listingState = ref.watch(listingProvider);
    final wishlistState = ref.watch(wishlistProvider);
    final items = _computeBaseItems(listingState, wishlistState);
    final int allCount = items.length;
    final int propertyCount = items
        .where((i) => (i['type'] ?? '').toString().toLowerCase() != 'vehicle')
        .length;
    final int vehicleCount = items
        .where((i) => (i['type'] ?? '').toString().toLowerCase() == 'vehicle')
        .length;
    
    return NeoGlass(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.zero,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white,
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
                    .withValues(alpha: isDark ? 0.16 : 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
                spreadRadius: 0.1,
              ),
            ]
          : const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.wishlist,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    if (wishlistCount > 0)
                      Text(
                        '$wishlistCount ${wishlistCount == 1 ? "item" : "items"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildControlButton(
                    icon: _isGridView ? Icons.view_list : Icons.grid_view,
                    label: _isGridView ? 'List' : 'Grid',
                    onTap: () => setState(() => _isGridView = !_isGridView),
                    theme: theme,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildSortButton(theme, isDark),
                  const SizedBox(width: 8),
                  if (wishlistCount > 0)
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.clearAll,
                      icon: const Icon(Icons.delete_sweep_outlined, size: 22),
                      onPressed: _clearAll,
                      color: isDark ? Colors.white70 : theme.primaryColor,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Pinned filter chips row (moved from scrolling content)
          Row(
            children: [
              Expanded(child: _buildModernFilterChip('All', 'all', allCount, theme, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildModernFilterChip('Properties', 'property', propertyCount, theme, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildModernFilterChip('Vehicles', 'vehicle', vehicleCount, theme, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return IconButton(
      tooltip: label,
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 20,
        color: isDark ? Colors.white70 : theme.primaryColor,
      ),
    );
  }

  Widget _buildSortButton(ThemeData theme, bool isDark) {
    return PopupMenuButton<String>(
      tooltip: 'Sort',
      initialValue: _sortBy,
      onSelected: (value) => setState(() => _sortBy = value),
      offset: const Offset(0, 40),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'recent', child: Text('Recently Added')),
        PopupMenuItem(value: 'price_low', child: Text('Price: Low → High')),
        PopupMenuItem(value: 'price_high', child: Text('Price: High → Low')),
        PopupMenuItem(value: 'rating', child: Text('Highest Rated')),
      ],
      icon: Icon(
        Icons.sort,
        size: 20,
        color: isDark ? Colors.white70 : theme.primaryColor,
      ),
    );
  }

  Widget _buildContent() {
    final listingState = ref.watch(listingProvider);
    final wishlistState = ref.watch(wishlistProvider);

    if (_error != null) {
      return _buildErrorState();
    }

    if (listingState.isLoading) {
      return _buildLoadingState();
    }

    final baseItems = _computeBaseItems(listingState, wishlistState);
    final sortedItems = _getSortedItems(baseItems);

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: () => ref.read(listingProvider.notifier).refreshListings(),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filter chips are now pinned in the header; removed top bar from scroll content
              ResponsiveLayout(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 12),
                child: sortedItems.isEmpty
                    ? _buildEmptyState()
                    : _isGridView
                        ? _buildGridView(sortedItems)
                        : _buildListView(sortedItems),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _computeBaseItems(ListingState listingState, WishlistState wishlistState) {
    final ids = wishlistState.wishlistIds;
    final listings = listingState.listings;
    final List<Map<String, dynamic>> items = [];
    for (final l in listings) {
      if (ids.contains(l.id)) {
        items.add({
          'id': l.id,
          'title': l.title,
          'location': '${l.city}, ${l.state}',
          'price': l.price,
          'rentalUnit': l.rentalUnit,
          'rating': l.rating ?? 0.0,
          'reviews': l.reviewCount,
          'image': l.images.isNotEmpty ? l.images.first : null,
          'addedAt': l.createdAt,
          'isAvailable': l.isActive,
          'type': (l.type).toString().toLowerCase(),
          'amenities': l.amenities,
        });
      }

    }
    return items;
  }

  Widget _buildModernFilterChip(String label, String value, int count, ThemeData theme, bool isDark) {
    final selected = _category == value;
    
    return AnimatedScale(
      scale: selected ? 1.0 : 0.96,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTap: () => setState(() => _category = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : (isDark ? theme.colorScheme.surface.withValues(alpha: 0.08) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : (isDark
                      ? EnterpriseDarkTheme.primaryBorder.withValues(alpha: 0.5)
                      : theme.colorScheme.outline.withValues(alpha: 0.2)),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                      blurRadius: 8,
                      offset: const Offset(-4, -4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: (isDark
                              ? EnterpriseDarkTheme.primaryAccent
                              : EnterpriseLightTheme.primaryAccent)
                          .withValues(alpha: isDark ? 0.15 : 0.10),
                      blurRadius: 8,
                      offset: const Offset(4, 4),
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: selected ? Colors.white : (isDark ? Colors.white70 : theme.colorScheme.onSurface),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: selected ? Colors.white : theme.colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return LoadingStates.listShimmer(context, itemCount: 6);
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.error,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = false; // rely on provider-level loading
                });
                ref.read(listingProvider.notifier).refreshListings();
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.emptyWishlist,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.emptyWishlistDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.search, size: 20),
                  label: Text(AppLocalizations.of(context)!.startExploring),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final progress = index / items.length;
        final delay = (progress * 400).toInt();
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + delay),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Dismissible(
            key: Key(item['id'] as String),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 10),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            ),
            confirmDismiss: (direction) async {
              return await _showRemoveDialog(item['id'] as String);
            },
            onDismissed: (direction) {
              ref.read(wishlistProvider.notifier).removeFromWishlist(item['id'] as String);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Removed from wishlist'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref.read(wishlistProvider.notifier).addToWishlist(item['id'] as String);
                    },
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: _buildListCard(item),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> items) {
    return LayoutBuilder(builder: (context, constraints) {
      final double w = constraints.maxWidth;
      // 1-up grid: always a single column regardless of width
      const int crossAxisCount = 1;
      const spacing = 12.0;
      final cellWidth = (w - spacing * (crossAxisCount - 1)) / crossAxisCount;
      final imageAspect = cellWidth > 280 ? 2.2 : 2.4;
      final imageHeight = cellWidth / imageAspect;
      double infoBase;
      if (cellWidth >= 260) {
        infoBase = 86.0;
      } else if (cellWidth >= 220) {
        infoBase = 80.0;
      } else {
        infoBase = 74.0;
      }
      const contentAllowance = 20.0;
      const borderExtra = 8.0;
      final textScale = MediaQuery.textScalerOf(context).scale(16.0) / 16.0;
      final textScalePad = textScale > 1.0 ? (textScale - 1.0) * 16.0 : 0.0;
      final itemHeight = imageHeight + infoBase + contentAllowance + borderExtra + textScalePad;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent: itemHeight,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final progress = index / items.length;
          final delay = (progress * 400).toInt();
          
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + delay),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: child,
                ),
              );
            },
            child: _buildGridCard(item),
          );
        },
      );
    });
  }

  Future<bool?> _showRemoveDialog(String itemId) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.favorite_border_rounded, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Remove from Wishlist?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 60,
              color: Colors.red.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'This item will be removed from your wishlist.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  Widget _buildListCard(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final isSelected = _selectedItems.contains(item['id']);
    final isDark = theme.brightness == Brightness.dark;
    final vm = _toViewModel(item);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: isSelected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary, width: 2),
            )
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return ListingListCard(
            model: vm,
            isDark: isDark,
            width: w,
            margin: EdgeInsets.zero,
            onTap: () => _navigateToDetail(item['id'] as String),
            onLongPress: () => _toggleSelection(item['id'] as String),
            chipOnImage: false,
            showInfoChip: false,
            chipBelowImage: true,
          );
        },
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final isSelected = _selectedItems.contains(item['id']);
    final isDark = theme.brightness == Brightness.dark;
    final vm = _toViewModel(item);
    return LayoutBuilder(builder: (context, constraints) {
      final cellWidth = constraints.maxWidth;
      return Container(
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              )
            : null,
        child: ListingCard(
          model: vm,
          isDark: isDark,
          width: cellWidth,
          margin: EdgeInsets.zero,
          onTap: () => _navigateToDetail(item['id'] as String),
          onLongPress: () => _toggleSelection(item['id'] as String),
          chipOnImage: false,
          showInfoChip: false,
          chipInRatingRowRight: true,
          priceBottomLeft: true,
          shareBottomRight: true,
        ),
      );
    });
  }

  List<Map<String, dynamic>> _getSortedItems(List<Map<String, dynamic>> source) {
    // Filter by category and search query first
    var items = source.where((item) {
      final type = (item['type'] ?? '').toString().toLowerCase();
      bool matchesCategory;
      if (_category == 'vehicle') {
        matchesCategory = type == 'vehicle';
      } else if (_category == 'property') {
        matchesCategory = type != 'vehicle';
      } else {
        matchesCategory = true; // 'all' or unspecified
      }
      final q = _query.toLowerCase();
      final matchesQuery = q.isEmpty
          ? true
          : (item['title'].toString().toLowerCase().contains(q) ||
              item['location'].toString().toLowerCase().contains(q));
      return matchesCategory && matchesQuery;
    }).toList();

    switch (_sortBy) {
      case 'price_low':
        items.sort((a, b) => a['price'].compareTo(b['price']));
        break;
      case 'price_high':
        items.sort((a, b) => b['price'].compareTo(a['price']));
        break;
      case 'rating':
        items.sort((a, b) => b['rating'].compareTo(a['rating']));
        break;
      case 'recent':
      default:
        items.sort((a, b) => b['addedAt'].compareTo(a['addedAt']));
        break;
    }
    
    return items;
  }

  

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  void _navigateToDetail(String itemId) {
    context.push('/listing/$itemId');
  }

  

  void _showDeleteDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Remove Selected Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist_rounded, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedItems.length} items selected',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Remove these items from your wishlist?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              final toRemove = List<String>.from(_selectedItems);
              for (final id in toRemove) {
                ref.read(wishlistProvider.notifier).removeFromWishlist(id);
              }
              _selectedItems.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Selected items removed'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.delete_sweep_rounded, size: 20),
            label: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  void _clearAll() {
    final currentIds = ref.read(wishlistProvider).wishlistIds;
    if (currentIds.isEmpty) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.clearWishlist,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.heart_broken_rounded,
              size: 60,
              color: Colors.red.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.clearWishlistConfirm,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ref.read(wishlistProvider.notifier).clearWishlist();
              _selectedItems.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.wishlistCleared),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 20),
            label: Text(AppLocalizations.of(context)!.clear, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  Widget _buildSelectionBar(ThemeData theme) {
    // Compute currently visible items to base selection actions on
    final items = _getSortedItems(_computeBaseItems(ref.read(listingProvider), ref.read(wishlistProvider)));
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4))),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          children: [
            Text('${_selectedItems.length} selected', style: theme.textTheme.bodyMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: _showDeleteDialog,
              icon: const Icon(Icons.delete_outline),
              label: Text(AppLocalizations.of(context)!.delete),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.share)),
                );
              },
              icon: const Icon(Icons.share_outlined),
              label: Text(AppLocalizations.of(context)!.share),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  if (_selectedItems.length == items.length) {
                    _selectedItems.clear();
                  } else {
                    _selectedItems
                      ..clear()
                      ..addAll(items.map((e) => e['id'] as String));
                  }
                });
              },
              child: Text(_selectedItems.length == items.length ? 'Clear selection' : 'Select all'),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
