import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/rent_reminder_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../services/termination_service.dart';
import '../../services/notification_service.dart';

class RentRemindersManageScreen extends ConsumerStatefulWidget {
  final String? filterListingId;
  const RentRemindersManageScreen({super.key, this.filterListingId});

  @override
  ConsumerState<RentRemindersManageScreen> createState() => _RentRemindersManageScreenState();
}

class _RentRemindersManageScreenState extends ConsumerState<RentRemindersManageScreen> {
  bool _loading = true;
  String? _error;
  List<RentReminder> _reminders = const [];
  Map<String, TerminationSchedule> _terminationMap = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _shouldShowBanner() {
    if (_reminders.isEmpty) return false;
    if (widget.filterListingId != null) {
      return _terminationMap.containsKey(widget.filterListingId);
    }
    // show banner if any reminder has a termination
    for (final r in _reminders) {
      if (_terminationMap.containsKey(r.listingId)) return true;
    }
    return false;
  }

  Widget _buildTerminationBanner() {
    // find earliest termination among visible reminders
    DateTime? earliest;
    String? listingId;
    for (final r in _reminders) {
      final t = _terminationMap[r.listingId];
      if (t != null) {
        if (earliest == null || t.terminateAt.isBefore(earliest)) {
          earliest = t.terminateAt;
          listingId = r.listingId;
        }
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Termination scheduled', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  earliest != null
                      ? 'Listing ${listingId ?? ''}: ${earliest.toLocal()}. Reminders will auto-cancel on this date.'
                      : 'One or more terminations are scheduled. Reminders will auto-cancel on their dates.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestTermination(RentReminder r) async {
    final now = DateTime.now();
    final min = now.add(const Duration(days: RentReminderService.noticeDays));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: min,
      firstDate: min,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    final DateTime terminateAt = DateTime(picked.year, picked.month, picked.day, 10, 0);
    try {
      await RentReminderService.requestTermination(
        listingId: r.listingId,
        terminateAt: terminateAt,
        reason: 'User requested termination',
      );
      await _load();
      if (!mounted) return;
      // Create in-app notification with email/SMS templates for owner
      final subject = 'Termination request for listing ${r.listingId} effective ${terminateAt.toLocal()}';
      final emailBody = 'Hello Owner,\n\nThe tenant has requested to end the monthly stay for listing ${r.listingId} effective ${terminateAt.toLocal()}.\nNotice period: ${RentReminderService.noticeDays} days.\nPlease review and coordinate move-out and final invoice.\n\nThanks,';
      final smsText = 'Tenant requested termination for ${r.listingId}, effective ${terminateAt.toLocal()}.';
      await ref.read(notificationProvider.notifier).addNotification(
        AppNotification(
          id: 'term_req_${r.listingId}_${terminateAt.millisecondsSinceEpoch}',
          title: 'Send termination notice',
          body: 'Email/SMS templates ready for owner',
          type: 'termination',
          timestamp: DateTime.now(),
          data: {
            'emailSubject': subject,
            'emailBody': emailBody,
            'smsText': smsText,
            'listingId': r.listingId,
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

  Future<void> _cancelTermination(RentReminder r) async {
    try {
      await RentReminderService.cancelTermination(r.listingId);
      await _load();
      if (!mounted) return;
      // Notify both parties template on cancellation
      await ref.read(notificationProvider.notifier).addNotification(
        AppNotification(
          id: 'term_cancel_${r.listingId}_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Termination cancelled',
          body: 'Email/SMS templates ready to inform both parties',
          type: 'termination',
          timestamp: DateTime.now(),
          data: {
            'emailSubject': 'Termination cancelled for listing ${r.listingId}',
            'emailBody': 'Hello,\n\nThe previously scheduled termination for listing ${r.listingId} has been cancelled.\n\nThanks,',
            'smsText': 'Termination cancelled for ${r.listingId}.',
            'listingId': r.listingId,
          },
        ),
      );
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Termination cancelled');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to cancel termination: $e');
    }
  }

  Future<void> _debugFireIn60s(RentReminder r) async {
    final nowPlus = DateTime.now().add(const Duration(minutes: 1));
    try {
      await RentReminderService.reschedule(
        listingId: r.listingId,
        billingDay: nowPlus.day,
        hour: nowPlus.hour,
        minute: nowPlus.minute,
      );
      await _load();
      if (!mounted) return;
      final t = TimeOfDay.fromDateTime(nowPlus).format(context);
      SnackBarUtils.showSuccess(context, 'Debug scheduled in ~60s (at $t)');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to schedule debug: $e');
    }
  }

  Future<void> _createSampleReminder() async {
    final id = widget.filterListingId ?? 'demo-001';
    try {
      // Seed a reminder using today as start date
      await RentReminderService.scheduleForMonthlyStay(
        listingId: id,
        startDate: DateTime.now(),
        monthlyAmount: 100.0,
        currency: 'USD',
      );
      // Then move the next due to ~60s from now to test quickly
      final nowPlus = DateTime.now().add(const Duration(minutes: 1));
      await RentReminderService.reschedule(
        listingId: id,
        billingDay: nowPlus.day,
        hour: nowPlus.hour,
        minute: nowPlus.minute,
      );
      await _load();
      if (!mounted) return;
      final t = TimeOfDay.fromDateTime(nowPlus).format(context);
      SnackBarUtils.showSuccess(context, 'Sample reminder created. Will fire at ~$t');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to create sample: $e');
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await RentReminderService.listAll();
      final filtered = widget.filterListingId == null
          ? list
          : list.where((r) => r.listingId == widget.filterListingId).toList();
      final tmap = await TerminationService.listAll();
      setState(() {
        _reminders = filtered;
        _terminationMap = tmap;
      });
    } catch (e) {
      setState(() { _error = 'Failed to load reminders: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _toggleActive(RentReminder r) async {
    try {
      await RentReminderService.setActive(r.listingId, !r.active);
      await _load();
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, r.active ? 'Paused reminders' : 'Resumed reminders');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to update: $e');
    }
  }

  Future<void> _cancel(RentReminder r) async {
    try {
      await RentReminderService.cancelForListing(r.listingId);
      await _load();
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Cancelled reminders for ${r.listingId}');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to cancel: $e');
    }
  }

  Future<void> _reschedule(RentReminder r) async {
    int selectedDay = r.billingDay;
    TimeOfDay selectedTime = TimeOfDay(hour: r.nextDueAt.hour, minute: r.nextDueAt.minute);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reschedule reminder'),
          content: StatefulBuilder(builder: (context, setModal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Billing day of month'),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  value: selectedDay,
                  isExpanded: true,
                  items: List.generate(31, (i) => i + 1)
                      .map((d) => DropdownMenuItem(value: d, child: Text('Day $d')))
                      .toList(),
                  onChanged: (v) => setModal(() => selectedDay = v ?? selectedDay),
                ),
                const SizedBox(height: 12),
                const Text('Reminder time'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text(selectedTime.format(context)),
                  onPressed: () async {
                    final t = await showTimePicker(context: context, initialTime: selectedTime);
                    if (t != null) setModal(() => selectedTime = t);
                  },
                ),
              ],
            );
          }),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop('ok'), child: const Text('Save')),
          ],
        );
      },
    );

