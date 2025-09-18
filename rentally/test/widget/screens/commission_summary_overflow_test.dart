import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rentally/features/owner/clean_owner_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpOwnerDashboard(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: CleanOwnerDashboardScreen(),
        ),
      ),
    );
    // Allow initial async work to complete (dashboard mock delay is 2s)
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }

  void drainFlutterErrors(WidgetTester tester) {
    // Clear out any previously thrown framework/layout exceptions so our
    // assertions only consider errors occurring after switching to Earnings.
    dynamic e;
    do {
      e = tester.takeException();
    } while (e != null);
  }

  testWidgets('Commission Summary renders without overflow across common breakpoints', (tester) async {
    const heights = 800.0;
    const widths = <double>[320, 360, 390, 414, 480, 600];

    for (final w in widths) {
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await pumpOwnerDashboard(tester, Size(w, heights));

      // Drain any exceptions that might have occurred while rendering the
      // initial Overview tab so they don't affect this Earnings-specific test.
      drainFlutterErrors(tester);

      // Switch to the Earnings tab to reveal Commission Summary
      expect(find.text('Earnings'), findsOneWidget);
      await tester.tap(find.text('Earnings'));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Ensure the section title exists
      expect(find.text('Commission Summary'), findsOneWidget);

      // Scroll a bit to layout nested content if needed
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // If any overflow happened during build/layout, it would surface as a test exception
      expect(tester.takeException(), isNull, reason: 'No exceptions expected at width $w');
    }
  });
}
