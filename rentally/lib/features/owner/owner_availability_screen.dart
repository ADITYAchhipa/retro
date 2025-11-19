import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/availability_service.dart';

class OwnerAvailabilityScreen extends ConsumerStatefulWidget {
  final String listingId;
  const OwnerAvailabilityScreen({super.key, required this.listingId});

  @override
  ConsumerState<OwnerAvailabilityScreen> createState() => _OwnerAvailabilityScreenState();
}

class _OwnerAvailabilityScreenState extends ConsumerState<OwnerAvailabilityScreen> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availability = ref.watch(availabilityProvider);
    final a = availability.byListingId[widget.listingId] ?? const Availability();

    bool isBlockedDay(DateTime d) {
      final key = _fmtDay(d);
      final monthKey = _fmtMonth(d);
      return a.blockedDays.contains(key) || a.blockedMonths.contains(monthKey);
    }

    Future<void> toggleDay(DateTime d) async {
      final day = DateTime(d.year, d.month, d.day);
      if (isBlockedDay(day)) {
        await ref.read(availabilityProvider.notifier).unblockDays(widget.listingId, day, day);
      } else {
        await ref.read(availabilityProvider.notifier).blockDays(widget.listingId, day, day);
      }
      if (mounted) setState(() {});
    }

    Future<void> toggleMonthBlock() async {
      final monthKey = _fmtMonth(_focusedDay);
      if (a.blockedMonths.contains(monthKey)) {
        await ref.read(availabilityProvider.notifier).unblockMonth(widget.listingId, _focusedDay);
      } else {
        await ref.read(availabilityProvider.notifier).blockMonth(widget.listingId, _focusedDay);
      }
      if (mounted) setState(() {});
    }

    final monthBlocked = a.blockedMonths.contains(_fmtMonth(_focusedDay));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_busy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Set unavailable dates for this listing. Seekers cannot book on blocked dates.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: toggleMonthBlock,
                          icon: Icon(monthBlocked ? Icons.lock_open : Icons.block),
                          label: Text(monthBlocked ? 'Unblock this month' : 'Block this month'),
                        ),
                        const SizedBox(width: 8),
                        Text(_fmtMonthLabel(_focusedDay), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TableCalendar(
                      focusedDay: _focusedDay,
                      firstDay: DateTime.now().subtract(const Duration(days: 1)),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      calendarStyle: const CalendarStyle(outsideDaysVisible: false),
                      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                      selectedDayPredicate: (d) => false,
                      enabledDayPredicate: (d) => true,
                      onDaySelected: (selectedDay, _) => toggleDay(selectedDay),
                      onPageChanged: (fd) => setState(() => _focusedDay = fd),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, _) {
                          final disabled = isBlockedDay(day);
                          return Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: disabled ? theme.colorScheme.error.withValues(alpha: 0.15) : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: disabled ? theme.colorScheme.error : null,
                                  fontWeight: disabled ? FontWeight.w700 : null,
                                ),
                              ),
                            ),
                          );
                        },
                        todayBuilder: (context, day, _) {
                          final disabled = isBlockedDay(day);
                          return Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: disabled ? theme.colorScheme.error.withValues(alpha: 0.2) : theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: disabled ? theme.colorScheme.error : theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(width: 14, height: 14, decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 6),
                        const Text('Blocked'),
                        const SizedBox(width: 16),
                        Container(width: 14, height: 14, decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 6),
                        const Text('Today'),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Tip: Tap a date to toggle blocked/unblocked. Use the Block this month button to block entire months.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  static String _fmtDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String _fmtMonth(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
  static String _fmtMonthLabel(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }
}
