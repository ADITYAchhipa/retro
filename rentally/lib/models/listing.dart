class Listing {
  final String id;
  final String title;
  final String description;
  final String location;
  final double price;
  final List<String> images;
  final double rating;
  final int reviews;
  final List<String> amenities;
  final String hostName;
  final String hostImage;
  final String category;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    required this.images,
    this.rating = 0.0,
    this.reviews = 0,
    this.amenities = const [],
    required this.hostName,
    required this.hostImage,
    this.category = 'Property',
    this.isAvailable = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      images: List<String>.from(json['images'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviews: json['reviews'] ?? 0,
      amenities: List<String>.from(json['amenities'] ?? []),
      hostName: json['hostName'] ?? '',
      hostImage: json['hostImage'] ?? '',
      category: json['category'] ?? 'Property',
      isAvailable: json['isAvailable'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'price': price,
      'images': images,
      'rating': rating,
      'reviews': reviews,
      'amenities': amenities,
      'hostName': hostName,
      'hostImage': hostImage,
      'category': category,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Listing copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    double? price,
    List<String>? images,
    double? rating,
    int? reviews,
    List<String>? amenities,
    String? hostName,
    String? hostImage,
    String? category,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Listing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      price: price ?? this.price,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      amenities: amenities ?? this.amenities,
      hostName: hostName ?? this.hostName,
      hostImage: hostImage ?? this.hostImage,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
