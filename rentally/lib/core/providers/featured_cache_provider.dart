import 'dart:async';
import 'package:flutter/foundation.dart';

/// Cache entry with data and expiry time
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  Timer? expiryTimer;

  CacheEntry({
    required this.data,
    required this.timestamp,
    this.expiryTimer,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > const Duration(minutes: 5);
  }
}

/// Featured Items Cache Provider
/// Caches featured items (properties/vehicles) by type and category for 5 minutes
class FeaturedCacheProvider with ChangeNotifier {
  // Separate caches for properties and vehicles
  final Map<String, CacheEntry<List<Map<String, dynamic>>>> _propertyCache = {};
  final Map<String, CacheEntry<List<Map<String, dynamic>>>> _vehicleCache = {};
  
  // Track last accessed category for each type
  String? _lastPropertyCategory;
  String? _lastVehicleCategory;
  DateTime? _lastPropertyAccess;
  DateTime? _lastVehicleAccess;

  /// Get cached properties for a category
  List<Map<String, dynamic>>? getPropertyCache(String category) {
    final key = category.toLowerCase();
    final entry = _propertyCache[key];
    
    if (entry != null && !entry.isExpired) {
      _lastPropertyCategory = category;
      _lastPropertyAccess = DateTime.now();
      debugPrint('✅ Cache HIT for property category: $category');
      return entry.data;
    }
    
    // Cache miss or expired
    if (entry != null && entry.isExpired) {
      _propertyCache.remove(key);
      debugPrint('⏰ Cache EXPIRED for property category: $category');
    } else {
      debugPrint('❌ Cache MISS for property category: $category');
    }
    
    return null;
  }

  /// Get cached vehicles for a category
  List<Map<String, dynamic>>? getVehicleCache(String category) {
    final key = category.toLowerCase();
    final entry = _vehicleCache[key];
    
    if (entry != null && !entry.isExpired) {
      _lastVehicleCategory = category;
      _lastVehicleAccess = DateTime.now();
      debugPrint('✅ Cache HIT for vehicle category: $category');
      return entry.data;
    }
    
    // Cache miss or expired
    if (entry != null && entry.isExpired) {
      _vehicleCache.remove(key);
      debugPrint('⏰ Cache EXPIRED for vehicle category: $category');
    } else {
      debugPrint('❌ Cache MISS for vehicle category: $category');
    }
    
    return null;
  }

  /// Set property cache with auto-expiry
  void setPropertyCache(String category, List<Map<String, dynamic>> data) {
    final key = category.toLowerCase();
    
    // Cancel previous timer if exists
    _propertyCache[key]?.expiryTimer?.cancel();
    
    // Create new cache entry with auto-expiry timer
    final timer = Timer(const Duration(minutes: 5), () {
      _propertyCache.remove(key);
      debugPrint('🗑️  Auto-removed expired property cache: $category');
      notifyListeners();
    });
    
    _propertyCache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      expiryTimer: timer,
    );
    
    _lastPropertyCategory = category;
    _lastPropertyAccess = DateTime.now();
    
    debugPrint('💾 Cached ${data.length} properties for category: $category');
    notifyListeners();
  }

  /// Set vehicle cache with auto-expiry
  void setVehicleCache(String category, List<Map<String, dynamic>> data) {
    final key = category.toLowerCase();
    
    // Cancel previous timer if exists
    _vehicleCache[key]?.expiryTimer?.cancel();
    
    // Create new cache entry with auto-expiry timer
    final timer = Timer(const Duration(minutes: 5), () {
      _vehicleCache.remove(key);
      debugPrint('🗑️  Auto-removed expired vehicle cache: $category');
      notifyListeners();
    });
    
    _vehicleCache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      expiryTimer: timer,
    );
    
    _lastVehicleCategory = category;
    _lastVehicleAccess = DateTime.now();
    
    debugPrint('💾 Cached ${data.length} vehicles for category: $category');
    notifyListeners();
  }

  /// Clear all property cache
  void clearPropertyCache() {
    for (var entry in _propertyCache.values) {
      entry.expiryTimer?.cancel();
    }
    _propertyCache.clear();
    _lastPropertyCategory = null;
    _lastPropertyAccess = null;
    debugPrint('🧹 Cleared all property cache');
    notifyListeners();
  }

  /// Clear all vehicle cache
  void clearVehicleCache() {
    for (var entry in _vehicleCache.values) {
      entry.expiryTimer?.cancel();
    }
    _vehicleCache.clear();
    _lastVehicleCategory = null;
    _lastVehicleAccess = null;
    debugPrint('🧹 Cleared all vehicle cache');
    notifyListeners();
  }

  /// Clear specific category cache
  void clearCategoryCache(String type, String category) {
    final key = category.toLowerCase();
    if (type == 'property') {
      _propertyCache[key]?.expiryTimer?.cancel();
      _propertyCache.remove(key);
      debugPrint('🧹 Cleared property cache for: $category');
    } else if (type == 'vehicle') {
      _vehicleCache[key]?.expiryTimer?.cancel();
      _vehicleCache.remove(key);
      debugPrint('🧹 Cleared vehicle cache for: $category');
    }
    notifyListeners();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'propertyCategories': _propertyCache.keys.toList(),
      'vehicleCategories': _vehicleCache.keys.toList(),
      'propertyCacheSize': _propertyCache.length,
      'vehicleCacheSize': _vehicleCache.length,
      'lastPropertyCategory': _lastPropertyCategory,
      'lastVehicleCategory': _lastVehicleCategory,
      'lastPropertyAccess': _lastPropertyAccess,
      'lastVehicleAccess': _lastVehicleAccess,
    };
  }

  @override
  void dispose() {
    // Cancel all timers
    for (var entry in _propertyCache.values) {
      entry.expiryTimer?.cancel();
    }
    for (var entry in _vehicleCache.values) {
      entry.expiryTimer?.cancel();
    }
    super.dispose();
  }
}
