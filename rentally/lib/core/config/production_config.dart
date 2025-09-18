import 'package:flutter/foundation.dart';

/// Production-ready configuration for industrial-grade deployment
class ProductionConfig {
  // API Configuration
  static const String baseUrl = kDebugMode 
      ? 'https://api-dev.rentally.com'
      : 'https://api.rentally.com';
  
  static const String websocketUrl = kDebugMode
      ? 'wss://ws-dev.rentally.com'
      : 'wss://ws.rentally.com';
  
  // App Configuration
  static const String appName = 'Rentally';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  
  // Security Configuration
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  
  // Cache Configuration
  static const Duration cacheExpiry = Duration(hours: 1);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int maxImageCacheSize = 50 * 1024 * 1024; // 50MB
  
  // Network Configuration
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // Performance Configuration
  static const int listPageSize = 20;
  static const int maxConcurrentRequests = 5;
  static const Duration debounceDelay = Duration(milliseconds: 500);
  
  // Feature Flags
  static const bool enableAnalytics = !kDebugMode;
  static const bool enableCrashReporting = !kDebugMode;
  static const bool enablePerformanceMonitoring = !kDebugMode;
  static const bool enableOfflineMode = true;
  static const bool enableBiometricAuth = true;
  static const bool enablePushNotifications = true;
  
  // Logging Configuration
  static const bool enableLogging = kDebugMode;
  static const bool enableNetworkLogging = kDebugMode;
  static const bool enablePerformanceLogging = kDebugMode;
  
  // Storage Configuration
  static const String databaseName = 'rentally.db';
  static const int databaseVersion = 1;
  static const String preferencesPrefix = 'rentally_';
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Validation Configuration
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 1000;
  
  // File Upload Configuration
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB
  static const int maxDocumentSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedVideoTypes = ['mp4', 'mov', 'avi'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];
  
  // Notification Configuration
  static const Duration notificationRetryDelay = Duration(seconds: 30);
  static const int maxNotificationRetries = 3;
  
  // Location Configuration
  static const double defaultLatitude = 37.7749;
  static const double defaultLongitude = -122.4194;
  static const double locationAccuracyThreshold = 100.0; // meters
  
  // Payment Configuration
  static const List<String> supportedCurrencies = ['USD', 'EUR', 'GBP', 'CAD'];
  static const String defaultCurrency = 'USD';
  static const double minBookingAmount = 10.0;
  static const double maxBookingAmount = 10000.0;
  
  // Search Configuration
  static const int maxSearchResults = 100;
  static const double defaultSearchRadius = 50.0; // km
  static const int maxSearchHistory = 10;
  
  // Chat Configuration
  static const int maxMessageLength = 1000;
  static const Duration typingIndicatorTimeout = Duration(seconds: 3);
  static const int maxChatHistory = 100;
  
  // Review Configuration
  static const int minReviewLength = 10;
  static const int maxReviewLength = 500;
  static const double minRating = 1.0;
  static const double maxRating = 5.0;
  
  // Booking Configuration
  static const Duration minBookingDuration = Duration(hours: 1);
  static const Duration maxBookingDuration = Duration(days: 30);
  static const Duration cancellationWindow = Duration(hours: 24);
  
  // Environment-specific configurations
  static bool get isProduction => !kDebugMode;
  static bool get isDevelopment => kDebugMode;
  
  // Get configuration based on environment
  static T getConfig<T>(T development, T production) {
    return kDebugMode ? development : production;
  }
  
  // Validate configuration
  static bool validateConfig() {
    // Validate critical configurations
    if (baseUrl.isEmpty) return false;
    if (appName.isEmpty) return false;
    if (appVersion.isEmpty) return false;
    if (buildNumber <= 0) return false;
    
    // Validate timeouts
    if (connectTimeout.inSeconds <= 0) return false;
    if (receiveTimeout.inSeconds <= 0) return false;
    if (sendTimeout.inSeconds <= 0) return false;
    
    // Validate cache sizes
    if (maxCacheSize <= 0) return false;
    if (maxImageCacheSize <= 0) return false;
    
    // Validate file sizes
    if (maxImageSize <= 0) return false;
    if (maxVideoSize <= 0) return false;
    if (maxDocumentSize <= 0) return false;
    
    return true;
  }
  
  // Get user agent string
  static String getUserAgent() {
    return '$appName/$appVersion (${isProduction ? 'production' : 'development'})';
  }
  
  // Get API headers
  static Map<String, String> getApiHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': getUserAgent(),
      'X-App-Version': appVersion,
      'X-Build-Number': buildNumber.toString(),
    };
  }
  
  // Get database configuration
  static Map<String, dynamic> getDatabaseConfig() {
    return {
      'name': databaseName,
      'version': databaseVersion,
      'enableWAL': isProduction,
      'enableForeignKeys': true,
      'pageSize': 4096,
      'cacheSize': isProduction ? 2000 : 1000,
    };
  }
  
  // Get logging configuration
  static Map<String, dynamic> getLoggingConfig() {
    return {
      'enableLogging': enableLogging,
      'enableNetworkLogging': enableNetworkLogging,
      'enablePerformanceLogging': enablePerformanceLogging,
      'logLevel': isProduction ? 'ERROR' : 'DEBUG',
      'maxLogFiles': 5,
      'maxLogFileSize': 10 * 1024 * 1024, // 10MB
    };
  }
  
  // Get security configuration
  static Map<String, dynamic> getSecurityConfig() {
    return {
      'enableCertificatePinning': isProduction,
      'enableRootDetection': isProduction,
      'enableDebugDetection': isProduction,
      'enableTamperDetection': isProduction,
      'tokenRefreshThreshold': tokenRefreshThreshold.inMinutes,
      'sessionTimeout': sessionTimeout.inHours,
      'maxLoginAttempts': maxLoginAttempts,
      'lockoutDuration': lockoutDuration.inMinutes,
    };
  }
  
  // Get performance configuration
  static Map<String, dynamic> getPerformanceConfig() {
    return {
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'enableMemoryProfiling': isDevelopment,
      'enableNetworkProfiling': isDevelopment,
      'enableRenderProfiling': isDevelopment,
      'maxConcurrentRequests': maxConcurrentRequests,
      'listPageSize': listPageSize,
      'debounceDelay': debounceDelay.inMilliseconds,
    };
  }
}
