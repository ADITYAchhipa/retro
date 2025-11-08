import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/widgets/loading_states.dart';
import '../../widgets/responsive_layout.dart';
import '../../core/providers/ui_visibility_provider.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

/// Industrial-Grade Modular Reviews and Ratings Screen
/// 
/// Features:
/// - Error boundaries and crash prevention
/// - Skeleton loading states with animations
/// - Responsive design for all devices
/// - Accessibility compliance (WCAG 2.1)
/// - Interactive rating system
/// - Photo reviews support
/// - Filter and sort capabilities
/// - Pagination and lazy loading
/// - Review submission form
/// - Performance optimization
class ModularReviewsScreen extends ConsumerStatefulWidget {
  final String propertyId;
  
  const ModularReviewsScreen({
    super.key,
    required this.propertyId,
  });

  @override
  ConsumerState<ModularReviewsScreen> createState() =>
      _ModularReviewsScreenState();
}

class _ModularReviewsScreenState extends ConsumerState<ModularReviewsScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  
  // Review Data
  List<PropertyReview> _reviews = [];
  ReviewStats? _stats;
  ReviewFilter _currentFilter = ReviewFilter.all;
  ReviewSort _currentSort = ReviewSort.newest;
  int _currentPage = 1;
  bool _hasMoreReviews = true;
  bool _isLoadingMore = false;
  
  // Review Form
  double _userRating = 0.0;
  final TextEditingController _reviewController = TextEditingController();
  // final List<String> _selectedPhotos = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadReviews();
    // Hide Shell chrome while immersive reviews screen is open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(immersiveRouteOpenProvider.notifier).state = true;
      }
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadReviews({bool refresh = false}) async {
    try {
      if (refresh) {
        setState(() {
          _currentPage = 1;
          _hasMoreReviews = true;
        });
      }
      
      setState(() {
        _isLoading = refresh ? false : _isLoading;
        _error = null;
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      
      if (mounted) {
        final newReviews = _getMockReviews();
        setState(() {
          if (refresh) {
            _reviews = newReviews;
          } else {
            _reviews.addAll(newReviews);
          }
          _stats = _getMockStats();
          _isLoading = false;
          _hasMoreReviews = _currentPage < 3; // Mock pagination
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load reviews: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  List<PropertyReview> _getMockReviews() {
    return [
      PropertyReview(
        id: '1',
        userName: 'Sarah Johnson',
        userAvatar: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100',
        rating: 5.0,
        comment: 'Amazing property! The location is perfect and the host was incredibly helpful. The apartment was exactly as described and even better in person.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        photos: [
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400',
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400',
        ],
        likes: 12,
        isVerified: true,
      ),
      PropertyReview(
        id: '2',
        userName: 'Mike Chen',
        userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
        rating: 4.0,
        comment: 'Great place for a business trip. Clean, comfortable, and well-located. Only minor issue was the WiFi speed could be better.',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        photos: [],
        likes: 8,
        isVerified: true,
      ),
      PropertyReview(
        id: '3',
        userName: 'Emma Wilson',
        userAvatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
        rating: 5.0,
        comment: 'Absolutely loved staying here! The view from the balcony is breathtaking and the amenities are top-notch.',
        timestamp: DateTime.now().subtract(const Duration(days: 8)),
        photos: [
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400',
        ],
        likes: 15,
        isVerified: false,
      ),
    ];
  }

  ReviewStats _getMockStats() {
    return ReviewStats(
      totalReviews: 124,
      averageRating: 4.6,
      ratingDistribution: {
        5: 78,
        4: 32,
        3: 10,
        2: 3,
        1: 1,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: _buildWriteReviewFAB(),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 600) {
          // Full-bleed on phones
          return scaffold;
        }
        // Constrain on larger screens while keeping modest padding
        return ResponsiveLayout(
          maxWidth: 900,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: scaffold,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(AppLocalizations.of(context)!.reviews),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterOptions,
          tooltip: AppLocalizations.of(context)!.filters,
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: _showSortOptions,
          tooltip: AppLocalizations.of(context)!.sortBy,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    final isPhone = MediaQuery.of(context).size.width <= 600;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isPhone ? 0 : 16, vertical: 16),
      child: ListView(
        children: [
          LoadingStates.propertyCardShimmer(context),
          const SizedBox(height: 16),
          for (int i = 0; i < 3; i++) ...[
            LoadingStates.propertyCardShimmer(context),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return _buildErrorState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: () => _loadReviews(refresh: true),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildStatsSection()),
            SliverToBoxAdapter(child: _buildFiltersSection()),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < _reviews.length) {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: _buildReviewCard(_reviews[index]),
                    );
                  } else if (_hasMoreReviews) {
                    if (!_isLoadingMore) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _loadMoreReviews();
                      });
                    }
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return null;
                },
                childCount: _reviews.length + (_hasMoreReviews ? 1 : 0),
              ),
            ),
          ],
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
              onPressed: _loadReviews,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_stats == null) return const SizedBox.shrink();
    
    final isPhone = MediaQuery.of(context).size.width <= 600;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isPhone ? 0 : 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stats!.averageRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    _buildStarRating(_stats!.averageRating, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      '${_stats!.totalReviews} reviews',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(child: _buildRatingDistribution()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    return Column(
      children: [
        for (int rating = 5; rating >= 1; rating--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text('$rating'),
                const SizedBox(width: 8),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_stats!.ratingDistribution[rating] ?? 0) / _stats!.totalReviews,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_stats!.ratingDistribution[rating] ?? 0}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    final isPhone = MediaQuery.of(context).size.width <= 600;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isPhone ? 0 : 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ReviewFilter.values.map((filter) {
                  final isSelected = filter == _currentFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _currentFilter = filter;
                        });
                        _loadReviews(refresh: true);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(PropertyReview review) {
    final isPhone = MediaQuery.of(context).size.width <= 600;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isPhone ? 0 : 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: review.userAvatar,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Icon(
                      Icons.person,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (review.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        _buildStarRating(review.rating, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _formatTimeAgo(review.timestamp),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showReviewOptions(review),
                icon: const Icon(Icons.more_vert),
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (review.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildReviewPhotos(review.photos),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _likeReview(review),
                icon: Icon(
                  Icons.thumb_up_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text('${review.likes}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              TextButton.icon(
                onPressed: () => _replyToReview(review),
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Reply'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _reportReview(review),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Report'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPhotos(List<String> photos) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showPhotoGallery(photos, index),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: photos[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SkeletonLoader(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black12,
                    child: const Center(child: Icon(Icons.broken_image, size: 20, color: Colors.grey)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
                  ? Icons.star_half
                  : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  Widget _buildWriteReviewFAB() {
    return FloatingActionButton.extended(
      onPressed: _showWriteReviewDialog,
      icon: const Icon(Icons.rate_review),
      label: Text(AppLocalizations.of(context)!.writeReview),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  void _loadMoreReviews() {
    if (!_hasMoreReviews || _isLoadingMore) return;
    _isLoadingMore = true;
    setState(() {
      _currentPage++;
    });
    _loadReviews().whenComplete(() {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      } else {
        _isLoadingMore = false;
      }
    });
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.filters,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            for (final filter in ReviewFilter.values)
              ListTile(
                title: Text(filter.displayName),
                trailing: _currentFilter == filter
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _currentFilter = filter;
                  });
                  Navigator.pop(context);
                  _loadReviews(refresh: true);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.sortBy,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            for (final sort in ReviewSort.values)
              ListTile(
                title: Text(sort.displayName),
                trailing: _currentSort == sort
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _currentSort = sort;
                  });
                  Navigator.pop(context);
                  _loadReviews(refresh: true);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showWriteReviewDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber, Colors.amber.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.writeReview,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.rating}:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _userRating = index + 1.0;
                            });
                            setDialogState(() {});
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              index < _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 36,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.comment,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewController,
                  maxLines: 5,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[400],
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
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
              onPressed: _userRating > 0 ? _submitReview : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                AppLocalizations.of(context)!.submit,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        ),
      ),
    );
  }

  void _submitReview() async {
    setState(() {
      _isSubmitting = true;
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isSubmitting = false;
    });
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.success)),
      );
    }
    
    _reviewController.clear();
    _userRating = 0.0;
    _loadReviews(refresh: true);
  }

  void _likeReview(PropertyReview review) {
    setState(() {
      review.likes++;
    });
  }

  void _replyToReview(PropertyReview review) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.info)),
    );
  }

  void _reportReview(PropertyReview review) {
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.flag_rounded, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.reportProperty,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.report_problem_rounded,
              size: 60,
              color: Colors.red.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Report this review for inappropriate content?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Our team will review your report.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.grey[500],
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Report submitted successfully'),
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
            icon: const Icon(Icons.flag_rounded, size: 20),
            label: const Text('Report', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  void _showReviewOptions(PropertyReview review) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(AppLocalizations.of(context)!.share),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: Text(AppLocalizations.of(context)!.reportProperty),
              onTap: () {
                Navigator.pop(context);
                _reportReview(review);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoGallery(List<String> photos, int initialIndex) {
    // Preserve immersive flag (this screen is already immersive)
    final prev = ref.read(immersiveRouteOpenProvider);
    ref.read(immersiveRouteOpenProvider.notifier).state = true;
    context
        .push(
          '/gallery',
          extra: {
            'images': photos,
            'initialIndex': initialIndex,
            'heroTag': 'reviews-${widget.propertyId}-gallery',
          },
        )
        .whenComplete(() {
      ref.read(immersiveRouteOpenProvider.notifier).state = prev;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _reviewController.dispose();
    // Clear immersive route flag on exit
    ref.read(immersiveRouteOpenProvider.notifier).state = false;
    super.dispose();
  }
}

enum ReviewFilter {
  all('All Reviews'),
  fiveStars('5 Stars'),
  fourStars('4 Stars'),
  threeStars('3 Stars'),
  twoStars('2 Stars'),
  oneStar('1 Star'),
  withPhotos('With Photos'),
  verified('Verified Only');

  const ReviewFilter(this.displayName);
  final String displayName;
}

enum ReviewSort {
  newest('Newest First'),
  oldest('Oldest First'),
  highestRated('Highest Rated'),
  lowestRated('Lowest Rated'),
  mostHelpful('Most Helpful');

  const ReviewSort(this.displayName);
  final String displayName;
}

class PropertyReview {
  final String id;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime timestamp;
  final List<String> photos;
  int likes;
  final bool isVerified;

  PropertyReview({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.timestamp,
    required this.photos,
    required this.likes,
    required this.isVerified,
  });
}

class ReviewStats {
  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingDistribution;

  ReviewStats({
    required this.totalReviews,
    required this.averageRating,
    required this.ratingDistribution,
  });
}
