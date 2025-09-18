import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Mock notification data
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'data': data,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }
}

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState()) {
    _loadNotifications();
    _generateMockNotifications();
  }

  static const String _storageKey = 'notifications';

  Future<void> _loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_storageKey) ?? [];
      
      final List<AppNotification> notifications = [];
      for (final jsonStr in notificationsJson) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          notifications.add(AppNotification.fromJson(map));
        } catch (_) {
          // Skip legacy/malformed entries
        }
      }

      final unreadCount = notifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: $e',
      );
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = state.notifications
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();
      await prefs.setStringList(_storageKey, notificationsJson);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save notifications: $e');
    }
  }

  Future<void> addNotification(AppNotification notification) async {
    final updatedNotifications = [notification, ...state.notifications];
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
    
    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );
    
    await _saveNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    final updatedNotifications = state.notifications.map((notification) {
      if (notification.id == notificationId) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );

    await _saveNotifications();
  }

  Future<void> markAllAsRead() async {
    final updatedNotifications = state.notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    );

    await _saveNotifications();
  }

  Future<void> deleteNotification(String notificationId) async {
    final updatedNotifications = state.notifications
        .where((notification) => notification.id != notificationId)
        .toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );

    await _saveNotifications();
  }

  Future<void> clearAllNotifications() async {
    state = state.copyWith(
      notifications: [],
      unreadCount: 0,
    );

    await _saveNotifications();
  }

  void _generateMockNotifications() {
    // Generate some mock notifications for demo purposes
    final mockNotifications = [
      AppNotification(
        id: '1',
        title: 'Booking Confirmed',
        body: 'Your booking for Luxury Apartment has been confirmed!',
        type: 'booking',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        data: {'bookingId': '123'},
      ),
      AppNotification(
        id: '2',
        title: 'New Message',
        body: 'You have a new message from Sarah Johnson',
        type: 'message',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        data: {'chatId': '456'},
      ),
      AppNotification(
        id: '3',
        title: 'Price Drop Alert',
        body: 'A property in your wishlist has dropped in price!',
        type: 'price_alert',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: true,
        data: {'listingId': '789'},
      ),
      AppNotification(
        id: '4',
        title: 'Booking Reminder',
        body: 'Your check-in is tomorrow at 3:00 PM',
        type: 'reminder',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        data: {'bookingId': '101'},
      ),
    ];

    // Only add mock notifications if there are no existing notifications
    if (state.notifications.isEmpty) {
      final unreadCount = mockNotifications.where((n) => !n.isRead).length;
      state = state.copyWith(
        notifications: mockNotifications,
        unreadCount: unreadCount,
      );
      _saveNotifications();
    }
  }

  // Simulate receiving push notifications
  Future<void> simulatePushNotification(String type) async {
    late AppNotification notification;
    
    switch (type) {
      case 'booking':
        notification = AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Booking Update',
          body: 'Your booking status has been updated',
          type: 'booking',
          timestamp: DateTime.now(),
        );
        break;
      case 'message':
        notification = AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'New Message',
          body: 'You have received a new message',
          type: 'message',
          timestamp: DateTime.now(),
        );
        break;
      case 'promotion':
        notification = AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Special Offer',
          body: 'Limited time offer: 20% off your next booking!',
          type: 'promotion',
          timestamp: DateTime.now(),
        );
        break;
      default:
        notification = AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Rentally',
          body: 'You have a new notification',
          type: 'general',
          timestamp: DateTime.now(),
        );
    }

    await addNotification(notification);
  }
}

// Providers
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

// Helper provider for unread count
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
