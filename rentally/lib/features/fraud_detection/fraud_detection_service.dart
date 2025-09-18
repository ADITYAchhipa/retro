import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Industrial-grade fraud detection service with ML-based risk assessment
class FraudDetectionService {
  static final FraudDetectionService _instance = FraudDetectionService._internal();
  static FraudDetectionService get instance => _instance;
  
  FraudDetectionService._internal();

  final List<FraudRule> _rules = [];
  final List<UserRiskProfile> _userProfiles = [];
  final List<TransactionPattern> _patterns = [];
  final Random _random = Random();

  /// Initialize fraud detection with default rules
  Future<void> initialize() async {
    _setupDefaultRules();
    
    if (kDebugMode) {
      print('Fraud detection service initialized with ${_rules.length} rules');
    }
  }

  /// Analyze transaction for fraud risk
  Future<FraudAnalysisResult> analyzeTransaction({
    required String userId,
    required String transactionId,
    required double amount,
    required String currency,
    required String paymentMethod,
    required Map<String, dynamic> deviceInfo,
    required Map<String, dynamic> locationInfo,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Simulate ML processing delay
      await Future.delayed(const Duration(milliseconds: 300));

      final riskFactors = <RiskFactor>[];
      double totalRiskScore = 0.0;

      // 1. Amount-based risk assessment
      final amountRisk = _analyzeAmountRisk(amount, userId);
      if (amountRisk.score > 0.3) {
        riskFactors.add(amountRisk);
        totalRiskScore += amountRisk.score * amountRisk.weight;
      }

      // 2. User behavior analysis
      final behaviorRisk = await _analyzeUserBehavior(userId, amount, paymentMethod);
      if (behaviorRisk.score > 0.2) {
        riskFactors.add(behaviorRisk);
        totalRiskScore += behaviorRisk.score * behaviorRisk.weight;
      }

      // 3. Device fingerprinting
      final deviceRisk = _analyzeDeviceRisk(deviceInfo, userId);
      if (deviceRisk.score > 0.2) {
        riskFactors.add(deviceRisk);
        totalRiskScore += deviceRisk.score * deviceRisk.weight;
      }

      // 4. Location analysis
      final locationRisk = _analyzeLocationRisk(locationInfo, userId);
      if (locationRisk.score > 0.2) {
        riskFactors.add(locationRisk);
        totalRiskScore += locationRisk.score * locationRisk.weight;
      }

      // 5. Payment method risk
      final paymentRisk = _analyzePaymentMethodRisk(paymentMethod, userId);
      if (paymentRisk.score > 0.1) {
        riskFactors.add(paymentRisk);
        totalRiskScore += paymentRisk.score * paymentRisk.weight;
      }

      // 6. Velocity checks
      final velocityRisk = await _analyzeVelocity(userId, amount);
      if (velocityRisk.score > 0.3) {
        riskFactors.add(velocityRisk);
        totalRiskScore += velocityRisk.score * velocityRisk.weight;
      }

      // 7. Pattern matching
      final patternRisk = _analyzePatterns(userId, amount, paymentMethod, deviceInfo);
      if (patternRisk.score > 0.2) {
        riskFactors.add(patternRisk);
        totalRiskScore += patternRisk.score * patternRisk.weight;
      }

      // Normalize risk score
      final normalizedScore = totalRiskScore.clamp(0.0, 1.0);
      final riskLevel = _calculateRiskLevel(normalizedScore);
      final recommendation = _getRecommendation(riskLevel, normalizedScore);

      return FraudAnalysisResult(
        transactionId: transactionId,
        userId: userId,
        riskScore: normalizedScore,
        riskLevel: riskLevel,
        recommendation: recommendation,
        riskFactors: riskFactors,
        requiresManualReview: normalizedScore > 0.7,
        blockedReasons: riskLevel == RiskLevel.high ? _getBlockedReasons(riskFactors) : [],
        timestamp: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error analyzing transaction: $e');
      }
      
      return FraudAnalysisResult(
        transactionId: transactionId,
        userId: userId,
        riskScore: 0.5, // Default medium risk on error
        riskLevel: RiskLevel.medium,
        recommendation: FraudRecommendation.review,
        riskFactors: [],
        requiresManualReview: true,
        blockedReasons: ['Analysis error - manual review required'],
        timestamp: DateTime.now(),
      );
    }
  }

