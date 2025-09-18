import 'dart:async';
import 'package:flutter/foundation.dart';

/// Simplified Performance Monitoring Service for Frontend-Only App
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance = PerformanceMonitoringService._internal();
  static PerformanceMonitoringService get instance => _instance;
  
  PerformanceMonitoringService._internal();

  bool _isInitialized = false;
  bool _isMonitoring = false;
  final List<PerformanceMetric> _metrics = [];
  final int _maxMetrics = 1000;
  Timer? _monitoringTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isInitialized = true;
    if (kDebugMode) {
      print('Performance Monitoring Service initialized');
    }
  }

  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _collectMetrics();
    });
    
    if (kDebugMode) {
      print('Performance monitoring started');
    }
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    
    if (kDebugMode) {
      print('Performance monitoring stopped');
    }
  }

  void _collectMetrics() {
    final now = DateTime.now();
    final frameRate = _estimateFrameRate();
    
    final metric = PerformanceMetric(
      timestamp: now,
      frameRate: frameRate,
      memoryUsage: _estimateMemoryUsage(),
      cpuUsage: _estimateCpuUsage(),
    );
    
    _addMetric(metric);
  }

  double _estimateFrameRate() {
    // Simplified frame rate estimation
    return 60.0; // Default to 60 FPS for frontend-only app
  }

  double _estimateMemoryUsage() {
    // Simplified memory usage estimation
    return 50.0; // Default to 50MB for frontend-only app
  }

  double _estimateCpuUsage() {
    // Simplified CPU usage estimation
    return 10.0; // Default to 10% for frontend-only app
  }

  void _addMetric(PerformanceMetric metric) {
    _metrics.add(metric);
    if (_metrics.length > _maxMetrics) {
      _metrics.removeAt(0);
    }
  }

  void trackWidgetBuild(String widgetName, Duration buildTime) {
    if (kDebugMode) {
      print('Widget build: $widgetName took ${buildTime.inMilliseconds}ms');
    }
  }

  void trackAsyncOperation(String operationName, Duration duration) {
    if (kDebugMode) {
      print('Async operation: $operationName took ${duration.inMilliseconds}ms');
    }
  }

  void trackNetworkRequest(String url, Duration duration, int statusCode) {
    if (kDebugMode) {
      print('Network request: $url took ${duration.inMilliseconds}ms (status: $statusCode)');
    }
  }

  PerformanceReport generateReport() {
    if (_metrics.isEmpty) {
      return PerformanceReport(
        averageFrameRate: 60.0,
        averageMemoryUsage: 50.0,
        averageCpuUsage: 10.0,
        totalMetrics: 0,
        reportGeneratedAt: DateTime.now(),
      );
    }

    final avgFrameRate = _metrics.map((m) => m.frameRate).reduce((a, b) => a + b) / _metrics.length;
    final avgMemoryUsage = _metrics.map((m) => m.memoryUsage).reduce((a, b) => a + b) / _metrics.length;
    final avgCpuUsage = _metrics.map((m) => m.cpuUsage).reduce((a, b) => a + b) / _metrics.length;

    return PerformanceReport(
      averageFrameRate: avgFrameRate,
      averageMemoryUsage: avgMemoryUsage,
      averageCpuUsage: avgCpuUsage,
      totalMetrics: _metrics.length,
      reportGeneratedAt: DateTime.now(),
    );
  }

  List<PerformanceMetric> getMetrics() => List.unmodifiable(_metrics);

  void clearMetrics() {
    _metrics.clear();
  }

  void dispose() {
    stopMonitoring();
    _metrics.clear();
    _isInitialized = false;
  }
}

class PerformanceMetric {
  final DateTime timestamp;
  final double frameRate;
  final double memoryUsage;
  final double cpuUsage;

  PerformanceMetric({
    required this.timestamp,
    required this.frameRate,
    required this.memoryUsage,
    required this.cpuUsage,
  });
}

class PerformanceReport {
  final double averageFrameRate;
  final double averageMemoryUsage;
  final double averageCpuUsage;
  final int totalMetrics;
  final DateTime reportGeneratedAt;

  PerformanceReport({
    required this.averageFrameRate,
    required this.averageMemoryUsage,
    required this.averageCpuUsage,
    required this.totalMetrics,
    required this.reportGeneratedAt,
  });
}
