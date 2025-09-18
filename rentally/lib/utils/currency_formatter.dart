import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_preferences_service.dart';

/// Utility class for formatting prices with currency symbols
class CurrencyFormatter {
  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'INR': '₹',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'BRL': 'R\$',
    'MXN': 'MX\$',
  };

  static const Map<String, double> _exchangeRates = {
    'USD': 1.0,      // Base currency
    'EUR': 0.85,     // 1 USD = 0.85 EUR
    'GBP': 0.73,     // 1 USD = 0.73 GBP
    'JPY': 110.0,    // 1 USD = 110 JPY
    'INR': 83.0,     // 1 USD = 83 INR
    'CAD': 1.25,     // 1 USD = 1.25 CAD
    'AUD': 1.35,     // 1 USD = 1.35 AUD
    'BRL': 5.2,      // 1 USD = 5.2 BRL
    'MXN': 18.0,     // 1 USD = 18 MXN
  };

  /// Formats a price with the appropriate currency symbol
  static String formatPrice(double priceInUSD, String currency) {
    final symbol = _currencySymbols[currency] ?? '\$';
    final rate = _exchangeRates[currency] ?? 1.0;
    final convertedPrice = priceInUSD * rate;
    
    // Format based on currency
    if (currency == 'JPY') {
      return '$symbol${convertedPrice.toStringAsFixed(0)}';
    } else {
      return '$symbol${convertedPrice.toStringAsFixed(0)}';
    }
  }

  /// Formats a price with currency and period (e.g., /night, /day, /month)
  static String formatPriceWithPeriod(double priceInUSD, String currency, String period) {
    return '${formatPrice(priceInUSD, currency)}/$period';
  }

  /// Gets currency symbol for a given currency code
  static String getCurrencySymbol(String currency) {
    return _currencySymbols[currency] ?? '\$';
  }

  /// Converts USD price to target currency
  static double convertPrice(double priceInUSD, String targetCurrency) {
    final rate = _exchangeRates[targetCurrency] ?? 1.0;
    return priceInUSD * rate;
  }
}

/// Provider-aware currency formatter widget
class CurrencyText extends ConsumerWidget {
  final double priceInUSD;
  final String? period;
  final TextStyle? style;

  const CurrencyText({
    super.key,
    required this.priceInUSD,
    this.period,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currentCurrencyProvider);
    
    final formattedPrice = period != null
        ? CurrencyFormatter.formatPriceWithPeriod(priceInUSD, currency, period!)
        : CurrencyFormatter.formatPrice(priceInUSD, currency);
    
    return Text(formattedPrice, style: style);
  }
}
