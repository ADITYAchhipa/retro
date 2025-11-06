// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/monetization_service.dart';
import '../../models/monetization_models.dart';
import '../../core/utils/currency_formatter.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  final bool isHost;
  
  const SubscriptionPlansScreen({
    super.key,
    this.isHost = true,
  });

  @override
  ConsumerState<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> {
  SubscriptionDuration _selectedDuration = SubscriptionDuration.monthly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final monetization = ref.watch(monetizationServiceProvider);
    
    final plans = widget.isHost 
        ? monetization.subscriptionPlans.where((plan) => plan.id.startsWith('host_')).toList()
        : monetization.subscriptionPlans.where((plan) => plan.id.startsWith('seeker_')).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isHost ? 'Host Plans' : 'Premium Plans'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: monetization.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isPhone ? 16 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary.withOpacity(0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        widget.isHost ? Icons.business : Icons.star,
                        size: isPhone ? 34 : 48,
                        color: theme.colorScheme.onPrimary,
                      ),
                      SizedBox(height: isPhone ? 10 : 16),
                      Text(
                        widget.isHost 
                            ? 'Grow Your Hosting Business'
                            : 'Unlock Premium Features',
                        style: (isPhone ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall)?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isPhone ? 6 : 8),
                      Text(
                        widget.isHost
                            ? 'Choose the perfect plan to maximize your earnings and reach more guests'
                            : 'Get early access, advanced filters, and exclusive deals',
                        style: (isPhone ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.92),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Duration Toggle
                Padding(
                  padding: EdgeInsets.all(isPhone ? 12 : 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildDurationButton(
                            'Monthly',
                            SubscriptionDuration.monthly,
                          ),
                        ),
                        Expanded(
                          child: _buildDurationButton(
                            'Yearly (Save 17%)',
                            SubscriptionDuration.yearly,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Plans List (responsive)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      // Desktop: 3 columns, Tablet: 2, Mobile: list
                      if (width >= 1024) {
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: plans.length,
                          itemBuilder: (context, index) => _buildPlanCard(plans[index]),
                        );
                      } else if (width >= 720) {
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: plans.length,
                          itemBuilder: (context, index) => _buildPlanCard(plans[index]),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: plans.length,
                        itemBuilder: (context, index) => _buildPlanCard(plans[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDurationButton(String text, SubscriptionDuration duration) {
    final isSelected = _selectedDuration == duration;
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = duration),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isPhone ? 10 : 12, horizontal: isPhone ? 6 : 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                )]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: isPhone ? 12 : null,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final price = plan.getPrice(_selectedDuration);
    final monthlyEquivalent = _selectedDuration == SubscriptionDuration.yearly
        ? price / 12
        : price;
    final annualIfMonthly = plan.monthlyPrice * 12;
    final yearlySavings = ((annualIfMonthly - plan.yearlyPrice).clamp(0, double.infinity)) as double;
    final yearlySavingsPct = annualIfMonthly > 0 ? ((yearlySavings / annualIfMonthly) * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: plan.isPopular ? (isPhone ? 6 : 8) : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: plan.isPopular
              ? BorderSide(color: theme.primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Stack(
          children: [
            // Popular Badge
            if (plan.isPopular)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: isPhone ? 6 : 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.recommend, size: isPhone ? 14 : 16, color: theme.colorScheme.onPrimary),
                      const SizedBox(width: 6),
                      Text(
                        'Most Popular',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          fontSize: isPhone ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            Padding(
              padding: EdgeInsets.all(plan.isPopular ? (isPhone ? 18 : 24) : (isPhone ? 14 : 20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plan.isPopular) SizedBox(height: isPhone ? 10 : 16),
                  
                  // Plan Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall)?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plan.description,
                              style: (isPhone ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.formatPrice(price, currency: plan.currency),
                            style: (isPhone ? theme.textTheme.titleLarge : theme.textTheme.headlineMedium)?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            _selectedDuration == SubscriptionDuration.yearly
                                ? '/year (${CurrencyFormatter.formatPrice(monthlyEquivalent, currency: plan.currency)}/month)'
                                : '/month',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_selectedDuration == SubscriptionDuration.yearly && yearlySavings > 0)
                            Padding(
                              padding: EdgeInsets.only(top: isPhone ? 4 : 6),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: isPhone ? 6 : 8, vertical: isPhone ? 3 : 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.green.withOpacity(0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.savings, size: isPhone ? 12 : 14, color: Colors.green),
                                    SizedBox(width: isPhone ? 4 : 6),
                                    Text(
                                      'Save ${CurrencyFormatter.formatPrice(yearlySavings, currency: plan.currency)} ($yearlySavingsPct%)',
                                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: isPhone ? 11 : 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isPhone ? 14 : 20),
                  
                  // Features List
                  ...plan.features.map((feature) => Padding(
                    padding: EdgeInsets.symmetric(vertical: isPhone ? 3 : 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: isPhone ? 16 : 20,
                        ),
                        SizedBox(width: isPhone ? 8 : 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: isPhone ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                  SizedBox(height: isPhone ? 16 : 24),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _selectPlan(plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, isPhone ? 42 : 48),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      child: const Text(
                        'Select Plan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  // Current Plan Indicator
                  if (_isCurrentPlan(plan))
                    Padding(
                      padding: EdgeInsets.only(top: isPhone ? 8 : 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: isPhone ? 14 : 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Current Plan',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

  Widget _buildTrustSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Secure Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTrustBadge(Icons.credit_card, 'Stripe Secured'),
              _buildTrustBadge(Icons.lock, '256-bit SSL'),
              _buildTrustBadge(Icons.cancel, 'Cancel Anytime'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your payment information is encrypted and secure. Cancel or change your plan anytime.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 16),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }


  bool _isCurrentPlan(SubscriptionPlan plan) {
    final currentSubscription = ref.read(monetizationServiceProvider).currentSubscription;
    return currentSubscription != null && 
           currentSubscription.plan.id == plan.id && 
           currentSubscription.isValid;
  }

  void _selectPlan(SubscriptionPlan plan) async {
    // Don't allow selecting current plan
    if (_isCurrentPlan(plan)) return;
    
    // Show confirmation dialog
    final confirmed = await _showPurchaseConfirmation(plan);
    if (!confirmed) return;
    
    // setState(() => _isProcessing = true);
    
    try {
      final success = await ref
          .read(monetizationServiceProvider.notifier)
          .purchaseSubscription(plan, _selectedDuration);
      
      if (success && mounted) {
        _showSuccessDialog(plan);
      } else if (mounted) {
        _showErrorDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog();
      }
    } finally {
      if (mounted) {
        // setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool> _showPurchaseConfirmation(SubscriptionPlan plan) async {
    final price = plan.getPrice(_selectedDuration);
    
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        final promoController = TextEditingController();
        double discountedPrice = price;
        String? promoMsg;
        return StatefulBuilder(
          builder: (context, setState) {
            void applyPromo() {
              final code = promoController.text.trim().toUpperCase();
              int pct = 0;
              if (code == 'SAVE10') pct = 10;
              if (code == 'SAVE20') pct = 20;
              if (pct > 0) {
                setState(() {
                  discountedPrice = price * (1 - pct / 100);
                  promoMsg = 'Applied $pct% off';
                });
              } else {
                setState(() {
                  discountedPrice = price;
                  promoMsg = 'Invalid code';
                });
              }
            }

            return AlertDialog(
              title: const Text('Confirm Subscription'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plan: ${plan.name}'),
                  Text('Duration: ${_selectedDuration.name}'),
                  const SizedBox(height: 8),
                  Text('Price: ${CurrencyFormatter.formatPrice(price, currency: plan.currency)}'),
                  if (discountedPrice != price)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Discounted: ${CurrencyFormatter.formatPrice(discountedPrice, currency: plan.currency)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.green),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: promoController,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Promo code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: applyPromo,
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  if (promoMsg != null) ...[
                    const SizedBox(height: 6),
                    Text(promoMsg!, style: TextStyle(color: promoMsg!.startsWith('Applied') ? Colors.green : Colors.red)),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'You will be charged ${CurrencyFormatter.formatPrice(discountedPrice, currency: plan.currency)} ${_selectedDuration == SubscriptionDuration.monthly ? 'monthly' : 'yearly'}.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    ) ?? false;
  }

  Widget _buildComparisonSection(List<SubscriptionPlan> plans) {
    final theme = Theme.of(context);
    if (plans.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Compare plans', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: plans.map((p) {
                final planPrice = CurrencyFormatter.formatPrice(p.getPrice(_selectedDuration), currency: p.currency);
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          if (p.isPopular)
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(planPrice, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 14),
                          const SizedBox(width: 6),
                          Text('${p.features.length} features', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(SubscriptionPlan plan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success!'),
          ],
        ),
        content: Text('Welcome to ${plan.name}! Your subscription is now active.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: const Text('There was an issue processing your payment. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
