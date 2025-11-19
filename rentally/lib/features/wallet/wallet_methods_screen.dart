import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/auth_router.dart';

class _MoneyRequest {
  final double amount;
  final String? promoCode;
  final String? note;
  final String? destination;
  const _MoneyRequest({required this.amount, this.promoCode, this.note, this.destination});
}

class WalletMethodsScreen extends StatefulWidget {
  final String initialTab;
  const WalletMethodsScreen({super.key, this.initialTab = 'add'});

  @override
  State<WalletMethodsScreen> createState() => _WalletMethodsScreenState();
}

class _WalletMethodsScreenState extends State<WalletMethodsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _defaultWithdrawDestination = 'Primary Bank Account';

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTab.toLowerCase() == 'withdraw' ? 1 : 0;
    _tab = TabController(length: 2, vsync: this, initialIndex: initialIndex);
    _loadPrefs();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultWithdrawDestination = prefs.getString('wallet.defaultWithdrawDest') ?? 'Primary Bank Account';
    });
  }

  Future<void> _saveDefaultDestination(String dest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallet.defaultWithdrawDest', dest);
    setState(() => _defaultWithdrawDestination = dest);
  }

  Future<_MoneyRequest?> _promptAddMoneyDetails(BuildContext context) async {
    final amountCtrl = TextEditingController();
    final promoCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    return showDialog<_MoneyRequest?>(
      context: context,
      builder: (context) {
        final isPhone = MediaQuery.sizeOf(context).width < 600;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Money', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                const SizedBox(height: 6),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: amountCtrl,
                  builder: (context, value, _) {
                    const minAdd = 10.0;
                    const maxAdd = 100000.0;
                    const feePct = 0.02; // 2%
                    const feeFixed = 5.0; // ₹5
                    final amt = double.tryParse(value.text.trim()) ?? 0;
                    final fee = amt > 0 ? (amt * feePct + feeFixed) : 0;
                    final total = amt > 0 ? (amt + fee) : 0;
                    final invalid = amt > 0 && (amt < minAdd || amt > maxAdd);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invalid
                              ? 'Enter between ₹${minAdd.toStringAsFixed(0)} and ₹${maxAdd.toStringAsFixed(0)}'
                              : 'Estimated fee ~2% + ₹5 • Total charge: ₹${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: invalid ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [100, 500, 1000].map((v) => ActionChip(
                    label: Text('₹$v'),
                    onPressed: () => amountCtrl.text = v.toString(),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: promoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Promo code (optional)',
                    prefixIcon: Icon(Icons.local_offer_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: isPhone ? 2 : 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final amount = double.tryParse(amountCtrl.text.trim());
                          const minAdd = 10.0;
                          const maxAdd = 100000.0;
                          if (amount == null || amount <= 0 || amount < minAdd || amount > maxAdd) {
                            Navigator.pop(context, null);
                            return;
                          }
                          Navigator.pop(context, _MoneyRequest(
                            amount: amount,
                            promoCode: promoCtrl.text.trim().isEmpty ? null : promoCtrl.text.trim(),
                            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                          ));
                        },
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_MoneyRequest?> _promptWithdrawDetails(BuildContext context) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String destination = _defaultWithdrawDestination;
    return showDialog<_MoneyRequest?>(
      context: context,
      builder: (context) {
        final isPhone = MediaQuery.sizeOf(context).width < 600;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Request Withdrawal', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                const SizedBox(height: 6),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: amountCtrl,
                  builder: (context, value, _) {
                    const minW = 100.0;
                    const maxW = 500000.0;
                    const feePct = 0.01; // 1%
                    const feeFixed = 10.0; // ₹10
                    final amt = double.tryParse(value.text.trim()) ?? 0;
                    final fee = amt > 0 ? (amt * feePct + feeFixed) : 0;
                    final net = amt > 0 ? (amt - fee) : 0;
                    final invalid = amt > 0 && (amt < minW || amt > maxW);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invalid
                              ? 'Enter between ₹${minW.toStringAsFixed(0)} and ₹${maxW.toStringAsFixed(0)}'
                              : 'Estimated fee ~1% + ₹10 • You receive: ₹${net.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: invalid ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [500, 1000, 2000].map((v) => ActionChip(
                    label: Text('₹$v'),
                    onPressed: () => amountCtrl.text = v.toString(),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: destination,
                  items: const [
                    DropdownMenuItem(value: 'Primary Bank Account', child: Text('Primary Bank Account')),
                    DropdownMenuItem(value: 'UPI: demo@upi', child: Text('UPI: demo@upi')),
                    DropdownMenuItem(value: 'PayPal: user@example.com', child: Text('PayPal: user@example.com')),
                  ],
                  onChanged: (v) { if (v != null) destination = v; },
                  decoration: const InputDecoration(
                    labelText: 'Destination (optional)',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: isPhone ? 2 : 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final amount = double.tryParse(amountCtrl.text.trim());
                          const minW = 100.0;
                          const maxW = 500000.0;
                          if (amount == null || amount <= 0 || amount < minW || amount > maxW) {
                            Navigator.pop(context, null);
                            return;
                          }
                          Navigator.pop(context, _MoneyRequest(
                            amount: amount,
                            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                            destination: destination,
                          ));
                          _saveDefaultDestination(destination);
                        },
                        child: const Text('Request'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onAddMoney() async {
    final req = await _promptAddMoneyDetails(context);
    if (!mounted) return;
    if (req == null || req.amount <= 0) return;
    final result = await context.push(Routes.paymentIntegration, extra: {
      'amount': req.amount,
      'propertyTitle': 'Wallet Top-Up',
      'note': req.note,
      'promo': req.promoCode,
    });
    if (!mounted) return;
    final amount = (result is Map && result['walletTopUp'] is num) ? (result['walletTopUp'] as num).toDouble() : null;
    if (amount != null && amount > 0) {
      await _appendTransaction(
        idPrefix: 'topup',
        type: 'earning',
        amount: amount,
        description: 'Wallet top-up',
        status: 'completed',
      );
      await _adjustBalanceOffset(amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wallet topped up by ₹${amount.toStringAsFixed(2)}')),
      );
      context.go(Routes.wallet);
    }
  }

  Future<void> _onRequestWithdrawal() async {
    final req = await _promptWithdrawDetails(context);
    if (!mounted) return;
    if (req == null || req.amount <= 0) return;
    await _appendTransaction(
      idPrefix: 'wd',
      type: 'withdrawal',
      amount: -req.amount.abs(),
      description: 'Withdrawal request${req.destination != null ? ' • ${req.destination}' : ''}',
      status: 'pending',
    );
    await _adjustBalanceOffset(-req.amount.abs());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Withdrawal requested: ₹${req.amount.toStringAsFixed(2)}${req.destination != null ? ' to ${req.destination}' : ''}',
        ),
      ),
    );
    context.go(Routes.wallet);
  }

  Future<void> _appendTransaction({
    required String idPrefix,
    required String type,
    required double amount,
    required String description,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'wallet.extraTx';
    final now = DateTime.now();
    final tx = {
      'id': '${idPrefix}_${now.millisecondsSinceEpoch}',
      'type': type,
      'amount': amount,
      'description': description,
      'date': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'status': status,
    };
    final listJson = prefs.getString(key);
    List<dynamic> list = [];
    if (listJson != null && listJson.isNotEmpty) {
      try { list = List<dynamic>.from(jsonDecode(listJson)); } catch (_) {}
    }
    list.insert(0, tx);
    await prefs.setString(key, jsonEncode(list));
  }

  Future<void> _adjustBalanceOffset(double delta) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'wallet.balanceOffset';
    final current = prefs.getDouble(key) ?? 0.0;
    await prefs.setDouble(key, current + delta);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Wallet Methods'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Add Money', icon: Icon(Icons.account_balance_wallet_outlined)),
            Tab(text: 'Withdraw', icon: Icon(Icons.payments_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          ListView(
            padding: EdgeInsets.all(isPhone ? 16 : 24),
            children: [
              FilledButton.icon(
                onPressed: _onAddMoney,
                icon: const Icon(Icons.account_balance_wallet_rounded),
                label: const Text('Add Money'),
                style: FilledButton.styleFrom(minimumSize: Size(double.infinity, isPhone ? 44 : 48)),
              ),
              const SizedBox(height: 16),
              _tile(
                context,
                title: 'Manage Payment Cards',
                subtitle: 'Add or remove saved cards',
                color: theme.colorScheme.primary,
                icon: Icons.credit_card,
                onTap: () => context.push(Routes.paymentMethods),
              ),
              const SizedBox(height: 12),
              _tile(
                context,
                title: 'UPI',
                subtitle: 'Instant add via UPI ID',
                color: const Color(0xFF10B981),
                icon: Icons.qr_code_2,
                onTap: () => context.push(Routes.paymentMethods),
              ),
              const SizedBox(height: 12),
              _tile(
                context,
                title: 'PayPal',
                subtitle: 'Use PayPal to add funds',
                color: Colors.indigo,
                icon: Icons.account_balance_wallet,
                onTap: () => context.push(Routes.paymentMethods),
              ),
            ],
          ),
          ListView(
            padding: EdgeInsets.all(isPhone ? 16 : 24),
            children: [
              FilledButton.icon(
                onPressed: _onRequestWithdrawal,
                icon: const Icon(Icons.payments_rounded),
                label: const Text('Request Withdrawal'),
                style: FilledButton.styleFrom(minimumSize: Size(double.infinity, isPhone ? 44 : 48)),
              ),
              const SizedBox(height: 16),
              _tile(
                context,
                title: 'Bank Account',
                subtitle: 'Direct bank transfer',
                color: const Color(0xFF3B82F6),
                icon: Icons.account_balance,
                onTap: () => context.push(Routes.payoutMethods),
              ),
              const SizedBox(height: 12),
              _tile(
                context,
                title: 'UPI',
                subtitle: 'Instant withdrawal to UPI ID',
                color: const Color(0xFF10B981),
                icon: Icons.qr_code_2,
                onTap: () => context.push(Routes.payoutMethods),
              ),
              const SizedBox(height: 12),
              _tile(
                context,
                title: 'PayPal',
                subtitle: 'International payouts',
                color: const Color(0xFF8B5CF6),
                icon: Icons.payment,
                onTap: () => context.push(Routes.payoutMethods),
              ),
              const SizedBox(height: 12),
              _tile(
                context,
                title: 'Wise (TransferWise)',
                subtitle: 'Low-cost global payouts',
                color: const Color(0xFF06B6D4),
                icon: Icons.swap_horiz,
                onTap: () => context.push(Routes.payoutMethods),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
