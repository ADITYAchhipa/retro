import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/tab_back_handler.dart';
import 'package:go_router/go_router.dart';

enum BookingStatus {
  pending,
  confirmed,
  checkedIn,
  checkedOut,
  cancelled,
  completed,
}

class OwnerBooking {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String propertyImage;
  final String guestId;
  final String guestName;
  final String guestAvatar;
  final String guestEmail;
  final String guestPhone;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double totalAmount;
  final BookingStatus status;
  final DateTime createdAt;
  final String? specialRequests;
  final double? rating;
  final String? review;

  const OwnerBooking({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyImage,
    required this.guestId,
    required this.guestName,
    required this.guestAvatar,
    required this.guestEmail,
    required this.guestPhone,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.specialRequests,
    this.rating,
    this.review,
  });

  OwnerBooking copyWith({
    String? id,
    String? propertyId,
    String? propertyTitle,
    String? propertyImage,
    String? guestId,
    String? guestName,
    String? guestAvatar,
    String? guestEmail,
    String? guestPhone,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    double? totalAmount,
    BookingStatus? status,
    DateTime? createdAt,
    String? specialRequests,
    double? rating,
    String? review,
  }) {
    return OwnerBooking(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyImage: propertyImage ?? this.propertyImage,
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      guestAvatar: guestAvatar ?? this.guestAvatar,
      guestEmail: guestEmail ?? this.guestEmail,
      guestPhone: guestPhone ?? this.guestPhone,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guests: guests ?? this.guests,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      specialRequests: specialRequests ?? this.specialRequests,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }

  int get nights => checkOut.difference(checkIn).inDays;
}

class BookingManagementService extends StateNotifier<List<OwnerBooking>> {
  BookingManagementService() : super(_mockBookings);

  static final List<OwnerBooking> _mockBookings = [
    OwnerBooking(
      id: '1',
      propertyId: '1',
      propertyTitle: 'Modern Downtown Apartment',
      propertyImage: 'https://picsum.photos/seed/booking_property1/300/200',
      guestId: '2',
      guestName: 'Sarah Johnson',
      guestAvatar: 'https://picsum.photos/seed/avatar_sj/150',
      guestEmail: 'sarah.johnson@email.com',
      guestPhone: '+1 (555) 123-4567',
      checkIn: DateTime.now().add(const Duration(days: 3)),
      checkOut: DateTime.now().add(const Duration(days: 7)),
      guests: 2,
      totalAmount: 480.0,
      status: BookingStatus.confirmed,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      specialRequests: 'Early check-in if possible, celebrating anniversary',
    ),
    OwnerBooking(
      id: '2',
      propertyId: '2',
      propertyTitle: 'Cozy Beach House',
      propertyImage: 'https://picsum.photos/seed/booking_property2/300/200',
      guestId: '3',
      guestName: 'Mike Chen',
      guestAvatar: 'https://picsum.photos/seed/avatar_mc/150',
      guestEmail: 'mike.chen@email.com',
      guestPhone: '+1 (555) 987-6543',
      checkIn: DateTime.now().subtract(const Duration(days: 5)),
      checkOut: DateTime.now().subtract(const Duration(days: 2)),
      guests: 4,
      totalAmount: 750.0,
      status: BookingStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      rating: 5.0,
      review: 'Amazing place! Perfect for our family vacation.',
    ),
    OwnerBooking(
      id: '3',
      propertyId: '1',
      propertyTitle: 'Modern Downtown Apartment',
      propertyImage: 'https://picsum.photos/seed/booking_property1b/300/200',
      guestId: '4',
      guestName: 'Emma Wilson',
      guestAvatar: 'https://picsum.photos/seed/avatar_ew/150',
      guestEmail: 'emma.wilson@email.com',
      guestPhone: '+1 (555) 456-7890',
      checkIn: DateTime.now().add(const Duration(days: 10)),
      checkOut: DateTime.now().add(const Duration(days: 13)),
      guests: 1,
      totalAmount: 360.0,
      status: BookingStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      specialRequests: 'Business trip, need good WiFi and workspace',
    ),
  ];

  void updateBookingStatus(String bookingId, BookingStatus newStatus) {
    state = state.map((booking) {
      if (booking.id == bookingId) {
        return booking.copyWith(status: newStatus);
      }
      return booking;
    }).toList();
  }

  List<OwnerBooking> getBookingsByStatus(BookingStatus status) {
    return state.where((booking) => booking.status == status).toList();
  }

  List<OwnerBooking> getUpcomingBookings() {
    final now = DateTime.now();
    return state.where((booking) => 
      booking.checkIn.isAfter(now) && 
      (booking.status == BookingStatus.confirmed || booking.status == BookingStatus.pending)
    ).toList();
  }

  double getTotalEarnings() {
    return state
        .where((booking) => booking.status == BookingStatus.completed)
        .fold(0.0, (sum, booking) => sum + booking.totalAmount);
  }

