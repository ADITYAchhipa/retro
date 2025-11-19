import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookingPaymentScreen extends StatefulWidget {
  final String listingId;
  final double? amount; // Optional total amount for short-term flow
  final String currency;
  final String? initialMethod; // Optional preselected method: 'card' | 'paypal' | 'upi' | 'bankTransfer'
  const BookingPaymentScreen({super.key, required this.listingId, this.amount, this.currency = 'USD', this.initialMethod});

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  String _method = 'card'; // card | paypal | upi | bankTransfer
  final TextEditingController _upiVpaCtrl = TextEditingController();
  final TextEditingController _upiNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _method = (widget.initialMethod ?? 'card');
  }

  @override
  void dispose() {
    _upiVpaCtrl.dispose();
    _upiNameCtrl.dispose();
    super.dispose();
  }

  void _pay() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Processing ${widget.currency} ${widget.amount?.toStringAsFixed(2) ?? ''} via $_method...')),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    final txn = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    context.pop({
      'success': true,
      'transactionId': txn,
      'method': _method,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Payment Method', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Card (Stripe)'),
                  selected: _method == 'card',
                  onSelected: (_) => setState(() => _method = 'card'),
                ),
                ChoiceChip(
                  label: const Text('PayPal'),
                  selected: _method == 'paypal',
                  onSelected: (_) => setState(() => _method = 'paypal'),
                ),
                ChoiceChip(
                  label: const Text('UPI (INR)'),
                  selected: _method == 'upi',
                  onSelected: (_) => setState(() => _method = 'upi'),
                ),
                ChoiceChip(
                  label: const Text('Bank Transfer'),
                  selected: _method == 'bankTransfer',
                  onSelected: (_) => setState(() => _method = 'bankTransfer'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_method == 'upi') ...[
              TextField(
                controller: _upiVpaCtrl,
                decoration: const InputDecoration(
                  labelText: 'UPI ID (VPA)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _upiNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Payee Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We route payments using region-appropriate gateways. Your data is encrypted and secure.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _pay,
                icon: const Icon(Icons.lock_outline),
                label: Text('Pay ${widget.amount != null ? '${widget.currency} ${widget.amount!.toStringAsFixed(2)}' : ''}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
