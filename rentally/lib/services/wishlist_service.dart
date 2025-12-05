import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import 'token_storage_service.dart';

class WishlistService {
  static const String _wishlistKey = 'user_wishlist';
  static const String _wishlistTypeKey = 'user_wishlist_types'; // Tracks which IDs are vehicles

  /// Get local wishlist from SharedPreferences (for offline fallback)
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

  /// Get type mapping (id -> isVehicle)
  Future<Map<String, bool>> getTypeMapping() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_wishlistTypeKey);
      if (json != null) {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value as bool));
      }
    } catch (e) {
      debugPrint('Error getting type mapping: $e');
    }
    return {};
  }

  /// Save type mapping
  Future<void> _saveTypeMapping(Map<String, bool> mapping) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_wishlistTypeKey, jsonEncode(mapping));
    } catch (e) {
      debugPrint('Error saving type mapping: $e');
    }
  }

  /// Load favourites from backend API
  Future<Set<String>> loadFromBackend() async {
    try {
      final token = await TokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ [Wishlist] No token available, using local wishlist');
        return await getWishlist();
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/favourite/ids');
      debugPrint('🔄 [Wishlist] Loading favourites from backend...');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          final propertyIds = (data['properties'] as List?)?.cast<String>() ?? [];
          final vehicleIds = (data['vehicles'] as List?)?.cast<String>() ?? [];
          final allIds = <String>{...propertyIds, ...vehicleIds};

          // Update local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(_wishlistKey, allIds.toList());

          // Save type mapping (which IDs are vehicles)
          final typeMap = <String, bool>{};
          for (final id in propertyIds) {
            typeMap[id] = false;
          }
          for (final id in vehicleIds) {
            typeMap[id] = true;
          }
          await _saveTypeMapping(typeMap);

          debugPrint('✅ [Wishlist] Loaded ${allIds.length} favourites from backend (${propertyIds.length} properties, ${vehicleIds.length} vehicles)');
          return allIds;
        }
      }

      debugPrint('⚠️ [Wishlist] Backend returned non-success, using local: ${response.statusCode}');
      return await getWishlist();
    } catch (e) {
      debugPrint('❌ [Wishlist] Error loading from backend: $e');
      return await getWishlist();
    }
  }

  /// Toggle wishlist via backend API
  Future<bool> toggleWishlistOnBackend(String listingId, {required bool isVehicle}) async {
    try {
      final token = await TokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [Wishlist] No token, falling back to local toggle');
        return await toggleWishlist(listingId, isVehicle: isVehicle);
      }

      final type = isVehicle ? 'vehicle' : 'property';
      final uri = Uri.parse('${ApiConstants.baseUrl}/favourite/toggle/$type/$listingId');
      debugPrint('🔄 [Wishlist] Toggling $type $listingId on backend...');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final isFavourite = body['data']?['isFavourite'] as bool? ?? false;
          debugPrint('✅ [Wishlist] Toggle successful: isFavourite=$isFavourite');

          // Update local storage to match
          final prefs = await SharedPreferences.getInstance();
          final wishlist = await getWishlist();
          final typeMap = await getTypeMapping();

          if (isFavourite) {
            wishlist.add(listingId);
            typeMap[listingId] = isVehicle;
          } else {
            wishlist.remove(listingId);
            typeMap.remove(listingId);
          }

          await prefs.setStringList(_wishlistKey, wishlist.toList());
          await _saveTypeMapping(typeMap);

          return true;
        }
      }

      debugPrint('⚠️ [Wishlist] Backend toggle failed: ${response.statusCode}');
      // Fall back to local-only toggle
      return await toggleWishlist(listingId, isVehicle: isVehicle);
    } catch (e) {
      debugPrint('❌ [Wishlist] Error toggling on backend: $e');
      // Fall back to local-only toggle
      return await toggleWishlist(listingId, isVehicle: isVehicle);
    }
  }

  /// Local-only toggle (for offline/fallback)
  Future<bool> toggleWishlist(String listingId, {bool isVehicle = false}) async {
    final wishlist = await getWishlist();
    if (wishlist.contains(listingId)) {
      return await removeFromWishlist(listingId);
    } else {
      return await addToWishlist(listingId, isVehicle: isVehicle);
    }
  }

  Future<bool> addToWishlist(String listingId, {bool isVehicle = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlist = await getWishlist();
      wishlist.add(listingId);
      
      // Also update type mapping
      final typeMap = await getTypeMapping();
      typeMap[listingId] = isVehicle;
      await _saveTypeMapping(typeMap);
      
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
      
      // Also update type mapping
      final typeMap = await getTypeMapping();
      typeMap.remove(listingId);
      await _saveTypeMapping(typeMap);
      
      return await prefs.setStringList(_wishlistKey, wishlist.toList());
    } catch (e) {
      debugPrint('Error removing from wishlist: $e');
      return false;
    }
  }

  Future<bool> isInWishlist(String listingId) async {
    final wishlist = await getWishlist();
    return wishlist.contains(listingId);
  }

  Future<bool> clearWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_wishlistTypeKey);
      return await prefs.remove(_wishlistKey);
    } catch (e) {
      debugPrint('Error clearing wishlist: $e');
      return false;
    }
  }

  /// Fetch sorted favourites with full details from backend
  /// Returns list of items with complete property/vehicle information
  Future<List<Map<String, dynamic>>> getSortedFavourites({
    String type = 'all', // all, properties, vehicles
    String sort = 'date', // date, priceAsc, priceDesc, rating
  }) async {
    try {
      final token = await TokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ [Wishlist] No token available for sorted fetch');
        return [];
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/favourite/sorted?type=$type&sort=$sort');
      debugPrint('🔄 [Wishlist] Fetching sorted favourites: type=$type, sort=$sort');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          // Backend returns: { success: true, data: { results: [...], type, sort, total } }
          final dataObj = body['data'];
          final resultsList = dataObj['results'];
          
          debugPrint('🔍 [Wishlist] Raw results type: ${resultsList.runtimeType}');
          
          if (resultsList is! List) {
            debugPrint('❌ [Wishlist] Expected List but got ${resultsList.runtimeType}');
            return [];
          }
          
          final results = <Map<String, dynamic>>[];
          for (int i = 0; i < resultsList.length; i++) {
            final item = resultsList[i];
            if (item is Map<String, dynamic>) {
              results.add(item);
            } else if (item is Map) {
              // Convert to Map<String, dynamic>
              results.add(Map<String, dynamic>.from(item));
            } else {
              debugPrint('⚠️ [Wishlist] Skipping item $i - unexpected type: ${item.runtimeType}');
            }
          }
          
          debugPrint('✅ [Wishlist] Loaded ${results.length} sorted favourites');
          return results;
        }
      }

      debugPrint('⚠️ [Wishlist] Backend returned non-success: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ [Wishlist] Error fetching sorted favourites: $e');
      return [];
    }
  }

  /// Check if a listing is a vehicle
  Future<bool> isVehicle(String listingId) async {
    final typeMap = await getTypeMapping();
    return typeMap[listingId] ?? false;
  }
}

