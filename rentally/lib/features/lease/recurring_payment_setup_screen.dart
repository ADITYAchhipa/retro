import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../services/referral_service.dart';
import '../../services/coupon_service.dart';
import '../../app/auth_router.dart';

class RecurringPaymentSetupScreen extends ConsumerStatefulWidget {
  final String listingId;
  final double? monthlyAmount;
  final String currency;

  const RecurringPaymentSetupScreen({
    super.key,
    required this.listingId,
    this.monthlyAmount,
    this.currency = 'USD',
  });

  @override
  ConsumerState<RecurringPaymentSetupScreen> createState() => _RecurringPaymentSetupScreenState();
}

class _RecurringPaymentSetupScreenState extends ConsumerState<RecurringPaymentSetupScreen> {
  String _gateway = 'stripe'; // stripe | paypal
  bool _autoDebit = true;
  int _billingDay = 1; // day of month
  bool _prorateFirstMonth = true;

  // Referral tokens (coins) input
  final TextEditingController _tokenCtrl = TextEditingController();
  int _tokensApplied = 0;
  // Coupon state
  String _couponCode = '';
  double _couponDiscount = 0.0;
  String? _appliedCouponCode;

  @override
  void initState() {
    super.initState();
    // Prefill coupon from Wallet deep-link if present
    final prefill = ref.read(selectedCouponCodeProvider);
    if (prefill != null && prefill.isNotEmpty) {
      _couponCode = prefill;
      // Apply on next frame to ensure context is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyCoupon();
          ref.read(selectedCouponCodeProvider.notifier).state = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    setState(() {
      final code = _couponCode.trim().toUpperCase();
      if ((_appliedCouponCode != null && _appliedCouponCode!.isNotEmpty) && code != _appliedCouponCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only one coupon can be applied. Clear current coupon to apply another.')),
        );
        return;
      }
      if (code.isEmpty) {
        _couponDiscount = 0.0;
        _appliedCouponCode = null;
        return;
      }

      final svc = ref.read(couponServiceProvider.notifier);
      final coupon = svc.getByCode(code);

      if (coupon == null) {
        _couponDiscount = 0.0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid coupon')),
        );
        return;
      }

      final double monthly = ((widget.monthlyAmount ?? 0).toDouble()).clamp(0.0, double.infinity);
      final double grossBeforeTokens = monthly; // monthly flow has no extra fees here
      final double base = coupon.applyOnBase ? monthly : grossBeforeTokens;

      if ((coupon.minSpend ?? 0) > 0 && base < (coupon.minSpend ?? 0)) {
        _couponDiscount = 0.0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon not applicable: minimum spend not met')),
        );
        return;
      }

      double discount;
      if (coupon.isPercentage) {
        discount = (base * (coupon.amount / 100)).clamp(0, base);
      } else {
        discount = coupon.amount.clamp(0, base);
      }

      _couponDiscount = discount;
      _appliedCouponCode = code;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coupon applied')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableTokens = ref.watch(referralServiceProvider).totalTokens;
    final double monthly = ((widget.monthlyAmount ?? 0).toDouble()).clamp(0.0, double.infinity).toDouble();
    // Apply coupon first; tokens apply to remaining payable with 10% of payable cap
    final double beforeTokens = (monthly - _couponDiscount).clamp(0.0, double.infinity);
    final int maxApplicable = beforeTokens.floor();
    final int capByTotal = (beforeTokens * 0.10).floor();
    int maxUsable = availableTokens;
    if (capByTotal < maxUsable) maxUsable = capByTotal;
    if (maxApplicable >= 0 && maxApplicable < maxUsable) maxUsable = maxUsable > 0 ? maxApplicable : maxUsable;
    final int tokensDiscount = _tokensApplied.clamp(0, maxUsable);
    final double nextCharge = (beforeTokens - tokensDiscount).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Payment Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Listing: ${widget.listingId}', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            if (widget.monthlyAmount != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Per month: ${CurrencyFormatter.formatPricePerUnit(widget.monthlyAmount!, 'month', currency: widget.currency)}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text('Billing Gateway', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'stripe', label: Text('Stripe')),
                ButtonSegment(value: 'paypal', label: Text('PayPal')),
              ],
              selected: {_gateway},
              onSelectionChanged: (s) => setState(() => _gateway = s.first),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _autoDebit,
              onChanged: (v) => setState(() => _autoDebit = v),
              title: const Text('Enable Auto-Debit'),
              subtitle: const Text('Automatically charge monthly rent on the billing day'),
            ),
            const SizedBox(height: 8),
            Text('Billing Day of Month', style: theme.textTheme.titleMedium),
            Slider(
              value: _billingDay.toDouble(),
              min: 1,
              max: 28,
              divisions: 27,
              label: _billingDay.toString(),
              onChanged: (v) => setState(() => _billingDay = v.toInt()),
            ),
            CheckboxListTile(
              value: _prorateFirstMonth,
              onChanged: (v) => setState(() => _prorateFirstMonth = v ?? true),
              title: const Text('Prorate first month'),
              subtitle: const Text('Align to billing cycle and charge only for remaining days'),
            ),
            const SizedBox(height: 16),
            // Discounts: coupon entry
            Text('Discounts', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Coupon code',
                hintText: 'Enter coupon (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sell_outlined),
              ),
              onChanged: (v) => _couponCode = v.trim(),
              onSubmitted: (_) => _applyCoupon(),
            ),
            const SizedBox(height: 8),
            if (_appliedCouponCode != null && _appliedCouponCode!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Text('Applied coupon: ${_appliedCouponCode!}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.green[700])),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _appliedCouponCode = null;
                        _couponCode = '';
                        _couponDiscount = 0.0;
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _applyCoupon,
                icon: const Icon(Icons.check),
                label: const Text('Apply'),
              ),
            ),
            const SizedBox(height: 12),
            // Discounts: referral tokens
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Referral credits', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tokenCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tokens to apply',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.loyalty_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () { _tokenCtrl.text = maxUsable.toString(); },
                          child: const Text('Max'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final v = int.tryParse(_tokenCtrl.text.trim()) ?? 0;
                            setState(() { _tokensApplied = v.clamp(0, maxUsable); });
                            if (_tokensApplied > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Applied: $_tokensApplied tokens')),
                              );
                            }
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Available: $availableTokens tokens', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text('Max usable this billing: $maxUsable tokens (10% of payable cap)', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Summary of charges
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Monthly rent')),
                        Text(CurrencyFormatter.formatPrice(monthly, currency: widget.currency)),
                      ],
                    ),
                    if (_couponDiscount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Expanded(child: Text('Coupon')),
                          Text('-${CurrencyFormatter.formatPrice(_couponDiscount, currency: widget.currency)}'),
                        ],
                      ),
                    ],
                    if (tokensDiscount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Expanded(child: Text('Referral credits')),
                          Text('-${CurrencyFormatter.formatPrice(tokensDiscount.toDouble(), currency: widget.currency)}'),
                        ],
                      ),
                    ],
                    const Divider(),
                    Row(
                      children: [
                        const Expanded(child: Text('Next charge', style: TextStyle(fontWeight: FontWeight.w600))),
                        Text(CurrencyFormatter.formatPrice(nextCharge, currency: widget.currency)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                // Placeholder for creating subscription via backend
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Create ${_gateway.toUpperCase()} subscription for day $_billingDay')),
                );
                await Future.delayed(const Duration(milliseconds: 400));
                // Redeem tokens if applied
                if (tokensDiscount > 0) {
                  final ok = await ref.read(referralServiceProvider.notifier)
                      .redeemTokens(tokensDiscount, 'Monthly discount for ${widget.listingId}');
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Redeemed $tokensDiscount tokens')),
                    );
                  }
                }
                if (!context.mounted) return;
                context.go(Routes.bookingHistory);
              },
              icon: const Icon(Icons.autorenew_rounded),
              label: const Text('Create Subscription'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                context.push(
                  '/monthly/start/${widget.listingId}',
                  extra: {
                    if (widget.monthlyAmount != null) 'monthlyAmount': widget.monthlyAmount,
                    'currency': widget.currency,
                  },
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Monthly Setup'),
            ),
          ],
        ),
      ),
    );
  }
}
