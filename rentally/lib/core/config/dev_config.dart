/// Development Configuration
/// This file helps with hot reload during development
class DevConfig {
  // Set to true during development to enable features that work better with hot reload
  static const bool isDevelopmentMode = true;
  
  // Enable debug logging
  static const bool enableDebugLogs = true;
  
  // Skip certain initialization that requires full restart
  static const bool skipHeavyInitialization = false;
  
  // Force refresh auth state on hot reload
  static const bool forceAuthRefreshOnHotReload = true;
  
  // Default test credentials for quick testing
  static const String defaultTestEmail = 'user@test.com';
  static const String defaultTestPassword = 'user123';
}
