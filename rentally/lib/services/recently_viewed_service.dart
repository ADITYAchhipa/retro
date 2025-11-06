import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RecentlyViewedItem {
  final String id;
  final String title;
  final String location;
  final double price;
  final String? imageUrl;
  final DateTime viewedAt;

  const RecentlyViewedItem({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.viewedAt,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'location': location,
        'price': price,
        'imageUrl': imageUrl,
        'viewedAt': viewedAt.millisecondsSinceEpoch,
      };

  static RecentlyViewedItem fromJson(Map<String, dynamic> json) => RecentlyViewedItem(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        location: (json['location'] ?? '').toString(),
        price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
        imageUrl: (json['imageUrl'] as String?),
        viewedAt: DateTime.fromMillisecondsSinceEpoch(json['viewedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      );
}

class RecentlyViewedService {
  static const String _storageKey = 'recently_viewed_v1';
  static const int _maxItems = 10;

  static Future<List<RecentlyViewedItem>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final List<RecentlyViewedItem> out = [];
    for (final s in raw) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        out.add(RecentlyViewedItem.fromJson(map));
      } catch (_) {}
    }
    // sort by viewedAt desc just in case
    out.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    return out;
  }

  static Future<void> addFromFields({
    required String id,
    required String title,
    required String location,
    required double price,
    String? imageUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final newItem = RecentlyViewedItem(
      id: id,
      title: title,
      location: location,
      price: price,
      imageUrl: imageUrl,
      viewedAt: now,
    );
    final items = await list();
    // remove if exists
    final filtered = items.where((e) => e.id != id).toList();
    filtered.insert(0, newItem);
    if (filtered.length > _maxItems) {
      filtered.removeRange(_maxItems, filtered.length);
    }
    final strings = filtered.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, strings);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
