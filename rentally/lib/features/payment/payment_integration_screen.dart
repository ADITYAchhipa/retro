import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../app/auth_router.dart';
import '../../core/providers/ui_visibility_provider.dart';
import '../../core/utils/currency_formatter.dart';

enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  applePay,
  googlePay,
  bankTransfer,
}

class PaymentCard {
  final String id;
  final String last4;
  final String brand;
  final String expiryMonth;
  final String expiryYear;
  final bool isDefault;

  const PaymentCard({
    required this.id,
    required this.last4,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    this.isDefault = false,
  });

  PaymentCard copyWith({
    String? id,
    String? last4,
    String? brand,
    String? expiryMonth,
    String? expiryYear,
    bool? isDefault,
  }) {
    return PaymentCard(
      id: id ?? this.id,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class PaymentService extends StateNotifier<List<PaymentCard>> {
  PaymentService() : super(_mockCards);

  static final List<PaymentCard> _mockCards = [
    const PaymentCard(
      id: '1',
      last4: '4242',
      brand: 'Visa',
      expiryMonth: '12',
      expiryYear: '25',
      isDefault: true,
    ),
    const PaymentCard(
      id: '2',
      last4: '5555',
      brand: 'Mastercard',
      expiryMonth: '08',
      expiryYear: '26',
    ),
  ];

  void addCard(PaymentCard card) {
    state = [...state, card];
  }

  void removeCard(String cardId) {
    state = state.where((card) => card.id != cardId).toList();
  }

  void setDefaultCard(String cardId) {
    state = state.map((card) {
      return card.copyWith(isDefault: card.id == cardId);
    }).toList();
  }
}

final paymentServiceProvider = StateNotifierProvider<PaymentService, List<PaymentCard>>((ref) {
  return PaymentService();
});

class PaymentIntegrationScreen extends ConsumerStatefulWidget {
  final String? bookingId;
  final double? amount;
  final String? propertyTitle;

  const PaymentIntegrationScreen({
    super.key,
    this.bookingId,
    this.amount,
    this.propertyTitle,
  });

  @override
  ConsumerState<PaymentIntegrationScreen> createState() => _PaymentIntegrationScreenState();
}

class _PaymentIntegrationScreenState extends ConsumerState<PaymentIntegrationScreen> {
  PaymentMethod? _selectedMethod;
  PaymentCard? _selectedCard;
  bool _isProcessing = false;
  
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mark immersive route open to hide Shell bottom bar without flicker
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(immersiveRouteOpenProvider.notifier).state = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(paymentServiceProvider);
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t?.payment ?? 'Payment'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Booking Summary
          if (widget.amount != null) _buildBookingSummary(theme),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Methods
                  Text(
                    'Payment Method',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Saved Cards
                  if (cards.isNotEmpty) ...[
                    Text(
                      'Saved Cards',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...cards.map((card) => _buildSavedCardTile(card, theme)),
                    const SizedBox(height: 24),
                  ],
                  
                  // Add New Card
                  _buildPaymentMethodTile(
                    PaymentMethod.creditCard,
                    'Credit/Debit Card',
                    Icons.credit_card,
                    theme,
                  ),
                  _buildPaymentMethodTile(
                    PaymentMethod.paypal,
                    'PayPal',
                    Icons.account_balance_wallet,
                    theme,
                  ),
                  _buildPaymentMethodTile(
                    PaymentMethod.applePay,
                    'Apple Pay',
                    Icons.phone_iphone,
                    theme,
                  ),
                  _buildPaymentMethodTile(
                    PaymentMethod.googlePay,
                    'Google Pay',
                    Icons.payment,
                    theme,
                  ),
                  
                  // New Card Form
                  if (_selectedMethod == PaymentMethod.creditCard) ...[
                    const SizedBox(height: 24),
                    _buildNewCardForm(theme),
                  ],
                ],
              ),
            ),
          ),
          
          // Payment Button
          _buildPaymentButton(theme),
        ],
      ),
    );
  }

  Widget _buildBookingSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.propertyTitle != null)
            Text(
              widget.propertyTitle!,
              style: theme.textTheme.bodyLarge,
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                CurrencyFormatter.formatPrice(widget.amount!),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCardTile(PaymentCard card, ThemeData theme) {
    // final isSelected = _selectedCard?.id == card.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<PaymentCard>(
        value: card,
        groupValue: _selectedCard,
        onChanged: (value) {
          setState(() {
            _selectedCard = value;
            _selectedMethod = null;
          });
        },
        title: Row(
          children: [
            Icon(_getCardIcon(card.brand)),
            const SizedBox(width: 12),
            Text('•••• •••• •••• ${card.last4}'),
            if (card.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Default',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text('${card.brand} • Expires ${card.expiryMonth}/${card.expiryYear}'),
        secondary: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'default',
              child: Text('Set as Default'),
            ),
            PopupMenuItem(
              value: 'remove',
              child: Text(
                'Remove Card',
                style: TextStyle(color: Colors.red[600]),
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'default') {
              ref.read(paymentServiceProvider.notifier).setDefaultCard(card.id);
            } else if (value == 'remove') {
              _showRemoveCardDialog(card);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method, String title, IconData icon, ThemeData theme) {
    // final isSelected = method == _selectedMethod;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<PaymentMethod>(
        value: method,
        groupValue: _selectedMethod,
        onChanged: (value) {
          setState(() {
            _selectedMethod = value;
            _selectedCard = null;
          });
        },
        title: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCardForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Card Number
        TextFormField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        
        // Expiry and CVV
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  hintText: '12/25',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Cardholder Name
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            hintText: 'John Doe',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        
        // Save Card Option
        CheckboxListTile(
          value: true,
          onChanged: (value) {},
          title: const Text('Save card for future payments'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildPaymentButton(ThemeData theme) {
    final hasSelectedPayment = _selectedCard != null || _selectedMethod != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Security Notice
          Row(
            children: [
              Icon(
                Icons.security,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your payment information is encrypted and secure',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Pay Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasSelectedPayment && !_isProcessing ? _processPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.amount != null
                          ? 'Pay ${CurrencyFormatter.formatPrice(widget.amount!)}'
                          : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCardIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);
    
    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: Icon(
              Icons.check_circle,
              color: Colors.green[600],
              size: 48,
            ),
            title: const Text('Payment Successful!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your booking has been confirmed.'),
                const SizedBox(height: 16),
                if (widget.amount != null)
                  Text(
                    'Amount: ${CurrencyFormatter.formatPrice(widget.amount!)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showRemoveCardDialog(PaymentCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Card'),
        content: Text('Are you sure you want to remove •••• ${card.last4}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(paymentServiceProvider.notifier).removeCard(card.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clear immersive route flag on exit
    ref.read(immersiveRouteOpenProvider.notifier).state = false;
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(paymentServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddCardDialog(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: cards.isEmpty
          ? _buildEmptyState(context, ref, theme)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return _buildCardTile(context, ref, card, theme);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Payment Methods',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a payment method to make bookings easier',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddCardDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(BuildContext context, WidgetRef ref, PaymentCard card, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(_getCardIcon(card.brand)),
        title: Row(
          children: [
            Text('•••• •••• •••• ${card.last4}'),
            if (card.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Default',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text('${card.brand} • Expires ${card.expiryMonth}/${card.expiryYear}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (!card.isDefault)
              const PopupMenuItem(
                value: 'default',
                child: Text('Set as Default'),
              ),
            PopupMenuItem(
              value: 'remove',
              child: Text(
                'Remove Card',
                style: TextStyle(color: Colors.red[600]),
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'default') {
              ref.read(paymentServiceProvider.notifier).setDefaultCard(card.id);
            } else if (value == 'remove') {
              _showRemoveCardDialog(context, ref, card);
            }
          },
        ),
      ),
    );
  }

  IconData _getCardIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }

  void _showAddCardDialog(BuildContext context, WidgetRef ref) {
    // Pre-toggle immersive state to avoid bottom bar flicker
    ref.read(immersiveRouteOpenProvider.notifier).state = true;
    context.push(Routes.paymentIntegration).whenComplete(() {
      // Ensure immersive flag is cleared when returning
      ref.read(immersiveRouteOpenProvider.notifier).state = false;
    });
  }

  void _showRemoveCardDialog(BuildContext context, WidgetRef ref, PaymentCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Card'),
        content: Text('Are you sure you want to remove •••• ${card.last4}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(paymentServiceProvider.notifier).removeCard(card.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