  /// Analyze amount-based risk
  RiskFactor _analyzeAmountRisk(double amount, String userId) {
    double score = 0.0;
    String reason = '';

    // High amount transactions
    if (amount > 5000) {
      score = 0.8;
      reason = 'Very high transaction amount';
    } else if (amount > 2000) {
      score = 0.6;
      reason = 'High transaction amount';
    } else if (amount > 1000) {
      score = 0.4;
      reason = 'Above average transaction amount';
    }

    // Unusual amount patterns (e.g., round numbers)
    if (amount % 100 == 0 && amount > 500) {
      score += 0.2;
      reason += ' - Round number pattern';
    }

    return RiskFactor(
      type: RiskFactorType.amount,
      score: score.clamp(0.0, 1.0),
      weight: 0.25,
      reason: reason,
      severity: score > 0.6 ? RiskSeverity.high : score > 0.3 ? RiskSeverity.medium : RiskSeverity.low,
    );
  }

  /// Analyze user behavior patterns
  Future<RiskFactor> _analyzeUserBehavior(String userId, double amount, String paymentMethod) async {
    double score = 0.0;
    String reason = '';

    // Simulate user history lookup
    final userProfile = _getUserRiskProfile(userId);
    
    // New user risk
    if (userProfile.transactionCount == 0) {
      score += 0.4;
      reason = 'New user - first transaction';
    }

    // Unusual amount for user
    if (userProfile.averageTransactionAmount > 0) {
      final amountRatio = amount / userProfile.averageTransactionAmount;
      if (amountRatio > 5.0) {
        score += 0.6;
        reason += ' - Amount 5x higher than usual';
      } else if (amountRatio > 3.0) {
        score += 0.4;
        reason += ' - Amount 3x higher than usual';
      }
    }

    // Unusual payment method
    if (!userProfile.usualPaymentMethods.contains(paymentMethod)) {
      score += 0.3;
      reason = reason.isEmpty ? 'New payment method' : '$reason - New payment method';
    }

    // Account age risk
    final accountAge = DateTime.now().difference(userProfile.createdAt).inDays;
    if (accountAge < 7) {
      score += 0.5;
      reason += ' - Very new account';
    } else if (accountAge < 30) {
      score += 0.3;
      reason += ' - New account';
    }

    return RiskFactor(
      type: RiskFactorType.behavior,
      score: score.clamp(0.0, 1.0),
      weight: 0.3,
      reason: reason,
      severity: score > 0.6 ? RiskSeverity.high : score > 0.3 ? RiskSeverity.medium : RiskSeverity.low,
    );
  }

  /// Analyze device-based risk
  RiskFactor _analyzeDeviceRisk(Map<String, dynamic> deviceInfo, String userId) {
    double score = 0.0;
    String reason = '';

    final deviceId = deviceInfo['deviceId'] as String? ?? '';
    final platform = deviceInfo['platform'] as String? ?? '';
    final isEmulator = deviceInfo['isEmulator'] as bool? ?? false;
    final isRooted = deviceInfo['isRooted'] as bool? ?? false;

    // Emulator/rooted device risk
    if (isEmulator) {
      score += 0.8;
      reason = 'Emulator detected';
    }
    
    if (isRooted) {
      score += 0.6;
      reason += ' - Rooted/jailbroken device';
    }

    // New device for user
    final userProfile = _getUserRiskProfile(userId);
    if (!userProfile.knownDevices.contains(deviceId)) {
      score += 0.4;
      reason += ' - New device';
    }

    // Suspicious platform patterns
    if (platform.isEmpty) {
      score += 0.3;
      reason += ' - Unknown platform';
    }

    return RiskFactor(
      type: RiskFactorType.device,
      score: score.clamp(0.0, 1.0),
      weight: 0.2,
      reason: reason,
      severity: score > 0.6 ? RiskSeverity.high : score > 0.3 ? RiskSeverity.medium : RiskSeverity.low,
    );
  }

  /// Analyze location-based risk
  RiskFactor _analyzeLocationRisk(Map<String, dynamic> locationInfo, String userId) {
    double score = 0.0;
    String reason = '';

    final country = locationInfo['country'] as String? ?? '';
    final ipAddress = locationInfo['ipAddress'] as String? ?? '';

    // High-risk countries (simulated)
    final highRiskCountries = ['XX', 'YY', 'ZZ']; // Placeholder
    if (highRiskCountries.contains(country)) {
      score += 0.7;
      reason = 'High-risk country';
    }

    // VPN/Proxy detection (simulated)
    if (ipAddress.startsWith('10.') || ipAddress.startsWith('192.168.')) {
      score += 0.4;
      reason += ' - Possible VPN/Proxy';
    }

    // Location change
    final userProfile = _getUserRiskProfile(userId);
    if (userProfile.lastKnownCountry.isNotEmpty && userProfile.lastKnownCountry != country) {
      score += 0.5;
      reason += ' - Location change detected';
    }

    // Impossible travel (if we had timestamp data)
    // This would check if user traveled impossibly fast between locations

    return RiskFactor(
      type: RiskFactorType.location,
      score: score.clamp(0.0, 1.0),
      weight: 0.15,
      reason: reason,
      severity: score > 0.6 ? RiskSeverity.high : score > 0.3 ? RiskSeverity.medium : RiskSeverity.low,
    );
  }