    // After dialog closed
    if (!mounted) return;
    try {
      await RentReminderService.reschedule(
        listingId: r.listingId,
        billingDay: selectedDay,
        hour: selectedTime.hour,
        minute: selectedTime.minute,
      );
      await _load();
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Rescheduled for day $selectedDay at ${selectedTime.format(context)}');
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to reschedule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.background : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Rent Reminders'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _reminders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.1),
                                  theme.colorScheme.secondary.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reminders found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a sample to test reminder system',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _createSampleReminder,
                              icon: const Icon(Icons.add_alert),
                              label: const Text('Create Sample Reminder'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Modern Header
                        Container(
                          margin: EdgeInsets.all(isPhone ? 16 : 24),
                          padding: EdgeInsets.all(isPhone ? 16 : 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.1),
                                theme.colorScheme.secondary.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.alarm,
                                  color: Colors.white,
                                  size: isPhone ? 24 : 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Active Rent Reminders',
                                      style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_reminders.length} reminder${_reminders.length == 1 ? '' : 's'} configured',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // List
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: isPhone ? 16 : 24, vertical: 8),
                        itemCount: _reminders.length + ((_shouldShowBanner()) ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final hasBanner = _shouldShowBanner();
                          if (hasBanner && index == 0) {
                            return _buildTerminationBanner();
                          }
                          final r = _reminders[index - (hasBanner ? 1 : 0)];
                          final termination = _terminationMap[r.listingId];
                          final primaryColor = r.active ? const Color(0xFF10B981) : Colors.grey.shade600;
                          final secondaryColor = r.active ? const Color(0xFF059669) : Colors.grey.shade400;
                          
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: secondaryColor.withOpacity(0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Card(
                              elevation: 0,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: EdgeInsets.all(isPhone ? 14 : 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [primaryColor, secondaryColor],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryColor.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.apartment, color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Listing ${r.listingId}',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            if (r.monthlyAmount != null)
                                              Text(
                                                '${r.currency} ${r.monthlyAmount!.toStringAsFixed(2)}/month',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [primaryColor, secondaryColor],
                                          ),
                                          borderRadius: BorderRadius.circular(999),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryColor.withOpacity(0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              r.active ? Icons.check_circle : Icons.pause_circle,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              r.active ? 'Active' : 'Paused',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: primaryColor.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.event, size: 18, color: primaryColor),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Billing Day: ${r.billingDay}',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.schedule, size: 18, color: primaryColor),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Next Due: ${r.nextDueAt.toLocal()}',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (termination != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.gavel_outlined, size: 18, color: Colors.redAccent),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Termination scheduled: ${termination.terminateAt.toLocal()}',
                                            style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (termination != null) const SizedBox(height: 6),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _toggleActive(r),
                                        icon: Icon(r.active ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 18),
                                        label: Text(r.active ? 'Pause' : 'Resume'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _reschedule(r),
                                        icon: const Icon(Icons.update, size: 18),
                                        label: const Text('Reschedule'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                      if (termination == null)
                                        OutlinedButton.icon(
                                          onPressed: () => _requestTermination(r),
                                          icon: const Icon(Icons.gavel_outlined, size: 18),
                                          label: const Text('Termination'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        )
                                      else
                                        OutlinedButton.icon(
                                          onPressed: () => _cancelTermination(r),
                                          icon: const Icon(Icons.undo, size: 18),
                                          label: const Text('Cancel Term'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      OutlinedButton.icon(
                                        onPressed: () => _cancel(r),
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        label: const Text('Delete'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ),
                          );
                        },
                      ),
                            ),
                          ),
                        ],
                      ),
    );
  }
}
