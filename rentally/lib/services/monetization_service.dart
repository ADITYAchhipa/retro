import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/monetization_models.dart';

// Providers
final monetizationServiceProvider = StateNotifierProvider<MonetizationService, MonetizationState>((ref) {
  return MonetizationService();
});

// Host Analytics Service
class HostAnalyticsService extends StateNotifier<HostAnalytics?> {
  HostAnalyticsService() : super(null) {
    _loadMockAnalytics();
  }

  void _loadMockAnalytics() {
    state = const HostAnalytics(
      hostId: 'host_001',
      monthlyEarnings: 45000,
      totalEarnings: 250000,
      totalBookings: 45,
      activeListings: 3,
      averageRating: 4.8,
      conversionRate: 0.25,
      listingHealthScore: 0.85,
      profileViews: 1250,
      inquiries: 85,
      earningsByMonth: {
        'Jan': 35000,
        'Feb': 38000,
        'Mar': 42000,
        'Apr': 45000,
        'May': 48000,
        'Jun': 45000,
      },
    );
  }
}

// Wallet Service
class WalletService extends StateNotifier<UserWallet?> {
  static const _walletKey = 'user_wallet';
  
  WalletService() : super(null) {
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletData = prefs.getString(_walletKey);
      if (walletData != null) {
        state = UserWallet.fromJson(jsonDecode(walletData));
      } else {
        // Initialize with default wallet
        state = UserWallet(
          userId: 'user_001',
          balance: 0,
          currency: 'INR',
          totalEarned: 0,
          totalSpent: 0,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      // TODO: Replace with proper logging
      // log.error('Error loading wallet: $e');
      state = UserWallet(
        userId: 'user_001',
        balance: 0,
        currency: 'INR',
        totalEarned: 0,
        totalSpent: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  Future<void> _saveWallet() async {
    if (state != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_walletKey, jsonEncode(state!.toJson()));
      } catch (e) {
        // TODO: Replace with proper logging
        // log.error('Error saving wallet: $e');
      }
    }
  }

  Future<void> addFunds(double amount, String source) async {
    if (state != null) {
      final updated = UserWallet(
        userId: state!.userId,
        balance: state!.balance + amount,
        currency: state!.currency,
        totalEarned: state!.totalEarned + amount,
        totalSpent: state!.totalSpent,
        lastUpdated: DateTime.now(),
      );
      state = updated;
      await _saveWallet();
    }
  }

  Future<bool> deductFunds(double amount, String purpose) async {
    if (state != null && state!.balance >= amount) {
      final updated = UserWallet(
        userId: state!.userId,
        balance: state!.balance - amount,
        currency: state!.currency,
        totalEarned: state!.totalEarned,
        totalSpent: state!.totalSpent + amount,
        lastUpdated: DateTime.now(),
      );
      state = updated;
      await _saveWallet();
      return true;
    }
    return false;
  }

  Future<void> earnFromAd(double amount) async {
    await addFunds(amount, 'Rewarded Ad');
  }
}

final hostAnalyticsProvider = StateNotifierProvider<HostAnalyticsService, HostAnalytics?>((ref) {
  return HostAnalyticsService();
});

final walletProvider = StateNotifierProvider<WalletService, UserWallet?>((ref) {
  return WalletService();
});

// State Classes
class MonetizationState {
  final List<SubscriptionPlan> subscriptionPlans;
  final List<MicrotransactionItem> microtransactionItems;
  final UserSubscription? currentSubscription;
  final List<Transaction> transactions;
  final RegionalPricing? regionalPricing;
  final bool isLoading;

  const MonetizationState({
    this.subscriptionPlans = const [],
    this.microtransactionItems = const [],
    this.currentSubscription,
    this.transactions = const [],
    this.regionalPricing,
    this.isLoading = false,
  });

  MonetizationState copyWith({
    List<SubscriptionPlan>? subscriptionPlans,
    List<MicrotransactionItem>? microtransactionItems,
    UserSubscription? currentSubscription,
    List<Transaction>? transactions,
    RegionalPricing? regionalPricing,
    bool? isLoading,
  }) {
    return MonetizationState(
      subscriptionPlans: subscriptionPlans ?? this.subscriptionPlans,
      microtransactionItems: microtransactionItems ?? this.microtransactionItems,
      currentSubscription: currentSubscription ?? this.currentSubscription,
      transactions: transactions ?? this.transactions,
      regionalPricing: regionalPricing ?? this.regionalPricing,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Main Monetization Service
class MonetizationService extends StateNotifier<MonetizationState> {
  MonetizationService() : super(const MonetizationState()) {
    _initializeService();
  }

  static const String _storageKey = 'monetization_data';

  Future<void> _initializeService() async {
    state = state.copyWith(isLoading: true);
    await _loadStoredData();
    await _initializeDefaultPlans();
    await _loadRegionalPricing();
    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString(_storageKey);
      if (storedData != null) {
        final data = jsonDecode(storedData);
        
        final transactions = (data['transactions'] as List?)
            ?.map((t) => Transaction.fromJson(t))
            .toList() ?? [];
            
        final currentSubscription = data['currentSubscription'] != null
            ? UserSubscription.fromJson(data['currentSubscription'])
            : null;

        state = state.copyWith(
          transactions: transactions,
          currentSubscription: currentSubscription,
        );
      }
    } catch (e) {
      // TODO: Replace with proper logging
      // log.error('Error loading monetization data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'transactions': state.transactions.map((t) => t.toJson()).toList(),
        'currentSubscription': state.currentSubscription?.toJson(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      // TODO: Replace with proper logging
      // log.error('Error saving monetization data: $e');
    }
  }

  Future<void> _initializeDefaultPlans() async {
    final plans = [
      // Host Plans
      const SubscriptionPlan(
        id: 'host_basic',
        tier: SubscriptionTier.basic,
        name: 'Basic (Owner)',
        description: 'Everything you need to start hosting',
        monthlyPrice: 199,
        yearlyPrice: 1990,
        features: [
          'Create and publish up to 3 active listings',
          'Properties & vehicles supported',
          'Standard analytics (views & inquiries)',
          'Standard chat with seekers',
          '10% platform commission on bookings',
          'Limited photos (max 5 per listing)',
        ],
      ),
      const SubscriptionPlan(
        id: 'host_pro',
        tier: SubscriptionTier.pro,
        name: 'Pro (Owner)',
        description: 'Grow faster with premium placement & insights',
        monthlyPrice: 499,
        yearlyPrice: 4990,
        isPopular: true,
        features: [
          'Unlimited listings',
          'Advanced analytics (conversion rate, demand heatmap)',
          'Featured property/vehicle placement',
          'Premium chat (auto-translation, canned responses)',
          'Reduced commission fee (5%)',
          'Upload 360° photos & videos',
          'Priority support',
        ],
      ),
      const SubscriptionPlan(
        id: 'host_elite',
        tier: SubscriptionTier.elite,
        name: 'Elite (Owner)',
        description: 'Zero commission. Global reach. Concierge support.',
        monthlyPrice: 999,
        yearlyPrice: 9990,
        features: [
          'All Pro features +',
          'Zero commission on bookings (flat subscription model)',
          'Global promotion across countries',
          'Auto currency conversion',
          'Access to premium AI pricing optimizer',
          'Dedicated account manager & priority support',
          'Unlock Seeker premium features',
        ],
      ),
      // Seeker Plans
      const SubscriptionPlan(
        id: 'seeker_basic',
        tier: SubscriptionTier.basic,
        name: 'Basic (Seeker)',
        description: 'Explore listings and start booking',
        monthlyPrice: 0,
        yearlyPrice: 0,
        features: [
          'Search & browse listings',
          'Book properties/vehicles',
          'Access reviews & ratings',
          'Standard support',
          'Limited saved searches (max 5)',
        ],
      ),
      const SubscriptionPlan(
        id: 'seeker_pro',
        tier: SubscriptionTier.pro,
        name: 'Pro (Seeker)',
        description: 'Book faster with smarter search & perks',
        monthlyPrice: 99,
        yearlyPrice: 990,
        isPopular: true,
        features: [
          'Unlimited saved searches',
          'Priority booking (faster confirmation)',
          'Premium support (priority ticket resolution)',
          'AI-powered recommendations',
          'Discounts on service fees',
          'Price drop alerts',
        ],
      ),
      const SubscriptionPlan(
        id: 'seeker_elite',
        tier: SubscriptionTier.elite,
        name: 'Elite (Seeker)',
        description: 'VIP access, concierge assistance & best deals',
        monthlyPrice: 299,
        yearlyPrice: 2990,
        features: [
          'All Pro features +',
          'VIP booking with early access to premium listings',
          'Dedicated travel/property concierge',
          'Insurance coverage discounts',
          'Free cancellation window',
          'Unlock Owner features (post your listings)',
        ],
      ),
    ];

    final microtransactions = [
      // Seeker Microtransactions
      const MicrotransactionItem(
        id: 'highlight_message',
        type: MicrotransactionType.highlightMessage,
        name: 'Highlight Message',
        description: 'Make your message stand out to hosts',
        price: 49,
        icon: '✨',
        duration: Duration(days: 1),
      ),
      const MicrotransactionItem(
        id: 'instant_booking',
        type: MicrotransactionType.instantBooking,
        name: 'Instant Booking',
        description: 'Skip the approval process',
        price: 99,
        icon: '⚡',
        isOneTime: true,
      ),
      const MicrotransactionItem(
        id: 'priority_badge',
        type: MicrotransactionType.priorityBadge,
        name: 'Priority Badge',
        description: 'Show hosts you\'re a serious renter',
        price: 199,
        icon: '🏆',
        duration: Duration(days: 30),
      ),
      // Host Microtransactions
      const MicrotransactionItem(
        id: 'boost_listing',
        type: MicrotransactionType.boostListing,
        name: 'Boost Listing',
        description: 'Increase visibility in search results',
        price: 299,
        icon: '🚀',
        duration: Duration(days: 7),
      ),
      const MicrotransactionItem(
        id: 'verified_badge',
        type: MicrotransactionType.verifiedBadge,
        name: 'Verified Badge',
        description: 'Build trust with a verification badge',
        price: 499,
        icon: '✅',
        isOneTime: true,
      ),
      const MicrotransactionItem(
        id: 'featured_listing',
        type: MicrotransactionType.featuredListing,
        name: 'Featured Listing',
        description: 'Get featured in premium spots',
        price: 799,
        icon: '⭐',
        duration: Duration(days: 14),
      ),
    ];

    state = state.copyWith(
      subscriptionPlans: plans,
      microtransactionItems: microtransactions,
    );
  }

  // Commission helpers for Owner side based on current subscription
  double getOwnerCommissionRate() {
    final planId = state.currentSubscription?.plan.id ?? '';
    if (planId.startsWith('host_elite')) return 0.0; // Zero commission
    if (planId.startsWith('host_pro')) return 0.05;  // Reduced commission (5%)
    if (planId.startsWith('host_basic')) return 0.10; // Default commission (10%)
    // If user has a seeker plan or no plan, default platform rate
    return 0.10;
  }

  double computeCommissionAmount(double bookingAmount) {
    final rate = getOwnerCommissionRate();
    return bookingAmount * rate;
  }

  Future<void> _loadRegionalPricing() async {
    // Mock regional pricing - in real app, fetch from API
    const regionalPricing = RegionalPricing(
      countryCode: 'IN',
      currency: 'INR',
      exchangeRate: 1.0,
      subscriptionMultipliers: {
        'IN': 1.0,
        'US': 0.8,
        'GB': 0.9,
        'AU': 0.85,
      },
      microtransactionMultipliers: {
        'IN': 1.0,
        'US': 0.75,
        'GB': 0.85,
        'AU': 0.8,
      },
      taxIncluded: true,
      taxRate: 0.18, // 18% GST in India
    );

    state = state.copyWith(regionalPricing: regionalPricing);
  }

  // Subscription Management
  Future<bool> purchaseSubscription(SubscriptionPlan plan, SubscriptionDuration duration) async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      final subscription = UserSubscription(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user', // Replace with actual user ID
        plan: plan,
        duration: duration,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(
          duration == SubscriptionDuration.monthly 
            ? const Duration(days: 30)
            : const Duration(days: 365)
        ),
        isActive: true,
        stripeSubscriptionId: 'stripe_${Random().nextInt(999999)}',
      );

      final transaction = Transaction(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        type: TransactionType.subscription,
        amount: plan.getPrice(duration),
        status: TransactionStatus.completed,
        description: 'Subscription: ${plan.name} (${duration.name})',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        metadata: {
          'plan_id': plan.id,
          'duration': duration.name,
        },
      );

      state = state.copyWith(
        currentSubscription: subscription,
        transactions: [transaction, ...state.transactions],
        isLoading: false,
      );

      await _saveData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  // Track commission against the current user's monetization record (stub)
  Future<void> collectCommission(double bookingAmount, {String? bookingId, String? ownerId}) async {
    try {
      final commission = computeCommissionAmount(bookingAmount);
      final txn = Transaction(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        type: TransactionType.commission,
        amount: commission,
        status: TransactionStatus.completed,
        description: 'Commission from booking ${bookingId ?? ''}'.trim(),
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        metadata: {
          if (bookingId != null) 'booking_id': bookingId,
          if (ownerId != null) 'owner_id': ownerId,
          'rate': getOwnerCommissionRate(),
          'booking_amount': bookingAmount,
        },
      );
      state = state.copyWith(transactions: [txn, ...state.transactions]);
      await _saveData();
    } catch (_) {
      // ignore stub failures
    }
  }

  // Purchase microtransaction
  Future<bool> purchaseMicrotransaction(MicrotransactionItem item) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 1));
      
      final transaction = Transaction(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        type: TransactionType.microtransaction,
        amount: item.price,
        currency: item.currency,
        status: TransactionStatus.completed,
        description: 'Microtransaction: ${item.name}',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        metadata: {
          'item_id': item.id,
          'item_type': item.type.name,
        },
      );
      
      state = state.copyWith(
        transactions: [transaction, ...state.transactions],
        isLoading: false,
      );
      
      await _saveData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  // Check if user has active subscription
  bool hasActiveSubscription() {
    return state.currentSubscription != null && state.currentSubscription!.isValid;
  }
}
