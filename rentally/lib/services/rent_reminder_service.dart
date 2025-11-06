import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import 'local_notifications_service.dart';
import 'termination_service.dart';

class RentReminder {
  final String id; // typically the listingId
  final String listingId;
  final int billingDay; // 1..31
  final DateTime nextDueAt; // local time when reminder should fire
  final double? monthlyAmount;
  final String currency;
  final bool active;

  const RentReminder({
    required this.id,
    required this.listingId,
    required this.billingDay,
    required this.nextDueAt,
    this.monthlyAmount,
    this.currency = 'USD',
    this.active = true,
  });

  RentReminder copyWith({
    String? id,
    String? listingId,
    int? billingDay,
    DateTime? nextDueAt,
    double? monthlyAmount,
    String? currency,
    bool? active,
  }) {
    return RentReminder(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      billingDay: billingDay ?? this.billingDay,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      currency: currency ?? this.currency,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'listingId': listingId,
        'billingDay': billingDay,
        'nextDueAt': nextDueAt.millisecondsSinceEpoch,
        'monthlyAmount': monthlyAmount,
        'currency': currency,
        'active': active,
      };

  static RentReminder fromJson(Map<String, dynamic> json) => RentReminder(
        id: json['id'] as String,
        listingId: json['listingId'] as String,
        billingDay: json['billingDay'] as int,
        nextDueAt: DateTime.fromMillisecondsSinceEpoch(json['nextDueAt'] as int),
        monthlyAmount: (json['monthlyAmount'] is num)
            ? (json['monthlyAmount'] as num).toDouble()
            : null,
        currency: (json['currency'] as String?) ?? 'USD',
        active: (json['active'] as bool?) ?? true,
      );
}

class RentReminderService {
  static const String _storageKey = 'rent_reminders_v1';
  static const int noticeDays = 30; // minimum 1-month notice for termination

  // Schedule a recurring monthly reminder on the selected start date's day-of-month.
  // The first reminder will fire next month on the same day at 10:00 local time.
  static Future<void> scheduleForMonthlyStay({
    required String listingId,
    required DateTime startDate,
    double? monthlyAmount,
    String currency = 'USD',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _loadFromPrefs(prefs);

    final int billingDay = startDate.day;
    final DateTime firstDue = _computeFirstDue(startDate, billingDay);

    final reminder = RentReminder(
      id: listingId,
      listingId: listingId,
      billingDay: billingDay,
      nextDueAt: firstDue,
      monthlyAmount: monthlyAmount,
      currency: currency,
      active: true,
    );

    // Replace any existing reminder for this listingId
    final filtered = list.where((r) => r.listingId != listingId).toList();
    filtered.add(reminder);
    await _saveToPrefs(prefs, filtered);
  }

  static Future<void> cancelForListing(String listingId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _loadFromPrefs(prefs)
        .where((r) => r.listingId != listingId)
        .toList();
    await _saveToPrefs(prefs, list);
    // Cancel OS-level notifications as well
    await LocalNotificationsService.instance.cancelForListing(listingId);
  }

  // Check and trigger due reminders. If a reminder is due or past due, sends
  // an in-app notification and advances nextDueAt by one month.
  static Future<void> checkAndFireDue(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _loadFromPrefs(prefs);
    if (list.isEmpty) return;

    final now = DateTime.now();
    bool changed = false;

    // Load any scheduled terminations once
    final terminations = await TerminationService.listAll();

    for (int i = 0; i < list.length; i++) {
      final r = list[i];
      if (!r.active) continue;

      // If termination date has arrived or passed, cancel reminders and remove schedule
      final t = terminations[r.listingId];
      if (t != null && !t.terminateAt.isAfter(now)) {
        await cancelForListing(r.listingId);
        await TerminationService.cancel(r.listingId);
        changed = true;
        continue;
      }

      if (!r.nextDueAt.isAfter(now)) {
        // Fire notification
        final amountLabel = r.monthlyAmount != null
            ? '${r.currency} ${r.monthlyAmount!.toStringAsFixed(2)}'
            : 'your monthly rent';

        final notification = AppNotification(
          id: 'rent_${r.listingId}_${r.nextDueAt.millisecondsSinceEpoch}',
          title: 'Rent due today',
          body: 'Your rent for listing ${r.listingId} is due today. Please pay $amountLabel.',
          type: 'rent_due',
          timestamp: now,
          data: {
            'listingId': r.listingId,
            'dueAt': r.nextDueAt.toIso8601String(),
          },
        );
        await ref.read(notificationProvider.notifier).addNotification(notification);

        // Advance next due by one month
        final next = _advanceOneMonth(r.nextDueAt, r.billingDay);
        list[i] = r.copyWith(nextDueAt: next);
        changed = true;
      }
    }

    if (changed) {
      await _saveToPrefs(prefs, list);
    }
  }

  /// Request termination with a local date/time; enforces minimum notice period.
  static Future<void> requestTermination({
    required String listingId,
    required DateTime terminateAt,
    String? reason,
  }) async {
    final DateTime minAllowed = DateTime.now().add(const Duration(days: noticeDays));
    if (terminateAt.isBefore(minAllowed)) {
      throw ArgumentError('Termination must be at least $noticeDays days from today');
    }
    await TerminationService.schedule(listingId: listingId, terminateAt: terminateAt, reason: reason);
    // Prune OS notifications immediately: keep only those strictly before terminateAt
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _loadFromPrefs(prefs);
      final r = list.firstWhere((e) => e.listingId == listingId, orElse: () => throw StateError('reminder_not_found'));
      // Cancel any existing OS notifications for this listing
      await LocalNotificationsService.instance.cancelForListing(listingId);
      // If next due occurs before termination, schedule up to (but not including) terminateAt
      if (r.nextDueAt.isBefore(terminateAt)) {
        int count = 0;
        DateTime d = r.nextDueAt;
        while (d.isBefore(terminateAt)) {
          count++;
          d = _advanceOneMonth(d, r.billingDay);
        }
        if (count > 0) {
          await LocalNotificationsService.instance.scheduleMonthlySeries(
            listingId: listingId,
            firstDueLocal: r.nextDueAt,
            count: count,
            title: 'Rent due today',
            body: 'Your monthly rent is due today. Please make the payment.',
          );
        }
      }
    } catch (_) {
      // fail safe: ignore pruning errors
    }
  }

