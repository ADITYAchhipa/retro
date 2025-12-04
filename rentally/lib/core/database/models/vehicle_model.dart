/// Vehicle model representing rental vehicles in the database
class VehicleModel {
  final String id;
  final String title;
  final String location;
  final double pricePerDay;
  final double? pricePerHour;
  final double? discountPercent;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final String category; // SUV, Sedan, Electric, etc.
  final int seats;
  final String transmission; // Auto / Manual
  final String fuel; // Petrol / Diesel / Electric / Hybrid
  final bool isFeatured;
  final double? latitude;
  final double? longitude;

  VehicleModel({
    required this.id,
    required this.title,
    required this.location,
    required this.pricePerDay,
    this.pricePerHour,
    this.discountPercent,
    required this.images,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.seats,
    required this.transmission,
    required this.fuel,
    required this.isFeatured,
    this.latitude,
    this.longitude,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    List<String> toStringList(dynamic v) {
      if (v == null) return <String>[];
      if (v is List) {
        return v.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      }
      return <String>[];
    }

    final String id = (json['_id'] ?? json['id'] ?? '').toString();
    
    // Backend uses make + model, frontend expects title
    String title = (json['title'] ?? '').toString();
    if (title.isEmpty && json['make'] != null && json['model'] != null) {
      title = '${json['make']} ${json['model']}';
    }
    
    // Backend location can be an object or string
    String location = '';
    if (json['location'] is Map) {
      final loc = json['location'] as Map;
      location = loc['city']?.toString() ?? loc['address']?.toString() ?? '';
    } else {
      location = (json['location'] ?? '').toString();
    }
    
    // Backend uses price.perDay and price.perHour
    double pricePerDay = 0.0;
    double? pricePerHour;
    if (json['price'] is Map) {
      final priceMap = json['price'] as Map;
      pricePerDay = toDouble(priceMap['perDay']);
      pricePerHour = toDouble(priceMap['perHour']);
    } else {
      pricePerDay = toDouble(json['pricePerDay'] ?? json['dayPrice']);
      pricePerHour = (json.containsKey('pricePerHour') || json.containsKey('hourPrice'))
          ? toDouble(json['pricePerHour'] ?? json['hourPrice'])
          : (json.containsKey('price') ? toDouble(json['price']) : null);
    }
    
    final double? discountPercent = (json.containsKey('discountPercent') || json.containsKey('discount'))
        ? toDouble(json['discountPercent'] ?? json['discount'])
        : null;

    // Backend uses 'photos', frontend expects 'images'
    List<String> images = toStringList(json['images'] ?? json['photos']);
    if (images.isEmpty) {
      final dynamic single = json['image'] ?? json['imageUrl'];
      if (single != null && single.toString().isNotEmpty) {
        images = [single.toString()];
      }
    }

    // Backend uses rating.avg and rating.count
    double rating = 0.0;
    int reviewCount = 0;
    if (json['rating'] is Map) {
      final ratingMap = json['rating'] as Map;
      rating = toDouble(ratingMap['avg'] ?? ratingMap['average']);
      reviewCount = toInt(ratingMap['count'] ?? 0);
    } else {
      rating = toDouble(json['rating']);
      reviewCount = toInt(json['reviewCount'] ?? json['reviews'] ?? 0);
    }
    
    // Backend uses vehicleType for category (car/bike/van/scooter)
    final String category = (json['vehicleType'] ?? json['category'] ?? 'Vehicle').toString();
    final int seats = toInt(json['seats'] ?? json['seatCount']);
    final String transmission = (json['transmission'] ?? 'Auto').toString();
    
    // Backend uses fuelType, frontend expects fuel
    final String fuel = (json['fuelType'] ?? json['fuel'] ?? 'Petrol').toString();
    
    // Handle boolean safely - backend might return null
    final bool isFeatured = json['isFeatured'] == true || json['Featured'] == true;
    double? latitude = (json['latitude'] != null) ? toDouble(json['latitude']) : null;
    double? longitude = (json['longitude'] != null) ? toDouble(json['longitude']) : null;
    // DEBUG: derive lat/lng from GeoJSON if direct fields are missing
    if ((latitude == null || longitude == null || (latitude == 0.0 && longitude == 0.0)) && json['location'] is Map) {
      final loc = json['location'] as Map;
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        // GeoJSON order is [lng, lat]
        final lng = toDouble(coords[0]);
        final lat = toDouble(coords[1]);
        if (lat != 0.0 || lng != 0.0) {
          latitude = lat;
          longitude = lng;
        }
      }
    }

    return VehicleModel(
      id: id,
      title: title,
      location: location,
      pricePerDay: pricePerDay,
      pricePerHour: pricePerHour,
      discountPercent: discountPercent,
      images: images,
      rating: rating,
      reviewCount: reviewCount,
      category: category,
      seats: seats,
      transmission: transmission,
      fuel: fuel,
      isFeatured: isFeatured,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'pricePerDay': pricePerDay,
      if (pricePerHour != null) 'pricePerHour': pricePerHour,
      if (discountPercent != null) 'discountPercent': discountPercent,
      'images': images,
      'rating': rating,
      'reviewCount': reviewCount,
      'category': category,
      'seats': seats,
      'transmission': transmission,
      'fuel': fuel,
      'isFeatured': isFeatured,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  VehicleModel copyWith({
    String? id,
    String? title,
    String? location,
    double? pricePerDay,
    double? pricePerHour,
    double? discountPercent,
    List<String>? images,
    double? rating,
    int? reviewCount,
    String? category,
    int? seats,
    String? transmission,
    String? fuel,
    bool? isFeatured,
    double? latitude,
    double? longitude,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      discountPercent: discountPercent ?? this.discountPercent,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      category: category ?? this.category,
      seats: seats ?? this.seats,
      transmission: transmission ?? this.transmission,
      fuel: fuel ?? this.fuel,
      isFeatured: isFeatured ?? this.isFeatured,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
