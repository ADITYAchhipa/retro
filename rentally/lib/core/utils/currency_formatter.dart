import 'package:intl/intl.dart';

/// Currency formatter utility for locale-aware price formatting
class CurrencyFormatter {
  static final Map<String, NumberFormat> _formatters = {};
  static String _defaultCurrency = 'USD';
  
  /// Set the app-wide default currency (affects calls that don't pass currency explicitly)
  static void setDefaultCurrency(String code) {
    _defaultCurrency = code.toUpperCase();
    _formatters.clear(); // reset cached formatters when currency changes
  }

  /// Get the app-wide default currency code
  static String get defaultCurrency => _defaultCurrency;

  /// Format price with currency symbol and locale
  static String formatPrice(double amount, {String? currency, String? locale}) {
    final c = (currency ?? _defaultCurrency).toUpperCase();
    final key = '${c}_${locale ?? 'en_US'}';
    
    if (!_formatters.containsKey(key)) {
      _formatters[key] = NumberFormat.currency(
        locale: locale ?? 'en_US',
        symbol: currencySymbolFor(c),
        decimalDigits: _getDecimalDigits(c),
      );
    }
    
    return _formatters[key]!.format(amount);
  }
  
  /// Format price per unit with standardized unit labels
  /// Supported units: hour/day/night/month (+ common aliases)
  static String formatPricePerUnit(double amount, String unit, {String? currency, String? locale}) {
    final formattedAmount = formatPrice(amount, currency: currency, locale: locale);
    final u = unit.trim().toLowerCase();
    String normalized;
    switch (u) {
      case 'h':
      case 'hr':
      case 'hour':
      case 'per_hour':
        normalized = 'hour';
        break;
      case 'd':
      case 'day':
      case 'per_day':
      case 'daily':
        normalized = 'day';
        break;
      case 'night':
      case 'per_night':
        normalized = 'night';
        break;
      case 'm':
      case 'mo':
      case 'month':
      case 'per_month':
      case 'monthly':
        normalized = 'month';
        break;
      case 'lease':
      case 'per_lease':
        // Map legacy 'lease' unit to monthly to remove lease-specific labeling
        normalized = 'month';
        break;
      default:
        normalized = u; // fallback to provided unit
    }
    return '$formattedAmount/$normalized';
  }
  
  /// Get currency symbol for common currencies
  static String currencySymbolFor(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'BRL':
        return 'R\$';
      case 'MXN':
        return '\u0024';
      default:
        return currency;
    }
  }
  
  /// Get human-readable currency name for common currencies
  static String currencyNameFor(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return 'United States Dollar';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'British Pound';
      case 'INR':
        return 'Indian Rupee';
      case 'JPY':
        return 'Japanese Yen';
      case 'CAD':
        return 'Canadian Dollar';
      case 'AUD':
        return 'Australian Dollar';
      case 'BRL':
        return 'Brazilian Real';
      case 'MXN':
        return 'Mexican Peso';
      default:
        return currency.toUpperCase();
    }
  }
  
  /// Get decimal digits for currency (some currencies don't use decimals)
  static int _getDecimalDigits(String currency) {
    switch (currency.toUpperCase()) {
      case 'JPY':
      case 'KRW':
        return 0;
      default:
        return 2;
    }
  }
  
  /// Format compact price (e.g., 1.2K, 1.5M)
  static String formatCompactPrice(double amount, {String? currency, String? locale}) {
    final formatter = NumberFormat.compactCurrency(
      locale: locale ?? 'en_US',
      symbol: currencySymbolFor((currency ?? _defaultCurrency)),
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }
}
