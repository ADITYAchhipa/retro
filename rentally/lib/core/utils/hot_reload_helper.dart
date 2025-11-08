import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../config/dev_config.dart';

/// Helper to make authentication work better with hot reload
class HotReloadHelper {
  static DateTime? _lastHotReload;
  
  /// Call this in main() to track hot reloads
  static void trackHotReload() {
    _lastHotReload = DateTime.now();
    if (DevConfig.enableDebugLogs) {
      debugPrint('🔥 Hot reload detected at ${_lastHotReload}');
    }
  }
  
  /// Check if this is a hot reload (useful for maintaining state)
  static bool isHotReload() {
    return _lastHotReload != null && 
           DateTime.now().difference(_lastHotReload!).inSeconds < 5;
  }
  
  /// Refresh auth state after hot reload (call in main widget)
  static void refreshAuthIfNeeded(WidgetRef ref) {
    if (DevConfig.forceAuthRefreshOnHotReload && isHotReload()) {
      // Re-check auth state
      final authState = ref.read(authProvider);
      if (DevConfig.enableDebugLogs) {
        debugPrint('🔄 Auth state after hot reload: ${authState.status}');
      }
    }
  }
}

/// Provider that survives hot reload by using keepAlive
final persistentAuthProvider = Provider<AuthState>((ref) {
  ref.keepAlive(); // This prevents the provider from being disposed on hot reload
  return ref.watch(authProvider);
});
