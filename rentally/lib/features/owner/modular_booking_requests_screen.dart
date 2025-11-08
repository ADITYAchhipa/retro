import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/loading_states.dart';
import '../../widgets/responsive_layout.dart';
import '../../core/widgets/tab_back_handler.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/providers/ui_visibility_provider.dart';
import '../../services/booking_service.dart' as bs;
import '../../services/notification_service.dart';

/// Modular Booking Requests Screen with Industrial-Grade Features
class ModularBookingRequestsScreen extends ConsumerStatefulWidget {
  const ModularBookingRequestsScreen({super.key});

  @override
  ConsumerState<ModularBookingRequestsScreen> createState() =>
      _ModularBookingRequestsScreenState();
}

class _ModularBookingRequestsScreenState
    extends ConsumerState<ModularBookingRequestsScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'pending';
  String _searchQuery = '';
  
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  
  // We use provider-backed bookings; no local mock list

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadRequests();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      await ref.read(bs.bookingProvider.notifier).refreshBookings();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load requests: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bs.bookingProvider);
    final ownerBookings = bookingState.ownerBookings;
    final isBusy = bookingState.isLoading || _isLoading;
    return ResponsiveLayout(
      maxWidth: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: TabBackHandler(
        child: Scaffold(
          appBar: _buildAppBar(),
          body: isBusy ? _buildLoadingState() : _buildContent(ownerBookings),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Booking Requests',
        style: (theme.textTheme.titleLarge ?? theme.textTheme.titleMedium)?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          height: 1.0,
        ),
      ),
      toolbarHeight: 44,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      actionsIconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      flexibleSpace: null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(105),
        child: Container(
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              _buildSearchBar(),
              _buildFilterTabs(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by guest or property...',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final theme = Theme.of(context);
    final bookings = ref.watch(bs.bookingProvider).ownerBookings;
    final pendingCount = bookings.where((b) => b.status == bs.BookingStatus.pending).length;
    final approvedCount = bookings.where((b) =>
      b.status == bs.BookingStatus.confirmed ||
      b.status == bs.BookingStatus.completed ||
      b.status == bs.BookingStatus.checkedIn ||
      b.status == bs.BookingStatus.checkedOut
    ).length;
    final rejectedCount = bookings.where((b) => b.status == bs.BookingStatus.cancelled).length;
    final filters = [
      {'key': 'pending', 'label': 'Pending', 'count': pendingCount},
      {'key': 'approved', 'label': 'Approved', 'count': approvedCount},
      {'key': 'rejected', 'label': 'Rejected', 'count': rejectedCount},
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['key'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${filter['label']} (${filter['count']})'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter['key'] as String);
              },
              showCheckmark: true,
              selectedColor: theme.colorScheme.primary.withOpacity(0.12),
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              side: BorderSide(color: theme.colorScheme.outline.withOpacity(isSelected ? 0.0 : 0.3)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(List<bs.Booking> ownerBookings) {
    if (_error != null) {
      return _buildErrorState();
    }

    final filteredRequests = _getFilteredRequests(ownerBookings);

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _loadRequests,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: filteredRequests.isEmpty
            ? _buildEmptyState()
            : _buildRequestsList(filteredRequests),
      ),
    );
  }

  Widget _buildLoadingState() {
    return LoadingStates.listShimmer(context, itemCount: 6);
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error Loading Requests',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64),
            const SizedBox(height: 16),
            Text(
              'No Requests Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'New booking requests will appear here',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<bs.Booking> requests) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 88;
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPad),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final booking = requests[index];
        return _buildRequestCard(booking);
      },
    );
  }

  Widget _buildRequestCard(bs.Booking booking) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest: ${booking.userId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Booking #${booking.id}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                _buildStatusChip(_mapStatusLabel(booking.status)),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 16, color: theme.colorScheme.outline.withOpacity(0.12)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.home_work_outlined, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Listing: ${booking.listingId}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${_formatDate(booking.checkIn)} - ${_formatDate(booking.checkOut)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          CurrencyFormatter.formatPrice(booking.totalPrice),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.green[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Optional: could show guest message if present in future
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Requested ${_formatTimeAgo(booking.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (booking.status == bs.BookingStatus.pending)
                  Text(
                    'Respond soon',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            if (booking.status == bs.BookingStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRequest(booking),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(booking),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _viewGuestProfile(booking),
                  icon: const Icon(Icons.person, size: 16),
                  label: const Text('Profile'),
                ),
                TextButton.icon(
                  onPressed: () => _contactGuest(booking),
                  icon: const Icon(Icons.message, size: 16),
                  label: const Text('Message'),
                ),
                TextButton.icon(
                  onPressed: () => _viewRequestDetails(booking),
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Map BookingStatus to display label used by _buildStatusChip
  String _mapStatusLabel(bs.BookingStatus status) {
    switch (status) {
      case bs.BookingStatus.pending:
        return 'pending';
      case bs.BookingStatus.confirmed:
      case bs.BookingStatus.checkedIn:
      case bs.BookingStatus.checkedOut:
      case bs.BookingStatus.completed:
        return 'approved';
      case bs.BookingStatus.cancelled:
        return 'rejected';
    }
  }

  // Filter owner bookings based on selected filter and search query
  List<bs.Booking> _getFilteredRequests(List<bs.Booking> bookings) {
    final filtered = bookings.where((b) {
      final matchesFilter = () {
        switch (_selectedFilter) {
          case 'pending':
            return b.status == bs.BookingStatus.pending;
          case 'approved':
            return b.status == bs.BookingStatus.confirmed ||
                   b.status == bs.BookingStatus.completed ||
                   b.status == bs.BookingStatus.checkedIn ||
                   b.status == bs.BookingStatus.checkedOut;
          case 'rejected':
            return b.status == bs.BookingStatus.cancelled;
          default:
            return true;
        }
      }();
      if (!matchesFilter) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.userId.toLowerCase().contains(q) || b.listingId.toLowerCase().contains(q) || b.id.toLowerCase().contains(q);
    }).toList();
    return filtered;
  }

  Future<void> _approveRequest(bs.Booking booking) async {
    final noteCtrl = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Optionally include a note for the guest:'),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Looking forward to hosting you!',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => context.pop(true), child: const Text('Approve')),
        ],
      ),
    );
    if (submit == true) {
      await ref.read(bs.bookingProvider.notifier).updateBookingStatus(booking.id, bs.BookingStatus.confirmed);
      final note = noteCtrl.text.trim();
      // Notify guest
      await ref.read(notificationProvider.notifier).addNotification(
        AppNotification(
          id: 'notif_approve_${booking.id}',
          title: 'Request Approved',
          body: 'Your booking request for listing ${booking.listingId} was approved.${note.isNotEmpty ? ' Note: $note' : ''}',
          type: 'booking',
          timestamp: DateTime.now(),
          data: {'bookingId': booking.id, 'status': 'confirmed'},
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request approved')),
        );
      }
    }
  }

  Future<void> _rejectRequest(bs.Booking booking) async {
    final reasonCtrl = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Optionally provide a reason for declining this request:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Dates unavailable',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => context.pop(true), child: const Text('Decline', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (submit == true) {
      await ref.read(bs.bookingProvider.notifier).updateBookingStatus(booking.id, bs.BookingStatus.cancelled);
      await ref.read(notificationProvider.notifier).addNotification(
        AppNotification(
          id: 'notif_decline_${booking.id}',
          title: 'Request Declined',
          body: 'Your booking request for listing ${booking.listingId} was declined.${reasonCtrl.text.trim().isNotEmpty ? ' Reason: ${reasonCtrl.text.trim()}' : ''}',
          type: 'booking',
          timestamp: DateTime.now(),
          data: {'bookingId': booking.id, 'status': 'cancelled'},
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request declined')),
        );
      }
    }
  }

  void _viewGuestProfile(bs.Booking booking) {
    final guestId = booking.userId;
    ref.read(immersiveRouteOpenProvider.notifier).state = true;
    context.push('/guest-profile/$guestId').whenComplete(() {
      if (!mounted) return;
      ref.read(immersiveRouteOpenProvider.notifier).state = false;
    });
  }

  void _contactGuest(bs.Booking booking) {
    final chatId = booking.id;
    context.push('/chat/$chatId', extra: {
      'requestId': booking.id,
      'guestName': booking.userId,
    });
  }

  void _viewRequestDetails(bs.Booking booking) {
    final id = booking.id;
    context.push('/booking-history/$id');
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        icon = Icons.schedule;
        break;
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Declined';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
