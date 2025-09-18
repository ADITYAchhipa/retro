import 'package:flutter/material.dart';
import '../../services/calendar/calendar_sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ui_visibility_provider.dart';

class CalendarSyncScreen extends ConsumerStatefulWidget {
  const CalendarSyncScreen({super.key});

  @override
  ConsumerState<CalendarSyncScreen> createState() => _CalendarSyncScreenState();
}

class _CalendarSyncScreenState extends ConsumerState<CalendarSyncScreen> {
  bool _googleConnected = false;
  bool _outlookConnected = false;
  String? _lastIcs;

  @override
  void initState() {
    super.initState();
    // Hide bottom navigation while on Calendar Sync screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(immersiveRouteOpenProvider.notifier).state = true;
    });
  }

  @override
  void dispose() {
    // Show it again when leaving
    ref.read(immersiveRouteOpenProvider.notifier).state = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar Sync')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile.adaptive(
            title: const Text('Connect Google Calendar'),
            value: _googleConnected,
            onChanged: (_) async {
              final ok = await CalendarSyncService.instance.connectGoogle();
              setState(() => _googleConnected = ok);
            },
          ),
          const Divider(height: 1),
          SwitchListTile.adaptive(
            title: const Text('Connect Outlook Calendar'),
            value: _outlookConnected,
            onChanged: (_) async {
              final ok = await CalendarSyncService.instance.connectOutlook();
              setState(() => _outlookConnected = ok);
            },
          ),
          const SizedBox(height: 24),
          Text('Export ICS', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final ics = await CalendarSyncService.instance.generateIcs(title: 'Sample Booking', start: now.add(const Duration(days: 1)), end: now.add(const Duration(days: 1, hours: 2)));
              setState(() => _lastIcs = ics);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ICS generated (mock)')));
            },
            icon: const Icon(Icons.event_available),
            label: const Text('Generate .ics'),
          ),
          if (_lastIcs != null) ...[
            const SizedBox(height: 12),
            Text(_lastIcs!, maxLines: 10, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'monospace')),
          ],
        ],
      ),
    );
  }
}
