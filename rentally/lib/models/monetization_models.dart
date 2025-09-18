
// Subscription Plans
enum SubscriptionTier {
  basic,
  pro,
  elite,
}

enum SubscriptionDuration {
  monthly,
  yearly,
}

class SubscriptionPlan {
  final String id;
  final SubscriptionTier tier;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;
  final bool isPopular;
  final String currency;

  const SubscriptionPlan({
    required this.id,
    required this.tier,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    this.isPopular = false,
    this.currency = 'INR',
  });

  double getPrice(SubscriptionDuration duration) {
    return duration == SubscriptionDuration.monthly ? monthlyPrice : yearlyPrice;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tier': tier.name,
      'name': name,
      'description': description,
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'features': features,
      'isPopular': isPopular,
      'currency': currency,
    };
  }

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      tier: SubscriptionTier.values.firstWhere((e) => e.name == json['tier']),
      name: json['name'],
      description: json['description'],
      monthlyPrice: json['monthlyPrice'].toDouble(),
      yearlyPrice: json['yearlyPrice'].toDouble(),
      features: List<String>.from(json['features']),
      isPopular: json['isPopular'] ?? false,
      currency: json['currency'] ?? 'INR',
    );
  }
}

// User Subscription Status
class UserSubscription {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final SubscriptionDuration duration;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool autoRenew;
  final String? stripeSubscriptionId;

  const UserSubscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.duration,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.autoRenew = true,
    this.stripeSubscriptionId,
  });

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isValid => isActive && !isExpired;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'plan': plan.toJson(),
      'duration': duration.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'autoRenew': autoRenew,
      'stripeSubscriptionId': stripeSubscriptionId,
    };
  }

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      userId: json['userId'],
      plan: SubscriptionPlan.fromJson(json['plan']),
      duration: SubscriptionDuration.values.firstWhere((e) => e.name == json['duration']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'],
      autoRenew: json['autoRenew'] ?? true,
      stripeSubscriptionId: json['stripeSubscriptionId'],
    );
  }
}

// Microtransaction Types
enum MicrotransactionType {
  highlightMessage,
  instantBooking,
  priorityBadge,
  boostListing,
  verifiedBadge,
  premiumSupport,
  extraPhotos,
  featuredListing,
}

class MicrotransactionItem {
  final String id;
  final MicrotransactionType type;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String icon;
  final Duration? duration;
  final bool isOneTime;

  const MicrotransactionItem({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'INR',
    required this.icon,
    this.duration,
    this.isOneTime = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'icon': icon,
      'duration': duration?.inHours,
      'isOneTime': isOneTime,
    };
  }

  factory MicrotransactionItem.fromJson(Map<String, dynamic> json) {
    return MicrotransactionItem(
      id: json['id'],
      type: MicrotransactionType.values.firstWhere((e) => e.name == json['type']),
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      currency: json['currency'] ?? 'INR',
      icon: json['icon'],
      duration: json['duration'] != null ? Duration(hours: json['duration']) : null,
      isOneTime: json['isOneTime'] ?? false,
    );
  }
}

// Transaction History
enum TransactionStatus {
  pending,
  completed,
  failed,
  refunded,
}

enum TransactionType {
  subscription,
  microtransaction,
  commission,
  withdrawal,
  refund,
  reward,
}

class Transaction {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String currency;
  final TransactionStatus status;
  final String description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;
  final String? stripePaymentIntentId;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    required this.description,
    required this.createdAt,
    this.completedAt,
    this.metadata,
    this.stripePaymentIntentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
      'stripePaymentIntentId': stripePaymentIntentId,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['userId'],
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      amount: json['amount'].toDouble(),
      currency: json['currency'] ?? 'INR',
      status: TransactionStatus.values.firstWhere((e) => e.name == json['status']),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      metadata: json['metadata'],
      stripePaymentIntentId: json['stripePaymentIntentId'],
    );
  }
}

// Host Analytics
class HostAnalytics {
  final String hostId;
  final double monthlyEarnings;
  final double totalEarnings;
  final int totalBookings;
  final int activeListings;
  final double averageRating;
  final double conversionRate;
  final double listingHealthScore;
  final int profileViews;
  final int inquiries;
  final Map<String, double> earningsByMonth;