// Provider for WishlistService
final wishlistServiceProvider = Provider<WishlistService>((ref) {
  return WishlistService();
});

// State for managing wishlist data
class WishlistState {
  final Set<String> wishlistIds;
  final Map<String, bool> typeMapping; // id -> isVehicle
  final bool isLoading;
  final String? error;

  const WishlistState({
    this.wishlistIds = const {},
    this.typeMapping = const {},
    this.isLoading = false,
    this.error,
  });

  WishlistState copyWith({
    Set<String>? wishlistIds,
    Map<String, bool>? typeMapping,
    bool? isLoading,
    String? error,
  }) {
    return WishlistState(
      wishlistIds: wishlistIds ?? this.wishlistIds,
      typeMapping: typeMapping ?? this.typeMapping,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isInWishlist(String listingId) {
    return wishlistIds.contains(listingId);
  }

  bool isVehicle(String listingId) {
    return typeMapping[listingId] ?? false;
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
      // Try to load from backend first (will fall back to local if no token)
      final wishlist = await _wishlistService.loadFromBackend();
      final typeMap = await _wishlistService.getTypeMapping();
      
      state = state.copyWith(
        wishlistIds: wishlist,
        typeMapping: typeMap,
        isLoading: false,
      );
      debugPrint('✅ [Wishlist] State loaded with ${wishlist.length} items');
    } catch (e) {
      debugPrint('❌ [Wishlist] Error loading: $e');
      // Fall back to local
      final wishlist = await _wishlistService.getWishlist();
      final typeMap = await _wishlistService.getTypeMapping();
      state = state.copyWith(
        wishlistIds: wishlist,
        typeMapping: typeMap,
        isLoading: false,
        error: 'Failed to sync with server',
      );
    }
  }

  /// Reload wishlist from backend (call after login)
  Future<void> reloadFromBackend() async {
    await _loadWishlist();
  }

  /// Toggle wishlist with backend sync
  Future<void> toggleWishlist(String listingId, {bool? isVehicle}) async {
    final wasInWishlist = state.isInWishlist(listingId);
    
    // Determine if this is a vehicle (use provided value or check stored type)
    final itemIsVehicle = isVehicle ?? state.isVehicle(listingId);
    
    // Optimistically update UI
    final updatedWishlist = Set<String>.from(state.wishlistIds);
    final updatedTypeMap = Map<String, bool>.from(state.typeMapping);
    
    if (wasInWishlist) {
      updatedWishlist.remove(listingId);
      updatedTypeMap.remove(listingId);
    } else {
      updatedWishlist.add(listingId);
      updatedTypeMap[listingId] = itemIsVehicle;
    }
    
    state = state.copyWith(
      wishlistIds: updatedWishlist, 
      typeMapping: updatedTypeMap,
      error: null,
    );

    try {
      // Sync with backend
      final success = await _wishlistService.toggleWishlistOnBackend(
        listingId,
        isVehicle: itemIsVehicle,
      );
      
      if (!success) {
        // Revert on failure
        final revertedWishlist = Set<String>.from(state.wishlistIds);
        final revertedTypeMap = Map<String, bool>.from(state.typeMapping);
        
        if (wasInWishlist) {
          revertedWishlist.add(listingId);
          revertedTypeMap[listingId] = itemIsVehicle;
        } else {
          revertedWishlist.remove(listingId);
          revertedTypeMap.remove(listingId);
        }
        state = state.copyWith(
          wishlistIds: revertedWishlist,
          typeMapping: revertedTypeMap,
          error: 'Failed to update wishlist',
        );
      }
    } catch (e) {
      // Revert on error
      final revertedWishlist = Set<String>.from(state.wishlistIds);
      final revertedTypeMap = Map<String, bool>.from(state.typeMapping);
      
      if (wasInWishlist) {
        revertedWishlist.add(listingId);
        revertedTypeMap[listingId] = itemIsVehicle;
      } else {
        revertedWishlist.remove(listingId);
        revertedTypeMap.remove(listingId);
      }
      state = state.copyWith(
        wishlistIds: revertedWishlist,
        typeMapping: revertedTypeMap,
        error: 'Failed to update wishlist: $e',
      );
    }
  }

  Future<void> addToWishlist(String listingId, {bool isVehicle = false}) async {
    if (state.isInWishlist(listingId)) return;
    await toggleWishlist(listingId, isVehicle: isVehicle);
  }

  Future<void> removeFromWishlist(String listingId) async {
    if (!state.isInWishlist(listingId)) return;
    await toggleWishlist(listingId);
  }

  Future<void> clearWishlist() async {
    final originalWishlist = Set<String>.from(state.wishlistIds);
    final originalTypeMap = Map<String, bool>.from(state.typeMapping);
    
    // Optimistically clear
    state = state.copyWith(
      wishlistIds: <String>{}, 
      typeMapping: <String, bool>{},
      error: null,
    );

    try {
      final success = await _wishlistService.clearWishlist();
      if (!success) {
        // Revert on failure
        state = state.copyWith(
          wishlistIds: originalWishlist,
          typeMapping: originalTypeMap,
          error: 'Failed to clear wishlist',
        );
      }
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        wishlistIds: originalWishlist,
        typeMapping: originalTypeMap,
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

