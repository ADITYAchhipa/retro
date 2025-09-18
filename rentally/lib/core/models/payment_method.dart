/// Payment method model for handling different payment types
class PaymentMethod {
  final String id;
  final String name;
  final PaymentMethodType type;
  final bool isEnabled;
  final Map<String, dynamic>? metadata;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.isEnabled,
    this.metadata,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PaymentMethodType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => PaymentMethodType.card,
      ),
      isEnabled: json['isEnabled'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'isEnabled': isEnabled,
      'metadata': metadata,
    };
  }
}

/// Payment method types supported by the app
enum PaymentMethodType {
  card,
  wallet,
  bankTransfer,
  crypto,
  applePay,
  googlePay,
}

/// Payment result model
class PaymentResult {
  final bool success;
  final String? transactionId;
  final double amount;
  final String currency;
  final String message;
  final Map<String, dynamic>? metadata;

  const PaymentResult({
    required this.success,
    this.transactionId,
    required this.amount,
    required this.currency,
    required this.message,
    this.metadata,
  });

  factory PaymentResult.success({
    required String transactionId,
    required double amount,
    required String currency,
    String message = 'Payment processed successfully',
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      amount: amount,
      currency: currency,
      message: message,
      metadata: metadata,
    );
  }

  factory PaymentResult.failure({
    required String message,
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      success: false,
      amount: amount,
      currency: currency,
      message: message,
      metadata: metadata,
    );
  }
}

/// Payment service for processing payments
class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance => _instance ??= PaymentService._();
  
  PaymentService._();

  /// Process a payment with the given parameters
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required PaymentMethod method,
    Map<String, dynamic>? metadata,
  }) async {
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock success/failure based on amount (for testing)
    final success = amount < 10000; // Fail for amounts >= 10000
    
    if (success) {
      return PaymentResult.success(
        transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        currency: currency,
        metadata: metadata,
      );
    } else {
      return PaymentResult.failure(
        message: 'Payment declined - amount too high',
        amount: amount,
        currency: currency,
        metadata: metadata,
      );
    }
  }

  /// Get available payment methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    return [
      const PaymentMethod(
        id: 'card',
        name: 'Credit/Debit Card',
        type: PaymentMethodType.card,
        isEnabled: true,
      ),
      const PaymentMethod(
        id: 'paypal',
        name: 'PayPal',
        type: PaymentMethodType.wallet,
        isEnabled: true,
      ),
      const PaymentMethod(
        id: 'bankTransfer',
        name: 'Bank Transfer',
        type: PaymentMethodType.bankTransfer,
        isEnabled: true,
      ),
    ];
  }
}
