import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

// Listing model
class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final String type;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final List<String> images;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic> amenities;
  final double? rating;
  final int reviewCount;

  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.images,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.amenities,
    this.rating,
    this.reviewCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'type': type,
    'address': address,
    'city': city,
    'state': state,
    'zipCode': zipCode,
    'images': images,
    'ownerId': ownerId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isActive': isActive,
    'amenities': amenities,
    'rating': rating,
    'reviewCount': reviewCount,
  };

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    price: json['price'].toDouble(),
    type: json['type'],
    address: json['address'],
    city: json['city'],
    state: json['state'],
    zipCode: json['zipCode'],
    images: List<String>.from(json['images']),
    ownerId: json['ownerId'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    isActive: json['isActive'],
    amenities: json['amenities'],
    rating: json['rating']?.toDouble(),
    reviewCount: json['reviewCount'] ?? 0,
  );

  Listing copyWith({
    String? title,
    String? description,
    double? price,
    String? type,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    List<String>? images,
    bool? isActive,
    Map<String, dynamic>? amenities,
    double? rating,
    int? reviewCount,
  }) => Listing(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    price: price ?? this.price,
    type: type ?? this.type,
    address: address ?? this.address,
    city: city ?? this.city,
    state: state ?? this.state,
    zipCode: zipCode ?? this.zipCode,
    images: images ?? this.images,
    ownerId: ownerId,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    isActive: isActive ?? this.isActive,
    amenities: amenities ?? this.amenities,
    rating: rating ?? this.rating,
    reviewCount: reviewCount ?? this.reviewCount,
  );
}

// Listing state
class ListingState {
  final List<Listing> listings;
  final List<Listing> userListings;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const ListingState({
    this.listings = const [],
    this.userListings = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  ListingState copyWith({
    List<Listing>? listings,
    List<Listing>? userListings,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) => ListingState(
    listings: listings ?? this.listings,
    userListings: userListings ?? this.userListings,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}

// Listing service
class ListingService extends StateNotifier<ListingState> {
  ListingService() : super(const ListingState()) {
    _loadListings();
    _startPeriodicSync();
  }

  Timer? _syncTimer;
  static const String _listingsKey = 'cached_listings';
  static const String _userListingsKey = 'user_listings';

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  // Load listings from cache
  Future<void> _loadListings() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load cached listings
      final listingsJson = prefs.getString(_listingsKey);
      if (listingsJson != null) {
        final List<dynamic> decoded = json.decode(listingsJson);
        final listings = decoded.map((item) => Listing.fromJson(item)).toList();
        state = state.copyWith(listings: listings);
      }

      // Load user listings
      final userListingsJson = prefs.getString(_userListingsKey);
      if (userListingsJson != null) {
        final List<dynamic> decoded = json.decode(userListingsJson);
        final userListings = decoded.map((item) => Listing.fromJson(item)).toList();
        state = state.copyWith(userListings: userListings);
      }

      // Simulate fetching fresh data
      await _fetchListings();
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to load listings: $e', isLoading: false);
    }
  }

  // Fetch listings (simulate API call)
  Future<void> _fetchListings() async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Generate mock listings if none exist
      if (state.listings.isEmpty) {
        final mockListings = _generateMockListings();
        state = state.copyWith(
          listings: mockListings,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
        await _cacheListings();
      } else {
        state = state.copyWith(
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to fetch listings: $e', isLoading: false);
    }
  }

  // Cache listings locally
  Future<void> _cacheListings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final listingsJson = json.encode(state.listings.map((l) => l.toJson()).toList());
      await prefs.setString(_listingsKey, listingsJson);
      
      final userListingsJson = json.encode(state.userListings.map((l) => l.toJson()).toList());
      await prefs.setString(_userListingsKey, userListingsJson);
    } catch (e) {
      // Handle caching error silently
    }
  }

  // Start periodic sync
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _fetchListings();
    });
  }

  // Public methods
  Future<void> refreshListings() async {
    await _fetchListings();
  }

  Future<void> addListing(Listing listing) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      final updatedUserListings = [...state.userListings, listing];
      final updatedAllListings = [...state.listings, listing];
      
      state = state.copyWith(
        listings: updatedAllListings,
        userListings: updatedUserListings,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      
      await _cacheListings();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add listing: $e', isLoading: false);
    }
  }

  Future<void> updateListing(String id, Listing updatedListing) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      final updatedListings = state.listings.map((l) => 
        l.id == id ? updatedListing : l).toList();
      final updatedUserListings = state.userListings.map((l) => 
        l.id == id ? updatedListing : l).toList();
      
      state = state.copyWith(
        listings: updatedListings,
        userListings: updatedUserListings,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      
      await _cacheListings();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update listing: $e', isLoading: false);
    }
  }

  Future<void> deleteListing(String id) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      final updatedListings = state.listings.where((l) => l.id != id).toList();
      final updatedUserListings = state.userListings.where((l) => l.id != id).toList();
      
      state = state.copyWith(
        listings: updatedListings,
        userListings: updatedUserListings,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      
      await _cacheListings();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete listing: $e', isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Generate mock listings
  List<Listing> _generateMockListings() {
    final now = DateTime.now();
    return [
      Listing(
        id: '1',
        title: 'Modern Downtown Apartment',
        description: 'Beautiful 2BR apartment in the heart of downtown with city views.',
        price: 120.0,
        type: 'Apartment',
        address: '123 Main St',
        city: 'San Francisco',
        state: 'CA',
        zipCode: '94102',
        images: ['https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Property+1'],
        ownerId: 'owner1',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
        isActive: true,
        amenities: {'wifi': true, 'parking': true, 'pool': false},
        rating: 4.5,
        reviewCount: 23,
      ),
      Listing(
        id: '2',
        title: 'Cozy Beach House',
        description: 'Relaxing beach house perfect for weekend getaways.',
        price: 200.0,
        type: 'House',
        address: '456 Ocean Ave',
        city: 'Santa Monica',
        state: 'CA',
        zipCode: '90401',
        images: ['https://via.placeholder.com/300x200/9C27B0/FFFFFF?text=Property+2'],
        ownerId: 'owner2',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 2)),
        isActive: true,
        amenities: {'wifi': true, 'parking': true, 'pool': true},
        rating: 4.8,
        reviewCount: 45,
      ),
    ];
  }
}

// Provider
final listingProvider = StateNotifierProvider<ListingService, ListingState>((ref) {
  return ListingService();
});

// Filtered listings provider
final filteredListingsProvider = Provider.family<List<Listing>, Map<String, dynamic>>((ref, filters) {
  final listings = ref.watch(listingProvider).listings;
  
  return listings.where((listing) {
    // Apply filters
    if (filters['type'] != null && listing.type != filters['type']) {
      return false;
    }
    if (filters['minPrice'] != null && listing.price < filters['minPrice']) {
      return false;
    }
    if (filters['maxPrice'] != null && listing.price > filters['maxPrice']) {
      return false;
    }
    if (filters['city'] != null && !listing.city.toLowerCase().contains(filters['city'].toLowerCase())) {
      return false;
    }
    return listing.isActive;
  }).toList();
});
