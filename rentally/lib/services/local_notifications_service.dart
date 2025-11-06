import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Lightweight wrapper over flutter_local_notifications to schedule
/// monthly rent reminders as OS-level notifications.
///
/// Notes:
/// - Uses tz for timezone-aware scheduling. We set tz to the device's
///   local zone when possible; if not available it may default to UTC.
/// - On platforms that don't support scheduling or permissions are denied,
///   calls will no-op safely.
class LocalNotificationsService {
  LocalNotificationsService._();
  static final LocalNotificationsService instance = LocalNotificationsService._();

  static const _androidChannelId = 'rent_reminders_channel';
  static const _androidChannelName = 'Rent Reminders';
  static const _androidChannelDesc = 'Monthly rent due notifications';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const MethodChannel _channel = MethodChannel('com.example.rentally/notifications');

  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezones
    try {
      tz.initializeTimeZones();
      // Set device local timezone if available
      try {
        final String name = await FlutterTimezone.getLocalTimezone();
        final location = tz.getLocation(name);
        tz.setLocalLocation(location);
      } catch (_) {
        // Fallback to default tz.local
      }
    } catch (_) {}

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const LinuxInitializationSettings linuxInit = LinuxInitializationSettings(defaultActionName: 'Open');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      linux: linuxInit,
    );

    await _plugin.initialize(initSettings);

    // Create Android notification channel
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDesc,
      importance: Importance.high,
    ));

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        // Android 13+ runtime notifications permission
        final granted = await androidImpl.requestNotificationsPermission();
        if (granted == false) return false;
      }
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final res = await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
        if (res == false) return false;
      }
      final macImpl = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
      if (macImpl != null) {
        final res = await macImpl.requestPermissions(alert: true, sound: true, badge: true);
        if (res == false) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // Android 12+ exact alarm permission helpers
  static Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return res ?? true;
    } catch (_) {
      return true; // fail open
    }
  }

  static Future<bool> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return true;
    try {
      await _channel.invokeMethod('openExactAlarmSettings');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Schedule the next [count] monthly notifications starting from [firstDueLocal].
  /// Each fires at the exact local datetime specified.
  Future<void> scheduleMonthlySeries({
    required String listingId,
    required DateTime firstDueLocal,
    int count = 12,
    String? title,
    String? body,
  }) async {
    await init();
    final ok = await requestPermissions();
    if (!ok) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _idsKey(listingId);
    final List<String> existing = prefs.getStringList(key) ?? <String>[];

    // Cancel any existing scheduled notifications for this listingId
    for (final s in existing) {
      final id = int.tryParse(s);
      if (id != null) {
        await _plugin.cancel(id);
      }
    }

    final List<int> scheduledIds = [];

    DateTime d = firstDueLocal;
    for (int i = 0; i < count; i++) {
      // Use tz local time
      final tz.TZDateTime scheduled = tz.TZDateTime(tz.local, d.year, d.month, d.day, d.hour, d.minute);
      final int id = _stableId(listingId, scheduled);
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(urgency: LinuxNotificationUrgency.normal),
      );

      try {
        await _plugin.zonedSchedule(
          id,
          title ?? 'Rent due today',
          body ?? 'Your monthly rent is due today. Please make the payment.',
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
          matchDateTimeComponents: null, // we explicitly schedule each month
        );
        scheduledIds.add(id);
      } catch (e) {
        if (kDebugMode) {
          // ignore and continue scheduling others
          // print('Failed to schedule id=$id error=$e');
        }
      }

      // advance one month, clamp day to month length
      final nextMonth = DateTime(d.year, d.month + 1, 1, d.hour, d.minute);
      final int lastDay = _daysInMonth(nextMonth.year, nextMonth.month);
      final int day = min(d.day, lastDay);
      d = DateTime(nextMonth.year, nextMonth.month, day, d.hour, d.minute);
    }

    await prefs.setStringList(key, scheduledIds.map((e) => e.toString()).toList());
  }

  Future<void> cancelForListing(String listingId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _idsKey(listingId);
    final List<String> existing = prefs.getStringList(key) ?? <String>[];
    for (final s in existing) {
      final id = int.tryParse(s);
      if (id != null) {
        await _plugin.cancel(id);
      }
    }
    await prefs.remove(key);
  }

  String _idsKey(String listingId) => 'rent_os_ids_$listingId';

  int _stableId(String listingId, tz.TZDateTime when) {
    // Create a stable positive 32-bit id based on listingId and date components
    final base = listingId.hashCode & 0x7fffffff;
    final composite = base ^ (when.year << 7) ^ (when.month << 3) ^ when.day;
    return composite & 0x7fffffff;
  }

  int _daysInMonth(int year, int month) {
    final firstNext = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstNext.subtract(const Duration(days: 1)).day;
  }
}
