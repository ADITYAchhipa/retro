import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/payment_method.dart';

class AppPaymentRouter {
  AppPaymentRouter._();
  static final AppPaymentRouter instance = AppPaymentRouter._();

  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required PaymentMethod method,
    Map<String, dynamic>? metadata,
  }) async {
    switch (method.id) {
      case 'card':
        // Stripe placeholder: requires backend to create PaymentIntent and return clientSecret
        if (kDebugMode) {
          debugPrint('Stripe(Card) payment in test mode. Implement clientSecret + confirmPayment for production.');
        }
        return PaymentResult.success(
          transactionId: 'card_${DateTime.now().millisecondsSinceEpoch}',
          amount: amount,
          currency: currency,
          message: 'Processed in test mode',
          metadata: {'gateway': 'stripe_test'},
        );

      case 'paypal':
        // Launch PayPal checkout URL if provided in metadata, else instruct configuration
        final approvalUrl = metadata?['approvalUrl'] as String?;
        if (approvalUrl != null && approvalUrl.isNotEmpty) {
          final ok = await _launchExternal(approvalUrl);
          if (ok) {
            return PaymentResult.success(
              transactionId: 'paypal_${DateTime.now().millisecondsSinceEpoch}',
              amount: amount,
              currency: currency,
              message: 'Redirected to PayPal',
              metadata: {'gateway': 'paypal'},
            );
          }
        }
        return PaymentResult.failure(
          message: 'PayPal not configured. Provide approvalUrl from your backend to proceed.',
          amount: amount,
          currency: currency,
          metadata: {'gateway': 'paypal'},
        );

      case 'upi':
        if (currency.toUpperCase() != 'INR') {
          return PaymentResult.failure(
            message: 'UPI is only available for INR payments',
            amount: amount,
            currency: currency,
            metadata: {'gateway': 'upi'},
          );
        }
        final vpa = (metadata?['upi_vpa'] as String?)?.trim();
        final name = (metadata?['upi_payeeName'] as String?)?.trim();
        final note = (metadata?['upi_note'] as String?)?.trim() ?? 'Rentally Booking';
        if (vpa == null || vpa.isEmpty || name == null || name.isEmpty) {
          return PaymentResult.failure(
            message: 'Please enter a valid UPI ID (VPA) and Payee name',
            amount: amount,
            currency: currency,
          );
        }
        final uri = Uri.parse(
          'upi://pay?pa=${Uri.encodeComponent(vpa)}&pn=${Uri.encodeComponent(name)}&am=${amount.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent(note)}',
        );
        final launched = await _launchExternal(uri.toString());
        if (launched) {
          return PaymentResult.success(
            transactionId: 'upi_${DateTime.now().millisecondsSinceEpoch}',
            amount: amount,
            currency: currency,
            message: 'Opened UPI app to complete payment',
            metadata: {'gateway': 'upi'},
          );
        }
        return PaymentResult.failure(
          message: 'Unable to open a UPI app. Please install a UPI-enabled app.',
          amount: amount,
          currency: currency,
          metadata: {'gateway': 'upi'},
        );

      case 'bankTransfer':
        return PaymentResult.success(
          transactionId: 'bank_${DateTime.now().millisecondsSinceEpoch}',
          amount: amount,
          currency: currency,
          message: 'Bank transfer instructions sent',
          metadata: {'gateway': 'offline_bank'},
        );

      default:
        return PaymentResult.failure(
          message: 'Payment method not supported: ${method.id}',
          amount: amount,
          currency: currency,
        );
    }
  }

  Future<bool> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
