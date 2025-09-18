import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:rentally/core/services/accessibility_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AccessibilityService', () {
    late AccessibilityService service;

    setUp(() {
      service = AccessibilityService.instance;
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize successfully', () async {
      await service.initialize();
      expect(service, isNotNull);
    });

    test('should validate color contrast', () {
      final isValid = service.validateColorContrast(
        Colors.black,
        Colors.white,
        level: ContrastLevel.aa,
      );
      
      expect(isValid, isTrue);
    });

    test('should get accessible color', () {
      final accessibleColor = service.getAccessibleColor(
        Colors.grey,
        preferDark: true,
      );
      
      expect(accessibleColor, isA<Color>());
    });

    test('should handle focus navigation', () {
      final focusNode = FocusNode();
      service.registerFocusNode('test_widget', focusNode);
      
      service.focusNext();
      service.focusPrevious();
      
      service.unregisterFocusNode('test_widget');
      focusNode.dispose();
    });

    test('should create accessible widgets', () {
      final button = service.createAccessibleButton(
        label: 'Test Button',
        onPressed: () {},
      );
      
      expect(button, isA<Widget>());
    });

    test('should wrap widgets with accessibility', () {
      final wrappedWidget = service.wrapWithAccessibility(
        const Text('Test'),
        label: 'Test Label',
        button: true,
      );
      
      expect(wrappedWidget, isA<Widget>());
    });

    test('should announce messages', () {
      expect(() {
        service.announce('Test announcement');
      }, returnsNormally);
    });

    test('should provide accessibility properties', () {
      expect(service.isScreenReaderEnabled, isA<bool>());
      expect(service.isHighContrastEnabled, isA<bool>());
      expect(service.textScaleFactor, isA<double>());
    });
  });
}
