// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rentally/main.dart';

void main() {
  testWidgets('App loads successfully', (tester) async {
    // Test that the app can be instantiated without errors
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    
    // Wait for initial render
    await tester.pump();
    // Allow any startup delayed timers/animations (e.g., splash typewriter delay) to complete
    await tester.pump(const Duration(seconds: 1));
    
    // Verify the app widget tree is built successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
