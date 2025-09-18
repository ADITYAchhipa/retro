import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';
import 'view_history_service.dart';

class OwnerActivityItem {
  final IconData icon;
  final String title;
  final DateTime timestamp;
  final String timeAgo;

  const OwnerActivityItem({
    required this.icon,
    required this.title,
    required this.timestamp,
    required this.timeAgo,
  });
}

String _formatTimeAgo(DateTime ts) {
  final now = DateTime.now();
  final diff = now.difference(ts);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final weeks = (diff.inDays / 7).floor();
  return '${weeks}w ago';
}

IconData _iconForNotification(String type) {
  switch (type) {
    case 'booking':
      return Icons.event_available_outlined;
    case 'message':
      return Icons.markunread_outlined;
    case 'promotion':
    case 'price_alert':
      return Icons.local_offer_outlined;
    case 'reminder':
      return Icons.alarm_on_outlined;
    default:
      return Icons.notifications_none_outlined;
  }
}

// Aggregates recent activity from notifications + view history
final ownerActivityProvider = FutureProvider<List<OwnerActivityItem>>((ref) async {
  // Notifications (Riverpod)
  final notifState = ref.watch(notificationProvider);
  final notifItems = notifState.notifications.map((n) {
    return OwnerActivityItem(
      icon: _iconForNotification(n.type),
      title: n.title,
      timestamp: n.timestamp,
      timeAgo: _formatTimeAgo(n.timestamp),
    );
  }).toList();

  // View history (Provider-based service) — read from SharedPreferences directly via the service
  final viewService = ViewHistoryService();
  await viewService.initialize();
  final recentViews = viewService.recentlyViewed.map((v) {
    final label = v.title.isNotEmpty ? v.title : (v.location ?? 'Listing');
    return OwnerActivityItem(
      icon: Icons.visibility_outlined,
      title: 'Listing viewed: $label',
      timestamp: v.viewedAt,
      timeAgo: v.timeAgo,
    );
  }).toList();

  // Merge and sort
  final merged = [...notifItems, ...recentViews];
  merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));

  // Limit to last 10
  return merged.take(10).toList();
});
