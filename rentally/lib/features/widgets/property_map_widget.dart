import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/listing_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/config/maps_config.dart';

class PropertyMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String title;
  final List<Listing>? nearbyListings;
  final bool showNearbyListings;

  const PropertyMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.nearbyListings,
    this.showNearbyListings = false,
  });

  @override
  State<PropertyMapWidget> createState() => _PropertyMapWidgetState();
}

class _PropertyMapWidgetState extends State<PropertyMapWidget> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  void _createMarkers() {
    _markers.clear();
    
    // Main property marker
    _markers.add(
      Marker(
        markerId: const MarkerId('main_property'),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(
          title: widget.title,
          snippet: 'Selected Property',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Nearby listings markers
    if (widget.showNearbyListings && widget.nearbyListings != null) {
      for (int i = 0; i < widget.nearbyListings!.length; i++) {
        final listing = widget.nearbyListings![i];
        _markers.add(
          Marker(
            markerId: MarkerId('nearby_$i'),
            position: const LatLng(37.7749, -122.4194), // Mock coordinates
            infoWindow: InfoWindow(
              title: listing.title,
              snippet: () {
                final ru = (listing.rentalUnit ?? '').trim().toLowerCase();
                final isVehicle = listing.type.toLowerCase() == 'vehicle';
                final fallback = isVehicle ? 'hour' : 'day';
                final unit = ru.isNotEmpty ? ru : fallback;
                return CurrencyFormatter.formatPricePerUnit(listing.price, unit);
              }(),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!MapsConfig.isEnabled) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 28, color: Colors.grey),
              SizedBox(height: 8),
              Text('Maps disabled', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.latitude, widget.longitude),
            zoom: widget.showNearbyListings ? 14.0 : 16.0,
          ),
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _controller = controller;
          },
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class LocationPickerWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double latitude, double longitude, String address) onLocationSelected;

  const LocationPickerWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  GoogleMapController? _controller;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _updateMarker();
    }
  }

  void _updateMarker() {
    if (_selectedLocation != null) {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          draggable: true,
          onDragEnd: (LatLng position) {
            setState(() {
              _selectedLocation = position;
            });
            _notifyLocationChange();
          },
        ),
      );
    }
  }

  void _notifyLocationChange() {
    if (_selectedLocation != null) {
      // In a real app, you would use geocoding to get the address
      final address = '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}';
      widget.onLocationSelected(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        address,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: MapsConfig.isEnabled
            ? GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ?? const LatLng(37.7749, -122.4194), // Default to SF
                zoom: 14.0,
              ),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
              onTap: (LatLng position) {
                setState(() {
                  _selectedLocation = position;
                  _updateMarker();
                });
                _notifyLocationChange();
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            )
            : const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 28, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Maps disabled', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
