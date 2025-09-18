import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistService {
  static const String _wishlistKey = 'user_wishlist';

  Future<Set<String>> getWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getStringList(_wishlistKey) ?? [];
      return Set<String>.from(wishlistJson);
    } catch (e) {
      debugPrint('Error getting wishlist: $e');
      return <String>{};
    }
  }

  Future<bool> addToWishlist(String listingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlist = await getWishlist();
      wishlist.add(listingId);
      return await prefs.setStringList(_wishlistKey, wishlist.toList());
    } catch (e) {
      debugPrint('Error adding to wishlist: $e');
      return false;
    }
  }

  Future<bool> removeFromWishlist(String listingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlist = await getWishlist();
      wishlist.remove(listingId);
      return await prefs.setStringList(_wishlistKey, wishlist.toList());
    } catch (e) {
      debugPrint('Error removing from wishlist: $e');
      return false;
    }
  }

  Future<bool> toggleWishlist(String listingId) async {
    final wishlist = await getWishlist();
    if (wishlist.contains(listingId)) {
      return await removeFromWishlist(listingId);
    } else {
      return await addToWishlist(listingId);
    }
  }

  Future<bool> isInWishlist(String listingId) async {
    final wishlist = await getWishlist();
    return wishlist.contains(listingId);
  }

  Future<bool> clearWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_wishlistKey);
    } catch (e) {
      debugPrint('Error clearing wishlist: $e');
      return false;
    }
  }
}

// Provider for WishlistService
final wishlistServiceProvider = Provider<WishlistService>((ref) {
  return WishlistService();
});

// State for managing wishlist data
class WishlistState {
  final Set<String> wishlistIds;
  final bool isLoading;
  final String? error;

  const WishlistState({
    this.wishlistIds = const {},
    this.isLoading = false,
    this.error,
  });

  WishlistState copyWith({
    Set<String>? wishlistIds,
    bool? isLoading,
    String? error,
  }) {
    return WishlistState(
      wishlistIds: wishlistIds ?? this.wishlistIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isInWishlist(String listingId) {
    return wishlistIds.contains(listingId);
  }
}

// StateNotifier for managing wishlist operations
class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistService _wishlistService;

  WishlistNotifier(this._wishlistService) : super(const WishlistState()) {
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final wishlist = await _wishlistService.getWishlist();
      state = state.copyWith(
        wishlistIds: wishlist,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load wishlist: $e',
      );
    }
  }

  Future<void> toggleWishlist(String listingId) async {
    final wasInWishlist = state.isInWishlist(listingId);
    
    // Optimistically update UI
    final updatedWishlist = Set<String>.from(state.wishlistIds);
    if (wasInWishlist) {
      updatedWishlist.remove(listingId);
    } else {
      updatedWishlist.add(listingId);
    }
    
    state = state.copyWith(wishlistIds: updatedWishlist, error: null);

    try {
      final success = await _wishlistService.toggleWishlist(listingId);
      if (!success) {
        // Revert on failure
        final revertedWishlist = Set<String>.from(state.wishlistIds);
        if (wasInWishlist) {
          revertedWishlist.add(listingId);
        } else {
          revertedWishlist.remove(listingId);
        }
        state = state.copyWith(
          wishlistIds: revertedWishlist,
          error: 'Failed to update wishlist',
        );
      }
    } catch (e) {
      // Revert on error
      final revertedWishlist = Set<String>.from(state.wishlistIds);
      if (wasInWishlist) {
        revertedWishlist.add(listingId);
      } else {
        revertedWishlist.remove(listingId);
      }
      state = state.copyWith(
        wishlistIds: revertedWishlist,
        error: 'Failed to update wishlist: $e',
      );
    }
  }

  Future<void> addToWishlist(String listingId) async {
    if (state.isInWishlist(listingId)) return;

    // Optimistically update UI
    final updatedWishlist = Set<String>.from(state.wishlistIds);
    updatedWishlist.add(listingId);
    state = state.copyWith(wishlistIds: updatedWishlist, error: null);

    try {
      final success = await _wishlistService.addToWishlist(listingId);
      if (!success) {
        // Revert on failure
        final revertedWishlist = Set<String>.from(state.wishlistIds);
        revertedWishlist.remove(listingId);
        state = state.copyWith(
          wishlistIds: revertedWishlist,
          error: 'Failed to add to wishlist',
        );
      }
    } catch (e) {
      // Revert on error
      final revertedWishlist = Set<String>.from(state.wishlistIds);
      revertedWishlist.remove(listingId);
      state = state.copyWith(
        wishlistIds: revertedWishlist,
        error: 'Failed to add to wishlist: $e',
      );
    }
  }

  Future<void> removeFromWishlist(String listingId) async {
    if (!state.isInWishlist(listingId)) return;

    // Optimistically update UI
    final updatedWishlist = Set<String>.from(state.wishlistIds);
    updatedWishlist.remove(listingId);
    state = state.copyWith(wishlistIds: updatedWishlist, error: null);

    try {
      final success = await _wishlistService.removeFromWishlist(listingId);
      if (!success) {
        // Revert on failure
        final revertedWishlist = Set<String>.from(state.wishlistIds);
        revertedWishlist.add(listingId);
        state = state.copyWith(
          wishlistIds: revertedWishlist,
          error: 'Failed to remove from wishlist',
        );
      }
    } catch (e) {
      // Revert on error
      final revertedWishlist = Set<String>.from(state.wishlistIds);
      revertedWishlist.add(listingId);
      state = state.copyWith(
        wishlistIds: revertedWishlist,
        error: 'Failed to remove from wishlist: $e',
      );
    }
  }

  Future<void> clearWishlist() async {
    final originalWishlist = Set<String>.from(state.wishlistIds);
    
    // Optimistically clear
    state = state.copyWith(wishlistIds: <String>{}, error: null);

    try {
      final success = await _wishlistService.clearWishlist();
      if (!success) {
        // Revert on failure
        state = state.copyWith(
          wishlistIds: originalWishlist,
          error: 'Failed to clear wishlist',
        );
      }
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        wishlistIds: originalWishlist,
        error: 'Failed to clear wishlist: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for WishlistNotifier
final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  final wishlistService = ref.read(wishlistServiceProvider);
  return WishlistNotifier(wishlistService);
});
