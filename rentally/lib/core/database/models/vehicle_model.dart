/// Vehicle model representing rental vehicles in the database
class VehicleModel {
  final String id;
  final String title;
  final String location;
  final double pricePerDay;
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

    final String id = (json['id'] ?? '').toString();
    final String title = (json['title'] ?? '').toString();
    final String location = (json['location'] ?? '').toString();
    final double pricePerDay = toDouble(json['pricePerDay'] ?? json['price'] ?? json['dayPrice']);

    // Images may come as 'image'/'imageUrl' or a list 'images'
    List<String> images = toStringList(json['images']);
    if (images.isEmpty) {
      final dynamic single = json['image'] ?? json['imageUrl'];
      if (single != null && single.toString().isNotEmpty) {
        images = [single.toString()];
      }
    }

    final double rating = toDouble(json['rating']);
    final int reviewCount = toInt(json['reviewCount'] ?? json['reviews']);
    final String category = (json['category'] ?? 'Vehicle').toString();
    final int seats = toInt(json['seats'] ?? json['seatCount']);
    final String transmission = (json['transmission'] ?? 'Auto').toString();
    final String fuel = (json['fuel'] ?? 'Petrol').toString();
    final bool isFeatured = (json['isFeatured'] is bool) ? (json['isFeatured'] as bool) : false;
    final double? latitude = (json['latitude'] != null) ? toDouble(json['latitude']) : null;
    final double? longitude = (json['longitude'] != null) ? toDouble(json['longitude']) : null;

    return VehicleModel(
      id: id,
      title: title,
      location: location,
      pricePerDay: pricePerDay,
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
