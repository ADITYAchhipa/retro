import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

// Referral reward types
enum ReferralRewardType {
  signup,
  firstBooking,
  hostRegistration,
  propertyListing,
  review,
}

// Referral levels for progressive rewards
enum ReferralLevel {
  bronze, // 0-2 active referrals (last 30 days)
  silver, // 3-5
  gold,   // 6-9
  elite,  // 10+
}

// Referral transaction model
class ReferralTransaction {
  final String id;
  final String userId;
  final String referredUserId;
  final String referredUserName;
  final ReferralRewardType type;
  final int tokensEarned;
  final DateTime createdAt;
  final String description;
  final bool isCompleted;

  const ReferralTransaction({
    required this.id,
    required this.userId,
    required this.referredUserId,
    required this.referredUserName,
    required this.type,
    required this.tokensEarned,
    required this.createdAt,
    required this.description,
    this.isCompleted = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'referredUserId': referredUserId,
    'referredUserName': referredUserName,
    'type': type.name,
    'tokensEarned': tokensEarned,
    'createdAt': createdAt.toIso8601String(),
    'description': description,
    'isCompleted': isCompleted,
  };

  factory ReferralTransaction.fromJson(Map<String, dynamic> json) => ReferralTransaction(
    id: json['id'],
    userId: json['userId'],
    referredUserId: json['referredUserId'],
    referredUserName: json['referredUserName'],
    type: ReferralRewardType.values.firstWhere((e) => e.name == json['type']),
    tokensEarned: json['tokensEarned'],
    createdAt: DateTime.parse(json['createdAt']),
    description: json['description'],
    isCompleted: json['isCompleted'] ?? true,
  );
}

// User referral stats model
class UserReferralStats {
  final String userId;
  final String referralCode;
  final int totalTokens;
  final int totalReferrals;
  final int pendingTokens;
  final List<ReferralTransaction> transactions;
  final Map<ReferralRewardType, int> rewardCounts;
  final DateTime lastUpdated;

  const UserReferralStats({
    required this.userId,
    required this.referralCode,
    this.totalTokens = 0,
    this.totalReferrals = 0,
    this.pendingTokens = 0,
    this.transactions = const [],
    this.rewardCounts = const {},
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'referralCode': referralCode,
    'totalTokens': totalTokens,
    'totalReferrals': totalReferrals,
    'pendingTokens': pendingTokens,
    'transactions': transactions.map((t) => t.toJson()).toList(),
    'rewardCounts': rewardCounts.map((k, v) => MapEntry(k.name, v)),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory UserReferralStats.fromJson(Map<String, dynamic> json) => UserReferralStats(
    userId: json['userId'],
    referralCode: json['referralCode'],
    totalTokens: json['totalTokens'] ?? 0,
    totalReferrals: json['totalReferrals'] ?? 0,
    pendingTokens: json['pendingTokens'] ?? 0,
    transactions: (json['transactions'] as List?)
        ?.map((t) => ReferralTransaction.fromJson(t))
        .toList() ?? [],
    rewardCounts: (json['rewardCounts'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(
            ReferralRewardType.values.firstWhere((e) => e.name == k), 
            v as int)) ?? {},
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );

  UserReferralStats copyWith({
    String? userId,
    String? referralCode,
    int? totalTokens,
    int? totalReferrals,
    int? pendingTokens,
    List<ReferralTransaction>? transactions,
    Map<ReferralRewardType, int>? rewardCounts,
    DateTime? lastUpdated,
  }) => UserReferralStats(
    userId: userId ?? this.userId,
    referralCode: referralCode ?? this.referralCode,
    totalTokens: totalTokens ?? this.totalTokens,
    totalReferrals: totalReferrals ?? this.totalReferrals,
    pendingTokens: pendingTokens ?? this.pendingTokens,
    transactions: transactions ?? this.transactions,
    rewardCounts: rewardCounts ?? this.rewardCounts,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}

// Referral service
class ReferralService extends StateNotifier<UserReferralStats> {
  ReferralService() : super(UserReferralStats(
    userId: 'current_user',
    referralCode: '',
    lastUpdated: DateTime.now(),
  )) {
    _loadReferralData();
  }

  static const String _referralDataKey = 'referral_data';
  static const Map<ReferralRewardType, int> _rewardAmounts = {
    ReferralRewardType.signup: 50,
    ReferralRewardType.firstBooking: 100,
    ReferralRewardType.hostRegistration: 200,
    ReferralRewardType.propertyListing: 150,
    ReferralRewardType.review: 25,
  };

  // Load referral data from storage
  Future<void> _loadReferralData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final referralJson = prefs.getString(_referralDataKey);
      
      if (referralJson != null) {
        final Map<String, dynamic> decoded = json.decode(referralJson);
        state = UserReferralStats.fromJson(decoded);
      } else {
        // Initialize with new referral code
        state = state.copyWith(
          referralCode: _generateReferralCode(),
          lastUpdated: DateTime.now(),
        );
        await _saveReferralData();
      }
    } catch (e) {
      // Initialize with default data on error
      state = state.copyWith(
        referralCode: _generateReferralCode(),
        lastUpdated: DateTime.now(),
      );
    }
  }

  // Save referral data to storage
  Future<void> _saveReferralData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final referralJson = json.encode(state.toJson());
      await prefs.setString(_referralDataKey, referralJson);
    } catch (e) {
      // Handle error silently
    }
  }

