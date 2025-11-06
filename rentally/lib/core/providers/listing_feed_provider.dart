import 'package:flutter/material.dart';
import '../repositories/listing_repository.dart';
import 'package:geolocator/geolocator.dart';
import '../database/models/property_model.dart';
import '../database/models/vehicle_model.dart';
import '../widgets/listing_card.dart';
import '../utils/price_unit_helper.dart';
import '../../services/view_history_service.dart';

/// ListingFeedProvider exposes combined, UI-ready feeds (as ListingViewModel)
/// for Recommended, Nearby, and RecentlyViewed sections.
class ListingFeedProvider with ChangeNotifier {
  final ListingRepository _repo;
  final ViewHistoryService? _viewHistoryService;
  ListingFeedProvider({ListingRepository? repo, ViewHistoryService? viewHistoryService}) 
    : _repo = repo ?? ListingRepository(),
      _viewHistoryService = viewHistoryService;

  bool _isLoading = false;
  String? _error;

  List<ListingViewModel> _recommended = const [];
  List<ListingViewModel> _nearby = const [];
  List<ListingViewModel> _recently = const [];
  double? _userLat;
  double? _userLng;

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ListingViewModel> get recommended => _recommended;
  List<ListingViewModel> get nearby => _nearby;
  List<ListingViewModel> get recently => _recently;

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _ensureUserLocation();
      final propsF = _repo.getFeaturedProperties();
      final vehsF = _repo.getFeaturedVehicles();
      final props = await _repo.getProperties();
      final vehs = await _repo.getVehicles();

      final featuredProps = await propsF;
      final featuredVehs = await vehsF;

      _recommended = [
        ...featuredProps.map(_vmFromProperty),
        ...featuredVehs.map(_vmFromVehicle),
      ];

      _nearby = [
        ...props.map(_vmFromProperty),
        ...vehs.map(_vmFromVehicle),
      ];
      // compute distances and sort nearby by distance if we have user location
      if (_userLat != null && _userLng != null) {
        _nearby = _nearby.map((vm) => _withDistance(vm)).toList();
        _nearby.sort((a, b) {
          final da = a.distanceKm ?? double.infinity;
          final db = b.distanceKm ?? double.infinity;
          return da.compareTo(db);
        });
      }

      // For recently viewed: use actual view history only. If not present or empty, keep empty.
      if (_viewHistoryService != null) {
        _recently = await _buildRecentlyViewedFromHistory();
      } else {
        _recently = [];
      }
    } catch (e) {
      _error = 'Failed to load listings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return; // gracefully skip
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      _userLat = pos.latitude;
      _userLng = pos.longitude;
    } catch (_) {
      // ignore errors, fallback to unsorted nearby
    }
  }

  ListingViewModel _vmFromProperty(PropertyModel p) {
    final res = PriceUnitHelper.forProperty(p);
    return ListingViewModel(
      id: p.id,
      title: p.title,
      location: p.location,
      priceLabel: PriceUnitHelper.format(res),
      originalPriceLabel: PriceUnitHelper.formatOriginal(res),
      discountPercent: res.discountPercent,
      rentalUnit: res.unit,
      imageUrl: p.images.isNotEmpty ? p.images.first : null,
      rating: p.rating,
      reviewCount: p.reviewCount,
      chips: [
        _capitalized(p.type.name),
        if (p.amenities.isNotEmpty) p.amenities.first,
      ],
      metaItems: [
        ListingMetaItem(icon: Icons.bed, text: '${p.bedrooms} bd'),
        ListingMetaItem(icon: Icons.bathtub, text: '${p.bathrooms} ba'),
      ],
      fallbackIcon: Icons.home,
      isVehicle: false,
      latitude: p.latitude,
      longitude: p.longitude,
    );
  }

  ListingViewModel _vmFromVehicle(VehicleModel v) {
    final res = PriceUnitHelper.forVehicle(v);
    return ListingViewModel(
      id: v.id,
      title: v.title,
      location: v.location,
      priceLabel: PriceUnitHelper.format(res),
      originalPriceLabel: PriceUnitHelper.formatOriginal(res),
      discountPercent: res.discountPercent,
      rentalUnit: res.unit,
      imageUrl: v.images.isNotEmpty ? v.images.first : null,
      rating: v.rating,
      reviewCount: v.reviewCount,
      chips: ['${v.category} • ${v.seats} seats'],
      metaItems: [
        ListingMetaItem(icon: Icons.settings, text: v.transmission),
        ListingMetaItem(icon: v.fuel.toLowerCase() == 'electric' ? Icons.electric_bolt : Icons.local_gas_station, text: v.fuel),
      ],
      fallbackIcon: Icons.directions_car,
      isVehicle: true,
      latitude: v.latitude,
      longitude: v.longitude,
    );
  }

  ListingViewModel _withDistance(ListingViewModel vm) {
    if (_userLat == null || _userLng == null || vm.latitude == null || vm.longitude == null) return vm;
    final meters = Geolocator.distanceBetween(_userLat!, _userLng!, vm.latitude!, vm.longitude!);
    return ListingViewModel(
      id: vm.id,
      title: vm.title,
      location: vm.location,
      priceLabel: vm.priceLabel,
      originalPriceLabel: vm.originalPriceLabel,
      discountPercent: vm.discountPercent,
      rentalUnit: vm.rentalUnit,
      imageUrl: vm.imageUrl,
      rating: vm.rating,
      reviewCount: vm.reviewCount,
      chips: vm.chips,
      metaItems: vm.metaItems,
      fallbackIcon: vm.fallbackIcon,
      isVehicle: vm.isVehicle,
      latitude: vm.latitude,
      longitude: vm.longitude,
      distanceKm: meters / 1000.0,
    );
  }

  /// Build recently viewed list from actual view history
  Future<List<ListingViewModel>> _buildRecentlyViewedFromHistory() async {
    if (_viewHistoryService == null) return [];
    
    final recentItems = _viewHistoryService!.recentlyViewed.take(10).toList();
    final List<ListingViewModel> viewModels = [];
    
    // Get all properties and vehicles to match with history
    final allProps = await _repo.getProperties();
    final allVehs = await _repo.getVehicles();
    
    for (final historyItem in recentItems) {
      if (historyItem.type == 'property') {
        final property = allProps.where((p) => p.id == historyItem.id).firstOrNull;
        if (property != null) {
          viewModels.add(_vmFromProperty(property));
        }
      } else if (historyItem.type == 'vehicle') {
        final vehicle = allVehs.where((v) => v.id == historyItem.id).firstOrNull;
        if (vehicle != null) {
          viewModels.add(_vmFromVehicle(vehicle));
        }
      }
    }
    
    return viewModels;
  }

  String _capitalized(String name) => name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
}
