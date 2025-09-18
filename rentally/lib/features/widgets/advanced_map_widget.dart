import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/utils/currency_formatter.dart';
import 'dart:math' as math;
import '../../core/config/maps_config.dart';

class MapProperty {
  final String id;
  final String title;
  final String imageUrl;
  final double price;
  final double rating;
  final LatLng position;
  final String propertyType;

  const MapProperty({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.position,
    required this.propertyType,
  });
}

class PropertyCluster {
  final LatLng center;
  final List<MapProperty> properties;
  final int count;

  const PropertyCluster({
    required this.center,
    required this.properties,
    required this.count,
  });
}

class MapClusteringService {
  static const double _clusterRadius = 100.0; // pixels

  static List<PropertyCluster> clusterProperties(
    List<MapProperty> properties,
    double zoomLevel,
    Size mapSize,
    LatLngBounds bounds,
  ) {
    if (properties.isEmpty) return [];
    
    // Don't cluster at high zoom levels
    if (zoomLevel > 14) {
      return properties.map((property) => PropertyCluster(
        center: property.position,
        properties: [property],
        count: 1,
      )).toList();
    }

    final clusters = <PropertyCluster>[];
    final processed = <bool>[];
    
    for (int i = 0; i < properties.length; i++) {
      processed.add(false);
    }

    for (int i = 0; i < properties.length; i++) {
      if (processed[i]) continue;

      final clusterProperties = <MapProperty>[properties[i]];
      processed[i] = true;

      for (int j = i + 1; j < properties.length; j++) {
        if (processed[j]) continue;

        final distance = _calculateDistance(
          properties[i].position,
          properties[j].position,
        );

        // Cluster if properties are close enough
        if (distance < _clusterRadius / (zoomLevel * 2)) {
          clusterProperties.add(properties[j]);
          processed[j] = true;
        }
      }

      // Calculate cluster center
      final centerLat = clusterProperties
          .map((p) => p.position.latitude)
          .reduce((a, b) => a + b) / clusterProperties.length;
      final centerLng = clusterProperties
          .map((p) => p.position.longitude)
          .reduce((a, b) => a + b) / clusterProperties.length;

      clusters.add(PropertyCluster(
        center: LatLng(centerLat, centerLng),
        properties: clusterProperties,
        count: clusterProperties.length,
      ));
    }

    return clusters;
  }

  static double _calculateDistance(LatLng pos1, LatLng pos2) {
    const double earthRadius = 6371000; // meters
    final double lat1Rad = pos1.latitude * (math.pi / 180);
    final double lat2Rad = pos2.latitude * (math.pi / 180);
    final double deltaLatRad = (pos2.latitude - pos1.latitude) * (math.pi / 180);
    final double deltaLngRad = (pos2.longitude - pos1.longitude) * (math.pi / 180);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }
}

class AdvancedMapWidget extends ConsumerStatefulWidget {
  final List<MapProperty> properties;
  final Function(MapProperty)? onPropertyTapped;
  final Function(PropertyCluster)? onClusterTapped;
  final LatLng? initialPosition;
  final double initialZoom;
  final bool showUserLocation;
  final bool enableClustering;

  const AdvancedMapWidget({
    super.key,
    required this.properties,
    this.onPropertyTapped,
    this.onClusterTapped,
    this.initialPosition,
    this.initialZoom = 12.0,
    this.showUserLocation = true,
    this.enableClustering = true,
  });

  @override
  ConsumerState<AdvancedMapWidget> createState() => _AdvancedMapWidgetState();
}

