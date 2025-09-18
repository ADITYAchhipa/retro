import 'package:flutter/material.dart';
import '../../services/payouts/payout_service.dart';

class PayoutHistoryScreen extends StatefulWidget {
  const PayoutHistoryScreen({super.key});

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
}

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  late Future<List<Payout>> _future;

  @override
  void initState() {
    super.initState();
    _future = PayoutService.instance.getPayouts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Payout History')),
      body: FutureBuilder<List<Payout>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Text('No payouts yet', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = items[i];
              return ListTile(
                leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: const Icon(Icons.payments, color: Colors.green)),
                title: Text('${p.currency} ${p.amount.toStringAsFixed(2)}'),
                subtitle: Text('Status: ${p.status} • ${DateTime.fromMillisecondsSinceEpoch(p.timestamp)}'),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          );
        },
      ),
    );
  }
}
