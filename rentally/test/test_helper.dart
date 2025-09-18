import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Test helper utilities for Rentally app testing
class TestHelper {
  /// Create a test app wrapper with providers
  static Widget createTestApp({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
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

  /// Enter text and submit
  static Future<void> enterTextAndSubmit(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  /// Tap and wait
  static Future<void> tapAndWait(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Scroll to widget
  static Future<void> scrollToWidget(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.scrollUntilVisible(finder, 100);
    await tester.pumpAndSettle();
  }

  /// Verify no exceptions
  static void verifyNoExceptions(WidgetTester tester) {
    expect(tester.takeException(), isNull);
  }

  /// Set screen size
  static Future<void> setScreenSize(
    WidgetTester tester,
    Size size,
  ) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpAndSettle();
  }

  /// Common screen sizes
  static const Size mobileSize = Size(375, 667);
  static const Size tabletSize = Size(768, 1024);
  static const Size desktopSize = Size(1920, 1080);
}
