import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
// Property model is imported via Property class

// Providers
final sponsoredListingsProvider = StateNotifierProvider<SponsoredListingsService, SponsoredListingsState>((ref) {
  return SponsoredListingsService();
});

final adsServiceProvider = StateNotifierProvider<AdsService, AdsState>((ref) {
  return AdsService();
});

// Models
class SponsoredListing {
  final String id;
  final String propertyId;
  final String hostId;
  final String campaignName;
  final double bidAmount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int impressions;
  final int clicks;
  final double totalSpent;
  final Map<String, dynamic> targetingOptions;

  const SponsoredListing({
    required this.id,
    required this.propertyId,
    required this.hostId,
    required this.campaignName,
    required this.bidAmount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.impressions = 0,
    this.clicks = 0,
    this.totalSpent = 0.0,
    this.targetingOptions = const {},
  });

  double get ctr => impressions > 0 ? clicks / impressions : 0.0;
  double get cpc => clicks > 0 ? totalSpent / clicks : 0.0;

  SponsoredListing copyWith({
    String? id,
    String? propertyType,
    String? hostId,
    String? campaignName,
    double? bidAmount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? impressions,
    int? clicks,
    double? totalSpent,
    Map<String, dynamic>? targetingOptions,
  }) {
    return SponsoredListing(
      id: id ?? this.id,
      propertyId: propertyId,
      hostId: hostId ?? this.hostId,
      campaignName: campaignName ?? this.campaignName,
      bidAmount: bidAmount ?? this.bidAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      totalSpent: totalSpent ?? this.totalSpent,
      targetingOptions: targetingOptions ?? this.targetingOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'hostId': hostId,
      'campaignName': campaignName,
      'bidAmount': bidAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'impressions': impressions,
      'clicks': clicks,
      'totalSpent': totalSpent,
      'targetingOptions': targetingOptions,
    };
  }

  factory SponsoredListing.fromJson(Map<String, dynamic> json) {
    return SponsoredListing(
      id: json['id'],
      propertyId: json['propertyId'],
      hostId: json['hostId'],
      campaignName: json['campaignName'],
      bidAmount: json['bidAmount'].toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'],
      impressions: json['impressions'] ?? 0,
      clicks: json['clicks'] ?? 0,
      totalSpent: json['totalSpent']?.toDouble() ?? 0.0,
      targetingOptions: json['targetingOptions'] ?? {},
    );
  }
}

enum AdType {
  banner,
  interstitial,
  rewarded,
  native,
}

class AdPlacement {
  final String id;
  final AdType type;
  final String location; // search_results, property_details, booking_flow
  final double cpmRate;
  final bool isActive;
  final Map<String, dynamic> config;

  const AdPlacement({
    required this.id,
    required this.type,
    required this.location,
    required this.cpmRate,
    this.isActive = true,
    this.config = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'location': location,
      'cpmRate': cpmRate,
      'isActive': isActive,
      'config': config,
    };
  }

  factory AdPlacement.fromJson(Map<String, dynamic> json) {
    return AdPlacement(
      id: json['id'],
      type: AdType.values.firstWhere((e) => e.name == json['type']),
      location: json['location'],
      cpmRate: json['cpmRate'].toDouble(),
      isActive: json['isActive'] ?? true,
      config: json['config'] ?? {},
    );
  }
}

class AdImpression {
  final String id;
  final String adId;
  final String userId;
  final DateTime timestamp;
  final double revenue;
  final Map<String, dynamic> metadata;

  const AdImpression({
    required this.id,
    required this.adId,
    required this.userId,
    required this.timestamp,
    required this.revenue,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adId': adId,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'revenue': revenue,
      'metadata': metadata,
    };
  }

  factory AdImpression.fromJson(Map<String, dynamic> json) {
    return AdImpression(
      id: json['id'],
      adId: json['adId'],
      userId: json['userId'],
      timestamp: DateTime.parse(json['timestamp']),
      revenue: json['revenue'].toDouble(),
      metadata: json['metadata'] ?? {},
    );
  }
}

// State Classes
class SponsoredListingsState {
  final List<SponsoredListing> campaigns;
  final List<Map<String, dynamic>> sponsoredProperties;
  final bool isLoading;
  final String? error;

  const SponsoredListingsState({
    this.campaigns = const [],
    this.sponsoredProperties = const [],
    this.isLoading = false,
    this.error,
  });

