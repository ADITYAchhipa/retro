import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/payment_method.dart';
import '../../core/validators/form_validators.dart';
import '../../core/widgets/tab_back_handler.dart';
import '../../services/payments/app_payment_router.dart';

/// Industrial-grade payment screen with multiple payment methods
class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final double amount;
  final String currency;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    this.currency = 'USD',
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  
  // Card payment fields
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  
  // Bank transfer fields
  final _accountNumberController = TextEditingController();
  final _routingNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  
  // PayPal fields
  final _paypalEmailController = TextEditingController();
  final _paypalApprovalUrlController = TextEditingController();
  
  // UPI fields
  final _upiVpaController = TextEditingController();
  final _upiPayeeController = TextEditingController();
  final _upiNoteController = TextEditingController(text: 'Rentally Booking');
  
  String _selectedMethod = 'card';
  bool _savePaymentMethod = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _accountHolderController.dispose();
    _paypalEmailController.dispose();
    _paypalApprovalUrlController.dispose();
    _upiVpaController.dispose();
    _upiPayeeController.dispose();
    _upiNoteController.dispose();
    super.dispose();
  }
  
  void _onTabChanged() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _selectedMethod = 'card';
          break;
        case 1:
          _selectedMethod = 'paypal';
          break;
        case 2:
          _selectedMethod = 'upi';
          break;
        case 3:
          _selectedMethod = 'bankTransfer';
          break;
      }
    });
  }
  
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final paymentRouter = AppPaymentRouter.instance;
      
      PaymentMethod method;
      switch (_selectedMethod) {
        case 'card':
          method = const PaymentMethod(
            id: 'card',
            name: 'Credit/Debit Card',
            type: PaymentMethodType.card,
            isEnabled: true,
          );
          break;
        case 'paypal':
          method = const PaymentMethod(
            id: 'paypal',
            name: 'PayPal',
            type: PaymentMethodType.wallet,
            isEnabled: true,
          );
          break;
        case 'upi':
          method = const PaymentMethod(
            id: 'upi',
            name: 'UPI',
            type: PaymentMethodType.wallet,
            isEnabled: true,
          );
          break;
        case 'bankTransfer':
          method = const PaymentMethod(
            id: 'bankTransfer',
            name: 'Bank Transfer',
            type: PaymentMethodType.bankTransfer,
            isEnabled: true,
          );
          break;
        default:
          method = const PaymentMethod(
            id: 'card',
            name: 'Credit/Debit Card',
            type: PaymentMethodType.card,
            isEnabled: true,
          );
      }
      
      // Pre-check for UPI currency
      if (_selectedMethod == 'upi' && widget.currency.toUpperCase() != 'INR') {
        _showErrorDialog('UPI is only available for INR payments');
        return;
      }

      final result = await paymentRouter.processPayment(
        amount: widget.amount,
        currency: widget.currency,
        method: method,
        metadata: {
          'bookingId': widget.bookingId,
          'savePaymentMethod': _savePaymentMethod,
          if (_selectedMethod == 'paypal' && _paypalApprovalUrlController.text.trim().isNotEmpty)
            'approvalUrl': _paypalApprovalUrlController.text.trim(),
          if (_selectedMethod == 'upi') ...{
            'upi_vpa': _upiVpaController.text.trim(),
            'upi_payeeName': _upiPayeeController.text.trim(),
            'upi_note': _upiNoteController.text.trim(),
          },
        },
      );
      
      if (result.success) {
        _showSuccessDialog(result);
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog('Payment failed: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }
  
  void _showSuccessDialog(PaymentResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Transaction ID: ${result.transactionId}'),
            const SizedBox(height: 8),
            Text('Amount: ${result.currency} ${result.amount.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/booking-confirmation/${widget.bookingId}');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 64),
        title: const Text('Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TabBackHandler(
      tabController: _tabController,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildPaymentSummary(theme),
          _buildPaymentMethods(theme),
          Expanded(child: _buildPaymentForm(theme)),
          _buildPaymentButton(theme),
        ],
      ),
      ),
    );
  }
  Widget _buildPaymentSummary(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Amount',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          Icon(
            Icons.security,
            color: theme.primaryColor,
            size: 32,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethods(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.primaryColor,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: theme.primaryColor,
        tabs: const [
          Tab(
            icon: Icon(Icons.credit_card),
            text: 'Card',
          ),
          Tab(
            icon: Icon(Icons.account_balance_wallet),
            text: 'PayPal',
          ),
          Tab(
            icon: Icon(Icons.currency_rupee),
            text: 'UPI',
          ),
          Tab(
            icon: Icon(Icons.account_balance),
            text: 'Bank',
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.down,
        physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
        children: [
          _buildCardForm(theme),
          _buildPayPalForm(theme),
          _buildUpiForm(theme),
          _buildBankTransferForm(theme),
        ],
      ),
    );
  }
  
  Widget _buildCardForm(ThemeData theme) {
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              prefixIcon: Icon(Icons.credit_card),
            ),
            keyboardType: TextInputType.number,
            validator: FormValidators.validateCreditCard,
            onChanged: (value) {
              // Format card number with spaces
              final formatted = value.replaceAll(' ', '');
              if (formatted.length <= 16) {
                final buffer = StringBuffer();
                for (int i = 0; i < formatted.length; i++) {
                  if (i > 0 && i % 4 == 0) buffer.write(' ');
                  buffer.write(formatted[i]);
                }
                _cardNumberController.value = TextEditingValue(
                  text: buffer.toString(),
                  selection: TextSelection.collapsed(offset: buffer.length),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormValidators.validateExpiryDate,
                  onChanged: (value) {
                    // Format expiry date
                    final formatted = value.replaceAll('/', '');
                    if (formatted.length <= 4) {
                      String result = formatted;
                      if (formatted.length >= 2) {
                        result = '${formatted.substring(0, 2)}/${formatted.substring(2)}';
                      }
                      _expiryController.value = TextEditingValue(
                        text: result,
                        selection: TextSelection.collapsed(offset: result.length),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormValidators.validateCVV,
                  maxLength: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _cardHolderController,
            decoration: const InputDecoration(
              labelText: 'Cardholder Name',
              hintText: 'John Doe',
              prefixIcon: Icon(Icons.person),
            ),
            validator: FormValidators.validateName,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          
          CheckboxListTile(
            title: const Text('Save this card for future payments'),
            value: _savePaymentMethod,
            onChanged: (value) {
              setState(() => _savePaymentMethod = value ?? false);
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPayPalForm(ThemeData theme) {
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PayPal Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _paypalEmailController,
            decoration: const InputDecoration(
              labelText: 'PayPal Email',
              hintText: 'your.email@example.com',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: FormValidators.validateEmail,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _paypalApprovalUrlController,
            decoration: const InputDecoration(
              labelText: 'PayPal Approval URL (sandbox/dev)',
              hintText: 'https://www.sandbox.paypal.com/checkoutnow?token=...'
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(height: 8),
                Text(
                  'You will be redirected to PayPal to complete your payment securely.',
                  style: TextStyle(color: Colors.blue[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiForm(ThemeData theme) {
    final isInr = widget.currency.toUpperCase() == 'INR';
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPI Payment',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (!isInr)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Text('UPI is only available for INR payments. Change currency to INR to enable.'),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _upiVpaController,
            decoration: const InputDecoration(
              labelText: 'UPI ID (VPA)',
              hintText: 'example@upi',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            enabled: isInr,
            validator: (v) {
              if (_selectedMethod == 'upi') {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Please enter a valid UPI ID';
                if (!value.contains('@')) return 'Invalid UPI ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _upiPayeeController,
            decoration: const InputDecoration(
              labelText: 'Payee Name',
              hintText: 'Acme Rentals Pvt Ltd',
              prefixIcon: Icon(Icons.person),
            ),
            enabled: isInr,
            validator: (v) {
              if (_selectedMethod == 'upi') {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Please enter payee name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _upiNoteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'Booking note',
              prefixIcon: Icon(Icons.note_alt_outlined),
            ),
            enabled: isInr,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Text('We will open your preferred UPI app (GPay/PhonePe/Paytm) to complete the payment.'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBankTransferForm(ThemeData theme) {
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bank Transfer Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _accountHolderController,
            decoration: const InputDecoration(
              labelText: 'Account Holder Name',
              hintText: 'John Doe',
              prefixIcon: Icon(Icons.person),
            ),
            validator: FormValidators.validateName,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _accountNumberController,
            decoration: const InputDecoration(
              labelText: 'Account Number',
              hintText: '1234567890',
              prefixIcon: Icon(Icons.account_balance),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter account number';
              }
              if (value.length < 8) {
                return 'Account number must be at least 8 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _routingNumberController,
            decoration: const InputDecoration(
              labelText: 'Routing Number',
              hintText: '123456789',
              prefixIcon: Icon(Icons.route),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter routing number';
              }
              if (value.length != 9) {
                return 'Routing number must be 9 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.schedule, color: Colors.orange),
                const SizedBox(height: 8),
                Text(
                  'Bank transfers may take 1-3 business days to process.',
                  style: TextStyle(color: Colors.orange[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Pay ${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
