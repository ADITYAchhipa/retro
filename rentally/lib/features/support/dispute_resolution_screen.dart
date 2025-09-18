import 'package:flutter/material.dart';

class DisputeResolutionScreen extends StatelessWidget {
  final String? bookingId;
  const DisputeResolutionScreen({super.key, this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispute Resolution')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (bookingId != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.confirmation_number_outlined),
                title: Text('Booking: $bookingId'),
                subtitle: const Text('You are creating a dispute for this booking'),
              ),
            ),
          const ListTile(
            leading: Icon(Icons.gavel_outlined),
            title: Text('No disputes'),
            subtitle: Text('Open a dispute from a booking detail page'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute creation flow coming soon')));
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Dispute'),
            ),
          ),
        ],
      ),
    );
  }
}
