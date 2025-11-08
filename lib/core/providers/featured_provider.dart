import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/listing.dart';
import '../../services/featured_cache_service.dart';

/// Enum for featured category selection
enum FeaturedCategory {
  property,
  vehicle,
}

/// State class for featured items
class FeaturedState {
  final List<Listing> items;
  final bool isLoading;
  final String? error;
  final FeaturedCategory category;

  const FeaturedState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.category = FeaturedCategory.property,
  });

  FeaturedState copyWith({
    List<Listing>? items,
    bool? isLoading,
    String? error,
    FeaturedCategory? category,
  }) {
    return FeaturedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      category: category ?? this.category,
    );
  }
}

/// Provider for featured items with caching
class FeaturedNotifier extends StateNotifier<FeaturedState> {
  final FeaturedCacheService _cacheService = FeaturedCacheService();

  FeaturedNotifier() : super(const FeaturedState()) {
    // Load properties by default on initialization
    loadFeaturedItems(FeaturedCategory.property);
  }

  /// Load featured items for a category
  Future<void> loadFeaturedItems(FeaturedCategory category) async {
    // If switching to the same category and data exists, no need to reload
    if (state.category == category && state.items.isNotEmpty && !state.isLoading) {
      return;
    }

    // Update category and set loading
    state = state.copyWith(
      category: category,
      isLoading: true,
      error: null,
    );

    try {
      List<Listing> items;

      if (category == FeaturedCategory.property) {
        items = await _cacheService.getFeaturedProperties();
      } else {
        items = await _cacheService.getFeaturedVehicles();
      }

      state = state.copyWith(
        items: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Switch category (will use cache if available)
  Future<void> switchCategory(FeaturedCategory category) async {
    if (state.category == category) return;
    await loadFeaturedItems(category);
  }

  /// Refresh current category (force reload)
  Future<void> refresh() async {
    if (state.category == FeaturedCategory.property) {
      _cacheService.clearPropertyCache();
    } else {
      _cacheService.clearVehicleCache();
    }
    await loadFeaturedItems(state.category);
  }

  /// Clear all cache and reload
  Future<void> clearCacheAndReload() async {
    _cacheService.clearCache();
    await loadFeaturedItems(state.category);
  }
}

/// Provider for featured items
final featuredProvider = StateNotifierProvider<FeaturedNotifier, FeaturedState>((ref) {
  return FeaturedNotifier();
});

/// Convenience provider for current category
final currentFeaturedCategoryProvider = Provider<FeaturedCategory>((ref) {
  return ref.watch(featuredProvider).category;
});

/// Convenience provider for featured items list
final featuredItemsProvider = Provider<List<Listing>>((ref) {
  return ref.watch(featuredProvider).items;
});

/// Convenience provider for loading state
final featuredLoadingProvider = Provider<bool>((ref) {
  return ref.watch(featuredProvider).isLoading;
});