class _AdvancedMapWidgetState extends ConsumerState<AdvancedMapWidget> {
  GoogleMapController? _controller;
  double _currentZoom = 12.0;
  Set<Marker> _markers = {};
  List<PropertyCluster> _clusters = [];
  MapProperty? _selectedProperty;

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.initialZoom;
    _updateClusters();
  }

  @override
  void didUpdateWidget(AdvancedMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.properties != widget.properties) {
      _updateClusters();
    }
  }

  Future<void> _loadMapStyle() async {
    // Load custom map style if needed
    // This is a placeholder for custom map styling
  }

  void _updateClusters() async {
    if (!widget.enableClustering) {
      _clusters = widget.properties.map((property) => PropertyCluster(
        center: property.position,
        properties: [property],
        count: 1,
      )).toList();
    } else {
      _clusters = MapClusteringService.clusterProperties(
        widget.properties,
        _currentZoom,
        const Size(400, 600), // Approximate map size
        LatLngBounds(
          southwest: const LatLng(37.4219999, -122.0840575),
          northeast: const LatLng(37.4419999, -122.0640575),
        ),
      );
    }
    _updateMarkers();
  }

  void _updateMarkers() {
    final newMarkers = <Marker>{};

    for (final cluster in _clusters) {
      if (cluster.count == 1) {
        // Single property marker
        final property = cluster.properties.first;
        newMarkers.add(
          Marker(
            markerId: MarkerId(property.id),
            position: property.position,
            onTap: () {
              setState(() {
                _selectedProperty = property;
              });
              widget.onPropertyTapped?.call(property);
            },
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerColor(property.propertyType),
            ),
          ),
        );
      } else {
        // Cluster marker
        newMarkers.add(
          Marker(
            markerId: MarkerId('cluster_${cluster.center.latitude}_${cluster.center.longitude}'),
            position: cluster.center,
            onTap: () {
              if (_currentZoom < 16) {
                _controller?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: cluster.center,
                      zoom: _currentZoom + 2,
                    ),
                  ),
                );
              } else {
                widget.onClusterTapped?.call(cluster);
                _showClusterBottomSheet(cluster);
              }
            },
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    }

    setState(() {
      _markers = newMarkers;
    });
  }


  double _getMarkerColor(String propertyType) {
    switch (propertyType.toLowerCase()) {
      case 'apartment':
        return BitmapDescriptor.hueRed;
      case 'house':
        return BitmapDescriptor.hueGreen;
      case 'villa':
        return BitmapDescriptor.hueBlue;
      case 'studio':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  void _showClusterBottomSheet(PropertyCluster cluster) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClusterBottomSheet(
        cluster: cluster,
        onPropertySelected: (property) {
          Navigator.of(context).pop();
          setState(() {
            _selectedProperty = property;
          });
          widget.onPropertyTapped?.call(property);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!MapsConfig.isEnabled) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 28, color: Colors.grey),
            const SizedBox(height: 8),
            Text('Maps disabled', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialPosition ?? const LatLng(37.4219999, -122.0840575),
            zoom: _currentZoom,
          ),
          markers: _markers,
          onMapCreated: (GoogleMapController controller) async {
            _controller = controller;
            await _loadMapStyle();
          },
          onCameraMove: (CameraPosition position) {
            _currentZoom = position.zoom;
          },
          onCameraIdle: () {
            _updateClusters();
          },
          myLocationEnabled: widget.showUserLocation,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),

        // Map Controls
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // Map Type Toggle
              FloatingActionButton.small(
                heroTag: "map_type",
                onPressed: () {
                  // Toggle map type
                },
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: theme.colorScheme.onSurface,
                child: const Icon(Icons.layers),
              ),
              const SizedBox(height: 8),
              
              // My Location
              if (widget.showUserLocation)
                FloatingActionButton.small(
                  heroTag: "my_location",
                  onPressed: () {
                    // Center on user location
                  },
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  child: const Icon(Icons.my_location),
                ),
            ],
          ),
        ),

        // Selected Property Card
        if (_selectedProperty != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: PropertyMapCard(
              property: _selectedProperty!,
              onClose: () {
                setState(() {
                  _selectedProperty = null;
                });
              },
              onTap: () {
                widget.onPropertyTapped?.call(_selectedProperty!);
              },
            ),
          ),

        // Zoom Controls
        Positioned(
          bottom: _selectedProperty != null ? 200 : 100,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: "zoom_in",
                onPressed: () {
                  _controller?.animateCamera(CameraUpdate.zoomIn());
                },
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: theme.colorScheme.onSurface,
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: "zoom_out",
                onPressed: () {
                  _controller?.animateCamera(CameraUpdate.zoomOut());
                },
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: theme.colorScheme.onSurface,
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PropertyMapCard extends StatelessWidget {
  final MapProperty property;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const PropertyMapCard({
    super.key,
    required this.property,
    required this.onClose,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Property Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  property.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: theme.colorScheme.surfaceVariant,
                      child: const Icon(Icons.image),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Property Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${property.rating}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          property.propertyType,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatPricePerUnit(property.price, 'night'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Close Button
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                iconSize: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClusterBottomSheet extends StatelessWidget {
  final PropertyCluster cluster;
  final Function(MapProperty) onPropertySelected;

  const ClusterBottomSheet({
    super.key,
    required this.cluster,
    required this.onPropertySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${cluster.count} Properties in this area',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Properties List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cluster.properties.length,
              itemBuilder: (context, index) {
                final property = cluster.properties[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        property.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: theme.colorScheme.surfaceVariant,
                            child: const Icon(Icons.image),
                          );
                        },
                      ),
                    ),
                    title: Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text('${property.rating}'),
                        const SizedBox(width: 8),
                        Text(property.propertyType),
                      ],
                    ),
                    trailing: Text(
                      CurrencyFormatter.formatPrice(property.price),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    onTap: () => onPropertySelected(property),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
