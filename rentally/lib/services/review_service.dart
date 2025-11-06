import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

// Review types
enum ReviewType { propertyReview, guestReview }

// Review model
class Review {
  final String id;
  final String listingId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String> images;
  final Map<String, double> categoryRatings; // cleanliness, communication, etc.
  final ReviewType type;
  final String? targetUserId; // For guest reviews, this is the guest being reviewed

  const Review({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images = const [],
    this.categoryRatings = const {},
    this.type = ReviewType.propertyReview,
    this.targetUserId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'listingId': listingId,
    'userId': userId,
    'userName': userName,
    'userAvatar': userAvatar,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
    'images': images,
    'categoryRatings': categoryRatings,
    'type': type.name,
    'targetUserId': targetUserId,
  };

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'],
    listingId: json['listingId'],
    userId: json['userId'],
    userName: json['userName'],
    userAvatar: json['userAvatar'],
    rating: json['rating'].toDouble(),
    comment: json['comment'],
    createdAt: DateTime.parse(json['createdAt']),
    images: List<String>.from(json['images'] ?? []),
    categoryRatings: Map<String, double>.from(json['categoryRatings'] ?? {}),
    type: ReviewType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ReviewType.propertyReview,
    ),
    targetUserId: json['targetUserId'],
  );
}

// Review statistics
class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // 1-5 stars count
  final Map<String, double> categoryAverages;

  const ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.categoryAverages,
  });
}

