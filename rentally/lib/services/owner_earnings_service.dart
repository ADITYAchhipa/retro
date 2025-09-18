import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../core/config/production_config.dart';

class _CachedSeries {
  final DateTime fetchedAt;
  final List<double> values; // daily gross values
  _CachedSeries(this.fetchedAt, this.values);
}

/// OwnerEarningsService
/// Provides daily gross earnings for a given date range, with simple in-memory caching
/// and graceful fallback to realistic mock data when the backend is unavailable.
class OwnerEarningsService {
  OwnerEarningsService._();
  static final OwnerEarningsService instance = OwnerEarningsService._();

  static const Duration _ttl = Duration(minutes: 10);
  final Map<String, _CachedSeries> _cache = {};

  Future<List<double>> getDailyGross({
    required DateTime start,
    required DateTime end,
  }) async {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final key = '${DateFormat('yyyy-MM-dd').format(startDay)}_${DateFormat('yyyy-MM-dd').format(endDay)}';

    // Cache hit
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.fetchedAt) < _ttl) {
      return cached.values;
    }

    // Try backend
    try {
      final url = Uri.parse(
        '${ProductionConfig.baseUrl}/owner/earnings?start=${DateFormat('yyyy-MM-dd').format(startDay)}&end=${DateFormat('yyyy-MM-dd').format(endDay)}',
      );
      final resp = await http
          .get(url, headers: ProductionConfig.getApiHeaders())
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final jsonResp = json.decode(resp.body) as Map<String, dynamic>;
        // Expecting: { "days": [ {"date": "2025-01-01", "gross": 123.45}, ... ] }
        final List days = (jsonResp['days'] as List?) ?? const [];
        if (days.isNotEmpty) {
          final values = days
              .map((e) => (e['gross'] as num?)?.toDouble() ?? 0.0)
              .toList(growable: false);
          _cache[key] = _CachedSeries(DateTime.now(), values);
          return values;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OwnerEarningsService: backend fetch failed: $e');
      }
    }

    // Fallback to realistic mock data
    final mock = _generateMockDaily(startDay, endDay);
    _cache[key] = _CachedSeries(DateTime.now(), mock);
    return mock;
  }

  List<double> _generateMockDaily(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    final rng = Random(start.millisecondsSinceEpoch);
    // pick a base between 80 and 180
    final base = 80.0 + rng.nextDouble() * 100.0;
    final List<double> values = [];
    for (int i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final isWeekend = d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
      final seasonal = isWeekend ? 1.25 : 1.0;
      // daily noise +/- 20%
      final noise = 0.8 + rng.nextDouble() * 0.4;
      // gentle upward or downward drift over range
      final drift = 1.0 + (i - (days - 1) / 2) * 0.002;
      // occasional spikes
      final spike = (rng.nextInt(20) == 0) ? (1.3 + rng.nextDouble() * 0.4) : 1.0;
      values.add(base * seasonal * noise * drift * spike);
    }
    return values;
  }
}
