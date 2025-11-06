import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/validators/form_validators.dart';
import '../../core/widgets/loading_states.dart';
import '../../widgets/responsive_layout.dart';
import '../../core/utils/currency_formatter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Industrial-grade payment screen with complete UI flow
class PaymentScreen extends ConsumerStatefulWidget {
  final double amount;
  final String bookingId;
  final String propertyTitle;
  
  const PaymentScreen({
    super.key,
    required this.amount,
    required this.bookingId,
    required this.propertyTitle,
  });
  
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _emailController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // State
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'card';
  bool _saveCard = false;
  bool _agreeToTerms = false;
  // int _currentStep = 0; // Removed unused field
  
  // Card formatting
  String _cardType = '';
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
    
    // Add card number formatting
    _cardNumberController.addListener(_formatCardNumber);
    _expiryController.addListener(_formatExpiry);
  }
  
  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _emailController.dispose();
    _billingAddressController.dispose();
    _postalCodeController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  
  void _formatCardNumber() {
    final text = _cardNumberController.text.replaceAll(' ', '');
    if (text.isEmpty) return;
    
    // Detect card type
    if (text.startsWith('4')) {
      _cardType = 'visa';
    } else if (text.startsWith('5')) {
      _cardType = 'mastercard';
    } else if (text.startsWith('3')) {
      _cardType = 'amex';
    } else {
      _cardType = '';
    }
    
    // Format with spaces
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    if (formatted != _cardNumberController.text) {
      _cardNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }
  
  void _formatExpiry() {
    final text = _expiryController.text.replaceAll('/', '');
    if (text.isEmpty) return;
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    if (formatted != _expiryController.text) {
      _expiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }
  
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isProcessing = true);
    
    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 3));
      
      if (!mounted) return;
      
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSuccessDialog(),
      );
      
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.payment),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: LoadingOverlay(
        isLoading: _isProcessing,
        loadingText: AppLocalizations.of(context)!.loading,
        child: ResponsiveLayout(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBookingSummary(theme, isDark),
                      const SizedBox(height: 24),
                      _buildPaymentMethods(theme, isDark),
                      const SizedBox(height: 24),
                      if (_selectedPaymentMethod == 'card')
                        _buildCardPaymentForm(theme, isDark),
                      if (_selectedPaymentMethod == 'paypal')
                        _buildPayPalOption(theme, isDark),
                      if (_selectedPaymentMethod == 'bank')
                        _buildBankTransferOption(theme, isDark),
                      const SizedBox(height: 24),
                      _buildTermsAndConditions(theme),
                      const SizedBox(height: 24),
                      _buildPayButton(theme),
                      const SizedBox(height: 32),
                      _buildSecurityBadges(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBookingSummary(ThemeData theme, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.bookingDetails,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.home,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.propertyTitle,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.confirmation_number,
                  color: theme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppLocalizations.of(context)!.bookingId}: ${widget.bookingId}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.totalAmount,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  CurrencyFormatter.formatPrice(widget.amount),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentMethods(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.paymentMethod,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodCard(
                theme,
                'card',
                Icons.credit_card,
                AppLocalizations.of(context)!.creditCard,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMethodCard(
                theme,
                'paypal',
                Icons.payment,
                AppLocalizations.of(context)!.paypal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMethodCard(
                theme,
                'bank',
                Icons.account_balance,
                'Bank Transfer',
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPaymentMethodCard(
    ThemeData theme,
    String method,
    IconData icon,
    String label,
  ) {
    final isSelected = _selectedPaymentMethod == method;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? theme.primaryColor.withOpacity(0.05)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.primaryColor : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? theme.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardPaymentForm(ThemeData theme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Number
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.cardNumber,
              hintText: '1234 5678 9012 3456',
              prefixIcon: const Icon(Icons.credit_card),
              suffixIcon: _cardType.isNotEmpty
                  ? Icon(
                      _cardType == 'visa'
                          ? Icons.payment
                          : _cardType == 'mastercard'
                              ? Icons.credit_card
                              : Icons.credit_card,
                      color: theme.primaryColor,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: FormValidators.validateCreditCard,
          ),
          const SizedBox(height: 16),
          
          // Card Holder Name
          TextFormField(
            controller: _cardHolderController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.cardholderName,
              hintText: 'John Doe',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) => FormValidators.validateName(
              value,
              fieldName: 'Card holder name',
            ),
          ),
          const SizedBox(height: 16),
          
          // Expiry and CVV
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.expiryDate,
                    hintText: 'MM/YY',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: FormValidators.validateExpiryDate,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.cvv,
                    hintText: '123',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: FormValidators.validateCVV,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.email,
              hintText: 'john@example.com',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: FormValidators.validateEmail,
          ),
          const SizedBox(height: 16),
          
          // Billing Address
          TextFormField(
            controller: _billingAddressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.billingAddress,
              hintText: '123 Main St, City, State',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: FormValidators.validateAddress,
          ),
          const SizedBox(height: 16),
          
          // Postal Code
          TextFormField(
            controller: _postalCodeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.zipCode,
              hintText: '12345',
              prefixIcon: const Icon(Icons.local_post_office),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) => FormValidators.validatePostalCode(value),
          ),
          const SizedBox(height: 16),
          
          // Save Card Checkbox
          CheckboxListTile(
            value: _saveCard,
            onChanged: (value) {
              setState(() {
                _saveCard = value ?? false;
              });
            },
            title: const Text('Save card for future payments'),
            subtitle: const Text('Card details will be securely stored'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPayPalOption(ThemeData theme, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Image.asset(
              'assets/images/paypal_logo.png',
              height: 60,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.payment,
                size: 60,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You will be redirected to PayPal to complete your payment',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'PayPal balance, credit cards, and bank accounts accepted',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBankTransferOption(ThemeData theme, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Transfer Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBankDetail('Bank Name', 'Example Bank'),
            _buildBankDetail('Account Name', 'Rentally Inc.'),
            _buildBankDetail('Account Number', '1234567890'),
            _buildBankDetail('Routing Number', '987654321'),
            _buildBankDetail('Swift Code', 'EXBKUS33'),
            _buildBankDetail('Reference', widget.bookingId),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please allow 2-3 business days for payment processing',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBankDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTermsAndConditions(ThemeData theme) {
    return CheckboxListTile(
      value: _agreeToTerms,
      onChanged: (value) {
        setState(() {
          _agreeToTerms = value ?? false;
        });
      },
      title: Text(AppLocalizations.of(context)!.agreeTerms),
      subtitle: InkWell(
        onTap: () {
          // Show terms and conditions
        },
        child: Text(
          AppLocalizations.of(context)!.termsOfService,
          style: TextStyle(
            color: theme.primaryColor,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  Widget _buildPayButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '${AppLocalizations.of(context)!.payNow} • ${CurrencyFormatter.formatPrice(widget.amount)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  Widget _buildSecurityBadges(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          'Secured by 256-bit SSL encryption',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSuccessDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.paymentCompleted,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.bookingConfirmed,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/booking-history');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.viewBooking),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
