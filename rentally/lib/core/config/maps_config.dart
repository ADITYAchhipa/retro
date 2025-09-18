import 'package:flutter/foundation.dart';

/// Centralized feature flag for Google Maps usage.
///
/// To enable maps at runtime, pass:
///   flutter run --dart-define=ENABLE_MAPS=true
/// and make sure the native API key is configured per platform.
class MapsConfig {
  static const bool enableMaps = bool.fromEnvironment('ENABLE_MAPS', defaultValue: false);

  static bool get isEnabled => enableMaps && !kIsWeb; // google_maps_flutter is not supported on web by default
}
