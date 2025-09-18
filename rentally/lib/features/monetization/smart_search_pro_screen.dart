import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/monetization_service.dart';
import '../../models/monetization_models.dart';

class SmartSearchProScreen extends ConsumerStatefulWidget {
  const SmartSearchProScreen({super.key});

  @override
  ConsumerState<SmartSearchProScreen> createState() => _SmartSearchProScreenState();
}

class _SmartSearchProScreenState extends ConsumerState<SmartSearchProScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monetization = ref.watch(monetizationServiceProvider);
    
    final seekerPlan = monetization.subscriptionPlans
        .where((plan) => plan.id == 'seeker_pro')
        .firstOrNull;

    if (seekerPlan == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasSubscription = ref.read(monetizationServiceProvider.notifier).hasActiveSubscription();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(
                            Icons.search,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Smart Search Pro',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Find your perfect rental faster with premium search features',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Features
                  _buildFeaturesSection(seekerPlan),
                  
                  const SizedBox(height: 32),
                  
                  // Pricing Card
                  _buildPricingCard(seekerPlan, hasSubscription),
                  
                  const SizedBox(height: 32),
                  
                  // Benefits Showcase
                  _buildBenefitsShowcase(),
                  
                  const SizedBox(height: 32),
                  
                  // Testimonials
                  _buildTestimonials(),
                  
                  const SizedBox(height: 32),
                  
                  // FAQ
                  _buildFAQ(),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Floating Action Button
      floatingActionButton: hasSubscription 
          ? null 
          : FloatingActionButton.extended(
              onPressed: _isProcessing ? null : () => _subscribeToPro(seekerPlan),
              icon: _isProcessing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.star),
              label: Text(_isProcessing ? 'Processing...' : 'Upgrade Now'),
            ),
    );
  }

  Widget _buildFeaturesSection(SubscriptionPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Features',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        ...plan.features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;
          final icons = [
            Icons.flash_on,
            Icons.filter_alt,
            Icons.chat_bubble,
            Icons.support_agent,
            Icons.money_off,
            Icons.local_offer,
            Icons.notifications_active,
          ];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icons[index % icons.length],
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPricingCard(SubscriptionPlan plan, bool hasSubscription) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (!hasSubscription) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LIMITED TIME OFFER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${plan.monthlyPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  '/month',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'or ₹${plan.yearlyPrice.toStringAsFixed(0)}/year (Save 17%)',
              style: TextStyle(
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (hasSubscription) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'You\'re a Pro Member!',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () => _subscribeToPro(plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Start Free Trial',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                '7-day free trial • Cancel anytime',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Choose Smart Search Pro?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildBenefitItem(
          'Save Time',
          'Find properties 3x faster with advanced filters and early access to new listings',
          Icons.access_time,
          Colors.blue,
        ),
        
        _buildBenefitItem(
          'Save Money',
          'Access exclusive deals and waived booking fees that pay for your subscription',
          Icons.savings,
          Colors.green,
        ),
        
        _buildBenefitItem(
          'Priority Support',
          'Get help when you need it with dedicated customer support',
          Icons.headset_mic,
          Colors.purple,
        ),
        
        _buildBenefitItem(
          'Better Matches',
          'Smart algorithms learn your preferences for more relevant results',
          Icons.psychology,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildBenefitItem(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What Our Pro Members Say',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTestimonialCard(
                'Amazing service! Found my perfect apartment in just 2 days.',
                'Priya S.',
                '⭐⭐⭐⭐⭐',
              ),
              _buildTestimonialCard(
                'The early access feature is a game-changer. Highly recommended!',
                'Rahul M.',
                '⭐⭐⭐⭐⭐',
              ),
              _buildTestimonialCard(
                'Saved me hundreds with exclusive deals. Worth every penny.',
                'Anjali K.',
                '⭐⭐⭐⭐⭐',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialCard(String review, String name, String rating) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Smart Search Pro Features'),
              const SizedBox(height: 16),
              Expanded(
                child: Text(
                  '"$review"',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '- $name',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQ() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildFAQItem(
          'Can I cancel anytime?',
          'Yes, you can cancel your subscription at any time. You\'ll continue to have access until the end of your billing period.',
        ),
        
        _buildFAQItem(
          'What happens after the free trial?',
          'After your 7-day free trial, you\'ll be charged the monthly fee. You can cancel before the trial ends to avoid charges.',
        ),
        
        _buildFAQItem(
          'Do I get refunds on booking fees?',
          'Yes, Pro members get booking fees waived on all reservations, which often covers the subscription cost.',
        ),
        
        _buildFAQItem(
          'How early do I get access to new listings?',
          'Pro members get access to new listings 24 hours before they\'re shown to regular users.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _subscribeToPro(SubscriptionPlan plan) async {
    setState(() => _isProcessing = true);
    
    try {
      final success = await ref
          .read(monetizationServiceProvider.notifier)
          .purchaseSubscription(plan, SubscriptionDuration.monthly);
      
      if (success && mounted) {
        _showSuccessDialog();
      } else if (mounted) {
        _showErrorDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.orange),
            SizedBox(width: 8),
            Text('Welcome to Pro!'),
          ],
        ),
        content: const Text(
          'You now have access to all premium features. Start exploring with Smart Search Pro!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Start Searching'),
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
            Text('Subscription Failed'),
          ],
        ),
        content: const Text('There was an issue processing your subscription. Please try again.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
