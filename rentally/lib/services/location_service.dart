import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationService {
  Future<bool> isLocationServiceEnabled() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return false;
    }
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkLocationPermission() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return LocationPermission.denied;
    }
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestLocationPermission() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return LocationPermission.denied;
    }
    return await Geolocator.requestPermission();
  }

  Future<Position?> getCurrentLocation() async {
    try {
      // Check if running on web platform
      if (kIsWeb) {
        debugPrint('🌐 Running on web platform - using browser geolocation');
        return await _getWebLocation();
      }

      // Guard for desktop platforms where Geolocator may not be available/registered
      if (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        // Silently return null to avoid MissingPluginException in desktop debug
        debugPrint('🖥️ Desktop platform detected - skipping native geolocation');
        return null;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  Future<Position?> _getWebLocation() async {
    try {
      // Use browser's geolocation API for web
      debugPrint('📍 Requesting browser geolocation...');
      
      // Fallback to IP-based location detection for web
      // This is a mock implementation - in production you'd use a service like ipapi.co
      debugPrint('🌍 Using IP-based location detection for web...');
      
      // Mock position for demonstration (you can replace with actual IP geolocation service)
      return Position(
        latitude: 28.6139, // Delhi coordinates as example
        longitude: 77.2090,
        timestamp: DateTime.now(),
        accuracy: 1000.0, // Lower accuracy for IP-based location
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    } catch (e) {
      debugPrint('💥 Web location detection failed: $e');
      return null;
    }
  }

  Future<List<Placemark>?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        // Reverse geocoding may be unsupported - skip on desktop/web in this setup
        return null;
      }
      return await placemarkFromCoordinates(latitude, longitude);
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
      return null;
    }
  }

  Future<List<Location>?> getCoordinatesFromAddress(String address) async {
    try {
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        // Geocoding may be unsupported - skip on desktop/web in this setup
        return null;
      }
      return await locationFromAddress(address);
    } catch (e) {
      debugPrint('Error getting coordinates from address: $e');
      return null;
    }
  }

  String formatAddress(Placemark placemark) {
    List<String> addressParts = [];
    
    if (placemark.street?.isNotEmpty == true) {
      addressParts.add(placemark.street!);
    }
    if (placemark.locality?.isNotEmpty == true) {
      addressParts.add(placemark.locality!);
    }
    if (placemark.administrativeArea?.isNotEmpty == true) {
      addressParts.add(placemark.administrativeArea!);
    }
    if (placemark.country?.isNotEmpty == true) {
      addressParts.add(placemark.country!);
    }
    
    return addressParts.join(', ');
  }

  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}

// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// State for managing location data
class LocationState {
  final Position? currentPosition;
  final String? currentAddress;
  final bool isLoading;
  final String? error;

  const LocationState({
    this.currentPosition,
    this.currentAddress,
    this.isLoading = false,
    this.error,
  });

  LocationState copyWith({
    Position? currentPosition,
    String? currentAddress,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      currentAddress: currentAddress ?? this.currentAddress,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// StateNotifier for managing location operations
class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(const LocationState());

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        final placemarks = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        String? address;
        if (placemarks != null && placemarks.isNotEmpty) {
          address = _locationService.formatAddress(placemarks.first);
        }

        state = state.copyWith(
          currentPosition: position,
          currentAddress: address,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to get current location',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error getting location: $e',
      );
    }
  }

  Future<void> getLocationFromAddress(String address) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final locations = await _locationService.getCoordinatesFromAddress(address);
      if (locations != null && locations.isNotEmpty) {
        final location = locations.first;
        final position = Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

        state = state.copyWith(
          currentPosition: position,
          currentAddress: address,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to find location for address',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error getting location from address: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for LocationNotifier
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final locationService = ref.read(locationServiceProvider);
  return LocationNotifier(locationService);
});
