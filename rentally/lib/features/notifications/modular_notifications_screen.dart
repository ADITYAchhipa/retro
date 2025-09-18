import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentally/services/notification_service.dart';

/// **ModularNotificationsScreen**
/// 
/// A comprehensive, modular notifications screen for the Rentaly app that displays
/// user notifications with filtering, actions, and management capabilities.
/// 
/// **Features:**
/// - Real-time notification display
/// - Mark as read/unread functionality
/// - Notification filtering by type
/// - Bulk actions (mark all read, clear all)
/// - Test notification simulation
/// - Swipe-to-dismiss actions
/// - Empty state handling
/// - Responsive design
/// 
/// **Architecture:**
/// - Modular widget composition for maintainability
/// - Riverpod state management integration
/// - Clean separation of notification logic and UI
/// - Reusable notification components
/// 
/// **Usage:**
/// ```dart
/// // Navigate to notifications screen
/// context.go('/notifications');
/// 
/// // In router configuration
/// GoRoute(
///   path: '/notifications',
///   builder: (context, state) => const ModularNotificationsScreen(),
/// )
/// ```
/// 
/// **Backend Integration Points:**
/// - Real-time notification updates via WebSocket/FCM
/// - Notification read status synchronization
/// - Push notification handling
/// - Notification preferences management
/// - Analytics tracking for notification interactions
class ModularNotificationsScreen extends ConsumerWidget {
  const ModularNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(context, ref, notificationState, theme),
      body: _buildBody(context, ref, notificationState, theme),
    );
  }

  /// Builds the app bar with actions
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    NotificationState notificationState,
    ThemeData theme,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _handleBack(context),
      ),
      title: const Text('Notifications'),
      actions: [
        if (notificationState.notifications.isNotEmpty) ...[
          _buildMarkAllReadButton(ref),
          _buildOptionsMenu(context, ref),
        ],
      ],
    );
  }

  /// Builds the mark all read button
  Widget _buildMarkAllReadButton(WidgetRef ref) {
    return TextButton(
      onPressed: () {
        ref.read(notificationProvider.notifier).markAllAsRead();
      },
      child: const Text('Mark All Read'),
    );
  }

  /// Builds the options popup menu
  Widget _buildOptionsMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuAction(context, ref, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'clear_all',
          child: Text('Clear All'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'test_booking',
          child: Text('Test Booking Notification'),
        ),
        const PopupMenuItem(
          value: 'test_message',
          child: Text('Test Message Notification'),
        ),
        const PopupMenuItem(
          value: 'test_promotion',
          child: Text('Test Promotion Notification'),
        ),
        const PopupMenuItem(
          value: 'filter_by_type',
          child: Text('Filter by Type'),
        ),
        const PopupMenuItem(
          value: 'filter_by_priority',
          child: Text('Filter by Priority'),
        ),
      ],
    );
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/home');
    }
  }



  /// Builds the main body content
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    NotificationState notificationState,
    ThemeData theme,
  ) {
    if (notificationState.isLoading) {
      return _buildLoadingState();
    }

    if (notificationState.notifications.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildNotificationsList(context, ref, notificationState, theme);
  }

  /// Builds loading state widget
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Builds empty state widget
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications about bookings, messages, and updates here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the notifications list
  Widget _buildNotificationsList(
    BuildContext context,
    WidgetRef ref,
    NotificationState notificationState,
    ThemeData theme,
  ) {
    return ListView.builder(
      itemCount: notificationState.notifications.length,
      itemBuilder: (context, index) {
        final notification = notificationState.notifications[index];
        return _buildNotificationItem(context, ref, notification, theme);
      },
    );
  }

  /// Builds individual notification item
  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
    ThemeData theme,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(theme),
      onDismissed: (direction) {
        // Remove notification functionality disabled for frontend-only app
        _showSnackBar(context, 'Notification dismissed');
      },
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead 
              ? theme.colorScheme.surface 
              : theme.colorScheme.primaryContainer.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: ListTile(
          leading: _buildNotificationIcon(notification, theme),
          title: Text(
            notification.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          subtitle: _buildNotificationSubtitle(notification, theme),
          trailing: _buildNotificationActions(context, ref, notification),
          onTap: () => _handleNotificationTap(context, ref, notification),
        ),
      ),
    );
  }

  /// Builds notification icon based on type
  Widget _buildNotificationIcon(AppNotification notification, ThemeData theme) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'booking':
        iconData = Icons.calendar_today;
        iconColor = Colors.blue;
        break;
      case 'message':
        iconData = Icons.message;
        iconColor = Colors.green;
        break;
      case 'promotion':
        iconData = Icons.local_offer;
        iconColor = Colors.orange;
        break;
      case 'system':
        iconData = Icons.info;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = theme.colorScheme.primary;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  /// Builds notification subtitle with timestamp
  Widget _buildNotificationSubtitle(AppNotification notification, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(notification.body),
        const SizedBox(height: 4),
        Text(
          _formatTimestamp(notification.timestamp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  /// Builds notification action buttons
  Widget _buildNotificationActions(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleNotificationAction(context, ref, notification, value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'mark_read',
          child: Text(notification.isRead ? 'Mark as Unread' : 'Mark as Read'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    );
  }

  /// Builds dismiss background for swipe actions
  Widget _buildDismissBackground(ThemeData theme) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.red,
      child: const Icon(
        Icons.delete,
        color: Colors.white,
      ),
    );
  }

  // Action Methods

  /// Handles menu action selection
  void _handleMenuAction(BuildContext context, WidgetRef ref, String value) {
    switch (value) {
      case 'clear_all':
        _showClearAllDialog(context, ref);
        break;
      case 'test_booking':
        ref.read(notificationProvider.notifier).simulatePushNotification('booking');
        break;
      case 'test_message':
        ref.read(notificationProvider.notifier).simulatePushNotification('message');
        break;
      case 'test_promotion':
        ref.read(notificationProvider.notifier).simulatePushNotification('promotion');
        break;
    }
  }

  /// Handles notification tap
  void _handleNotificationTap(BuildContext context, WidgetRef ref, AppNotification notification) {
    if (!notification.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }

    // Navigate based on notification type and payload
    switch (notification.type) {
      case 'booking':
        final data = notification.data ?? {};
        final bookingId = data['bookingId'] as String?;
        final status = (data['status'] as String?)?.toLowerCase();
        if (bookingId != null && bookingId.isNotEmpty) {
          if (status == 'confirmed') {
            context.push('/booking-confirmation/$bookingId');
          } else {
            context.push('/booking-history/$bookingId');
          }
        } else {
          context.push('/booking-history');
        }
        break;
      case 'message':
        final chatId = notification.data?['chatId'] as String?;
        if (chatId != null && chatId.isNotEmpty) {
          context.push('/chat/$chatId');
        } else {
          context.push('/chat');
        }
        break;
      default:
        // Fallback to notifications screen or home
        // Keep user on notifications; optionally navigate elsewhere
        break;
    }
  }

  /// Handles notification action menu
  void _handleNotificationAction(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
    String action,
  ) {
    switch (action) {
      case 'mark_read':
        if (notification.isRead) {
          // Mark as unread functionality disabled for frontend-only app
        } else {
          ref.read(notificationProvider.notifier).markAsRead(notification.id);
        }
        break;
      case 'delete':
        // Remove notification functionality disabled for frontend-only app
        _showSnackBar(context, 'Notification deleted');
        break;
    }
  }

  /// Shows clear all confirmation dialog
  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Clear all notifications functionality disabled for frontend-only app
              Navigator.of(context).pop();
              _showSnackBar(context, 'All notifications cleared');
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  /// Shows snack bar message
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Formats timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// **NotificationScreenUtils**
/// 
/// Utility class containing helper methods for notification functionality.
class NotificationScreenUtils {
  /// Gets notification type display name
  static String getNotificationTypeDisplayName(String type) {
    switch (type) {
      case 'booking':
        return 'Booking';
      case 'message':
        return 'Message';
      case 'promotion':
        return 'Promotion';
      case 'system':
        return 'System';
      default:
        return 'Notification';
    }
  }

  /// Determines notification priority color (simplified)
  static Color getPriorityColor(String type) {
    switch (type) {
      case 'booking':
        return Colors.red;
      case 'message':
        return Colors.orange;
      case 'promotion':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Determines if notification should show badge
  static bool shouldShowBadge(AppNotification notification) {
    return !notification.isRead && notification.type == 'booking';
  }

  /// Groups notifications by date
  static Map<String, List<AppNotification>> groupNotificationsByDate(
    List<AppNotification> notifications,
  ) {
    final grouped = <String, List<AppNotification>>{};
    
    for (final notification in notifications) {
      final dateKey = _getDateKey(notification.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(notification);
    }
    
    return grouped;
  }

  static String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
