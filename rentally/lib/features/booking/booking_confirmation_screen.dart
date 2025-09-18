import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/auth_router.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String bookingId;
  const BookingConfirmationScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 72),
              const SizedBox(height: 12),
              Text(
                'Your booking is confirmed!',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Booking ID: $bookingId',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go(Routes.bookingHistory),
                  icon: const Icon(Icons.history),
                  label: const Text('Go to My Bookings'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.go(Routes.home),
                icon: const Icon(Icons.home),
                label: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
