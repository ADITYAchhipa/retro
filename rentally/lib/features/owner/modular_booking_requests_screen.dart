import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/widgets/loading_states.dart';
import '../../widgets/responsive_layout.dart';
import '../../core/widgets/tab_back_handler.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/providers/ui_visibility_provider.dart';
import '../../services/booking_service.dart' as bs;
import '../../services/notification_service.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';
import '../../services/listing_service.dart' as ls;

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
  bool _isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();
  
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
          body: NestedScrollView(
            headerSliverBuilder: (context, inner) => [
              _buildSliverAppBar(),
            ],
            body: isBusy ? _buildLoadingState() : _buildContent(ownerBookings),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      toolbarHeight: 54,
      titleSpacing: 16,
      title: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        child: _isSearching
            ? _buildSearchPill(theme, isDark)
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      'Booking Requests',
                      style: (theme.textTheme.titleLarge ?? theme.textTheme.titleMedium)?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search_rounded, size: 22, color: isDark ? Colors.white70 : theme.primaryColor),
                    onPressed: () => setState(() => _isSearching = true),
                    tooltip: 'Search requests',
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      bottom: _isSearching
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: Container(
                width: double.infinity,
                color: theme.colorScheme.surface,
                child: _buildFilterTabs(),
              ),
            ),
    );
  }

  Widget _buildSearchPill(ThemeData theme, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
            blurRadius: 12,
            offset: const Offset(-6, -6),
          ),
          BoxShadow(
            color: (isDark
                    ? EnterpriseDarkTheme.primaryAccent
                    : EnterpriseLightTheme.primaryAccent)
                .withValues(alpha: isDark ? 0.2 : 0.15),
            blurRadius: 12,
            offset: const Offset(6, 6),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.search_rounded, size: 22, color: theme.colorScheme.primary),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
              decoration: InputDecoration(
                hintText: 'Search by guest, property or booking ID...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey[500],
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: theme.colorScheme.primary),
                onPressed: () {
                  if (_searchController.text.isNotEmpty) {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  } else {
                    setState(() => _isSearching = false);
                  }
                },
                tooltip: _searchController.text.isNotEmpty ? 'Clear' : 'Close search',
                padding: EdgeInsets.zero,
                iconSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bookings = ref.watch(bs.bookingProvider).ownerBookings;
    final pendingCount = bookings.where((b) => b.status == bs.BookingStatus.pending).length;
    final approvedCount = bookings.where((b) =>
      b.status == bs.BookingStatus.confirmed ||
      b.status == bs.BookingStatus.completed ||
      b.status == bs.BookingStatus.checkedIn ||
      b.status == bs.BookingStatus.checkedOut
    ).length;
    final rejectedCount = bookings.where((b) => b.status == bs.BookingStatus.cancelled).length;
    final items = [
      {'key': 'pending', 'label': 'Pending', 'count': pendingCount},
      {'key': 'approved', 'label': 'Approved', 'count': approvedCount},
      {'key': 'rejected', 'label': 'Rejected', 'count': rejectedCount},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              child: _wishlistStyleChip(
                label: items[i]['label'] as String,
                count: items[i]['count'] as int,
                selected: _selectedFilter == items[i]['key'],
                theme: theme,
                isDark: isDark,
                onTap: () => setState(() => _selectedFilter = items[i]['key'] as String),
              ),
            ),
            if (i != items.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _wishlistStyleChip({
    required String label,
    required int count,
    required bool selected,
    required ThemeData theme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AnimatedScale(
      scale: selected ? 1.0 : 0.98,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : (isDark ? theme.colorScheme.surface.withValues(alpha: 0.08) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : theme.colorScheme.outline.withValues(alpha: 0.2)),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                      blurRadius: 8,
                      offset: const Offset(-4, -4),
                    ),
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.10),
                      blurRadius: 8,
                      offset: const Offset(4, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: selected ? Colors.white : (isDark ? Colors.white70 : theme.colorScheme.onSurface),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: selected ? Colors.white : theme.colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
    final listing = _findListing(booking.listingId);
    final imageUrl = (listing?.images.isNotEmpty ?? false) ? listing!.images.first : null;
    final title = listing?.title ?? 'Listing #${booking.listingId}';
    final location = listing == null
        ? null
        : [listing.city, listing.state].where((s) => (s).toString().trim().isNotEmpty).join(', ');
    final nights = (booking.checkOut.difference(booking.checkIn).inDays).clamp(1, 365);
    final isPaid = booking.paymentInfo.isPaid;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey[200],
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey[200],
                            child: const Icon(Icons.home_rounded, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.home_rounded, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildStatusChip(_mapStatusLabel(booking.status)),
                        ],
                      ),
                      if (location != null && location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Guest: ${booking.userId} · Booking #${booking.id}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_formatDate(booking.checkIn)} - ${_formatDate(booking.checkOut)}  ·  $nights ${nights == 1 ? 'night' : 'nights'}',
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatPrice(booking.totalPrice),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaid ? Icons.verified_rounded : Icons.info_outline,
                          size: 14,
                          color: isPaid ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPaid ? 'Paid' : 'Unpaid',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isPaid ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Requested ${_formatTimeAgo(booking.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                if (booking.status == bs.BookingStatus.pending)
                  Text(
                    'Respond soon',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange[700], fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            if (booking.status == bs.BookingStatus.pending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRequest(booking),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
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

  ls.Listing? _findListing(String id) {
    final state = ref.read(ls.listingProvider);
    try {
      return state.listings.firstWhere((l) => l.id == id);
    } catch (_) {
      try {
        return state.userListings.firstWhere((l) => l.id == id);
      } catch (_) {
        return null;
      }
    }
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
    _searchFocusNode.dispose();
    super.dispose();
  }
}