// Review state
class ReviewState {
  final Map<String, List<Review>> listingReviews; // listingId -> reviews
  final Map<String, List<Review>> guestReviews; // guestId -> reviews
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const ReviewState({
    this.listingReviews = const {},
    this.guestReviews = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  ReviewState copyWith({
    Map<String, List<Review>>? listingReviews,
    Map<String, List<Review>>? guestReviews,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) => ReviewState(
    listingReviews: listingReviews ?? this.listingReviews,
    guestReviews: guestReviews ?? this.guestReviews,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}

// Review service
class ReviewService extends StateNotifier<ReviewState> {
  ReviewService() : super(const ReviewState()) {
    _loadReviews();
  }

  static const String _reviewsKey = 'cached_reviews';

  // Load reviews from cache
  Future<void> _loadReviews() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final reviewsJson = prefs.getString(_reviewsKey);
      
      if (reviewsJson != null) {
        final Map<String, dynamic> decoded = json.decode(reviewsJson);
        final Map<String, List<Review>> listingReviews = {};
        
        decoded.forEach((listingId, reviewsList) {
          listingReviews[listingId] = (reviewsList as List)
              .map((item) => Review.fromJson(item))
              .toList();
        });
        
        state = state.copyWith(listingReviews: listingReviews);
      }

      // Generate mock reviews if none exist
      if (state.listingReviews.isEmpty) {
        final mockListingReviews = _generateMockReviews();
        final mockGuestReviews = _generateMockGuestReviews();
        state = state.copyWith(
          listingReviews: mockListingReviews,
          guestReviews: mockGuestReviews,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
        await _cacheReviews();
      } else {
        state = state.copyWith(
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to load reviews: $e', isLoading: false);
    }
  }

  // Cache reviews locally
  Future<void> _cacheReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final Map<String, dynamic> reviewsJson = {};
      state.listingReviews.forEach((listingId, reviews) {
        reviewsJson[listingId] = reviews.map((r) => r.toJson()).toList();
      });
      
      await prefs.setString(_reviewsKey, json.encode(reviewsJson));
    } catch (e) {
      // Handle caching error silently
    }
  }

  // Public methods
  Future<void> addReview({
    required String listingId,
    required String userId,
    required String userName,
    String? userAvatar,
    required double rating,
    required String comment,
    required Map<String, double> categoryRatings,
    List<String> images = const [],
  }) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      final review = Review(
        id: 'review_${DateTime.now().millisecondsSinceEpoch}',
        listingId: listingId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        images: images,
        categoryRatings: categoryRatings,
        type: ReviewType.propertyReview,
      );

      final updatedListingReviews = Map<String, List<Review>>.from(state.listingReviews);
      final reviewsList = updatedListingReviews[listingId] ?? [];
      reviewsList.add(review);
      updatedListingReviews[listingId] = reviewsList;
      
      state = state.copyWith(
        listingReviews: updatedListingReviews,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      
      await _cacheReviews();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add review: $e', isLoading: false);
    }
  }

  Future<void> loadReviewsForListing(String listingId) async {
    if (state.listingReviews.containsKey(listingId)) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // For now, return empty list for new listings
      final updatedListingReviews = Map<String, List<Review>>.from(state.listingReviews);
      updatedListingReviews[listingId] = [];
      
      state = state.copyWith(
        listingReviews: updatedListingReviews,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load reviews: $e', isLoading: false);
    }
  }

  ReviewStats getReviewStats(String listingId) {
    final reviews = state.listingReviews[listingId] ?? [];
    
    if (reviews.isEmpty) {
      return const ReviewStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
        categoryAverages: {},
      );
    }

    final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
    final averageRating = totalRating / reviews.length;

    final ratingDistribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      ratingDistribution[i] = reviews.where((r) => r.rating.round() == i).length;
    }

    final categoryAverages = <String, double>{};
    final categories = ['cleanliness', 'communication', 'location', 'value'];
    
    for (final category in categories) {
      final categoryRatings = reviews
          .where((r) => r.categoryRatings.containsKey(category))
          .map((r) => r.categoryRatings[category]!)
          .toList();
      
      if (categoryRatings.isNotEmpty) {
        categoryAverages[category] = categoryRatings.reduce((a, b) => a + b) / categoryRatings.length;
      }
    }

    return ReviewStats(
      averageRating: averageRating,
      totalReviews: reviews.length,
      ratingDistribution: ratingDistribution,
      categoryAverages: categoryAverages,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Add guest review method
  Future<void> addGuestReview({
    required String guestId,
    required String listingId,
    required String ownerId,
    required String ownerName,
    required double rating,
    required String comment,
    required Map<String, double> categoryRatings,
    List<String> images = const [],
  }) async {
    try {
      final review = Review(
        id: 'guest_review_${DateTime.now().millisecondsSinceEpoch}',
        listingId: listingId,
        userId: ownerId,
        userName: ownerName,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        images: images,
        categoryRatings: categoryRatings,
        type: ReviewType.guestReview,
        targetUserId: guestId,
      );

      final currentGuestReviews = Map<String, List<Review>>.from(state.guestReviews);
      final guestReviewsList = currentGuestReviews[guestId] ?? [];
      guestReviewsList.add(review);
      currentGuestReviews[guestId] = guestReviewsList;

      state = state.copyWith(
        guestReviews: currentGuestReviews,
        lastUpdated: DateTime.now(),
      );

      await _cacheReviews();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add guest review: $e');
    }
  }

  // Get guest review stats
  ReviewStats getGuestReviewStats(String guestId) {
    final reviews = state.guestReviews[guestId] ?? [];
    
    if (reviews.isEmpty) {
      return const ReviewStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
        categoryAverages: {},
      );
    }

    final totalRating = reviews.fold(0.0, (sum, review) => sum + review.rating);
    final averageRating = totalRating / reviews.length;

    final Map<int, int> ratingDistribution = {};
    for (int i = 1; i <= 5; i++) {
      ratingDistribution[i] = reviews.where((r) => r.rating.round() == i).length;
    }

    final Map<String, double> categoryAverages = {};
    final allCategories = reviews
        .expand((review) => review.categoryRatings.keys)
        .toSet();

    for (final category in allCategories) {
      final categoryReviews = reviews
          .where((review) => review.categoryRatings.containsKey(category))
          .toList();
      if (categoryReviews.isNotEmpty) {
        final categoryTotal = categoryReviews.fold(
          0.0,
          (sum, review) => sum + review.categoryRatings[category]!,
        );
        categoryAverages[category] = categoryTotal / categoryReviews.length;
      }
    }

    return ReviewStats(
      averageRating: averageRating,
      totalReviews: reviews.length,
      ratingDistribution: ratingDistribution,
      categoryAverages: categoryAverages,
    );
  }

  // Generate mock reviews
  Map<String, List<Review>> _generateMockReviews() {
    final now = DateTime.now();
    
    final listingReviews = {
      '1': [
        Review(
          id: 'review1',
          listingId: '1',
          userId: 'user2',
          userName: 'Sarah Johnson',
          userAvatar: 'https://picsum.photos/seed/user_sj/150',
          rating: 4.8,
          comment: 'Amazing apartment with great amenities! The host was very responsive and helpful. Would definitely stay here again.',
          createdAt: now.subtract(const Duration(days: 3)),
          images: ['https://picsum.photos/seed/review_photo_sj/300/200'],
          categoryRatings: {
            'cleanliness': 5.0,
            'communication': 5.0,
            'location': 4.5,
            'value': 4.5,
          },
          type: ReviewType.propertyReview,
        ),
        Review(
          id: 'review2',
          listingId: '1',
          userId: 'user3',
          userName: 'Mike Chen',
          userAvatar: 'https://picsum.photos/seed/user_mc/150',
          rating: 4.0,
          comment: 'Great location and clean apartment. The only downside was some street noise at night, but overall a good experience.',
          createdAt: now.subtract(const Duration(days: 8)),
          categoryRatings: {
            'cleanliness': 5.0,
            'communication': 4.0,
            'location': 5.0,
            'value': 4.0,
          },
          type: ReviewType.propertyReview,
        ),
      ],
      '2': [
        Review(
          id: 'review3',
          listingId: '2',
          userId: 'user4',
          userName: 'Emma Davis',
          userAvatar: 'https://picsum.photos/seed/user_ed/150',
          rating: 5.0,
          comment: 'Perfect beach house for a relaxing weekend! Beautiful views, well-equipped kitchen, and the pool was amazing. Highly recommend!',
          createdAt: now.subtract(const Duration(days: 22)),
          images: ['https://picsum.photos/seed/review_photo_ed/300/200'],
          categoryRatings: {
            'cleanliness': 5.0,
            'communication': 5.0,
            'location': 5.0,
            'value': 5.0,
          },
          type: ReviewType.propertyReview,
        ),
      ],
    };

    return listingReviews;
  }

  // Generate mock guest reviews
  Map<String, List<Review>> _generateMockGuestReviews() {
    final now = DateTime.now();
    
    return {
      'user2': [
        Review(
          id: 'guest_review1',
          listingId: '1',
          userId: 'owner1',
          userName: 'Property Owner',
          userAvatar: 'https://picsum.photos/seed/user_po/150',
          rating: 4.9,
          comment: 'Sarah was an excellent guest! Very respectful of the property, followed all house rules, and left the place spotless. Would welcome her back anytime.',
          createdAt: now.subtract(const Duration(days: 4)),
          categoryRatings: {
            'cleanliness': 5.0,
            'communication': 5.0,
            'respect': 4.8,
            'reliability': 5.0,
          },
          type: ReviewType.guestReview,
          targetUserId: 'user2',
        ),
      ],
      'user3': [
        Review(
          id: 'guest_review2',
          listingId: '1',
          userId: 'owner1',
          userName: 'Property Owner',
          userAvatar: 'https://picsum.photos/seed/user_po/150',
          rating: 4.2,
          comment: 'Mike was a decent guest overall. Good communication and followed most rules. Had a small issue with checkout time but nothing major.',
          createdAt: now.subtract(const Duration(days: 9)),
          categoryRatings: {
            'cleanliness': 4.0,
            'communication': 4.5,
            'respect': 4.0,
            'reliability': 4.2,
          },
          type: ReviewType.guestReview,
          targetUserId: 'user3',
        ),
      ],
      'user4': [
        Review(
          id: 'guest_review3',
          listingId: '2',
          userId: 'owner2',
          userName: 'Beach House Owner',
          userAvatar: 'https://picsum.photos/seed/user_bh/150',
          rating: 5.0,
          comment: 'Emma was a fantastic guest! Perfect communication, treated our beach house with care, and was very considerate. Highly recommend to other hosts!',
          createdAt: now.subtract(const Duration(days: 23)),
          categoryRatings: {
            'cleanliness': 5.0,
            'communication': 5.0,
            'respect': 5.0,
            'reliability': 5.0,
          },
          type: ReviewType.guestReview,
          targetUserId: 'user4',
        ),
      ],
    };
  }
}

// Provider
final reviewProvider = StateNotifierProvider<ReviewService, ReviewState>((ref) {
  return ReviewService();
});

// Specific providers
final listingReviewsProvider = Provider.family<List<Review>, String>((ref, listingId) {
  final reviewState = ref.watch(reviewProvider);
  return reviewState.listingReviews[listingId] ?? [];
});

final guestReviewsProvider = Provider.family<List<Review>, String>((ref, guestId) {
  final reviewState = ref.watch(reviewProvider);
  return reviewState.guestReviews[guestId] ?? [];
});

final listingReviewStatsProvider = Provider.family<ReviewStats, String>((ref, listingId) {
  return ref.read(reviewProvider.notifier).getReviewStats(listingId);
});

final guestReviewStatsProvider = Provider.family<ReviewStats, String>((ref, guestId) {
  return ref.read(reviewProvider.notifier).getGuestReviewStats(guestId);
});