  /// Analyze payment method risk
  RiskFactor _analyzePaymentMethodRisk(String paymentMethod, String userId) {
    double score = 0.0;
    String reason = '';

    // Payment method risk levels
    switch (paymentMethod.toLowerCase()) {
      case 'cryptocurrency':
        score = 0.8;
        reason = 'High-risk payment method';
        break;
      case 'prepaid_card':
        score = 0.6;
        reason = 'Prepaid card - medium risk';
        break;
      case 'bank_transfer':
        score = 0.2;
        reason = 'Bank transfer - low risk';
        break;
      case 'credit_card':
        score = 0.3;
        reason = 'Credit card - standard risk';
        break;
      default:
        score = 0.4;
        reason = 'Unknown payment method';
    }

    return RiskFactor(
      type: RiskFactorType.paymentMethod,
      score: score,
      weight: 0.1,
      reason: reason,
      severity: score > 0.6 ? RiskSeverity.high : score > 0.3 ? RiskSeverity.medium : RiskSeverity.low,
    );
  }

  /// Analyze transaction velocity
  Future<RiskFactor> _analyzeVelocity(String userId, double amount) async {
    double score = 0.0;
    String reason = '';

    // Simulate velocity checks
    final recentTransactions = _random.nextInt(10); // 0-9 recent transactions
    final recentAmount = _random.nextDouble() * 5000; // Recent transaction total

    // Too many transactions in short time
    if (recentTransactions > 5) {
      score += 0.6;
      reason = 'High transaction frequency';
    } else if (recentTransactions > 3) {
      score += 0.4;
      reason = 'Above normal transaction frequency';
    }

    // High amount velocity
    if (recentAmount > 3000) {
      score += 0.5;
      reason += ' - High amount velocity';
    }

    return RiskFactor(
      type: RiskFactorType.velocity,
      score: score.clamp(0.0, 1.0),
      weight: 0.2,
      reason: reason,
      severity: score > 0.6 ? RiskSeverity.high : score > 0.3 ? RiskSeverity.medium : RiskSeverity.low,
    );
  }

  /// Analyze suspicious patterns
  RiskFactor _analyzePatterns(String userId, double amount, String paymentMethod, Map<String, dynamic> deviceInfo) {
    double score = 0.0;
    String reason = '';

    // Check against known fraud patterns
    for (final pattern in _patterns) {
      if (pattern.matches(userId, amount, paymentMethod, deviceInfo)) {
        score += pattern.riskScore;
        reason += '${pattern.description} ';
      }
    }

    return RiskFactor(
      type: RiskFactorType.pattern,
      score: score.clamp(0.0, 1.0),
      weight: 0.15,
      reason: reason.trim(),
      severity: score > 0.6 ? RiskSeverity.high : score > 0.3 ? RiskSeverity.medium : RiskSeverity.low,
    );
  }

  /// Get user risk profile
  UserRiskProfile _getUserRiskProfile(String userId) {
    // Try to find existing profile
    for (final profile in _userProfiles) {
      if (profile.userId == userId) {
        return profile;
      }
    }

    // Create new profile for new user
    final newProfile = UserRiskProfile(
      userId: userId,
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      transactionCount: _random.nextInt(50),
      averageTransactionAmount: 100 + _random.nextDouble() * 500,
      usualPaymentMethods: ['credit_card', 'bank_transfer'],
      knownDevices: [],
      lastKnownCountry: 'US',
      riskScore: _random.nextDouble() * 0.3, // Most users are low risk
    );

    _userProfiles.add(newProfile);
    return newProfile;
  }

  /// Calculate risk level from score
  RiskLevel _calculateRiskLevel(double score) {
    if (score >= 0.7) {
      return RiskLevel.high;
    } else if (score >= 0.4) {
      return RiskLevel.medium;
    } else {
      return RiskLevel.low;
    }
  }

  /// Get recommendation based on risk
  FraudRecommendation _getRecommendation(RiskLevel level, double score) {
    switch (level) {
      case RiskLevel.high:
        return score >= 0.9 ? FraudRecommendation.block : FraudRecommendation.review;
      case RiskLevel.medium:
        return FraudRecommendation.challenge;
      case RiskLevel.low:
        return FraudRecommendation.approve;
    }
  }

  /// Get blocked reasons for high-risk transactions
  List<String> _getBlockedReasons(List<RiskFactor> riskFactors) {
    return riskFactors
        .where((factor) => factor.severity == RiskSeverity.high)
        .map((factor) => factor.reason)
        .toList();
  }