  int getTotalBookings() {
    return state.length;
  }
}

final bookingManagementProvider = StateNotifierProvider<BookingManagementService, List<OwnerBooking>>((ref) {
  return BookingManagementService();
});

class BookingManagementScreen extends ConsumerStatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  ConsumerState<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends ConsumerState<BookingManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(bookingManagementProvider);
    final bookingService = ref.read(bookingManagementProvider.notifier);
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return TabBackHandler(
      tabController: _tabController,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Booking Management'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'All'),
            Tab(text: t?.pending ?? 'Pending'),
            const Tab(text: 'Confirmed'),
            Tab(text: t?.completed ?? 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Overview
          _buildStatsOverview(bookingService, theme),
          
          // Bookings List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              dragStartBehavior: DragStartBehavior.down,
              physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
              children: [
                _buildBookingsList(bookings, theme),
                _buildBookingsList(bookingService.getBookingsByStatus(BookingStatus.pending), theme),
                _buildBookingsList(bookingService.getBookingsByStatus(BookingStatus.confirmed), theme),
                _buildBookingsList(bookingService.getBookingsByStatus(BookingStatus.completed), theme),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStatsOverview(BookingManagementService service, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Bookings',
              '${service.getTotalBookings()}',
              Icons.book_outlined,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Earnings',
              CurrencyFormatter.formatPrice(service.getTotalEarnings()),
              Icons.attach_money,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Upcoming',
              '${service.getUpcomingBookings().length}',
              Icons.schedule,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<OwnerBooking> bookings, ThemeData theme) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking, theme);
      },
    );
  }

  Widget _buildBookingCard(OwnerBooking booking, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with guest info and status
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(booking.guestAvatar),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.guestName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          booking.propertyTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(booking.status, theme),
                ],
              ),
              const SizedBox(height: 16),

              // Booking details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Check-in',
                      _formatDate(booking.checkIn),
                      Icons.login,
                      theme,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Check-out',
                      _formatDate(booking.checkOut),
                      Icons.logout,
                      theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Guests',
                      '${booking.guests}',
                      Icons.people,
                      theme,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Total',
                      CurrencyFormatter.formatPrice(booking.totalAmount),
                      Icons.attach_money,
                      theme,
                    ),
                  ),
                ],
              ),

              // Special requests
              if (booking.specialRequests != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.specialRequests!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons
              if (booking.status == BookingStatus.pending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateBookingStatus(booking.id, BookingStatus.cancelled),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateBookingStatus(booking.id, BookingStatus.confirmed),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(BookingStatus status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case BookingStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange[700]!;
        text = 'Pending';
        break;
      case BookingStatus.confirmed:
        backgroundColor = Colors.blue.withValues(alpha: 0.2);
        textColor = Colors.blue[700]!;
        text = 'Confirmed';
        break;
      case BookingStatus.checkedIn:
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green[700]!;
        text = 'Checked In';
        break;
      case BookingStatus.checkedOut:
        backgroundColor = Colors.purple.withValues(alpha: 0.2);
        textColor = Colors.purple[700]!;
        text = 'Checked Out';
        break;
      case BookingStatus.cancelled:
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red[700]!;
        text = 'Cancelled';
        break;
      case BookingStatus.completed:
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green[700]!;
        text = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _updateBookingStatus(String bookingId, BookingStatus newStatus) {
    ref.read(bookingManagementProvider.notifier).updateBookingStatus(bookingId, newStatus);
    
    String message;
    switch (newStatus) {
      case BookingStatus.confirmed:
        message = 'Booking confirmed successfully!';
        break;
      case BookingStatus.cancelled:
        message = 'Booking declined';
        break;
      default:
        message = 'Booking status updated';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: newStatus == BookingStatus.cancelled ? Colors.red : Colors.green,
      ),
    );
  }

  void _showBookingDetails(OwnerBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BookingDetailsBottomSheet(booking: booking),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class BookingDetailsBottomSheet extends StatelessWidget {
  final OwnerBooking booking;

  const BookingDetailsBottomSheet({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(booking.guestAvatar),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.guestName,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  booking.propertyTitle,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Contact Info
                      _buildSection(
                        'Contact Information',
                        [
                          _buildInfoRow('Email', booking.guestEmail, Icons.email),
                          _buildInfoRow('Phone', booking.guestPhone, Icons.phone),
                        ],
                        theme,
                      ),
                      const SizedBox(height: 24),

                      // Booking Details
                      _buildSection(
                        'Booking Details',
                        [
                          _buildInfoRow('Check-in', _formatDateTime(booking.checkIn), Icons.login),
                          _buildInfoRow('Check-out', _formatDateTime(booking.checkOut), Icons.logout),
                          _buildInfoRow('Duration', '${booking.nights} nights', Icons.schedule),
                          _buildInfoRow('Guests', '${booking.guests}', Icons.people),
                          _buildInfoRow('Total Amount', CurrencyFormatter.formatPrice(booking.totalAmount), Icons.attach_money),
                        ],
                        theme,
                      ),

                      if (booking.specialRequests != null) ...[
                        const SizedBox(height: 24),
                        _buildSection(
                          'Special Requests',
                          [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                booking.specialRequests!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                          theme,
                        ),
                      ],

                      if (booking.review != null) ...[
                        const SizedBox(height: 24),
                        _buildSection(
                          'Guest Review',
                          [
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < (booking.rating ?? 0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  '${booking.rating}/5',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                booking.review!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                          theme,
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Open messaging
                              },
                              icon: const Icon(Icons.message),
                              label: const Text('Message'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Call guest
                              },
                              icon: const Icon(Icons.phone),
                              label: const Text('Call'),
                            ),
                          ),
                        ],
                      ),
                      if (booking.status == BookingStatus.completed) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _openReview(context),
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Review Guest'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

extension on BookingDetailsBottomSheet {
  void _openReview(BuildContext context) {
    context.push(
      '/bidirectional-review/${booking.id}',
      extra: {
        'guestId': booking.guestId,
        'guestName': booking.guestName,
        'listingId': booking.propertyId,
        'listingTitle': booking.propertyTitle,
      },
    );
  }
}
