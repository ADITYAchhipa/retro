import 'package:flutter_test/flutter_test.dart';
import 'package:rentally/core/services/error_handling_service.dart';

void main() {
  group('ErrorHandlingService', () {
    late ErrorHandlingService service;

    setUp(() {
      service = ErrorHandlingService();
    });

    test('should initialize without errors', () {
      expect(() => service.initialize(), returnsNormally);
    });

    test('should log errors without throwing', () {
      expect(() => service.logError('test error', StackTrace.current, 'test context'), returnsNormally);
    });

    test('should handle async operations', () async {
      final result = await service.handleAsync<String>(() async {
        return 'success';
      });
      
      expect(result, equals('success'));
    });

    test('should handle async errors gracefully', () async {
      final result = await service.handleAsync<String>(() async {
        throw Exception('test error');
      });
      
      expect(result, isNull);
    });
  });
}
