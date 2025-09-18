/// Property model representing rental properties in the database
class PropertyModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String address;
  final double latitude;
  final double longitude;
  final double pricePerNight;
  final double pricePerDay;
  final PropertyType type;
  final String ownerId;
  final String ownerName;
  final String ownerAvatar;
  final List<String> images;
  final List<String> amenities;
  final int bedrooms;
  final int bathrooms;
  final int maxGuests;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.pricePerNight,
    required this.pricePerDay,
    required this.type,
    required this.ownerId,
    required this.ownerName,
    required this.ownerAvatar,
    required this.images,
    required this.amenities,
    required this.bedrooms,
    required this.bathrooms,
    required this.maxGuests,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // Safe converters to tolerate nulls and alternate types
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

    DateTime toDateTime(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is String) {
        try { return DateTime.parse(v); } catch (_) { return DateTime.now(); }
      }
      return DateTime.now();
    }

    // Support alternate keys from mock/real APIs
    final String id = (json['id'] ?? '').toString();
    final String title = (json['title'] ?? '').toString();
    final String description = (json['description'] ?? '').toString();
    final String location = (json['location'] ?? '').toString();
    final String address = (json['address'] ?? '').toString();
    final double latitude = toDouble(json['latitude'] ?? json['lat']);
    final double longitude = toDouble(json['longitude'] ?? json['lng'] ?? json['long']);
    final double pricePerNight = toDouble(json['pricePerNight'] ?? json['price'] ?? json['nightPrice']);
    final double pricePerDay = toDouble(json['pricePerDay'] ?? json['dayPrice'] ?? 0);
    final PropertyType type = PropertyType.values.firstWhere(
      (e) => e.name == (json['type']?.toString().toLowerCase() ?? ''),
      orElse: () => PropertyType.apartment,
    );
    final String ownerId = (json['ownerId'] ?? '').toString();
    final String ownerName = (json['ownerName'] ?? '').toString();
    final String ownerAvatar = (json['ownerAvatar'] ?? '').toString();

    // Images may come as a single 'imageUrl' or a list 'images'
    List<String> images = toStringList(json['images']);
    if (images.isEmpty && json['imageUrl'] != null) {
      final url = json['imageUrl'].toString();
      if (url.isNotEmpty) images = [url];
    }

    final List<String> amenities = toStringList(json['amenities']);
    final int bedrooms = toInt(json['bedrooms']);
    final int bathrooms = toInt(json['bathrooms']);
    final int maxGuests = toInt(json['maxGuests']);
    final double rating = toDouble(json['rating']);
    final int reviewCount = toInt(json['reviewCount'] ?? json['reviews']);
    final bool isAvailable = (json['isAvailable'] is bool) ? (json['isAvailable'] as bool) : true;
    final bool isFeatured = (json['isFeatured'] is bool) ? (json['isFeatured'] as bool) : false;
    final DateTime createdAt = toDateTime(json['createdAt']);
    final DateTime updatedAt = toDateTime(json['updatedAt']);

    return PropertyModel(
      id: id,
      title: title,
      description: description,
      location: location,
      address: address,
      latitude: latitude,
      longitude: longitude,
      pricePerNight: pricePerNight,
      pricePerDay: pricePerDay,
      type: type,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerAvatar: ownerAvatar,
      images: images,
      amenities: amenities,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      maxGuests: maxGuests,
      rating: rating,
      reviewCount: reviewCount,
      isAvailable: isAvailable,
      isFeatured: isFeatured,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'pricePerNight': pricePerNight,
      'pricePerDay': pricePerDay,
      'type': type.name,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerAvatar': ownerAvatar,
      'images': images,
      'amenities': amenities,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'maxGuests': maxGuests,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PropertyModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    double? pricePerNight,
    double? pricePerDay,
    PropertyType? type,
    String? ownerId,
    String? ownerName,
    String? ownerAvatar,
    List<String>? images,
    List<String>? amenities,
    int? bedrooms,
    int? bathrooms,
    int? maxGuests,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      maxGuests: maxGuests ?? this.maxGuests,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum PropertyType {
  apartment,
  house,
  villa,
  condo,
  studio,
  loft,
  cabin,
  cottage,
  penthouse,
  townhouse,
}

extension PropertyTypeExtension on PropertyType {
  String get displayName {
    switch (this) {
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.house:
        return 'House';
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.condo:
        return 'Condo';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.loft:
        return 'Loft';
      case PropertyType.cabin:
        return 'Cabin';
      case PropertyType.cottage:
        return 'Cottage';
      case PropertyType.penthouse:
        return 'Penthouse';
      case PropertyType.townhouse:
        return 'Townhouse';
    }
  }
}