  // Generate unique referral code
  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'RENT${List.generate(6, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  // Add referral reward
  Future<void> addReferralReward({
    required String referredUserId,
    required String referredUserName,
    required ReferralRewardType type,
    String? customDescription,
  }) async {
    final baseTokens = _rewardAmounts[type] ?? 0;
    // Apply level multiplier based on recent (last 30 days) activity
    final level = getReferralLevel();
    final multiplier = getLevelMultiplier(level);
    final tokensEarned = (baseTokens * multiplier).round();
    final description = customDescription ?? _getDefaultDescription(type, referredUserName);
    
    final transaction = ReferralTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: state.userId,
      referredUserId: referredUserId,
      referredUserName: referredUserName,
      type: type,
      tokensEarned: tokensEarned,
      createdAt: DateTime.now(),
      description: description,
    );

    final updatedTransactions = [transaction, ...state.transactions];
    final updatedRewardCounts = Map<ReferralRewardType, int>.from(state.rewardCounts);
    updatedRewardCounts[type] = (updatedRewardCounts[type] ?? 0) + 1;

    state = state.copyWith(
      totalTokens: state.totalTokens + tokensEarned,
      totalReferrals: state.totalReferrals + 1,
      transactions: updatedTransactions,
      rewardCounts: updatedRewardCounts,
      lastUpdated: DateTime.now(),
    );

    await _saveReferralData();
  }

  // Compute referral level based on active referrals in last [days] (default 30)
  ReferralLevel getReferralLevel({int days = 30}) {
    final active = getActiveReferralCount(days: days);
    if (active >= 10) return ReferralLevel.elite;
    if (active >= 6) return ReferralLevel.gold;
    if (active >= 3) return ReferralLevel.silver;
    return ReferralLevel.bronze;
  }

  // Multiplier for rewards by level
  double getLevelMultiplier(ReferralLevel level) {
    switch (level) {
      case ReferralLevel.elite:
        return 1.5;
      case ReferralLevel.gold:
        return 1.25;
      case ReferralLevel.silver:
        return 1.1;
      case ReferralLevel.bronze:
        return 1.0;
    }
  }

