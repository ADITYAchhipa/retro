import 'package:flutter/material.dart';

class PayoutMethodsScreen extends StatelessWidget {
  const PayoutMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Payout Methods')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Link your payout accounts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _methodTile(context, 'Bank Account', Icons.account_balance, Colors.indigo),
          const Divider(height: 1),
          _methodTile(context, 'PayPal', Icons.account_balance_wallet, Colors.blue),
          const Divider(height: 1),
          _methodTile(context, 'Wise', Icons.swap_horiz, Colors.green),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_link),
            label: const Text('Add New Method'),
          ),
        ],
      ),
    );
  }

  ListTile _methodTile(BuildContext context, String name, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(name),
      subtitle: const Text('Not linked'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Linking $name coming soon')),);
      },
    );
  }
}
