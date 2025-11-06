import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TerminationSchedule {
  final String listingId;
  final DateTime terminateAt; // local time end-of-day or chosen time
  final String? reason;

  const TerminationSchedule({
    required this.listingId,
    required this.terminateAt,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'listingId': listingId,
        'terminateAt': terminateAt.millisecondsSinceEpoch,
        'reason': reason,
      };

  static TerminationSchedule fromJson(Map<String, dynamic> json) => TerminationSchedule(
        listingId: json['listingId'] as String,
        terminateAt: DateTime.fromMillisecondsSinceEpoch(json['terminateAt'] as int),
        reason: json['reason'] as String?,
      );
}

/// Stores scheduled monthly-stay terminations per listing in SharedPreferences.
/// Key format: JSON list of encoded schedules to support multiple listings.
class TerminationService {
  static const String _storageKey = 'stay_terminations_v1';

  static Future<List<TerminationSchedule>> _loadAll(SharedPreferences prefs) async {
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final List<TerminationSchedule> out = [];
    for (final s in raw) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        out.add(TerminationSchedule.fromJson(map));
      } catch (_) {}
    }
    return out;
  }

  static Future<void> _saveAll(SharedPreferences prefs, List<TerminationSchedule> list) async {
    final strings = list.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, strings);
  }

  static Future<Map<String, TerminationSchedule>> listAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _loadAll(prefs);
    final Map<String, TerminationSchedule> map = {};
    for (final t in list) {
      map[t.listingId] = t;
    }
    return map;
  }

  static Future<TerminationSchedule?> get(String listingId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _loadAll(prefs);
    for (final t in list) {
      if (t.listingId == listingId) return t;
    }
    return null;
  }

  /// Schedule termination on a specific local date/time.
  /// Caller must enforce a 1-month notice period.
  static Future<void> schedule({
    required String listingId,
    required DateTime terminateAt,
    String? reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _loadAll(prefs);
    // Replace any existing schedule for this listing
    final filtered = list.where((e) => e.listingId != listingId).toList();
    filtered.add(TerminationSchedule(listingId: listingId, terminateAt: terminateAt, reason: reason));
    await _saveAll(prefs, filtered);
  }

  static Future<void> cancel(String listingId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _loadAll(prefs);
    final filtered = list.where((e) => e.listingId != listingId).toList();
    await _saveAll(prefs, filtered);
  }
}
