import '../services/mock_api_service.dart';
import '../database/models/property_model.dart';
import '../database/models/vehicle_model.dart';

/// ListingRepository centralizes fetching for both properties and vehicles.
/// Initially backed by the mock RealApiService; when a real backend is ready,
/// swap RealApiService with the real implementation without changing UI.
class ListingRepository {
  final RealApiService _api;
  ListingRepository({RealApiService? api}) : _api = api ?? RealApiService();

  // Properties
  Future<List<PropertyModel>> getFeaturedProperties() async {
    final list = await _api.getFeaturedProperties();
    return list.map((e) => PropertyModel.fromJson(e)).toList();
  }

  Future<List<PropertyModel>> getProperties({int? page, int? limit}) async {
    final data = await _api.getProperties();
    // Apply pagination if specified
    if (page != null && limit != null) {
      final startIndex = (page - 1) * limit;
      final paginatedData = data.skip(startIndex).take(limit).toList();
      return paginatedData.map((json) => PropertyModel.fromJson(json)).toList();
    }
    return data.map((json) => PropertyModel.fromJson(json)).toList();
  }

  // Vehicles
  Future<List<VehicleModel>> getFeaturedVehicles() async {
    final list = await _api.getFeaturedVehicles();
    return list.map((e) => VehicleModel.fromJson(e)).toList();
  }

  Future<List<VehicleModel>> getVehicles({int? page, int? limit}) async {
    final data = await _api.getVehicles();
    // Apply pagination if specified
    if (page != null && limit != null) {
      final startIndex = (page - 1) * limit;
      final paginatedData = data.skip(startIndex).take(limit).toList();
      return paginatedData.map((json) => VehicleModel.fromJson(json)).toList();
    }
    return data.map((json) => VehicleModel.fromJson(json)).toList();
  }
}
