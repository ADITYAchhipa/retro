import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global UI visibility flags for immersive routes (detail, booking, etc.)
final immersiveRouteOpenProvider = StateProvider<bool>((ref) => false);
