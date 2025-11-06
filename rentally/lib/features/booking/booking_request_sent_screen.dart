import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/auth_router.dart';
import '../../services/booking_service.dart' as bs;

class BookingRequestSentScreen extends ConsumerWidget {
  final String bookingId;
  const BookingRequestSentScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(bs.bookingProvider);
    final booking = state.userBookings.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => bs.Booking(
        id: bookingId,
        listingId: '-',
        userId: '-',
        ownerId: '-',
        checkIn: DateTime.now(),
        checkOut: DateTime.now(),
        totalPrice: 0,
        status: bs.BookingStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paymentInfo: const bs.PaymentInfo(method: 'Request', isPaid: false),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Sent'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(Routes.bookingHistory),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.mark_email_read_outlined, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your booking request has been sent to the host. We will notify you when it\'s approved.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Request Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _row('Booking ID', booking.id),
                    _row('Dates', '${_fmt(booking.checkIn)} → ${_fmt(booking.checkOut)}'),
                    _row('Status', booking.status.name),
                    _row('Total', booking.totalPrice.toStringAsFixed(2)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(Routes.bookingHistory),
                    icon: const Icon(Icons.history),
                    label: const Text('Go to History'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await ref.read(bs.bookingProvider.notifier).cancelBooking(bookingId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request cancelled')),
                        );
                        context.go(Routes.bookingHistory);
                      }
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Request'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
