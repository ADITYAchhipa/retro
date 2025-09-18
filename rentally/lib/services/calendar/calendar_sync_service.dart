import 'dart:async';

class CalendarSyncService {
  CalendarSyncService._();
  static final CalendarSyncService instance = CalendarSyncService._();

  Future<bool> connectGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    return true; // mock success
  }

  Future<bool> connectOutlook() async {
    await Future.delayed(const Duration(seconds: 1));
    return true; // mock success
  }

  Future<String> generateIcs({required String title, required DateTime start, required DateTime end}) async {
    // Very minimal ICS content (mock)
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//Rentally//Calendar Sync//EN')
      ..writeln('BEGIN:VEVENT')
      ..writeln('SUMMARY:$title')
      ..writeln('DTSTART:${_formatDate(start)}')
      ..writeln('DTEND:${_formatDate(end)}')
      ..writeln('END:VEVENT')
      ..writeln('END:VCALENDAR');
    return buffer.toString();
  }

  String _formatDate(DateTime dt) {
    // YYYYMMDDTHHMMSSZ UTC
    final utc = dt.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }
}