  SponsoredListingsState copyWith({
    List<SponsoredListing>? campaigns,
    List<Map<String, dynamic>>? sponsoredProperties,
    bool? isLoading,
    String? error,
  }) {
    return SponsoredListingsState(
      campaigns: campaigns ?? this.campaigns,
      sponsoredProperties: sponsoredProperties ?? this.sponsoredProperties,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AdsState {
  final List<AdPlacement> placements;
  final List<AdImpression> impressions;
  final double totalRevenue;
  final bool isLoading;

  const AdsState({
    this.placements = const [],
    this.impressions = const [],
    this.totalRevenue = 0.0,
    this.isLoading = false,
  });

  AdsState copyWith({
    List<AdPlacement>? placements,
    List<AdImpression>? impressions,
    double? totalRevenue,
    bool? isLoading,
  }) {
    return AdsState(
      placements: placements ?? this.placements,
      impressions: impressions ?? this.impressions,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Services
class SponsoredListingsService extends StateNotifier<SponsoredListingsState> {
  SponsoredListingsService() : super(const SponsoredListingsState()) {
    _initializeService();
  }

  static const String _storageKey = 'sponsored_listings';

  Future<void> _initializeService() async {
    state = state.copyWith(isLoading: true);
    await _loadStoredData();
    await _loadMockData();
    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString(_storageKey);
      if (storedData != null) {
        final data = jsonDecode(storedData);
        final campaigns = (data['campaigns'] as List?)
            ?.map((c) => SponsoredListing.fromJson(c))
            .toList() ?? [];
        
        state = state.copyWith(campaigns: campaigns);
      }
    } catch (e) {
      // TODO: Replace with proper logging
      // log.error('Error loading sponsored listings: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'campaigns': state.campaigns.map((c) => c.toJson()).toList(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      // TODO: Replace with proper logging
      // log.error('Error saving sponsored listings: $e');
    }
  }

  Future<void> _loadMockData() async {
    // Mock sponsored properties for demo
    final mockProperties = [
      {
        'id': 'sponsored_1',
        'title': 'Luxury Villa with Pool',
        'description': 'Beautiful 4BHK villa with private pool and garden',
        'location': 'Goa, India',
        'type': 'villa',
        'bedrooms': 4,
        'bathrooms': 3,
        'maxGuests': 8,
        'pricePerNight': 8500,
        'rating': 4.8,
        'reviewCount': 124,
        'ownerId': 'host_1',
        'isAvailable': true,
        'createdAt': DateTime.now().toIso8601String(),
        'isSponsored': true,
        'images': [
          'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800',
        ],
        'amenities': ['Pool', 'WiFi', 'AC', 'Garden'],
      },
      {
        'id': 'sponsored_2',
        'title': 'Modern Apartment Downtown',
        'description': 'Stylish 2BHK apartment in the heart of the city',
        'location': 'Mumbai, India',
        'type': 'apartment',
        'bedrooms': 2,
        'bathrooms': 2,
        'maxGuests': 4,
        'pricePerNight': 3500,
        'rating': 4.6,
        'reviewCount': 89,
        'ownerId': 'host_2',
        'isAvailable': true,
        'createdAt': DateTime.now().toIso8601String(),
        'isSponsored': true,
        'images': [
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
        ],
        'amenities': ['WiFi', 'AC', 'Gym', 'Parking'],
      },
    ];

    state = state.copyWith(sponsoredProperties: mockProperties);
  }

  Future<bool> createSponsoredCampaign({
    required String propertyId,
    required String campaignName,
    required double bidAmount,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, dynamic> targetingOptions = const {},
  }) async {
    try {
      final campaign = SponsoredListing(
        id: 'campaign_${DateTime.now().millisecondsSinceEpoch}',
        propertyId: propertyId,
        hostId: 'current_host', // Replace with actual host ID
        campaignName: campaignName,
        bidAmount: bidAmount,
        startDate: startDate,
        endDate: endDate,
        isActive: true,
        targetingOptions: targetingOptions,
      );

      state = state.copyWith(
        campaigns: [...state.campaigns, campaign],
      );

      await _saveData();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create campaign: $e');
      return false;
    }
  }

  Future<void> updateCampaign(String campaignId, {
    String? campaignName,
    double? bidAmount,
    bool? isActive,
    Map<String, dynamic>? targetingOptions,
  }) async {
    final campaigns = state.campaigns.map((campaign) {
      if (campaign.id == campaignId) {
        return campaign.copyWith(
          campaignName: campaignName ?? campaign.campaignName,
          bidAmount: bidAmount ?? campaign.bidAmount,
          isActive: isActive ?? campaign.isActive,
          targetingOptions: targetingOptions ?? campaign.targetingOptions,
        );
      }
      return campaign;
    }).toList();

    state = state.copyWith(campaigns: campaigns);
    await _saveData();
  }

  Future<void> deleteCampaign(String campaignId) async {
    final campaigns = state.campaigns.where((c) => c.id != campaignId).toList();
    state = state.copyWith(campaigns: campaigns);
    await _saveData();
  }

  void recordImpression(String campaignId) {
    final campaigns = state.campaigns.map((campaign) {
      if (campaign.id == campaignId) {
        return campaign.copyWith(
          impressions: campaign.impressions + 1,
          totalSpent: campaign.totalSpent + (campaign.bidAmount * 0.001), // CPM calculation
        );
      }
      return campaign;
    }).toList();

    state = state.copyWith(campaigns: campaigns);
    _saveData();
  }

  void recordClick(String campaignId) {
    final campaigns = state.campaigns.map((campaign) {
      if (campaign.id == campaignId) {
        return campaign.copyWith(
          clicks: campaign.clicks + 1,
          totalSpent: campaign.totalSpent + campaign.bidAmount, // CPC calculation
        );
      }
      return campaign;
    }).toList();

    state = state.copyWith(campaigns: campaigns);
    _saveData();
  }

  List<Map<String, dynamic>> getSponsoredPropertiesForSearch({
    String? location,
    double? minPrice,
    double? maxPrice,
    String? propertyType,
  }) {
    // Filter sponsored properties based on search criteria
    var filtered = state.sponsoredProperties.where((property) {
      if (location != null && !(property['location'] as String).toLowerCase().contains(location.toLowerCase())) {
        return false;
      }
      if (minPrice != null && (property['pricePerNight'] as double) < minPrice) {
        return false;
      }
      if (maxPrice != null && (property['pricePerNight'] as double) > maxPrice) {
        return false;
      }
      if (propertyType != null && property['type'] != propertyType) {
        return false;
      }
      return true;
    }).toList();

    // Shuffle and return top 2 for injection into search results
    filtered.shuffle();
    return filtered.take(2).toList();
  }
}

class AdsService extends StateNotifier<AdsState> {
  AdsService() : super(const AdsState()) {
    _initializeAds();
  }

  static const String _adsStorageKey = 'ads_data';

  Future<void> _initializeAds() async {
    state = state.copyWith(isLoading: true);
    await _loadAdsData();
    await _setupAdPlacements();
    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadAdsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString(_adsStorageKey);
      if (storedData != null) {
        final data = jsonDecode(storedData);
        final impressions = (data['impressions'] as List?)
            ?.map((i) => AdImpression.fromJson(i))
            .toList() ?? [];
        final totalRevenue = data['totalRevenue']?.toDouble() ?? 0.0;
        
        state = state.copyWith(
          impressions: impressions,
          totalRevenue: totalRevenue,
        );
      }
    } catch (e) {
      // TODO: Replace with proper logging
      // log.error('Error loading ads data: $e');
    }
  }

  Future<void> _saveAdsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'impressions': state.impressions.map((i) => i.toJson()).toList(),
        'totalRevenue': state.totalRevenue,
      };
      await prefs.setString(_adsStorageKey, jsonEncode(data));
    } catch (e) {
      // TODO: Replace with proper logging
      // log.error('Error saving ads data: $e');
    }
  }

  Future<void> _setupAdPlacements() async {
    final placements = [
      const AdPlacement(
        id: 'search_banner',
        type: AdType.banner,
        location: 'search_results',
        cpmRate: 50.0,
        config: {'position': 'top', 'size': 'medium'},
      ),
      const AdPlacement(
        id: 'property_native',
        type: AdType.native,
        location: 'property_details',
        cpmRate: 75.0,
        config: {'position': 'bottom', 'style': 'card'},
      ),
      const AdPlacement(
        id: 'booking_interstitial',
        type: AdType.interstitial,
        location: 'booking_flow',
        cpmRate: 100.0,
        config: {'trigger': 'after_booking', 'frequency': 'once_per_session'},
      ),
      const AdPlacement(
        id: 'wallet_rewarded',
        type: AdType.rewarded,
        location: 'wallet',
        cpmRate: 150.0,
        config: {'reward': 50, 'currency': 'credits'},
      ),
    ];

    state = state.copyWith(placements: placements);
  }

  Future<void> showAd(String placementId, {String? userId}) async {
    final placement = state.placements.firstWhere(
      (p) => p.id == placementId,
      orElse: () => throw Exception('Placement not found'),
    );

    // Simulate ad impression
    final impression = AdImpression(
      id: 'imp_${DateTime.now().millisecondsSinceEpoch}',
      adId: placementId,
      userId: userId ?? 'anonymous',
      timestamp: DateTime.now(),
      revenue: placement.cpmRate / 1000, // Convert CPM to per-impression revenue
    );

    state = state.copyWith(
      impressions: [...state.impressions, impression],
      totalRevenue: state.totalRevenue + impression.revenue,
    );

    await _saveAdsData();
  }

  Future<double> showRewardedAd({String? userId}) async {
    const rewardAmount = 50.0;
    
    await showAd('wallet_rewarded', userId: userId);
    
    // Simulate ad watching delay
    await Future.delayed(const Duration(seconds: 3));
    
    return rewardAmount;
  }

  bool shouldShowInterstitialAd() {
    // Show interstitial ad every 5th app session or after major actions
    final random = Random();
    return random.nextDouble() < 0.2; // 20% chance
  }

  List<AdImpression> getRecentImpressions({int limit = 50}) {
    return state.impressions
        .take(limit)
        .toList();
  }

  double getTotalRevenue({DateTime? since}) {
    if (since == null) return state.totalRevenue;
    
    return state.impressions
        .where((imp) => imp.timestamp.isAfter(since))
        .fold(0.0, (sum, imp) => sum + imp.revenue);
  }

  Map<String, double> getRevenueByPlacement() {
    final revenueMap = <String, double>{};
    
    for (final impression in state.impressions) {
      revenueMap[impression.adId] = (revenueMap[impression.adId] ?? 0.0) + impression.revenue;
    }
    
    return revenueMap;
  }
}