  static Future<void> cancelTermination(String listingId) async {
    await TerminationService.cancel(listingId);
    // If reminder exists and is active, re-schedule full OS notifications from nextDueAt
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _loadFromPrefs(prefs);
      for (final r in list) {
        if (r.listingId == listingId && r.active) {
          // Clear any partial schedules and re-seed the next 12 months
          await LocalNotificationsService.instance.cancelForListing(listingId);
          await LocalNotificationsService.instance.scheduleMonthlySeries(
            listingId: listingId,
            firstDueLocal: r.nextDueAt,
            count: 12,
            title: 'Rent due today',
            body: 'Your monthly rent is due today. Please make the payment.',
          );
          break;
        }
      }
    } catch (_) {}
  }

  static Future<List<RentReminder>> listAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadFromPrefs(prefs);
  }

  /// Get reminder for a specific listing, if any.
  static Future<RentReminder?> getByListing(String listingId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _loadFromPrefs(prefs);
    for (final r in list) {
      if (r.listingId == listingId) return r;
    }
    return null;
  }

  /// Mark the current due cycle as paid and advance to next month.
  /// If [dueAt] is provided, it must match the current [nextDueAt] day to proceed.
  static Future<void> markDuePaid(String listingId, {DateTime? dueAt}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _loadFromPrefs(prefs);
    for (int i = 0; i < list.length; i++) {
      final r = list[i];
      if (r.listingId != listingId) continue;
      if (dueAt != null) {
        final a = r.nextDueAt;
        if (!(a.year == dueAt.year && a.month == dueAt.month && a.day == dueAt.day)) {
          // Provided dueAt does not match current cycle; do not alter
          return;
        }
      }
      // Advance next due and persist
      final advanced = _advanceOneMonth(r.nextDueAt, r.billingDay);
      final updated = r.copyWith(nextDueAt: advanced);
      list[i] = updated;
      await _saveToPrefs(prefs, list);
      // Reschedule OS-level notifications from new nextDueAt
      try {
        await LocalNotificationsService.instance.cancelForListing(listingId);
        await LocalNotificationsService.instance.scheduleMonthlySeries(
          listingId: listingId,
          firstDueLocal: updated.nextDueAt,
          count: 12,
          title: 'Rent due today',
          body: 'Your monthly rent is due today. Please make the payment.',
        );
      } catch (_) {}
      return;
    }
  }

  /// Pause or resume reminders for a listing. When paused, OS-level notifications
  /// are also canceled. When resumed, they are scheduled starting from nextDueAt.
  static Future<void> setActive(String listingId, bool active) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _loadFromPrefs(prefs);
    for (int i = 0; i < list.length; i++) {
      if (list[i].listingId == listingId) {
        final updated = list[i].copyWith(active: active);
        list[i] = updated;
        await _saveToPrefs(prefs, list);
        if (!active) {
          await LocalNotificationsService.instance.cancelForListing(listingId);
        } else {
          await LocalNotificationsService.instance.scheduleMonthlySeries(
            listingId: listingId,
            firstDueLocal: updated.nextDueAt,
            count: 12,
            title: 'Rent due today',
            body: 'Your monthly rent is due today. Please make the payment.',
          );
        }
        return;
      }
    }
  }

  /// Reschedule billing day and time for a listing.
  /// Computes the next occurrence after now and updates both in-app and OS-level schedules.
  static Future<void> reschedule({
    required String listingId,
    required int billingDay,
    int hour = 10,
    int minute = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _loadFromPrefs(prefs);
    final now = DateTime.now();
    for (int i = 0; i < list.length; i++) {
      if (list[i].listingId == listingId) {
        DateTime candidate = _candidateThisMonth(now, billingDay, hour, minute);
        if (!candidate.isAfter(now)) {
          final dt = DateTime(now.year, now.month + 1, 1, hour, minute);
          final int lastDay = _endOfMonth(dt.year, dt.month).day;
          final int day = billingDay > lastDay ? lastDay : billingDay;
          candidate = DateTime(dt.year, dt.month, day, hour, minute);
        }
        final updated = list[i].copyWith(
          billingDay: billingDay,
          nextDueAt: candidate,
        );
        list[i] = updated;
        await _saveToPrefs(prefs, list);
        // Reschedule OS-level notifications
        await LocalNotificationsService.instance.cancelForListing(listingId);
        await LocalNotificationsService.instance.scheduleMonthlySeries(
          listingId: listingId,
          firstDueLocal: candidate,
          count: 12,
          title: 'Rent due today',
          body: 'Your monthly rent is due today. Please make the payment.',
        );
        return;
      }
    }
  }

  // Helpers
  static List<RentReminder> _loadFromPrefs(SharedPreferences prefs) {
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final List<RentReminder> out = [];
    for (final s in raw) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        out.add(RentReminder.fromJson(map));
      } catch (_) {}
    }
    return out;
  }

  static Future<void> _saveToPrefs(SharedPreferences prefs, List<RentReminder> list) async {
    final strings = list.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_storageKey, strings);
  }

  static DateTime _computeFirstDue(DateTime startDate, int billingDay) {
    // First due is next month on the chosen billing day at 10:00 local time
    final DateTime nextMonth = DateTime(startDate.year, startDate.month + 1, 1);
    final int lastDay = _endOfMonth(nextMonth.year, nextMonth.month).day;
    final int day = min(billingDay, lastDay);
    return DateTime(nextMonth.year, nextMonth.month, day, 10);
  }

  static DateTime _candidateThisMonth(DateTime base, int billingDay, int hour, int minute) {
    final int lastDay = _endOfMonth(base.year, base.month).day;
    final int day = min(billingDay, lastDay);
    return DateTime(base.year, base.month, day, hour, minute);
  }

  static DateTime _advanceOneMonth(DateTime from, int billingDay) {
    final DateTime base = DateTime(from.year, from.month + 1, 1, from.hour, from.minute);
    final int lastDay = _endOfMonth(base.year, base.month).day;
    final int day = min(billingDay, lastDay);
    return DateTime(base.year, base.month, day, from.hour, from.minute);
  }

  static DateTime _endOfMonth(int year, int month) {
    final DateTime firstNext = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return firstNext.subtract(const Duration(days: 1));
  }
}
