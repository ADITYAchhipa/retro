import '../database/models/property_model.dart';
import '../database/models/vehicle_model.dart';
import 'currency_formatter.dart';

class PriceUnitResult {
  final double amount; // final displayed amount (discounted if discountPercent > 0)
  final String unit; // 'hour' | 'day' | 'night' | 'month'
  final double? originalAmount; // original amount before discount
  final int? discountPercent; // normalized integer percent
  const PriceUnitResult(this.amount, this.unit, {this.originalAmount, this.discountPercent});
}

/// Helper to determine display price and unit across properties and vehicles
class PriceUnitHelper {
  /// For properties: prefer explicit monthly price; otherwise derive monthly from day/night * 30
  static PriceUnitResult forProperty(PropertyModel p) {
    // Respect owner choice: if only monthly is provided, show per month.
    final bool monthlyProvided = (p.pricePerMonth != null && (p.pricePerMonth ?? 0) > 0);
    final bool dailyProvided = p.pricePerDay > 0;
    final bool nightlyProvided = p.pricePerNight > 0;

    if (monthlyProvided && !dailyProvided && !nightlyProvided) {
      return _applyDiscount(p.pricePerMonth!, 'month', p.discountPercent);
    }
    // Otherwise, show daily if provided, else nightly if provided.
    if (dailyProvided) {
      return _applyDiscount(p.pricePerDay, 'day', p.discountPercent);
    }
    if (nightlyProvided) {
      return _applyDiscount(p.pricePerNight, 'night', p.discountPercent);
    }
    // Fallback to 0 per month when no price is present.
    return const PriceUnitResult(0, 'month');
  }

  /// For vehicles: prefer hourly if provided; otherwise daily
  static PriceUnitResult forVehicle(VehicleModel v) {
    final bool hasHourly = (v.pricePerHour != null && (v.pricePerHour ?? 0) > 0);
    if (hasHourly) {
      return _applyDiscount(v.pricePerHour!, 'hour', v.discountPercent);
    }
    return _applyDiscount(v.pricePerDay, 'day', v.discountPercent);
  }

  /// Convenience: format with CurrencyFormatter
  static String format(PriceUnitResult res, {String? currency, String? locale}) {
    return CurrencyFormatter.formatPricePerUnit(res.amount, res.unit, currency: currency, locale: locale);
  }

  static String? formatOriginal(PriceUnitResult res, {String? currency, String? locale}) {
    if (res.originalAmount == null) return null;
    return CurrencyFormatter.formatPricePerUnit(res.originalAmount!, res.unit, currency: currency, locale: locale);
  }

  static PriceUnitResult _applyDiscount(double amount, String unit, double? percent) {
    final p = (percent ?? 0).clamp(0, 100).toDouble();
    if (p <= 0) return PriceUnitResult(amount, unit);
    final discounted = (amount * (1 - p / 100));
    return PriceUnitResult(discounted, unit, originalAmount: amount, discountPercent: p.round());
  }
}