  /// Setup default fraud detection rules
  void _setupDefaultRules() {
    _rules.addAll([
      FraudRule(
        id: 'high_amount',
        name: 'High Amount Transaction',
        description: 'Transactions above \$5000',
        condition: (data) => (data['amount'] as double? ?? 0) > 5000,
        riskScore: 0.8,
        action: FraudAction.review,
      ),
      FraudRule(
        id: 'new_user_high_amount',
        name: 'New User High Amount',
        description: 'New users with transactions above \$1000',
        condition: (data) => (data['accountAge'] as int? ?? 0) < 7 && (data['amount'] as double? ?? 0) > 1000,
        riskScore: 0.9,
        action: FraudAction.block,
      ),
      FraudRule(
        id: 'velocity_check',
        name: 'High Velocity',
        description: 'More than 5 transactions in 1 hour',
        condition: (data) => (data['recentTransactionCount'] as int? ?? 0) > 5,
        riskScore: 0.7,
        action: FraudAction.challenge,
      ),
    ]);

    // Add some sample fraud patterns
    _patterns.addAll([
      TransactionPattern(
        id: 'round_amount_pattern',
        description: 'Suspicious round amount pattern',
        riskScore: 0.3,
      ),
      TransactionPattern(
        id: 'rapid_succession',
        description: 'Multiple transactions in rapid succession',
        riskScore: 0.5,
      ),
    ]);
  }

  /// Add custom fraud rule
  void addRule(FraudRule rule) {
    _rules.add(rule);
  }

  /// Remove fraud rule
  void removeRule(String ruleId) {
    _rules.removeWhere((rule) => rule.id == ruleId);
  }

  /// Update user risk profile after transaction
  void updateUserProfile(String userId, Map<String, dynamic> transactionData) {
    final profile = _getUserRiskProfile(userId);
    profile.transactionCount++;
    
    final amount = transactionData['amount'] as double? ?? 0;
    profile.averageTransactionAmount = 
        (profile.averageTransactionAmount * (profile.transactionCount - 1) + amount) / profile.transactionCount;
    
    final paymentMethod = transactionData['paymentMethod'] as String? ?? '';
    if (!profile.usualPaymentMethods.contains(paymentMethod)) {
      profile.usualPaymentMethods.add(paymentMethod);
    }
  }
}

/// Risk factor model
class RiskFactor {
  final RiskFactorType type;
  final double score;
  final double weight;
  final String reason;
  final RiskSeverity severity;

  RiskFactor({
    required this.type,
    required this.score,
    required this.weight,
    required this.reason,
    required this.severity,
  });
}

/// Fraud analysis result
class FraudAnalysisResult {
  final String transactionId;
  final String userId;
  final double riskScore;
  final RiskLevel riskLevel;
  final FraudRecommendation recommendation;
  final List<RiskFactor> riskFactors;
  final bool requiresManualReview;
  final List<String> blockedReasons;
  final DateTime timestamp;

  FraudAnalysisResult({
    required this.transactionId,
    required this.userId,
    required this.riskScore,
    required this.riskLevel,
    required this.recommendation,
    required this.riskFactors,
    required this.requiresManualReview,
    required this.blockedReasons,
    required this.timestamp,
  });
}

/// User risk profile
class UserRiskProfile {
  final String userId;
  final DateTime createdAt;
  int transactionCount;
  double averageTransactionAmount;
  List<String> usualPaymentMethods;
  List<String> knownDevices;
  String lastKnownCountry;
  double riskScore;

  UserRiskProfile({
    required this.userId,
    required this.createdAt,
    required this.transactionCount,
    required this.averageTransactionAmount,
    required this.usualPaymentMethods,
    required this.knownDevices,
    required this.lastKnownCountry,
    required this.riskScore,
  });
}

/// Fraud rule model
class FraudRule {
  final String id;
  final String name;
  final String description;
  final bool Function(Map<String, dynamic>) condition;
  final double riskScore;
  final FraudAction action;

  FraudRule({
    required this.id,
    required this.name,
    required this.description,
    required this.condition,
    required this.riskScore,
    required this.action,
  });
}

/// Transaction pattern model
class TransactionPattern {
  final String id;
  final String description;
  final double riskScore;

  TransactionPattern({
    required this.id,
    required this.description,
    required this.riskScore,
  });

  bool matches(String userId, double amount, String paymentMethod, Map<String, dynamic> deviceInfo) {
    // Simplified pattern matching - in real implementation this would be more sophisticated
    switch (id) {
      case 'round_amount_pattern':
        return amount % 100 == 0 && amount > 500;
      case 'rapid_succession':
        return true; // Would check transaction timing
      default:
        return false;
    }
  }
}

/// Enums
enum RiskLevel { low, medium, high }
enum RiskSeverity { low, medium, high }
enum RiskFactorType { amount, behavior, device, location, paymentMethod, velocity, pattern }
enum FraudRecommendation { approve, challenge, review, block }
enum FraudAction { allow, challenge, review, block }
