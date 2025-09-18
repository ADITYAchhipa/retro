import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Advanced AI-powered recommendation engine with machine learning algorithms
class AIRecommendationEngine {
  static final AIRecommendationEngine _instance = AIRecommendationEngine._internal();
  static AIRecommendationEngine get instance => _instance;
  
  AIRecommendationEngine._internal();

  final Map<String, UserProfile> _userProfiles = {};
  final Map<String, PropertyProfile> _propertyProfiles = {};
  final List<UserInteraction> _interactions = [];
  final Random _random = Random();

  /// Generate personalized property recommendations
  Future<List<PropertyRecommendation>> generateRecommendations({
    required String userId,
    required List<Map<String, dynamic>> availableProperties,
    int limit = 10,
  }) async {
    try {
      // Simulate ML processing delay
      await Future.delayed(const Duration(milliseconds: 500));

      final userProfile = await _getUserProfile(userId);
      final recommendations = <PropertyRecommendation>[];

      for (final property in availableProperties) {
        final propertyId = property['id'] as String;
        final propertyProfile = await _getPropertyProfile(propertyId, property);
        
        final score = await _calculateRecommendationScore(
          userProfile,
          propertyProfile,
          property,
        );

        if (score > 0.3) { // Minimum threshold
          recommendations.add(PropertyRecommendation(
            propertyId: propertyId,
            userId: userId,
            score: score,
            reasons: _generateRecommendationReasons(userProfile, propertyProfile, property),
            confidence: _calculateConfidence(score, userProfile, propertyProfile),
            category: _categorizeRecommendation(score, userProfile, propertyProfile),
            timestamp: DateTime.now(),
          ));
        }
      }

      // Sort by score and limit results
      recommendations.sort((a, b) => b.score.compareTo(a.score));
      return recommendations.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error generating recommendations: $e');
      }
      return [];
    }
  }

  /// Calculate recommendation score using multiple algorithms
  Future<double> _calculateRecommendationScore(
    UserProfile userProfile,
    PropertyProfile propertyProfile,
    Map<String, dynamic> property,
  ) async {
    double score = 0.0;

    // 1. Collaborative Filtering (30% weight)
    score += await _collaborativeFiltering(userProfile, propertyProfile) * 0.3;

    // 2. Content-Based Filtering (25% weight)
    score += _contentBasedFiltering(userProfile, propertyProfile, property) * 0.25;

    // 3. Location Preference (20% weight)
    score += _locationPreferenceScore(userProfile, property) * 0.2;

    // 4. Price Preference (15% weight)
    score += _pricePreferenceScore(userProfile, property) * 0.15;

    // 5. Behavioral Patterns (10% weight)
    score += _behavioralPatternScore(userProfile, propertyProfile) * 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Collaborative filtering algorithm
  Future<double> _collaborativeFiltering(UserProfile userProfile, PropertyProfile propertyProfile) async {
    // Find similar users based on preferences and interactions
    final similarUsers = await _findSimilarUsers(userProfile);
    
    if (similarUsers.isEmpty) return 0.5; // Default score for new users

    double totalScore = 0.0;
    int count = 0;

    for (final similarUser in similarUsers) {
      final interactions = _interactions.where(
        (i) => i.userId == similarUser.userId && i.propertyId == propertyProfile.propertyId
      ).toList();

      if (interactions.isNotEmpty) {
        final avgRating = interactions.map((i) => i.rating ?? 0.0).reduce((a, b) => a + b) / interactions.length;
        totalScore += avgRating * similarUser.similarity;
        count++;
      }
    }

    return count > 0 ? (totalScore / count) / 5.0 : 0.5; // Normalize to 0-1
  }

  /// Content-based filtering algorithm
  double _contentBasedFiltering(UserProfile userProfile, PropertyProfile propertyProfile, Map<String, dynamic> property) {
    double score = 0.0;
    int factors = 0;

    // Property type preference
    final propertyType = property['type'] as String? ?? '';
    if (userProfile.preferredPropertyTypes.contains(propertyType)) {
      score += 1.0;
    }
    factors++;

    // Amenities matching
    final propertyAmenities = List<String>.from(property['amenities'] ?? []);
    final matchingAmenities = propertyAmenities.where(
      (amenity) => userProfile.preferredAmenities.contains(amenity)
    ).length;
    
    if (propertyAmenities.isNotEmpty) {
      score += matchingAmenities / propertyAmenities.length;
      factors++;
    }

    // Rating preference
    final rating = (property['rating'] as num?)?.toDouble() ?? 0.0;
    if (rating >= userProfile.minRatingPreference) {
      score += (rating - userProfile.minRatingPreference) / (5.0 - userProfile.minRatingPreference);
    }
    factors++;

    return factors > 0 ? score / factors : 0.0;
  }

  /// Location preference scoring
  double _locationPreferenceScore(UserProfile userProfile, Map<String, dynamic> property) {
    final propertyLocation = property['location'] as String? ?? '';
    
    // Check if location matches preferred areas
    for (final preferredLocation in userProfile.preferredLocations) {
      if (propertyLocation.toLowerCase().contains(preferredLocation.toLowerCase())) {
        return 1.0;
      }
    }

    // Distance-based scoring (simulated)
    final distance = _random.nextDouble() * 50; // 0-50 km
    return (50 - distance) / 50; // Closer = higher score
  }

  /// Price preference scoring
  double _pricePreferenceScore(UserProfile userProfile, Map<String, dynamic> property) {
    final price = (property['price'] as num?)?.toDouble() ?? 0.0;
    
    if (price <= userProfile.maxBudget && price >= userProfile.minBudget) {
      // Perfect price range
      return 1.0;
    } else if (price < userProfile.minBudget) {
      // Too cheap might indicate quality issues
      return 0.7;
    } else {
      // Too expensive
      final overBudget = price - userProfile.maxBudget;
      final tolerance = userProfile.maxBudget * 0.2; // 20% tolerance
      return (tolerance - overBudget) / tolerance;
    }
  }

  /// Behavioral pattern scoring
  double _behavioralPatternScore(UserProfile userProfile, PropertyProfile propertyProfile) {
    // Time-based preferences
    double score = 0.0;
    
    // Booking time patterns
    if (userProfile.preferredBookingDays.isNotEmpty) {
      score += 0.3;
    }
    
    // Duration preferences
    if (propertyProfile.averageStayDuration >= userProfile.preferredStayDuration) {
      score += 0.4;
    }
    
    // Repeat booking likelihood
    score += propertyProfile.repeatBookingRate * 0.3;
    
    return score;
  }

  /// Find users with similar preferences
  Future<List<SimilarUser>> _findSimilarUsers(UserProfile userProfile) async {
    final similarUsers = <SimilarUser>[];
    
    for (final otherProfile in _userProfiles.values) {
      if (otherProfile.userId == userProfile.userId) continue;
      
      final similarity = _calculateUserSimilarity(userProfile, otherProfile);
      if (similarity > 0.5) {
        similarUsers.add(SimilarUser(
          userId: otherProfile.userId,
          similarity: similarity,
        ));
      }
    }
    
    similarUsers.sort((a, b) => b.similarity.compareTo(a.similarity));
    return similarUsers.take(10).toList(); // Top 10 similar users
  }

  /// Calculate similarity between two users
  double _calculateUserSimilarity(UserProfile user1, UserProfile user2) {
    double similarity = 0.0;
    int factors = 0;

    // Property type similarity
    final commonTypes = user1.preferredPropertyTypes.toSet()
        .intersection(user2.preferredPropertyTypes.toSet());
    if (user1.preferredPropertyTypes.isNotEmpty || user2.preferredPropertyTypes.isNotEmpty) {
      similarity += commonTypes.length / 
          user1.preferredPropertyTypes.toSet().union(user2.preferredPropertyTypes.toSet()).length;
      factors++;
    }

    // Amenities similarity
    final commonAmenities = user1.preferredAmenities.toSet()
        .intersection(user2.preferredAmenities.toSet());
    if (user1.preferredAmenities.isNotEmpty || user2.preferredAmenities.isNotEmpty) {
      similarity += commonAmenities.length / 
          user1.preferredAmenities.toSet().union(user2.preferredAmenities.toSet()).length;
      factors++;
    }

    // Budget similarity
    final budgetDiff = (user1.maxBudget - user2.maxBudget).abs();
    final maxBudget = [user1.maxBudget, user2.maxBudget].reduce((a, b) => a > b ? a : b);
    if (maxBudget > 0) {
      similarity += 1.0 - (budgetDiff / maxBudget);
      factors++;
    }

    return factors > 0 ? similarity / factors : 0.0;
  }

  /// Generate recommendation reasons
  List<String> _generateRecommendationReasons(
    UserProfile userProfile,
    PropertyProfile propertyProfile,
    Map<String, dynamic> property,
  ) {
    final reasons = <String>[];

    // Property type match
    final propertyType = property['type'] as String? ?? '';
    if (userProfile.preferredPropertyTypes.contains(propertyType)) {
      reasons.add('Matches your preferred property type');
    }

    // Price match
    final price = (property['price'] as num?)?.toDouble() ?? 0.0;
    if (price <= userProfile.maxBudget) {
      reasons.add('Within your budget range');
    }

    // High rating
    final rating = (property['rating'] as num?)?.toDouble() ?? 0.0;
    if (rating >= 4.5) {
      reasons.add('Highly rated by guests');
    }

    // Popular choice
    if (propertyProfile.bookingCount > 50) {
      reasons.add('Popular choice among travelers');
    }

    // Location match
    final location = property['location'] as String? ?? '';
    for (final preferredLocation in userProfile.preferredLocations) {
      if (location.toLowerCase().contains(preferredLocation.toLowerCase())) {
        reasons.add('Located in your preferred area');
        break;
      }
    }

    // Amenities match
    final propertyAmenities = List<String>.from(property['amenities'] ?? []);
    final matchingAmenities = propertyAmenities.where(
      (amenity) => userProfile.preferredAmenities.contains(amenity)
    ).toList();
    
    if (matchingAmenities.isNotEmpty) {
      reasons.add('Has ${matchingAmenities.length} of your preferred amenities');
    }

    return reasons.take(3).toList(); // Limit to top 3 reasons
  }

  /// Calculate recommendation confidence
  double _calculateConfidence(double score, UserProfile userProfile, PropertyProfile propertyProfile) {
    double confidence = score;
    
    // Boost confidence for users with more interaction history
    if (userProfile.interactionCount > 10) {
      confidence += 0.1;
    }
    
    // Boost confidence for properties with more data
    if (propertyProfile.bookingCount > 20) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Categorize recommendation type
  RecommendationType _categorizeRecommendation(
    double score,
    UserProfile userProfile,
    PropertyProfile propertyProfile,
  ) {
    if (score >= 0.8) {
      return RecommendationType.perfectMatch;
    } else if (score >= 0.6) {
      return RecommendationType.goodMatch;
    } else if (propertyProfile.bookingCount > 100) {
      return RecommendationType.popular;
    } else if (propertyProfile.averageRating >= 4.5) {
      return RecommendationType.highlyRated;
    } else {
      return RecommendationType.general;
    }
  }

  /// Get or create user profile
  Future<UserProfile> _getUserProfile(String userId) async {
    if (_userProfiles.containsKey(userId)) {
      return _userProfiles[userId]!;
    }

    // Create new profile with default values
    final profile = UserProfile(
      userId: userId,
      preferredPropertyTypes: ['apartment', 'house'],
      preferredAmenities: ['wifi', 'parking'],
      preferredLocations: ['downtown', 'city center'],
      minBudget: 50.0,
      maxBudget: 200.0,
      minRatingPreference: 4.0,
      preferredStayDuration: 3,
      preferredBookingDays: [DateTime.friday, DateTime.saturday],
      interactionCount: 0,
    );

    _userProfiles[userId] = profile;
    return profile;
  }

  /// Get or create property profile
  Future<PropertyProfile> _getPropertyProfile(String propertyId, Map<String, dynamic> property) async {
    if (_propertyProfiles.containsKey(propertyId)) {
      return _propertyProfiles[propertyId]!;
    }

    // Create new profile with simulated data
    final profile = PropertyProfile(
      propertyId: propertyId,
      averageRating: (property['rating'] as num?)?.toDouble() ?? 4.0,
      bookingCount: _random.nextInt(200),
      averageStayDuration: 3 + _random.nextInt(7),
      repeatBookingRate: _random.nextDouble() * 0.3,
      seasonalPopularity: _generateSeasonalData(),
    );

    _propertyProfiles[propertyId] = profile;
    return profile;
  }

  /// Generate seasonal popularity data
  Map<int, double> _generateSeasonalData() {
    return {
      1: 0.6 + _random.nextDouble() * 0.4,  // January
      2: 0.5 + _random.nextDouble() * 0.4,  // February
      3: 0.7 + _random.nextDouble() * 0.3,  // March
      4: 0.8 + _random.nextDouble() * 0.2,  // April
      5: 0.9 + _random.nextDouble() * 0.1,  // May
      6: 1.0,                               // June (peak)
      7: 1.0,                               // July (peak)
      8: 0.9 + _random.nextDouble() * 0.1,  // August
      9: 0.8 + _random.nextDouble() * 0.2,  // September
      10: 0.7 + _random.nextDouble() * 0.3, // October
      11: 0.6 + _random.nextDouble() * 0.4, // November
      12: 0.7 + _random.nextDouble() * 0.3, // December
    };
  }

  /// Record user interaction for learning
  void recordInteraction(UserInteraction interaction) {
    _interactions.add(interaction);
    
    // Update user profile based on interaction
    final userProfile = _userProfiles[interaction.userId];
    if (userProfile != null) {
      userProfile.interactionCount++;
      
      // Learn from positive interactions
      if (interaction.rating != null && interaction.rating! >= 4.0) {
        // Add to preferred types/amenities if not already present
        // This would be more sophisticated in a real ML system
      }
    }
  }

  /// Update user preferences
  void updateUserPreferences(String userId, Map<String, dynamic> preferences) {
    final profile = _userProfiles[userId];
    if (profile != null) {
      if (preferences.containsKey('propertyTypes')) {
        profile.preferredPropertyTypes = List<String>.from(preferences['propertyTypes']);
      }
      if (preferences.containsKey('amenities')) {
        profile.preferredAmenities = List<String>.from(preferences['amenities']);
      }
      if (preferences.containsKey('locations')) {
        profile.preferredLocations = List<String>.from(preferences['locations']);
      }
      if (preferences.containsKey('budget')) {
        final budget = preferences['budget'] as Map<String, dynamic>;
        profile.minBudget = (budget['min'] as num?)?.toDouble() ?? profile.minBudget;
        profile.maxBudget = (budget['max'] as num?)?.toDouble() ?? profile.maxBudget;
      }
    }
  }

  /// Get trending properties
  Future<List<String>> getTrendingProperties({int limit = 10}) async {
    final trending = _propertyProfiles.entries
        .where((entry) => entry.value.bookingCount > 50)
        .toList()
      ..sort((a, b) => b.value.bookingCount.compareTo(a.value.bookingCount));
    
    return trending.take(limit).map((e) => e.key).toList();
  }

  /// Clear user data (for GDPR compliance)
  void clearUserData(String userId) {
    _userProfiles.remove(userId);
    _interactions.removeWhere((interaction) => interaction.userId == userId);
  }
}

/// User profile model
class UserProfile {
  final String userId;
  List<String> preferredPropertyTypes;
  List<String> preferredAmenities;
  List<String> preferredLocations;
  double minBudget;
  double maxBudget;
  double minRatingPreference;
  int preferredStayDuration;
  List<int> preferredBookingDays;
  int interactionCount;

  UserProfile({
    required this.userId,
    required this.preferredPropertyTypes,
    required this.preferredAmenities,
    required this.preferredLocations,
    required this.minBudget,
    required this.maxBudget,
    required this.minRatingPreference,
    required this.preferredStayDuration,
    required this.preferredBookingDays,
    required this.interactionCount,
  });
}

/// Property profile model
class PropertyProfile {
  final String propertyId;
  final double averageRating;
  final int bookingCount;
  final int averageStayDuration;
  final double repeatBookingRate;
  final Map<int, double> seasonalPopularity;

  PropertyProfile({
    required this.propertyId,
    required this.averageRating,
    required this.bookingCount,
    required this.averageStayDuration,
    required this.repeatBookingRate,
    required this.seasonalPopularity,
  });
}

/// User interaction model
class UserInteraction {
  final String userId;
  final String propertyId;
  final InteractionType type;
  final double? rating;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  UserInteraction({
    required this.userId,
    required this.propertyId,
    required this.type,
    this.rating,
    required this.timestamp,
    this.metadata,
  });
}

/// Similar user model
class SimilarUser {
  final String userId;
  final double similarity;

  SimilarUser({
    required this.userId,
    required this.similarity,
  });
}

/// Property recommendation model
class PropertyRecommendation {
  final String propertyId;
  final String userId;
  final double score;
  final List<String> reasons;
  final double confidence;
  final RecommendationType category;
  final DateTime timestamp;

  PropertyRecommendation({
    required this.propertyId,
    required this.userId,
    required this.score,
    required this.reasons,
    required this.confidence,
    required this.category,
    required this.timestamp,
  });
}

/// Interaction types
enum InteractionType {
  view,
  like,
  share,
  book,
  review,
  search,
}

/// Recommendation types
enum RecommendationType {
  perfectMatch,
  goodMatch,
  popular,
  highlyRated,
  general,
}
