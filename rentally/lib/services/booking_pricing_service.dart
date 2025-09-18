import 'dart:async';
import 'dart:math';

class AvailabilityResult {
  final Set<DateTime> unavailableDates;
  const AvailabilityResult(this.unavailableDates);
}

class PriceQuote {
  final int nights;
  final List<DateTime> nightlyDates;
  final List<double> nightlyRates;
  final double subtotal;
  final double cleaningFee;
  final double serviceFee;
  final double taxes;
  final double total;
  final String currency;

  const PriceQuote({
    required this.nights,
    required this.nightlyDates,
    required this.nightlyRates,
    required this.subtotal,
    required this.cleaningFee,
    required this.serviceFee,
    required this.taxes,
    required this.total,
    this.currency = 'USD',
  });
}

/// Backend-ready service for availability and pricing.
/// Currently uses deterministic mock logic with slight randomness seeded
/// on listingId for reproducible results.
class BookingPricingService {
  Future<AvailabilityResult> getAvailability(
    String listingId,
    DateTime from,
    DateTime to,
  ) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final seed = listingId.hashCode ^ from.millisecondsSinceEpoch ^ to.millisecondsSinceEpoch;
    final rng = Random(seed);
    final Set<DateTime> blocked = {};
    DateTime d = _dateOnly(from);
    final end = _dateOnly(to);
    while (!d.isAfter(end)) {
      // ~12% of days blocked; add occasional 2-day blocks
      if (rng.nextDouble() < 0.12) {
        blocked.add(d);
        if (rng.nextBool()) blocked.add(d.add(const Duration(days: 1)));
      }
      d = d.add(const Duration(days: 1));
    }
    return AvailabilityResult(blocked);
  }

  Future<PriceQuote> quote(
    String listingId,
    DateTime checkIn,
    DateTime checkOut,
    int guests, {
    required double baseNightly,
    String currency = 'USD',
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final nights = max(0, checkOut.difference(checkIn).inDays);
    final List<DateTime> dates = List.generate(nights, (i) => _dateOnly(checkIn.add(Duration(days: i))));
    final List<double> nightlyRates = [];
    for (final d in dates) {
      double rate = baseNightly;
      // Weekend uplift
      if (d.weekday == DateTime.friday || d.weekday == DateTime.saturday) {
        rate *= 1.15;
      }
      // Short-notice discount within 7 days
      if (d.difference(_dateOnly(DateTime.now())).inDays < 7) {
        rate *= 0.9;
      }
      // Guest-based small uplift beyond 2 guests
      if (guests > 2) {
        rate *= 1 + (min(guests - 2, 4) * 0.03); // up to +12%
      }
      nightlyRates.add(double.parse(rate.toStringAsFixed(2)));
    }
    final subtotal = nightlyRates.fold<double>(0, (s, v) => s + v);
    final cleaning = subtotal * 0.08;
    final service = subtotal * 0.12;
    final tax = subtotal * 0.10;
    final total = subtotal + cleaning + service + tax;
    return PriceQuote(
      nights: nights,
      nightlyDates: dates,
      nightlyRates: nightlyRates,
      subtotal: double.parse(subtotal.toStringAsFixed(2)),
      cleaningFee: double.parse(cleaning.toStringAsFixed(2)),
      serviceFee: double.parse(service.toStringAsFixed(2)),
      taxes: double.parse(tax.toStringAsFixed(2)),
      total: double.parse(total.toStringAsFixed(2)),
      currency: currency,
    );
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
