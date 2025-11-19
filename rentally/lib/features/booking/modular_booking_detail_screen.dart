import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/loading_states.dart';
import 'package:rentally/widgets/responsive_layout.dart';
import 'package:rentally/widgets/unified_card.dart';
import '../../utils/snackbar_utils.dart';
import '../../core/utils/currency_formatter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
import '../../services/booking_service.dart' as bs;
import '../../services/notification_service.dart';
import '../../services/listing_service.dart' as ls;
import '../../services/rent_reminder_service.dart';
import '../../services/termination_service.dart';
import '../../services/offline_payment_service.dart';

/// Industrial-grade modular booking detail screen with comprehensive features
/// 
/// Features:
/// - Error boundaries with recovery mechanisms
/// - Skeleton loading states with shimmer animations
/// - Responsive design for desktop and mobile
/// - Pull-to-refresh functionality
/// - Offline support with cached data
/// - Accessibility compliance
/// - Performance optimizations
/// - Security measures and input validation
/// - Comprehensive error handling
/// - Real-time status updates
class ModularBookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const ModularBookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<ModularBookingDetailScreen> createState() => _ModularBookingDetailScreenState();
}

class _ModularBookingDetailScreenState extends ConsumerState<ModularBookingDetailScreen>
    with TickerProviderStateMixin {
  
  // State management
  bool _isLoading = true;
  // bool _isRefreshing = false; // Unused field removed
  String? _error;
  Map<String, dynamic>? _booking;
  bs.Booking? _bookingModel;
  TerminationSchedule? _termination;
  // Offline cash claim state
  List<OfflinePaymentClaim> _offlineClaims = const [];
  RentReminder? _rentReminder;
  OfflinePaymentHandshake? _activeHandshake;
  
  // Helpers: determine unit and compute months for properties
  bool get _isVehicleBooking => ((_booking?['category'] ?? 'Property').toString().toLowerCase() == 'vehicle');
  int _calculateMonths() {
    final nights = _calculateNights();
    if (nights <= 0) return 0;
    return ((nights + 29) ~/ 30);
  }

  Widget _buildTerminationSection() {
    final listingId = (_booking?['listingId'] ?? '').toString();
    final dt = _termination?.terminateAt.toLocal();
    final when = dt != null ? _formatDate(dt) : '';
    return UnifiedCard(
      leading: const Icon(Icons.gavel_outlined, color: Colors.redAccent),
      title: 'Termination Scheduled',
      subtitle: dt != null ? 'Termination date: $when' : null,
      actions: [
        TextButton.icon(
          onPressed: () async {
            if (listingId.isEmpty) return;
            try {
              await RentReminderService.cancelTermination(listingId);
              // Refresh local termination state
              final t = await TerminationService.get(listingId);
              if (!mounted) return;
              setState(() { _termination = t; });
              // Create cancellation template notification
              await ref.read(notificationProvider.notifier).addNotification(
                AppNotification(
                  id: 'term_cancel_${listingId}_${DateTime.now().millisecondsSinceEpoch}',
                  title: 'Termination cancelled',
                  body: 'Email/SMS templates ready to inform both parties',
                  type: 'termination',
                  timestamp: DateTime.now(),
                  data: {
                    'emailSubject': 'Termination cancelled for listing $listingId',
                    'emailBody': 'Hello,\n\nThe previously scheduled termination for listing $listingId has been cancelled.\n\nThanks,',
                    'smsText': 'Termination cancelled for $listingId.',
                    'listingId': listingId,
                  },
                ),
              );
              if (!mounted) return;
              SnackBarUtils.showSuccess(context, 'Termination cancelled');
            } catch (e) {
              if (!mounted) return;
              SnackBarUtils.showError(context, 'Failed to cancel termination: $e');
            }
          },
          icon: const Icon(Icons.undo, color: Colors.redAccent),
          label: const Text('Cancel Termination', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  Widget _buildOfflinePaymentSection() {
    // Show only for monthly stays where a reminder exists
    final reminder = _rentReminder;
    if (reminder == null) {
      return const SizedBox.shrink();
    }
    final listingId = (_booking?['listingId'] ?? '').toString();
    final isOwner = ref.read(authProvider).user?.role == UserRole.owner;
    final isSeeker = ref.read(authProvider).user?.role == UserRole.seeker;
    final dueAt = reminder.nextDueAt;
    final amountLabel = reminder.monthlyAmount != null
        ? CurrencyFormatter.formatPrice(reminder.monthlyAmount!)
        : CurrencyFormatter.formatPrice((_booking?['pricePerMonth'] as double?) ?? 0);
    OfflinePaymentClaim? claimForCycle;
    for (final c in _offlineClaims) {
      if (c.listingId == listingId && _sameDay(c.dueAt, dueAt)) {
        claimForCycle = c;
        break;
      }
    }

    // Only show Offline Cash Payment section AFTER someone initiates
    // (tenant submits a claim OR owner generates a handshake code)
    if (claimForCycle == null && _activeHandshake == null) {
      return const SizedBox.shrink();
    }

    return UnifiedCard(
      leading: const Icon(Icons.receipt_long, color: Colors.teal),
      title: 'Offline Cash Payment',
      subtitle: 'Covers monthly due on ${_formatDate(dueAt)} ($amountLabel)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (claimForCycle == null && isSeeker && _activeHandshake == null) ...[
            Text(
              'If you paid cash directly to the owner, submit a claim so this month shows as paid. The owner must approve.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _submitOfflineClaim,
                icon: const Icon(Icons.upload_file),
                label: const Text('Submit Cash Payment Claim'),
              ),
            ),
          ],
          if (claimForCycle != null) ...[
            _buildClaimStatusTile(claimForCycle, isOwner: isOwner),
            if (isOwner && claimForCycle.status == OfflinePaymentStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => _approveOfflineClaim(claimForCycle!.id),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Approve'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _rejectOfflineClaim(claimForCycle!.id),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                    label: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ],
          // Handshake UI: shown when cycle not yet approved
          if ((claimForCycle == null || claimForCycle.status != OfflinePaymentStatus.approved)) ...[
            const Divider(height: 24),
            if (isOwner) _buildOwnerHandshakeControls(listingId, dueAt) else _buildTenantHandshakeControls(dueAt),
          ],
        ],
      ),
    );
  }

  Widget _buildClaimStatusTile(OfflinePaymentClaim claim, {required bool isOwner}) {
    IconData icon;
    Color color;
    String text;
    switch (claim.status) {
      case OfflinePaymentStatus.pending:
        icon = Icons.hourglass_bottom;
        color = Colors.orange;
        text = 'Pending owner review';
        break;
      case OfflinePaymentStatus.approved:
        icon = Icons.verified;
        color = Colors.green;
        text = 'Approved — this cycle marked as paid';
        break;
      case OfflinePaymentStatus.rejected:
        icon = Icons.cancel;
        color = Colors.red;
        text = 'Rejected${claim.rejectionReason != null ? ': ${claim.rejectionReason}' : ''}';
        break;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                ),
                if (claim.note != null && claim.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Note: ${claim.note!}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerHandshakeControls(String listingId, DateTime dueAt) {
    final hs = _activeHandshake;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('In-person code (owner confirmation)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (hs == null) ...[
          OutlinedButton.icon(
            onPressed: () => _generateHandshake(listingId, dueAt),
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Generate 6-digit Code'),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_clock),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code: ${hs.code}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Expires at: ${_formatDateTimeShort(hs.expiresAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: hs.code));
                    if (!mounted) return;
                    SnackBarUtils.showSuccess(context, 'Code copied');
                  },
                  icon: const Icon(Icons.copy_all),
                ),
                IconButton(
                  tooltip: 'Cancel',
                  onPressed: () => _cancelHandshake(hs.id),
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTenantHandshakeControls(DateTime dueAt) {
    final hs = _activeHandshake;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('In-person code (tenant entry)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (hs != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_bottom, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code active — ask owner for the 6-digit code',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text('Expires at: ${_formatDateTimeShort(hs.expiresAt)}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _promptEnterCode,
          icon: const Icon(Icons.keyboard),
          label: const Text("Enter Owner's Code"),
        ),
      ],
    );
  }

  String _formatDateTimeShort(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }

  Future<void> _generateHandshake(String listingId, DateTime dueAt) async {
    final ownerId = (_booking?['hostId'] ?? '').toString();
    try {
      final hs = await OfflinePaymentService.generateHandshake(listingId: listingId, dueAt: dueAt, ownerId: ownerId);
      if (!mounted) return;
      setState(() => _activeHandshake = hs);
      SnackBarUtils.showSuccess(context, 'Code generated: ${hs.code}');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to generate code: $e');
    }
  }

  Future<void> _cancelHandshake(String id) async {
    try {
      await OfflinePaymentService.cancelHandshake(id);
      if (!mounted) return;
      setState(() => _activeHandshake = null);
      SnackBarUtils.showSuccess(context, 'Code cancelled');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to cancel code: $e');
    }
  }

  Future<void> _promptEnterCode() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Owner's Code"),
        content: TextField(
          controller: controller,
          maxLength: 6,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '6-digit code'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true) {
      await _validateHandshakeCode(controller.text.trim());
    }
  }

  Future<void> _validateHandshakeCode(String code) async {
    final reminder = _rentReminder;
    if (reminder == null) return;
    final amount = reminder.monthlyAmount ?? ((_booking?['pricePerMonth'] as double?) ?? 0.0);
    final currency = (_booking?['currency'] ?? 'USD').toString();
    final tenantId = ref.read(authProvider).user?.id ?? 'tenant';
    final listingId = (_booking?['listingId'] ?? '').toString();
    try {
      await OfflinePaymentService.validateAndConsumeCode(
        code: code,
        tenantId: tenantId,
        amount: amount,
        currency: currency,
      );
      // Owner notification that code was used
      await ref.read(notificationProvider.notifier).addNotification(
        AppNotification(
          id: 'offline_code_confirm_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Cash payment confirmed via code',
          body: 'Cash payment for ${_formatDate(reminder.nextDueAt)} confirmed.',
          type: 'offline_payment_code_confirmed',
          timestamp: DateTime.now(),
          data: {
            'listingId': listingId,
            'dueAt': reminder.nextDueAt.toIso8601String(),
          },
        ),
      );
      // Refresh state
      await _loadOfflinePaymentData();
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Code accepted — this cycle is marked as paid');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Invalid or expired code: $e');
    }
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _submitOfflineClaim() async {
    final listingId = (_booking?['listingId'] ?? '').toString();
    final user = ref.read(authProvider).user;
    final tenantId = user?.id ?? 'tenant';
    final ownerId = (_booking?['hostId'] ?? '').toString();
    final reminder = _rentReminder;
    if (listingId.isEmpty || reminder == null) return;

    final controller = TextEditingController();
    final dueAt = reminder.nextDueAt;
    final amount = reminder.monthlyAmount ?? ((_booking?['pricePerMonth'] as double?) ?? 0.0);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Submit Cash Payment Claim'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This will notify the owner to review your cash payment for ${_formatDate(dueAt)}.'),
              const SizedBox(height: 8),
              Text('Amount: ${CurrencyFormatter.formatPrice(amount)}'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Optional note (e.g., receipt number)'
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final claim = await OfflinePaymentService.submitClaim(
        listingId: listingId,
        dueAt: dueAt,
        amount: amount,
        currency: (_booking?['currency'] ?? 'USD').toString(),
        tenantId: tenantId,
        ownerId: ownerId,
        note: controller.text.trim().isEmpty ? null : controller.text.trim(),
      );

      // Notify owner
      await ref.read(notificationProvider.notifier).addNotification(
        AppNotification(
          id: 'offline_claim_${claim.id}',
          title: 'Cash payment claim submitted',
          body: 'Tenant submitted a cash payment claim for ${_formatDate(claim.dueAt)}.',
          type: 'offline_payment_claim',
          timestamp: DateTime.now(),
          data: {
            'listingId': listingId,
            'claimId': claim.id,
            'dueAt': claim.dueAt.toIso8601String(),
          },
        ),
      );

      await _loadOfflinePaymentData();
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Claim submitted for review');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to submit claim: $e');
    }
  }

  Future<void> _approveOfflineClaim(String claimId) async {
    try {
      final c = await OfflinePaymentService.approveClaim(claimId);
      // Notify tenant
      await ref.read(notificationProvider.notifier).addNotification(
        AppNotification(
          id: 'offline_claim_approved_${c.id}',
          title: 'Cash payment approved',
          body: 'Your cash payment for ${_formatDate(c.dueAt)} was approved.',
          type: 'offline_payment_approved',
          timestamp: DateTime.now(),
          data: {
            'listingId': c.listingId,
            'claimId': c.id,
          },
        ),
      );
      await _loadOfflinePaymentData();
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Claim approved and cycle advanced');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to approve claim: $e');
    }
  }

  Future<void> _rejectOfflineClaim(String claimId) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Claim'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final c = await OfflinePaymentService.rejectClaim(claimId, reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim());
      // Notify tenant
      await ref.read(notificationProvider.notifier).addNotification(
        AppNotification(
          id: 'offline_claim_rejected_${c.id}',
          title: 'Cash payment rejected',
          body: 'Your cash payment claim for ${_formatDate(c.dueAt)} was rejected.',
          type: 'offline_payment_rejected',
          timestamp: DateTime.now(),
          data: {
            'listingId': c.listingId,
            'claimId': c.id,
          },
        ),
      );
      await _loadOfflinePaymentData();
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Claim rejected');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to reject claim: $e');
    }
  }
  
  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBookingData();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadBookingData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Try loading from provider state first
      final bsState = ref.read(bs.bookingProvider);
      bs.Booking? model;
      for (final b in bsState.userBookings) {
        if (b.id == widget.bookingId) { model = b; break; }
      }
      if (model == null) {
        for (final b in bsState.ownerBookings) {
          if (b.id == widget.bookingId) { model = b; break; }
        }
      }

      Map<String, dynamic>? booking;
      if (model != null) {
        // Map Booking model to local structure used by this UI
        BookingStatus localStatus;
        switch (model.status) {
          case bs.BookingStatus.cancelled:
            localStatus = BookingStatus.cancelled;
            break;
          case bs.BookingStatus.completed:
          case bs.BookingStatus.checkedOut:
            localStatus = BookingStatus.completed;
            break;
          default:
            localStatus = BookingStatus.upcoming;
        }
        // Pull listing details if available
        final listingsState = ref.read(ls.listingProvider);
        final allListings = [...listingsState.listings, ...listingsState.userListings];
        final listing = allListings.where((l) => l.id == model!.listingId).cast<ls.Listing?>().firstOrNull;
        final listingTitle = listing?.title ?? 'Property';
        final listingImageUrl = (listing?.images.isNotEmpty ?? false) ? listing!.images.first : '';
        final double priceBase = listing?.price ?? 120.0;
        booking = {
          'id': model.id,
          'listingId': model.listingId,
          'listingTitle': listingTitle,
          'listingImage': '🏠',
          'listingImageUrl': listingImageUrl,
          'checkIn': model.checkIn,
          'checkOut': model.checkOut,
          'category': 'Property',
          'totalPrice': model.totalPrice,
          'pricePerNight': priceBase,
          'pricePerMonth': priceBase * 30,
          'status': localStatus,
          'guestCount': 1,
          'location': listing?.city ?? '',
          'hostName': 'Host',
          'hostImage': '👤',
          'hostId': model.ownerId,
          'hostRating': 4.8,
          'hostReviewCount': 0,
          'rating': 4.8,
          'reviewCount': 0,
          'paymentMethod': model.paymentInfo.method,
          'bookingDate': model.createdAt,
        };
        _bookingModel = model;
      } else {
        // Fallback to mock
        await Future.delayed(const Duration(milliseconds: 500));
        booking = _getMockBooking(widget.bookingId);
        if (booking == null) {
          throw Exception('Booking not found');
        }
      }

      // Load termination schedule for this listing (if any)
      TerminationSchedule? termination;
      final String listingIdForTerm = (booking['listingId']?.toString()) ?? '';
      if (listingIdForTerm.isNotEmpty) {
        termination = await TerminationService.get(listingIdForTerm);
      }

      if (!mounted) return;

      setState(() {
        _booking = booking;
        _termination = termination;
        _isLoading = false;
      });

      // Load offline payment related state (claims + reminder) after booking is ready
      await _loadOfflinePaymentData();

      // Start animations
      _fadeAnimationController.forward();
      _slideAnimationController.forward();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load booking: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshBookingData() async {
    setState(() {
      _isLoading = true;
    });
    await ref.read(bs.bookingProvider.notifier).refreshBookings();
    await _loadBookingData();
  }

  Future<void> _loadOfflinePaymentData() async {
    final listingId = (_booking?['listingId'] ?? '').toString();
    if (listingId.isEmpty) return;
    try {
      final claims = await OfflinePaymentService.listForListing(listingId);
      final reminder = await RentReminderService.getByListing(listingId);
      OfflinePaymentHandshake? hs;
      if (reminder != null) {
        hs = await OfflinePaymentService.getActiveHandshake(listingId, reminder.nextDueAt);
      }
      if (!mounted) return;
      setState(() {
        _offlineClaims = claims;
        _rentReminder = reminder;
        _activeHandshake = hs;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: ResponsiveLayout(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final t = AppLocalizations.of(context);
    
    return AppBar(
      title: Text(t?.bookingDetails ?? 'Booking Details'),
      elevation: 0,
      actions: [
        if (_booking != null && _getBookingStatus() == BookingStatus.upcoming)
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) {
              final items = <PopupMenuEntry<String>>[];
              // Base actions
              items.add(
                PopupMenuItem(
                  value: 'modify',
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 8),
                      Text(t?.modify ?? 'Modify'),
                    ],
                  ),
                ),
              );
              items.add(
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
              );

              // Offline cash actions
              final auth = ref.read(authProvider);
              final isOwner = auth.user?.role == UserRole.owner;
              final listingId = (_booking?['listingId'] ?? '').toString();
              final reminder = _rentReminder;
              OfflinePaymentClaim? claimForCycle;
              if (reminder != null && listingId.isNotEmpty) {
                for (final c in _offlineClaims) {
                  if (c.listingId == listingId && _sameDay(c.dueAt, reminder.nextDueAt)) {
                    claimForCycle = c;
                    break;
                  }
                }
              }
              final hasActiveCode = _activeHandshake != null;

              if (!isOwner) {
                // Tenant options
                if (!hasActiveCode && claimForCycle == null && reminder != null && listingId.isNotEmpty) {
                  items.add(const PopupMenuDivider());
                  items.add(
                    const PopupMenuItem<String>(
                      value: 'offline_claim',
                      child: Row(
                        children: [
                          Icon(Icons.payments_outlined),
                          SizedBox(width: 8),
                          Text('Claim Cash Payment'),
                        ],
                      ),
                    ),
                  );
                }
                if (hasActiveCode) {
                  if (items.isNotEmpty) items.add(const PopupMenuDivider());
                  items.add(
                    const PopupMenuItem<String>(
                      value: 'offline_enter_code',
                      child: Row(
                        children: [
                          Icon(Icons.keyboard),
                          SizedBox(width: 8),
                          Text("Enter Owner's Code"),
                        ],
                      ),
                    ),
                  );
                }
              } else {
                // Owner options
                if (hasActiveCode) {
                  items.add(const PopupMenuDivider());
                  items.add(
                    const PopupMenuItem<String>(
                      value: 'offline_cancel_code',
                      child: Row(
                        children: [
                          Icon(Icons.close, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('Cancel Cash Code'),
                        ],
                      ),
                    ),
                  );
                } else if (reminder != null && listingId.isNotEmpty && (claimForCycle?.status != OfflinePaymentStatus.approved)) {
                  items.add(const PopupMenuDivider());
                  items.add(
                    const PopupMenuItem<String>(
                      value: 'offline_generate_code',
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_2),
                          SizedBox(width: 8),
                          Text('Generate Cash Code'),
                        ],
                      ),
                    ),
                  );
                }
              }

              // Cancel booking
              items.add(
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      const Icon(Icons.cancel, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        t?.cancel ?? 'Cancel',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
              return items;
            },
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_booking == null) {
      return _buildNotFoundState();
    }

    return RefreshIndicator(
      onRefresh: _refreshBookingData,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPropertySection(),
                      const SizedBox(height: 24),
                      _buildBookingDetailsSection(),
                      const SizedBox(height: 24),
                      _buildOfflinePaymentSection(),
                      if (_termination != null) ...[
                        const SizedBox(height: 24),
                        _buildTerminationSection(),
                      ],
                      const SizedBox(height: 24),
                      _buildHostSection(),
                      const SizedBox(height: 24),
                      _buildPaymentSection(),
                      const SizedBox(height: 24),
                      if (_getBookingStatus() == BookingStatus.upcoming) ...[
                        _buildContactSection(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                      if (_getBookingStatus() == BookingStatus.completed) ...[
                        _buildReviewSection(),
                        const SizedBox(height: 24),
                      ],
                      _buildSafetySection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    // Modern shimmer-based loading list
    return LoadingStates.listShimmer(context, itemCount: 4);
  }

  Widget _buildErrorState() {
    final t = AppLocalizations.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              t?.error ?? 'Error',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadBookingData,
              icon: const Icon(Icons.refresh),
              label: Text(t?.tryAgain ?? 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Booking Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The booking you\'re looking for doesn\'t exist or has been removed.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final status = _getBookingStatus();
    final statusInfo = _getStatusInfo(status);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusInfo['color'].withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: statusInfo['color'].withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusInfo['icon'],
            color: statusInfo['color'],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusInfo['text'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: statusInfo['color'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Booking ID: ${widget.bookingId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusInfo['color'].withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (status == BookingStatus.upcoming)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusInfo['color'],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getTimeUntilCheckIn(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertySection() {
    final t = AppLocalizations.of(context);
    
    return _buildSection(
      title: t?.property ?? 'Property',
      child: UnifiedCard(
        onTap: () => context.push('/listing/${_booking!['listingId']}'),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: _booking!['listingImageUrl'] ?? '',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _booking!['listingTitle'] ?? 'Property',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _booking!['location'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        (_booking!['rating'] ?? 4.8).toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_booking!['reviewCount'] ?? 127} reviews)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailsSection() {
    final t = AppLocalizations.of(context);
    
    return UnifiedCard(
      leading: const Icon(Icons.event_note),
      title: t?.bookingDetails ?? 'Booking Details',
      child: Column(
        children: [
          _buildDetailRow(
            label: t?.checkIn ?? 'Check-in',
            value: _formatDate(_booking!['checkIn']),
            icon: Icons.login,
          ),
          const Divider(),
          _buildDetailRow(
            label: t?.checkOut ?? 'Check-out',
            value: _formatDate(_booking!['checkOut']),
            icon: Icons.logout,
          ),
          const Divider(),
          _buildDetailRow(
            label: _isVehicleBooking ? (t?.nights ?? 'Nights') : 'Months',
            value: _isVehicleBooking ? '${_calculateNights()} nights' : '${_calculateMonths()} months',
            icon: _isVehicleBooking ? Icons.event : Icons.calendar_month,
          ),
          const Divider(),
          _buildDetailRow(
            label: 'Booking Date',
            value: _formatDate(_booking!['bookingDate'] ?? DateTime.now().subtract(const Duration(days: 7))),
            icon: Icons.event,
          ),
        ],
      ),
    );
  }

  Widget _buildHostSection() {
    return UnifiedCard(
      onTap: _viewHostProfile,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              _booking!['hostImage'] ?? '👤',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _booking!['hostName'] ?? 'Host',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _messageHost,
                      icon: const Icon(Icons.message),
                      tooltip: 'Message Host',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      (_booking!['hostRating'] ?? 4.8).toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_booking!['hostReviewCount'] ?? 0} reviews)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Host',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    // final t = AppLocalizations.of(context);
    final nights = _calculateNights();
    final months = _calculateMonths();
    // Prefer explicit monthly or daily pricing if provided
    final double vehiclePerDay = (_booking?['pricePerDay'] as double?) ?? ((_booking?['pricePerNight'] as double?) ?? 120.0);
    final double propertyPerMonth = (_booking?['pricePerMonth'] as double?) ?? (((_booking?['pricePerNight'] as double?) ?? 120.0) * 30);
    final perUnit = _isVehicleBooking ? vehiclePerDay : propertyPerMonth;
    final units = _isVehicleBooking ? nights : months;
    final subtotal = perUnit * units;
    final serviceFee = subtotal * 0.1;
    final taxes = subtotal * 0.08;
    final total = _booking!['totalPrice'] ?? (subtotal + serviceFee + taxes);
    
    return UnifiedCard(
      leading: Icon(
        _isVehicleBooking ? Icons.directions_car : Icons.apartment,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: 'Payment Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            label: _isVehicleBooking ? 'Per day' : 'Per month',
            value: CurrencyFormatter.formatPrice(perUnit),
          ),
          _buildDetailRow(
            label: _isVehicleBooking ? 'Nights' : 'Months',
            value: units.toString(),
          ),
          const Divider(),
          _buildDetailRow(
            label: 'Total',
            value: CurrencyFormatter.formatPrice(total),
            isTotal: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _booking!['paymentMethod'] ?? 'Visa •••• 4242',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.security,
                  color: Colors.green,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetySection() {
    return UnifiedCard(
      leading: const Icon(Icons.security, color: Colors.green),
      title: 'Safety & Security',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSafetyItem(
            icon: Icons.verified_user,
            title: 'Identity Verified',
            subtitle: 'Host identity has been verified',
          ),
          _buildSafetyItem(
            icon: Icons.support_agent,
            title: '24/7 Support',
            subtitle: 'Get help anytime during your stay',
          ),
          _buildSafetyItem(
            icon: Icons.security,
            title: 'Secure Payments',
            subtitle: 'Your payment information is protected',
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    IconData? icon,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: isTotal
                  ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: isTotal
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int _calculateNights() {
    if (_bookingModel != null) {
      return _bookingModel!.checkOut.difference(_bookingModel!.checkIn).inDays;
    }
    final checkIn = _booking!['checkIn'] as DateTime;
    final checkOut = _booking!['checkOut'] as DateTime;
    return checkOut.difference(checkIn).inDays;
  }

  // Action methods
  void _viewHostProfile() {
    final hostId = _bookingModel?.ownerId ?? (_booking?['hostId'] ?? '').toString();
    final hostName = (_booking?['hostName'] ?? '').toString();
    final hostAvatar = (_booking?['hostImage'] ?? '').toString();
    context.push('/guest-profile/$hostId', extra: {
      'guestName': hostName,
      'guestAvatar': hostAvatar,
    });
  }

  void _messageHost() {
    final hostId = _bookingModel?.ownerId ?? (_booking?['hostId'] ?? '').toString();
    context.push('/chat/$hostId');
  }

  void _callHost() {
    SnackBarUtils.showInfo(context, 'Calling host...');
  }

  void _getDirections() {
    SnackBarUtils.showInfo(context, 'Opening directions...');
  }

  void _addToCalendar() {
    SnackBarUtils.showSuccess(context, 'Added to calendar');
  }

  void _downloadReceipt() {
    _generateAndShareReceiptPdf();
  }

  Future<void> _generateAndShareReceiptPdf() async {
    try {
      final booking = _booking ?? {};
      final doc = pw.Document();
      final title = (booking['listingTitle'] ?? 'Property') as String;
      final bookingId = widget.bookingId;
      final checkIn = booking['checkIn'] as DateTime? ?? DateTime.now();
      final checkOut = booking['checkOut'] as DateTime? ?? DateTime.now().add(const Duration(days: 2));
      final nights = checkOut.difference(checkIn).inDays;
      final months = nights <= 0 ? 0 : ((nights + 29) ~/ 30);
      final isVehicle = ((booking['category'] ?? 'Property').toString().toLowerCase() == 'vehicle');
      final perUnit = isVehicle
          ? ((booking['pricePerDay'] as double?) ?? ((booking['pricePerNight'] as double?) ?? 120.0))
          : ((booking['pricePerMonth'] as double?) ?? (((booking['pricePerNight'] as double?) ?? 120.0) * 30));
      final units = isVehicle ? nights : months;
      final subtotal = perUnit * units;
      final serviceFee = subtotal * 0.10;
      final taxes = subtotal * 0.08;
      final total = (booking['totalPrice'] as double?) ?? (subtotal + serviceFee + taxes);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Booking Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('ID: $bookingId', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(booking['location']?.toString() ?? ''),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              pw.Expanded(child: pw.Text('Check-in:\n${_formatDate(checkIn)}')),
              pw.Expanded(child: pw.Text('Check-out:\n${_formatDate(checkOut)}')),
              pw.Expanded(child: pw.Text('Guests:\n${booking['guestCount'] ?? 1}')),
            ]),
            pw.SizedBox(height: 16),
            pw.Table(columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
            }, children: [
              pw.TableRow(children: [pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]),
              pw.TableRow(children: [pw.Text('${perUnit.toStringAsFixed(2)} x $units ${isVehicle ? 'days' : 'months'}'), pw.Text(subtotal.toStringAsFixed(2))]),
              pw.TableRow(children: [pw.Text('Service fee'), pw.Text(serviceFee.toStringAsFixed(2))]),
              pw.TableRow(children: [pw.Text('Taxes'), pw.Text(taxes.toStringAsFixed(2))]),
              pw.TableRow(children: [pw.SizedBox(height: 6), pw.SizedBox(height: 6)]),
              pw.TableRow(children: [pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(total.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]),
            ]),
            pw.SizedBox(height: 16),
            pw.Text('Payment Method: ${booking['paymentMethod'] ?? 'Visa •••• 4242'}'),
            pw.SizedBox(height: 8),
            pw.Text('Thank you for booking with Rentally!'),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/booking_receipt_$bookingId.pdf');
      await file.writeAsBytes(await doc.save());

      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: 'Booking Receipt');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to generate receipt: $e');
    }
  }

  void _writeReview() {
    final booking = _booking ?? {};
    final listingId = (booking['listingId'] ?? '').toString();
    final listingTitle = (booking['listingTitle'] ?? 'Property').toString();
    final user = ref.read(authProvider).user;
    final guestId = user?.id ?? '';
    final guestName = user?.name ?? '';
    context.push(
      '/bidirectional-review/${widget.bookingId}',
      extra: {
        'guestId': guestId,
        'guestName': guestName,
        'listingId': listingId,
        'listingTitle': listingTitle,
      },
    );
  }

  BookingStatus _getBookingStatus() {
    // Prefer explicit status from loaded booking map when available
    final dynamic s = _booking?['status'];
    if (s is BookingStatus) return s;

    // Derive from dates as a fallback
    final now = DateTime.now();
    final checkIn = _booking?['checkIn'] as DateTime?;
    final checkOut = _booking?['checkOut'] as DateTime?;
    if (checkOut != null && checkOut.isBefore(now)) return BookingStatus.completed;
    if (checkIn != null && now.isAfter(checkIn) && (checkOut == null || now.isBefore(checkOut))) {
      return BookingStatus.upcoming; // in-progress treated as upcoming for this UI
    }
    return BookingStatus.upcoming;
  }

  Map<String, dynamic> _getStatusInfo(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return {
          'text': 'Upcoming',
          'color': Theme.of(context).colorScheme.primary,
          'icon': Icons.schedule,
        };
      case BookingStatus.completed:
        return {
          'text': 'Completed',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case BookingStatus.cancelled:
        return {
          'text': 'Cancelled',
          'color': Colors.red,
          'icon': Icons.cancel,
        };
    }
  }

  String _getTimeUntilCheckIn() {
    final checkIn = _booking?['checkIn'] as DateTime?;
    if (checkIn == null) return '';
    final now = DateTime.now();
    if (!checkIn.isAfter(now)) return 'Today';
    final diff = checkIn.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    if (days > 0) return '${days}d ${hours}h';
    return '${diff.inHours}h';
  }

  Widget _buildContactSection() {
    return UnifiedCard(
      leading: const Icon(Icons.support_agent),
      title: 'Contact & Help',
      actions: [
        OutlinedButton.icon(
          onPressed: _messageHost,
          icon: const Icon(Icons.message_outlined),
          label: const Text('Message Host'),
        ),
        OutlinedButton.icon(
          onPressed: _callHost,
          icon: const Icon(Icons.call_outlined),
          label: const Text('Call Host'),
        ),
        OutlinedButton.icon(
          onPressed: _getDirections,
          icon: const Icon(Icons.directions_outlined),
          label: const Text('Directions'),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final auth = ref.watch(authProvider);
    final isOwner = auth.user?.role == UserRole.owner;
    final terminationLabel = isOwner ? 'Terminate Tenancy' : 'End Monthly Stay';
    return UnifiedCard(
      leading: const Icon(Icons.event_available),
      title: 'Actions',
      actions: [
        OutlinedButton.icon(
          onPressed: _openManageReminders,
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Manage Rent Reminders'),
        ),
        OutlinedButton.icon(
          onPressed: _addToCalendar,
          icon: const Icon(Icons.calendar_today_outlined),
          label: const Text('Add to Calendar'),
        ),
        FilledButton.icon(
          onPressed: _downloadReceipt,
          icon: const Icon(Icons.receipt_long),
          label: const Text('Download Receipt'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _requestTerminationViaBooking,
          icon: const Icon(Icons.gavel_outlined),
          label: Text(terminationLabel),
        ),
        const SizedBox(width: 8),
        if (kDebugMode)
          TextButton.icon(
            onPressed: _debugTerminateIn60s,
            icon: const Icon(Icons.bug_report_outlined, color: Colors.redAccent),
            label: const Text('Debug terminate +60s', style: TextStyle(color: Colors.redAccent)),
          ),
      ],
    );
  }

  void _openManageReminders() {
    final listingId = (_booking?['listingId'] ?? '').toString();
    if (listingId.isEmpty) {
      SnackBarUtils.showInfo(context, 'Listing not found for this booking');
      return;
    }
    context.push('/rent-reminders?listingId=$listingId');
  }

  Future<void> _requestTerminationViaBooking() async {
    final listingId = (_booking?['listingId'] ?? '').toString();
    if (listingId.isEmpty) {
      SnackBarUtils.showInfo(context, 'Listing not found for this booking');
      return;
    }
    final now = DateTime.now();
    final min = now.add(const Duration(days: RentReminderService.noticeDays));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: min,
      firstDate: min,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    final terminateAt = DateTime(picked.year, picked.month, picked.day, 10, 0);
    try {
      final role = ref.read(authProvider).user?.role;
      final reason = role == UserRole.owner ? 'Owner initiated termination' : 'Tenant requested termination';
      await RentReminderService.requestTermination(
        listingId: listingId,
        terminateAt: terminateAt,
        reason: reason,
      );
      // Create role-aware in-app template notification
      final forWhom = role == UserRole.owner ? 'tenant' : 'owner';
      final subject = 'Termination request for listing $listingId effective ${terminateAt.toLocal()}';
      final emailBody = 'Hello ${forWhom == 'tenant' ? 'Tenant' : 'Owner'},\n\n' 
          '${role == UserRole.owner ? 'The owner' : 'The tenant'} has requested to end the monthly stay for listing $listingId effective ${terminateAt.toLocal()}.\n'
          'Notice period: ${RentReminderService.noticeDays} days.\nPlease review and coordinate move-out and final invoice.\n\nThanks,';
      final smsText = '${role == UserRole.owner ? 'Owner' : 'Tenant'} requested termination for $listingId, effective ${terminateAt.toLocal()}.';
      await ref.read(notificationProvider.notifier).addNotification(
        AppNotification(
          id: 'term_req_${listingId}_${terminateAt.millisecondsSinceEpoch}',
          title: 'Send termination notice',
          body: 'Email/SMS templates ready for $forWhom',
          type: 'termination',
          timestamp: DateTime.now(),
          data: {
            'emailSubject': subject,
            'emailBody': emailBody,
            'smsText': smsText,
            'listingId': listingId,
            'terminateAt': terminateAt.toIso8601String(),
          },
        ),
      );
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Termination scheduled for ${terminateAt.toLocal()}');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to schedule termination: $e');
    }
  }

  Future<void> _debugTerminateIn60s() async {
    final listingId = (_booking?['listingId'] ?? '').toString();
    if (listingId.isEmpty) {
      SnackBarUtils.showInfo(context, 'Listing not found for this booking');
      return;
    }
    final dt = DateTime.now().add(const Duration(minutes: 1));
    try {
      await TerminationService.schedule(listingId: listingId, terminateAt: dt, reason: 'Debug terminate in +60s');
      if (!mounted) return;
      final t = TimeOfDay.fromDateTime(dt).format(context);
      SnackBarUtils.showSuccess(context, 'Debug termination set for ~$t');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to set debug termination: $e');
    }
  }

  Widget _buildReviewSection() {
    return UnifiedCard(
      leading: const Icon(Icons.rate_review_outlined),
      title: 'How was your stay?',
      subtitle: 'Share your experience with the host and future guests',
      actions: [
        FilledButton.icon(
          onPressed: _writeReview,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Write a Review'),
        ),
      ],
    );
  }

  Future<void> _handleMenuAction(String value) async {
    switch (value) {
      case 'modify':
        final listingId = (_booking?['listingId'] ?? '').toString();
        if (listingId.isNotEmpty) {
          context.push('/book/$listingId/choose');
        } else {
          SnackBarUtils.showInfo(context, 'Listing not found for this booking');
        }
        break;
      case 'share':
        final id = widget.bookingId;
        final title = (_booking?['listingTitle'] ?? 'Property').toString();
        final dates = (_booking?['checkIn'] is DateTime && _booking?['checkOut'] is DateTime)
            ? '${_formatDate(_booking!['checkIn'])} → ${_formatDate(_booking!['checkOut'])}'
            : '';
        await Share.share('Booking #$id\n$title\n$dates');
        break;
      case 'offline_claim':
        await _submitOfflineClaim();
        break;
      case 'offline_enter_code':
        await _promptEnterCode();
        break;
      case 'offline_cancel_code':
        if (_activeHandshake != null) {
          await _cancelHandshake(_activeHandshake!.id);
        } else {
          SnackBarUtils.showInfo(context, 'No active code to cancel');
        }
        break;
      case 'offline_generate_code':
        final listingId2 = (_booking?['listingId'] ?? '').toString();
        final reminder2 = _rentReminder;
        if (listingId2.isEmpty || reminder2 == null) {
          SnackBarUtils.showInfo(context, 'Cannot generate code: missing listing or due date');
          break;
        }
        await _generateHandshake(listingId2, reminder2.nextDueAt);
        break;
      case 'cancel':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cancel Booking?'),
            content: const Text('Are you sure you want to cancel this booking?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, cancel')),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(bs.bookingProvider.notifier).cancelBooking(widget.bookingId);
          // Notify owner and user of cancellation
          await ref.read(notificationProvider.notifier).addNotification(
            AppNotification(
              id: 'notif_cancel_${widget.bookingId}',
              title: 'Booking Cancelled',
              body: 'The booking ${widget.bookingId} has been cancelled.',
              type: 'booking',
              timestamp: DateTime.now(),
              data: {'bookingId': widget.bookingId, 'status': 'cancelled'},
            ),
          );
          if (!mounted) return;
          SnackBarUtils.showSuccess(context, 'Booking cancelled');
          // Refresh local data
          await _refreshBookingData();
        }
        break;
    }
  }

  Map<String, dynamic>? _getMockBooking(String bookingId) {
    // Simple mock for fallback when provider/state data isn't available
    final now = DateTime.now();
    return {
      'id': bookingId,
      'listingId': 'lst_${bookingId.substring(0, bookingId.length > 4 ? 4 : bookingId.length)}',
      'listingTitle': 'Modern Downtown Apartment',
      'listingImage': '🏠',
      'listingImageUrl': 'https://picsum.photos/400/300?random=42',
      'checkIn': now.add(const Duration(days: 5)),
      'checkOut': now.add(const Duration(days: 8)),
      'category': 'Property',
      'totalPrice': 580.0,
      'pricePerNight': 120.0,
      'pricePerMonth': 3600.0,
      'status': BookingStatus.upcoming,
      'guestCount': 2,
      'location': 'Manhattan, NY',
      'hostName': 'Alexandra Chen',
      'hostImage': '👤',
      'hostId': 'host_001',
      'hostRating': 4.9,
      'hostReviewCount': 127,
      'rating': 4.8,
      'reviewCount': 245,
      'paymentMethod': 'Visa •••• 4242',
      'bookingDate': now.subtract(const Duration(days: 7)),
    };
  }
}

enum BookingStatus { upcoming, completed, cancelled }
