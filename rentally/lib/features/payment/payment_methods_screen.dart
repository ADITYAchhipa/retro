import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<_CardItem> _cards = const [
    _CardItem(brand: 'Visa', last4: '4242', expiry: '12/26', isDefault: true),
    _CardItem(brand: 'Mastercard', last4: '2210', expiry: '07/25'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(theme, 'Your Cards', Icons.credit_card, isPhone),
          const SizedBox(height: 12),
          ..._cards.map((c) => _cardTile(context, c)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _showAddCardDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add New Card'),
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'Other Methods', Icons.account_balance_wallet_outlined, isPhone),
          const SizedBox(height: 12),
          _walletTile(context, 'PayPal', Icons.account_balance_wallet, Colors.indigo),
          const Divider(height: 1),
          _walletTile(context, 'Cash on Arrival', Icons.payments, Colors.green),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title, IconData icon, bool isPhone) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: isPhone ? 20 : 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: isPhone ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _cardTile(BuildContext context, _CardItem c) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.credit_card, color: Colors.blue),
        ),
        title: Text('${c.brand} •••• ${c.last4}'),
        subtitle: Text('Expires ${c.expiry}${c.isDefault ? '  •  Default' : ''}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'default':
                setState(() {
                  _cards = _cards.map((cc) => cc == c
                      ? cc.copyWith(isDefault: true)
                      : cc.copyWith(isDefault: false)).toList();
                });
                break;
              case 'remove':
                setState(() => _cards = _cards.where((cc) => cc != c).toList());
                break;
            }
          },
          itemBuilder: (context) => [
            if (!c.isDefault)
              const PopupMenuItem(value: 'default', child: Text('Set as default')),
            const PopupMenuItem(value: 'remove', child: Text('Remove')),
          ],
        ),
      ),
    );
  }

  Widget _walletTile(BuildContext context, String title, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: const Text('Tap to configure'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => SnackBarUtils.showInfo(context, '$title setup coming soon'),
    );
  }

  void _showAddCardDialog() {
    final numberCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: expiryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Expiry',
                      hintText: 'MM/YY',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: cvvCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'John Doe',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _cards = [
                  ..._cards,
                  _CardItem(
                    brand: 'Card',
                    last4: numberCtrl.text.isNotEmpty
                        ? numberCtrl.text.substring(numberCtrl.text.length - 4)
                        : '0000',
                    expiry: expiryCtrl.text.isNotEmpty ? expiryCtrl.text : '01/30',
                  ),
                ];
              });
              Navigator.pop(context);
              SnackBarUtils.showSuccess(context, 'Card added');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _CardItem {
  final String brand;
  final String last4;
  final String expiry;
  final bool isDefault;
  const _CardItem({required this.brand, required this.last4, required this.expiry, this.isDefault = false});

  _CardItem copyWith({String? brand, String? last4, String? expiry, bool? isDefault}) {
    return _CardItem(
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      expiry: expiry ?? this.expiry,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
