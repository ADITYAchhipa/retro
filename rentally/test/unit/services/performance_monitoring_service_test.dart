import 'package:flutter_test/flutter_test.dart';
import 'package:rentally/core/services/performance_monitoring_service.dart';

void main() {
  group('PerformanceMonitoringService', () {
    late PerformanceMonitoringService service;

    setUp(() {
      service = PerformanceMonitoringService.instance;
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize successfully', () async {
      await service.initialize();
      expect(service, isNotNull);
    });

    test('should start and stop monitoring', () {
      service.startMonitoring();
      service.stopMonitoring();
      expect(service, isNotNull);
    });

    test('should track widget build performance', () {
      service.trackWidgetBuild('TestWidget', const Duration(milliseconds: 10));
      expect(service, isNotNull);
    });

    test('should track async operations', () {
      service.trackAsyncOperation('TestOperation', const Duration(milliseconds: 100));
      expect(service, isNotNull);
    });

    test('should track network requests', () {
      service.trackNetworkRequest('https://api.test.com', const Duration(milliseconds: 200), 200);
      expect(service, isNotNull);
    });

    test('should generate performance report', () {
      final report = service.generateReport();
      
      expect(report.averageFrameRate, greaterThan(0));
      expect(report.averageMemoryUsage, greaterThan(0));
      expect(report.averageCpuUsage, greaterThan(0));
      expect(report.totalMetrics, greaterThanOrEqualTo(0));
    });

    test('should clear metrics', () {
      service.clearMetrics();
      final metrics = service.getMetrics();
      expect(metrics, isEmpty);
    });
  });
}
