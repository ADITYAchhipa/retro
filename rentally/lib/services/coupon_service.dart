import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CouponDiscountType { percent, fixed }

class Coupon {
  final String code;
  final String title;
  final String? description;
  final CouponDiscountType discountType;
  final double amount; // percent (0-100) if percent, else fixed amount
  final bool applyOnBase; // true: apply to base rent/monthly, false: to gross payable
  final bool active;
  final double? minSpend; // optional
  final DateTime? validFrom;
  final DateTime? validUntil; // expiry

  const Coupon({
    required this.code,
    required this.title,
    this.description,
    required this.discountType,
    required this.amount,
    this.applyOnBase = true,
    this.active = true,
    this.minSpend,
    this.validFrom,
    this.validUntil,
  });

  bool get isPercentage => discountType == CouponDiscountType.percent;
  bool isValidNow(DateTime now) {
    if (!active) return false;
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    return true;
  }
}

class CouponService extends StateNotifier<List<Coupon>> {
  CouponService() : super(const []) {
    final now = DateTime.now();
    state = [
      Coupon(
        code: 'SAVE10',
        title: '10% off base',
        description: 'Apply during checkout on eligible bookings',
        discountType: CouponDiscountType.percent,
        amount: 10.0,
        applyOnBase: true,
        validFrom: now,
        validUntil: now.add(const Duration(days: 30)),
      ),
      Coupon(
        code: 'FLAT50',
        title: 'Flat 50 off',
        description: 'Get a flat 50 off your booking (min spend 200)',
        discountType: CouponDiscountType.fixed,
        amount: 50.0,
        applyOnBase: false,
        active: true,
        minSpend: 200.0,
        validFrom: now,
        validUntil: now.add(const Duration(days: 20)),
      ),
    ];
  }

  List<Coupon> getAvailableCoupons() {
    final now = DateTime.now();
    return state.where((c) => c.isValidNow(now)).toList();
  }

  Coupon? getByCode(String code) {
    if (code.trim().isEmpty) return null;
    final now = DateTime.now();
    final found = state.firstWhere(
      (c) => c.code.toUpperCase() == code.trim().toUpperCase() && c.isValidNow(now),
      orElse: () => const Coupon(code: '', title: '', discountType: CouponDiscountType.fixed, amount: 0),
    );
    return found.code.isEmpty ? null : found;
  }
}

final couponServiceProvider = StateNotifierProvider<CouponService, List<Coupon>>((ref) {
  return CouponService();
});

// Selected coupon code for deep-link prefill from Wallet
final selectedCouponCodeProvider = StateProvider<String?>((ref) => null);
