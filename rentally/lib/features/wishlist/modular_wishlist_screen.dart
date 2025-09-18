import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/loading_states.dart';
import '../../widgets/responsive_layout.dart';
import '../../services/wishlist_service.dart';
import '../../services/listing_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/listing_card.dart';
import '../../core/widgets/listing_card_list.dart';

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
  
  bool _isLoading = true;
  String? _error;
  bool _isGridView = true; // default to grid view
  String _sortBy = 'recent';
  
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();
  final _scrollController = ScrollController();
  
  final Set<String> _selectedItems = {};
  String _category = 'all'; // all, apartment, house, villa
  final String _query = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

    return ListingViewModel(
      id: item['id'] as String,
      title: item['title']?.toString() ?? '',
      location: pickLocation(item),
      priceLabel: CurrencyFormatter.formatPricePerUnit((item['price'] as num).toDouble(), 'night'),
      imageUrl: pickImage(item),
      rating: (item['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (item['reviews'] ?? item['reviewCount']) as int?,
      chips: [cap(type)],
      metaItems: metas,
      isVehicle: (type == 'vehicle'),
      badges: const [],
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
    _fadeController.forward();
  }

  // _loadWishlist() removed: wishlist now derives from providers (listingProvider, wishlistProvider)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      bottomNavigationBar: _selectedItems.isNotEmpty
          ? _buildSelectionBar(Theme.of(context))
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    return AppBar(
      title: const Text('Wishlist'),
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      toolbarHeight: 44,
      actions: [
        IconButton(
          tooltip: _isGridView ? 'List view' : 'Grid view',
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        PopupMenuButton<String>(
          tooltip: 'Sort',
          initialValue: _sortBy,
          onSelected: (value) => setState(() => _sortBy = value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'recent', child: Text('Recently Added')),
            PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
            PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
            PopupMenuItem(value: 'rating', child: Text('Highest Rated')),
          ],
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.sort),
          ),
        ),
        if (ref.watch(wishlistProvider).wishlistIds.isNotEmpty)
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clearAll,
          ),
        if (_selectedItems.isNotEmpty)
          IconButton(
            tooltip: 'Remove selected',
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteDialog,
          ),
      ],
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
              _buildTopBar(Theme.of(context)),
              ResponsiveLayout(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
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

Widget _buildTopBar(ThemeData theme) {
  return MediaQuery.removePadding(
    context: context,
    removeLeft: true,
    removeRight: true,
    removeTop: false,
    removeBottom: false,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Center(child: _buildFilterChip('All', 'all'))),
              Expanded(child: Center(child: _buildFilterChip('Properties', 'property'))),
              Expanded(child: Center(child: _buildFilterChip('Vehicles', 'vehicle'))),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    ),
  );
  }

  Widget _buildFilterChip(String label, String value) {
    final theme = Theme.of(context);
    final selected = _category == value;
    return ChoiceChip(
      label: Text(label, style: theme.textTheme.bodySmall),
      selected: selected,
      onSelected: (_) => setState(() => _category = value),
      selectedColor: theme.colorScheme.primary.withOpacity(0.15),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.5),
        width: 1.2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: LoadingStates.propertyCardSkeleton(context),
        ),
      ),
    );
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
              'Error Loading Wishlist',
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
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64),
            const SizedBox(height: 16),
            Text(
              'Your Wishlist is Empty',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Start exploring and save your favorite properties',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.search),
              label: const Text('Explore Properties'),
            ),
          ],
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
        return _buildListCard(item);
      },
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> items) {
    return LayoutBuilder(builder: (context, constraints) {
      // Use 2 columns on desktop/tablet widths, 1 on phones
      final bool isPhoneWidth = constraints.maxWidth < 600;
      final int crossAxisCount = isPhoneWidth ? 1 : 2;
      const spacing = 12.0; // consistent with search grid spacing
      final cellWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

      // Match ListingCard's image (2:1) + info base heights
      final imageHeight = cellWidth / 2; // AspectRatio 2.0 -> height = width/2
      double infoBase;
      if (cellWidth >= 260) {
        infoBase = 104.0;
      } else if (cellWidth >= 220) {
        infoBase = 96.0;
      } else {
        infoBase = 90.0;
      }
      const contentAllowance = 48.0; // increased to prevent bottom overflow (meta row + share + spacing buffer)
      const borderExtra = 8.0;
      final itemHeight = imageHeight + infoBase + contentAllowance + borderExtra;

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
          return _buildGridCard(item);
        },
      );
    });
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
            chipOnImage: false,
            showInfoChip: false,
            chipBelowImage: true,
            onTap: () => _navigateToDetail(item['id'] as String),
            onLongPress: () => _toggleSelection(item['id'] as String),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Selected Items'),
        content: Text('Remove ${_selectedItems.length} items from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final toRemove = List<String>.from(_selectedItems);
              for (final id in toRemove) {
                ref.read(wishlistProvider.notifier).removeFromWishlist(id);
              }
              _selectedItems.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selected items removed from wishlist'),
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _clearAll() {
    final currentIds = ref.read(wishlistProvider).wishlistIds;
    if (currentIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Wishlist'),
        content: const Text('Remove all items from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(wishlistProvider.notifier).clearWishlist();
              _selectedItems.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wishlist cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
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
          border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.4))),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          children: [
            Text('${_selectedItems.length} selected', style: theme.textTheme.bodyMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: _showDeleteDialog,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing selected items...')),
                );
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share'),
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
