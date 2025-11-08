/// Unified listing model for both properties and vehicles
class Listing {
  final String id;
  final String title;
  final String location;
  final double price;
  final String? rentalUnit; // 'hour', 'day', 'month', etc.
  final List<String> images;
  final double rating;
  final int? reviewCount;
  final String type; // 'property' or 'vehicle'
  final String? category; // e.g., 'Apartment', 'Car', etc.
  final bool featured;
  final bool available;
  final String? description;
  final Map<String, dynamic>? metadata; // Additional flexible data

  Listing({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    this.rentalUnit,
    this.images = const [],
    this.rating = 0.0,
    this.reviewCount,
    required this.type,
    this.category,
    this.featured = false,
    this.available = true,
    this.description,
    this.metadata,
  });

  /// Create Listing from JSON
  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      location: json['location']?.toString() ?? json['Location']?.toString() ?? 'Unknown',
      price: _parsePrice(json['price'] ?? json['Price'] ?? json['pricePerMonth'] ?? 0),
      rentalUnit: json['rentalUnit']?.toString() ?? json['RentalUnit']?.toString() ?? 'month',
      images: _parseImages(json['images'] ?? json['Images'] ?? []),
      rating: _parseDouble(json['rating'] ?? json['Rating'] ?? 0.0),
      reviewCount: _parseInt(json['reviewCount'] ?? json['reviews']?.length),
      type: json['type']?.toString() ?? _inferType(json),
      category: json['category']?.toString() ?? json['Category']?.toString() ?? json['Type']?.toString(),
      featured: json['Featured'] == true || json['featured'] == true,
      available: json['available'] != false && json['status'] != 'inactive',
      description: json['description']?.toString() ?? json['Description']?.toString(),
      metadata: json,
    );
  }

  /// Convert Listing to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'price': price,
      'rentalUnit': rentalUnit,
      'images': images,
      'rating': rating,
      'reviewCount': reviewCount,
      'type': type,
      'category': category,
      'featured': featured,
      'available': available,
      'description': description,
    };
  }

  /// Get the main image URL
  String? get imageUrl => images.isNotEmpty ? images.first : null;

  /// Get formatted price string
  String get priceLabel {
    if (rentalUnit != null) {
      return '\$${price.toStringAsFixed(0)}/$rentalUnit';
    }
    return '\$${price.toStringAsFixed(0)}';
  }

  /// Check if this is a property
  bool get isProperty => type.toLowerCase() == 'property';

  /// Check if this is a vehicle
  bool get isVehicle => type.toLowerCase() == 'vehicle';

  // Helper methods for parsing
  static double _parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static List<String> _parseImages(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return [];
  }

  static String _inferType(Map<String, dynamic> json) {
    // Try to infer type from the data structure
    if (json.containsKey('bedrooms') || json.containsKey('Bedrooms') ||
        json.containsKey('propertyType') || json.containsKey('PropertyType')) {
      return 'property';
    }
    if (json.containsKey('make') || json.containsKey('Make') ||
        json.containsKey('model') || json.containsKey('Model') ||
        json.containsKey('vehicleType') || json.containsKey('VehicleType')) {
      return 'vehicle';
    }
    return 'property'; // default
  }

  @override
  String toString() {
    return 'Listing(id: $id, title: $title, type: $type, price: $price)';
  }
}
