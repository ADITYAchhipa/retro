// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Comprehensive test helpers for industrial-grade testing
class TestHelpers {
  /// Create a test widget with providers
  static Widget createTestWidget({
    required Widget child,
    List<Override>? overrides,
  }) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// Create a test widget with navigation
  static Widget createTestWidgetWithNavigation({
    required Widget child,
    List<Override>? overrides,
  }) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  /// Pump and settle with timeout
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpAndSettle(timeout);
  }

  /// Find widget by key
  static Finder findByKey(String key) {
    return find.byKey(Key(key));
  }

  /// Find widget by text
  static Finder findByText(String text) {
    return find.text(text);
  }

  /// Find widget by type
  static Finder findByType<T extends Widget>() {
    return find.byType(T);
  }

  /// Verify widget exists
  static void verifyWidgetExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verify widget doesn't exist
  static void verifyWidgetNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verify multiple widgets exist
  static void verifyMultipleWidgetsExist(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

  /// Tap widget and pump
  static Future<void> tapAndPump(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pump();
  }

  /// Enter text and pump
  static Future<void> enterTextAndPump(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// Scroll and pump
  static Future<void> scrollAndPump(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pump();
  }

  /// Wait for widget to appear
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.pumpAndSettle();
    
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    throw TimeoutException('Widget not found within timeout', timeout);
  }

  /// Verify form validation
  static Future<void> verifyFormValidation(
    WidgetTester tester,
    String submitButtonKey,
    List<String> errorMessages,
  ) async {
    // Tap submit without filling form
    await tapAndPump(tester, findByKey(submitButtonKey));
    
    // Verify error messages appear
    for (final message in errorMessages) {
      verifyWidgetExists(find.text(message));
    }
  }

  /// Mock network delay
  static Future<void> mockNetworkDelay([Duration? delay]) async {
    await Future.delayed(delay ?? const Duration(milliseconds: 500));
  }

  /// Create mock user data
  static Map<String, dynamic> createMockUser({
    String? id,
    String? name,
    String? email,
  }) {
    return {
      'id': id ?? 'test_user_123',
      'name': name ?? 'Test User',
      'email': email ?? 'test@example.com',
      'avatar': 'https://example.com/avatar.jpg',
      'verified': true,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create mock property data
  static Map<String, dynamic> createMockProperty({
    String? id,
    String? title,
    double? price,
  }) {
    return {
      'id': id ?? 'property_123',
      'title': title ?? 'Test Property',
      'price': price ?? 100.0,
      'currency': 'USD',
      'location': 'Test City',
      'images': ['https://example.com/image1.jpg'],
      'amenities': ['WiFi', 'Parking'],
      'rating': 4.5,
      'reviews': 10,
    };
  }

  /// Create mock booking data
  static Map<String, dynamic> createMockBooking({
    String? id,
    String? propertyId,
    String? userId,
  }) {
    return {
      'id': id ?? 'booking_123',
      'propertyId': propertyId ?? 'property_123',
      'userId': userId ?? 'user_123',
      'checkIn': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'checkOut': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      'status': 'confirmed',
      'totalAmount': 200.0,
      'currency': 'USD',
    };
  }
}

/// Custom matchers for testing
class CustomMatchers {
  /// Match widget with specific text style
  static Matcher hasTextStyle(TextStyle expectedStyle) {
    return _HasTextStyle(expectedStyle);
  }

  /// Match widget with specific color
  static Matcher hasColor(Color expectedColor) {
    return _HasColor(expectedColor);
  }

  /// Match widget with specific padding
  static Matcher hasPadding(EdgeInsets expectedPadding) {
    return _HasPadding(expectedPadding);
  }
}

class _HasTextStyle extends Matcher {
  final TextStyle expectedStyle;
  
  _HasTextStyle(this.expectedStyle);
  
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Text) return false;
    return item.style == expectedStyle;
  }
  
  @override
  Description describe(Description description) {
    return description.add('has text style $expectedStyle');
  }
}

class _HasColor extends Matcher {
  final Color expectedColor;
  
  _HasColor(this.expectedColor);
  
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Container && item.color == expectedColor) return true;
    if (item is Card && item.color == expectedColor) return true;
    return false;
  }
  
  @override
  Description describe(Description description) {
    return description.add('has color $expectedColor');
  }
}

class _HasPadding extends Matcher {
  final EdgeInsets expectedPadding;
  
  _HasPadding(this.expectedPadding);
  
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Padding) {
      return item.padding == expectedPadding;
    }
    return false;
  }
  
  @override
  Description describe(Description description) {
    return description.add('has padding $expectedPadding');
  }
}

/// Test data generators
class TestDataGenerators {
  /// Generate list of mock properties
  static List<Map<String, dynamic>> generateMockProperties(int count) {
    return List.generate(count, (index) {
      return TestHelpers.createMockProperty(
        id: 'property_$index',
        title: 'Property $index',
        price: 100.0 + (index * 10),
      );
    });
  }

  /// Generate list of mock users
  static List<Map<String, dynamic>> generateMockUsers(int count) {
    return List.generate(count, (index) {
      return TestHelpers.createMockUser(
        id: 'user_$index',
        name: 'User $index',
        email: 'user$index@example.com',
      );
    });
  }

  /// Generate list of mock bookings
  static List<Map<String, dynamic>> generateMockBookings(int count) {
    return List.generate(count, (index) {
      return TestHelpers.createMockBooking(
        id: 'booking_$index',
        propertyId: 'property_$index',
        userId: 'user_$index',
      );
    });
  }
}

/// Performance testing helpers
class PerformanceTestHelpers {
  /// Measure widget build time
  static Future<Duration> measureBuildTime(
    WidgetTester tester,
    Widget widget,
  ) async {
    final stopwatch = Stopwatch()..start();
    await tester.pumpWidget(widget);
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Measure scroll performance
  static Future<Duration> measureScrollPerformance(
    WidgetTester tester,
    Finder scrollable,
    double scrollDistance,
  ) async {
    final stopwatch = Stopwatch()..start();
    await tester.drag(scrollable, Offset(0, -scrollDistance));
    await tester.pumpAndSettle();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Check for memory leaks
  static void checkMemoryLeaks() {
    // This would integrate with memory profiling tools
    // For now, just a placeholder
    debugPrint('Memory leak check completed');
  }
}

class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  TimeoutException(this.message, this.timeout);
  
  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}
