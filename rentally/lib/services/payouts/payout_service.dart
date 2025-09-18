import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PayoutMethod {
  final String id; // uuid
  final String type; // bank|paypal|wise
  final String label; // e.g., Bank ****1234
  final Map<String, dynamic> details;
  final bool isDefault;

  const PayoutMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.details,
    this.isDefault = false,
  });

  PayoutMethod copyWith({
    String? id,
    String? type,
    String? label,
    Map<String, dynamic>? details,
    bool? isDefault,
  }) {
    return PayoutMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      details: details ?? this.details,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'details': details,
        'isDefault': isDefault,
      };

  factory PayoutMethod.fromJson(Map<String, dynamic> json) => PayoutMethod(
        id: json['id'] as String,
        type: json['type'] as String,
        label: json['label'] as String,
        details: Map<String, dynamic>.from(json['details'] as Map),
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

class Payout {
  final String id; // uuid
  final double amount;
  final String currency;
  final String methodId;
  final String status; // pending|processing|paid|failed
  final int timestamp;

  const Payout({
    required this.id,
    required this.amount,
    required this.currency,
    required this.methodId,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'methodId': methodId,
        'status': status,
        'timestamp': timestamp,
      };

  factory Payout.fromJson(Map<String, dynamic> json) => Payout(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        methodId: json['methodId'] as String,
        status: json['status'] as String,
        timestamp: json['timestamp'] as int,
      );
}

class PayoutService {
  PayoutService._();
  static final PayoutService instance = PayoutService._();

  static const _methodsKey = 'payout_methods_v1';
  static const _payoutsKey = 'payouts_v1';

  Future<List<PayoutMethod>> getMethods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_methodsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => PayoutMethod.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return list;
    } catch (e) {
      if (kDebugMode) print('PayoutService getMethods error: $e');
      return const [];
    }
  }

  Future<void> saveMethods(List<PayoutMethod> methods) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(methods.map((e) => e.toJson()).toList());
    await prefs.setString(_methodsKey, raw);
  }

  Future<List<Payout>> getPayouts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_payoutsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Payout.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      if (kDebugMode) print('PayoutService getPayouts error: $e');
      return const [];
    }
  }

  Future<void> savePayouts(List<Payout> payouts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(payouts.map((e) => e.toJson()).toList());
    await prefs.setString(_payoutsKey, raw);
  }

  Future<PayoutMethod> linkMethod(PayoutMethod method) async {
    final methods = await getMethods();
    final updated = [method, ...methods.where((m) => m.id != method.id)];
    await saveMethods(updated);
    return method;
  }

  Future<void> setDefault(String methodId) async {
    final methods = await getMethods();
    final updated = methods
        .map((m) => m.copyWith(isDefault: m.id == methodId))
        .toList();
    await saveMethods(updated);
  }

  Future<Payout> requestWithdrawal({
    required double amount,
    required String currency,
    required String methodId,
  }) async {
    final newPayout = Payout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      currency: currency,
      methodId: methodId,
      status: 'processing',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    final payouts = await getPayouts();
    await savePayouts([newPayout, ...payouts]);
    return newPayout;
  }
}
