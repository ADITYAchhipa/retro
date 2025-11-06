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
    return Scaffold(
      appBar: AppBar(title: const Text('Rent Reminders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _reminders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No reminders found'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _createSampleReminder,
                            icon: const Icon(Icons.add_alert),
                            label: const Text('Create Sample Reminder'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reminders.length + ((_shouldShowBanner()) ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final hasBanner = _shouldShowBanner();
                          if (hasBanner && index == 0) {
                            return _buildTerminationBanner();
                          }
                          final r = _reminders[index - (hasBanner ? 1 : 0)];
                          final termination = _terminationMap[r.listingId];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.apartment),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Listing ${r.listingId}',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: r.active ? Colors.green.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(r.active ? 'Active' : 'Paused', style: TextStyle(color: r.active ? Colors.green[800] : Colors.grey[800], fontSize: 12)),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.event, size: 18),
                                      const SizedBox(width: 6),
                                      Text('Billing day: ${r.billingDay}'),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.schedule, size: 18),
                                      const SizedBox(width: 6),
                                      Text('Next: ${r.nextDueAt.toLocal()}')
                                    ],
                                  ),
                                  const SizedBox(height: 6),
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
                                  if (r.monthlyAmount != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.currency_exchange, size: 18),
                                        const SizedBox(width: 6),
                                        Text('Amount: ${r.currency} ${r.monthlyAmount!.toStringAsFixed(2)}'),
                                      ],
                                    ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _toggleActive(r),
                                        icon: Icon(r.active ? Icons.pause_circle_outline : Icons.play_circle_outline),
                                        label: Text(r.active ? 'Pause' : 'Resume'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _reschedule(r),
                                        icon: const Icon(Icons.update),
                                        label: const Text('Reschedule'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _debugFireIn60s(r),
                                        icon: const Icon(Icons.bug_report_outlined),
                                        label: const Text('Debug: +60s'),
                                      ),
                                      const SizedBox(width: 8),
                                      if (termination == null)
                                        OutlinedButton.icon(
                                          onPressed: () => _requestTermination(r),
                                          icon: const Icon(Icons.gavel_outlined),
                                          label: const Text('Request Termination'),
                                        )
                                      else
                                        TextButton.icon(
                                          onPressed: () => _cancelTermination(r),
                                          icon: const Icon(Icons.undo, color: Colors.red),
                                          label: const Text('Cancel Termination', style: TextStyle(color: Colors.red)),
                                        ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => _cancel(r),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
