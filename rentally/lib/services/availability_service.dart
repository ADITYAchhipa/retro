import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Availability {
  final Set<String> blockedDays; // 'yyyy-MM-dd'
  final Set<String> blockedMonths; // 'yyyy-MM'

  const Availability({this.blockedDays = const {}, this.blockedMonths = const {}});

  Availability copyWith({Set<String>? blockedDays, Set<String>? blockedMonths}) => Availability(
        blockedDays: blockedDays ?? this.blockedDays,
        blockedMonths: blockedMonths ?? this.blockedMonths,
      );

  Map<String, dynamic> toJson() => {
        'blockedDays': blockedDays.toList(),
        'blockedMonths': blockedMonths.toList(),
      };

  factory Availability.fromJson(Map<String, dynamic> json) => Availability(
        blockedDays: Set<String>.from(json['blockedDays'] ?? const <String>[]),
        blockedMonths: Set<String>.from(json['blockedMonths'] ?? const <String>[]),
      );
}

class AvailabilityState {
  final Map<String, Availability> byListingId;
  final bool isLoading;
  final String? error;

  const AvailabilityState({this.byListingId = const {}, this.isLoading = false, this.error});

  AvailabilityState copyWith({Map<String, Availability>? byListingId, bool? isLoading, String? error}) => AvailabilityState(
        byListingId: byListingId ?? this.byListingId,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AvailabilityService extends StateNotifier<AvailabilityState> {
  AvailabilityService() : super(const AvailabilityState()) {
    _load();
  }

  static const _storageKey = 'availability_v1';

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final map = (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, Availability.fromJson(v)));
        state = state.copyWith(byListingId: map, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load availability: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.byListingId.map((k, v) => MapEntry(k, v.toJson())));
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  Availability getForListing(String listingId) {
    return state.byListingId[listingId] ?? const Availability();
  }

  bool isDayBlocked(String listingId, DateTime day) {
    final key = _fmtDay(day);
    return getForListing(listingId).blockedDays.contains(key);
  }

  bool isMonthBlocked(String listingId, DateTime month) {
    final key = _fmtMonth(month);
    return getForListing(listingId).blockedMonths.contains(key);
  }

  Future<void> blockDays(String listingId, DateTime start, DateTime end) async {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    final updated = Set<String>.from(getForListing(listingId).blockedDays);
    for (DateTime d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
      updated.add(_fmtDay(d));
    }
    final current = getForListing(listingId);
    final next = current.copyWith(blockedDays: updated);
    state = state.copyWith(byListingId: {...state.byListingId, listingId: next});
    await _save();
  }

  Future<void> unblockDays(String listingId, DateTime start, DateTime end) async {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    final updated = Set<String>.from(getForListing(listingId).blockedDays);
    for (DateTime d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
      updated.remove(_fmtDay(d));
    }
    final current = getForListing(listingId);
    final next = current.copyWith(blockedDays: updated);
    state = state.copyWith(byListingId: {...state.byListingId, listingId: next});
    await _save();
  }

  Future<void> blockMonth(String listingId, DateTime month) async {
    final key = _fmtMonth(month);
    final updated = Set<String>.from(getForListing(listingId).blockedMonths)..add(key);
    final current = getForListing(listingId);
    final next = current.copyWith(blockedMonths: updated);
    state = state.copyWith(byListingId: {...state.byListingId, listingId: next});
    await _save();
  }

  Future<void> unblockMonth(String listingId, DateTime month) async {
    final key = _fmtMonth(month);
    final updated = Set<String>.from(getForListing(listingId).blockedMonths)..remove(key);
    final current = getForListing(listingId);
    final next = current.copyWith(blockedMonths: updated);
    state = state.copyWith(byListingId: {...state.byListingId, listingId: next});
    await _save();
  }

  static String _fmtDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String _fmtMonth(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
}

final availabilityProvider = StateNotifierProvider<AvailabilityService, AvailabilityState>((ref) {
  return AvailabilityService();
});
