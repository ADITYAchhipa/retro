import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to track user's viewing history of properties and vehicles
class ViewHistoryService with ChangeNotifier {
  static const String _viewHistoryKey = 'user_view_history';
  static const int _maxHistoryItems = 50; // Keep last 50 viewed items
  
  List<ViewHistoryItem> _viewHistory = [];
  
  List<ViewHistoryItem> get viewHistory => List.unmodifiable(_viewHistory);
  
  /// Get recently viewed items sorted by most recent first
  List<ViewHistoryItem> get recentlyViewed {
    final sorted = List<ViewHistoryItem>.from(_viewHistory);
    sorted.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    return sorted;
  }
  
  /// Initialize service and load stored history
  Future<void> initialize() async {
    await _loadViewHistory();
  }
  
  /// Track a property or vehicle view
  Future<void> trackView({
    required String id,
    required String title,
    required String type, // 'property' or 'vehicle'
    String? imageUrl,
    double? price,
    String? location,
  }) async {
    // Remove existing entry if it exists (to update timestamp)
    _viewHistory.removeWhere((item) => item.id == id);
    
    // Add new entry at the beginning
    final newItem = ViewHistoryItem(
      id: id,
      title: title,
      type: type,
      imageUrl: imageUrl,
      price: price,
      location: location,
      viewedAt: DateTime.now(),
    );
    
    _viewHistory.insert(0, newItem);
    
    // Keep only the most recent items
    if (_viewHistory.length > _maxHistoryItems) {
      _viewHistory = _viewHistory.take(_maxHistoryItems).toList();
    }
    
    await _saveViewHistory();
    notifyListeners();
  }
  
  /// Clear all view history
  Future<void> clearHistory() async {
    _viewHistory.clear();
    await _saveViewHistory();
    notifyListeners();
  }
  
  /// Remove a specific item from history
  Future<void> removeFromHistory(String id) async {
    _viewHistory.removeWhere((item) => item.id == id);
    await _saveViewHistory();
    notifyListeners();
  }
  
  /// Check if an item has been viewed
  bool hasViewed(String id) {
    return _viewHistory.any((item) => item.id == id);
  }
  
  /// Get view count for analytics
  int get totalViewCount => _viewHistory.length;
  
  /// Get recently viewed items by type
  List<ViewHistoryItem> getRecentlyViewedByType(String type) {
    return recentlyViewed.where((item) => item.type == type).toList();
  }
  
  /// Load view history from storage
  Future<void> _loadViewHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_viewHistoryKey);
      
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _viewHistory = historyList
            .map((item) => ViewHistoryItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading view history: $e');
      _viewHistory = [];
    }
  }
  
  /// Save view history to storage
  Future<void> _saveViewHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(
        _viewHistory.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_viewHistoryKey, historyJson);
    } catch (e) {
      debugPrint('Error saving view history: $e');
    }
  }
}

/// Model for a view history item
class ViewHistoryItem {
  final String id;
  final String title;
  final String type; // 'property' or 'vehicle'
  final String? imageUrl;
  final double? price;
  final String? location;
  final DateTime viewedAt;
  
  const ViewHistoryItem({
    required this.id,
    required this.title,
    required this.type,
    this.imageUrl,
    this.price,
    this.location,
    required this.viewedAt,
  });
  
  /// Create from JSON
  factory ViewHistoryItem.fromJson(Map<String, dynamic> json) {
    return ViewHistoryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      imageUrl: json['imageUrl'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      location: json['location'] as String?,
      viewedAt: DateTime.parse(json['viewedAt'] as String),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'imageUrl': imageUrl,
      'price': price,
      'location': location,
      'viewedAt': viewedAt.toIso8601String(),
    };
  }
  
  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(viewedAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