  // Active referrals within the last [days]
  int getActiveReferralCount({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return state.transactions.where((t) => t.tokensEarned > 0 && t.createdAt.isAfter(cutoff)).length;
  }

  // Total used tokens (negative entries)
  int getUsedTokens() {
    return state.transactions.where((t) => t.tokensEarned < 0).fold<int>(0, (s, t) => s + (-t.tokensEarned));
  }

  // Redeem tokens
  Future<bool> redeemTokens(int amount, String purpose) async {
    if (state.totalTokens < amount) {
      return false;
    }

    // Create redemption transaction (negative tokens)
    final transaction = ReferralTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: state.userId,
      referredUserId: 'system',
      referredUserName: 'System',
      type: ReferralRewardType.signup, // Placeholder type
      tokensEarned: -amount,
      createdAt: DateTime.now(),
      description: 'Redeemed $amount tokens for $purpose',
    );

    final updatedTransactions = [transaction, ...state.transactions];

    state = state.copyWith(
      totalTokens: state.totalTokens - amount,
      transactions: updatedTransactions,
      lastUpdated: DateTime.now(),
    );

    await _saveReferralData();
    return true;
  }

  // Get reward amount for type
  int getRewardAmount(ReferralRewardType type) {
    return _rewardAmounts[type] ?? 0;
  }

  // Get default description for reward type
  String _getDefaultDescription(ReferralRewardType type, String userName) {
    switch (type) {
      case ReferralRewardType.signup:
        return '$userName signed up using your referral code';
      case ReferralRewardType.firstBooking:
        return '$userName made their first booking';
      case ReferralRewardType.hostRegistration:
        return '$userName became a host';
      case ReferralRewardType.propertyListing:
        return '$userName listed their first property';
      case ReferralRewardType.review:
        return '$userName left their first review';
    }
  }

  // Get transactions by type
  List<ReferralTransaction> getTransactionsByType(ReferralRewardType type) {
    return state.transactions.where((t) => t.type == type).toList();
  }

  // Get recent transactions
  List<ReferralTransaction> getRecentTransactions({int limit = 10}) {
    return state.transactions.take(limit).toList();
  }

  // Calculate monthly earnings
  Map<String, int> getMonthlyEarnings() {
    final Map<String, int> monthlyEarnings = {};
    final now = DateTime.now();
    
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      
      final monthTransactions = state.transactions.where((t) => 
        t.createdAt.year == month.year && 
        t.createdAt.month == month.month &&
        t.tokensEarned > 0
      );
      
      monthlyEarnings[monthKey] = monthTransactions
          .fold(0, (sum, t) => sum + t.tokensEarned);
    }
    
    return monthlyEarnings;
  }

  // Reset referral data (for testing)
  Future<void> resetReferralData() async {
    state = UserReferralStats(
      userId: state.userId,
      referralCode: _generateReferralCode(),
      lastUpdated: DateTime.now(),
    );
    await _saveReferralData();
  }

  // Simulate referral activities (for demo)
  Future<void> simulateReferralActivity() async {
    final mockUsers = [
      'Sarah Johnson',
      'Mike Chen',
      'Emma Wilson',
      'David Brown',
      'Lisa Garcia',
    ];

    final random = Random();
    
    for (int i = 0; i < 5; i++) {
      final userName = mockUsers[random.nextInt(mockUsers.length)];
      final type = ReferralRewardType.values[random.nextInt(ReferralRewardType.values.length)];
      
      await addReferralReward(
        referredUserId: 'user_${i + 1}',
        referredUserName: userName,
        type: type,
      );
      
      // Add some delay for realistic timing
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}

// Provider
final referralServiceProvider = StateNotifierProvider<ReferralService, UserReferralStats>((ref) {
  return ReferralService();
});

// Specific providers
final totalTokensProvider = Provider<int>((ref) {
  return ref.watch(referralServiceProvider).totalTokens;
});

final totalReferralsProvider = Provider<int>((ref) {
  return ref.watch(referralServiceProvider).totalReferrals;
});

final referralCodeProvider = Provider<String>((ref) {
  return ref.watch(referralServiceProvider).referralCode;
});

final recentTransactionsProvider = Provider<List<ReferralTransaction>>((ref) {
  return ref.watch(referralServiceProvider).transactions.take(10).toList();
});

// Current referral level provider (computed from last 30 days)
final referralLevelProvider = Provider<ReferralLevel>((ref) {
  final svc = ref.read(referralServiceProvider.notifier);
  return svc.getReferralLevel(days: 30);
});