  const HostAnalytics({
    required this.hostId,
    required this.monthlyEarnings,
    required this.totalEarnings,
    required this.totalBookings,
    required this.activeListings,
    required this.averageRating,
    required this.conversionRate,
    required this.listingHealthScore,
    required this.profileViews,
    required this.inquiries,
    required this.earningsByMonth,
  });

  Map<String, dynamic> toJson() {
    return {
      'hostId': hostId,
      'monthlyEarnings': monthlyEarnings,
      'totalEarnings': totalEarnings,
      'totalBookings': totalBookings,
      'activeListings': activeListings,
      'averageRating': averageRating,
      'conversionRate': conversionRate,
      'listingHealthScore': listingHealthScore,
      'profileViews': profileViews,
      'inquiries': inquiries,
      'earningsByMonth': earningsByMonth,
    };
  }

  factory HostAnalytics.fromJson(Map<String, dynamic> json) {
    return HostAnalytics(
      hostId: json['hostId'],
      monthlyEarnings: json['monthlyEarnings'].toDouble(),
      totalEarnings: json['totalEarnings'].toDouble(),
      totalBookings: json['totalBookings'],
      activeListings: json['activeListings'],
      averageRating: json['averageRating'].toDouble(),
      conversionRate: json['conversionRate'].toDouble(),
      listingHealthScore: json['listingHealthScore'].toDouble(),
      profileViews: json['profileViews'],
      inquiries: json['inquiries'],
      earningsByMonth: Map<String, double>.from(json['earningsByMonth']),
    );
  }
}

// Wallet System
class UserWallet {
  final String userId;
  final double balance;
  final String currency;
  final double totalEarned;
  final double totalSpent;
  final DateTime lastUpdated;

  const UserWallet({
    required this.userId,
    required this.balance,
    this.currency = 'INR',
    required this.totalEarned,
    required this.totalSpent,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'balance': balance,
      'currency': currency,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserWallet.fromJson(Map<String, dynamic> json) {
    return UserWallet(
      userId: json['userId'],
      balance: json['balance'].toDouble(),
      currency: json['currency'] ?? 'INR',
      totalEarned: json['totalEarned'].toDouble(),
      totalSpent: json['totalSpent'].toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

// Regional Pricing
class RegionalPricing {
  final String countryCode;
  final String currency;
  final double exchangeRate;
  final Map<String, double> subscriptionMultipliers;
  final Map<String, double> microtransactionMultipliers;
  final bool taxIncluded;
  final double taxRate;

  const RegionalPricing({
    required this.countryCode,
    required this.currency,
    required this.exchangeRate,
    required this.subscriptionMultipliers,
    required this.microtransactionMultipliers,
    this.taxIncluded = false,
    this.taxRate = 0.0,
  });

  double convertPrice(double basePrice, String category) {
    double multiplier = 1.0;
    if (category == 'subscription') {
      multiplier = subscriptionMultipliers[countryCode] ?? 1.0;
    } else if (category == 'microtransaction') {
      multiplier = microtransactionMultipliers[countryCode] ?? 1.0;
    }
    
    double convertedPrice = basePrice * exchangeRate * multiplier;
    if (!taxIncluded) {
      convertedPrice += convertedPrice * taxRate;
    }
    return convertedPrice;
  }

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'currency': currency,
      'exchangeRate': exchangeRate,
      'subscriptionMultipliers': subscriptionMultipliers,
      'microtransactionMultipliers': microtransactionMultipliers,
      'taxIncluded': taxIncluded,
      'taxRate': taxRate,
    };
  }

  factory RegionalPricing.fromJson(Map<String, dynamic> json) {
    return RegionalPricing(
      countryCode: json['countryCode'],
      currency: json['currency'],
      exchangeRate: json['exchangeRate'].toDouble(),
      subscriptionMultipliers: Map<String, double>.from(json['subscriptionMultipliers']),
      microtransactionMultipliers: Map<String, double>.from(json['microtransactionMultipliers']),
      taxIncluded: json['taxIncluded'] ?? false,
      taxRate: json['taxRate']?.toDouble() ?? 0.0,
    );
  }
}
