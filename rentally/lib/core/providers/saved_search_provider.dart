import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model representing a saved search configuration
class SavedSearch {
  final String id; // unique id
  final String name;
  final String query;
  final bool isVehicleMode;
  final String propertyType; // 'all'|'apartment'|... or 'vehicle'
  final double priceMin;
  final double priceMax;
  final int bedrooms;
  final int bathrooms;
  final bool instantBooking;
  final bool verifiedOnly;
  // Vehicle-specific
  final String vehicleCategory;
  final String vehicleFuel;
  final String vehicleTransmission;
  final int vehicleSeats;
  // Other
  final String sortOption; // relevance|price_asc|price_desc|rating_desc
  final int timestamp; // epoch millis

  const SavedSearch({
    required this.id,
    required this.name,
    required this.query,
    required this.isVehicleMode,
    required this.propertyType,
    required this.priceMin,
    required this.priceMax,
    required this.bedrooms,
    required this.bathrooms,
    required this.instantBooking,
    required this.verifiedOnly,
    required this.vehicleCategory,
    required this.vehicleFuel,
    required this.vehicleTransmission,
    required this.vehicleSeats,
    required this.sortOption,
    required this.timestamp,
  });

  SavedSearch copyWith({
    String? id,
    String? name,
    String? query,
    bool? isVehicleMode,
    String? propertyType,
    double? priceMin,
    double? priceMax,
    int? bedrooms,
    int? bathrooms,
    bool? instantBooking,
    bool? verifiedOnly,
    String? vehicleCategory,
    String? vehicleFuel,
    String? vehicleTransmission,
    int? vehicleSeats,
    String? sortOption,
    int? timestamp,
  }) {
    return SavedSearch(
      id: id ?? this.id,
      name: name ?? this.name,
      query: query ?? this.query,
      isVehicleMode: isVehicleMode ?? this.isVehicleMode,
      propertyType: propertyType ?? this.propertyType,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      instantBooking: instantBooking ?? this.instantBooking,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      vehicleFuel: vehicleFuel ?? this.vehicleFuel,
      vehicleTransmission: vehicleTransmission ?? this.vehicleTransmission,
      vehicleSeats: vehicleSeats ?? this.vehicleSeats,
      sortOption: sortOption ?? this.sortOption,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'query': query,
        'isVehicleMode': isVehicleMode,
        'propertyType': propertyType,
        'priceMin': priceMin,
        'priceMax': priceMax,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'instantBooking': instantBooking,
        'verifiedOnly': verifiedOnly,
        'vehicleCategory': vehicleCategory,
        'vehicleFuel': vehicleFuel,
        'vehicleTransmission': vehicleTransmission,
        'vehicleSeats': vehicleSeats,
        'sortOption': sortOption,
        'timestamp': timestamp,
      };

  factory SavedSearch.fromJson(Map<String, dynamic> json) => SavedSearch(
        id: json['id'] as String,
        name: json['name'] as String,
        query: json['query'] as String,
        isVehicleMode: json['isVehicleMode'] as bool,
        propertyType: json['propertyType'] as String,
        priceMin: (json['priceMin'] as num).toDouble(),
        priceMax: (json['priceMax'] as num).toDouble(),
        bedrooms: json['bedrooms'] as int,
        bathrooms: json['bathrooms'] as int,
        instantBooking: json['instantBooking'] as bool,
        verifiedOnly: json['verifiedOnly'] as bool,
        vehicleCategory: json['vehicleCategory'] as String,
        vehicleFuel: json['vehicleFuel'] as String,
        vehicleTransmission: json['vehicleTransmission'] as String,
        vehicleSeats: json['vehicleSeats'] as int,
        sortOption: json['sortOption'] as String,
        timestamp: json['timestamp'] as int,
      );
}

class SavedSearchesNotifier extends StateNotifier<List<SavedSearch>> {
  static const _prefsKey = 'saved_searches_v1';
  SavedSearchesNotifier() : super(const []);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) {
        state = const [];
        return;
      }
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => SavedSearch.fromJson(e as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = list;
    } catch (e) {
      if (kDebugMode) {
        print('SavedSearches load error: $e');
      }
      state = const [];
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(state.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, raw);
    } catch (e) {
      if (kDebugMode) {
        print('SavedSearches persist error: $e');
      }
    }
  }

  Future<void> add(SavedSearch s) async {
    final filtered = state.where((e) => e.id != s.id).toList();
    filtered.insert(0, s);
    state = filtered.take(50).toList();
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    await _persist();
  }
}

final savedSearchesProvider =
    StateNotifierProvider<SavedSearchesNotifier, List<SavedSearch>>(
        (ref) => SavedSearchesNotifier()..load());
