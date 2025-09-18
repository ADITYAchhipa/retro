import 'package:flutter/material.dart';
import '../../services/payouts/payout_service.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  String? _methodId;
  bool _submitting = false;
  List<PayoutMethod> _methods = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final methods = await PayoutService.instance.getMethods();
    setState(() {
      _methods = methods;
      _methodId = methods.where((m) => m.isDefault).map((m) => m.id).firstOrNull ?? (methods.isNotEmpty ? methods.first.id : null);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Withdrawal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _methodId,
                decoration: const InputDecoration(labelText: 'Payout Method'),
                items: _methods
                    .map((m) => DropdownMenuItem(value: m.id, child: Text(m.label)))
                    .toList(),
                onChanged: (v) => setState(() => _methodId = v),
                validator: (v) => v == null ? 'Select a payout method' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final t = double.tryParse(v ?? '');
                  if (t == null || t <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Withdraw'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_methodId == null) return;
    setState(() => _submitting = true);
    try {
      final amount = double.parse(_amountCtrl.text.trim());
      await PayoutService.instance.requestWithdrawal(amount: amount, currency: 'USD', methodId: _methodId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal requested')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
