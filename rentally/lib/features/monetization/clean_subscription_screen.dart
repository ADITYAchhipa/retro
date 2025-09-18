import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/responsive_layout.dart';
import '../../widgets/error_boundary.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';

/// **CleanSubscriptionScreen**
/// 
/// Clean subscription plans management screen
/// 
/// **Features:**
/// - Responsive design for all screen sizes
/// - Error boundaries with crash protection
/// - Multiple subscription tiers
/// - Feature comparison
/// - Payment integration ready
class CleanSubscriptionScreen extends StatefulWidget {
  const CleanSubscriptionScreen({super.key});

  @override
  State<CleanSubscriptionScreen> createState() => _CleanSubscriptionScreenState();
}

class _CleanSubscriptionScreenState extends State<CleanSubscriptionScreen> {
  late ScrollController _scrollController;
  
  bool _isLoading = false;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  String? _currentPlanId = 'basic';
  
  // Mock subscription plans data
  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'basic',
      'name': 'Basic',
      'price': 0.0,
      'period': 'month',
      'features': [
        'List up to 2 properties',
        'Basic analytics',
        'Email support',
        'Standard visibility',
      ],
      'popular': false,
      'color': Colors.grey,
    },
    {
      'id': 'pro',
      'name': 'Professional',
      'price': 29.99,
      'period': 'month',
      'features': [
        'List up to 10 properties',
        'Advanced analytics',
        'Priority support',
        'Enhanced visibility',
        'Custom branding',
        'Performance insights',
      ],
      'popular': true,
      'color': Colors.blue,
    },
    {
      'id': 'enterprise',
      'name': 'Enterprise',
      'price': 99.99,
      'period': 'month',
      'features': [
        'Unlimited properties',
        'Premium analytics',
        '24/7 phone support',
        'Maximum visibility',
        'White-label solution',
        'API access',
        'Dedicated account manager',
        'Custom integrations',
      ],
      'popular': false,
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadSubscriptionPlans();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionPlans() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data is already loaded
      setState(() => _isLoading = false);
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plans: $error')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadSubscriptionPlans();
  }

  Future<void> _subscribeToPlan(String planId) async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _currentPlanId = planId;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully subscribed to plan!')),
        );
      }
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error subscribing: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ErrorBoundary(
      onError: (details) {
        debugPrint('Subscription screen error: ${details.exception}');
      },
      child: ResponsiveLayout(
        child: Scaffold(
          backgroundColor: isDark ? EnterpriseDarkTheme.primaryBackground : EnterpriseLightTheme.primaryBackground,
          appBar: _buildAppBar(theme),
          body: _buildBody(theme, isDark),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('Subscription Plans'),
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          onPressed: () => context.push('/help'),
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help',
        ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildPlansGrid(theme, isDark),
            const SizedBox(height: 24),
            _buildCurrentPlan(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the perfect plan for your rental business',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPlansGrid(ThemeData theme, bool isDark) {
    return Column(
      children: _plans.map((plan) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildPlanCard(plan, theme, isDark),
      )).toList(),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, ThemeData theme, bool isDark) {
    final isCurrentPlan = plan['id'] == _currentPlanId;
    final isPopular = plan['popular'] == true;
    
    return Card(
      elevation: isPopular ? 8 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isCurrentPlan 
            ? Border.all(color: theme.primaryColor, width: 2)
            : isPopular 
              ? Border.all(color: plan['color'], width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: plan['color'],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isPopular) const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['name'],
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: plan['color'],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            plan['price'] == 0.0 ? 'Free' : '\$${plan['price'].toStringAsFixed(2)}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (plan['price'] > 0.0)
                            Text(
                              '/${plan['period']}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (isCurrentPlan)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'CURRENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ...plan['features'].map<Widget>((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: plan['color'],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCurrentPlan ? null : () => _subscribeToPlan(plan['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentPlan ? Colors.grey : plan['color'],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isCurrentPlan ? 'Current Plan' : 'Subscribe Now',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPlan(ThemeData theme, bool isDark) {
    final currentPlan = _plans.firstWhere((plan) => plan['id'] == _currentPlanId);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Subscription',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: currentPlan['color'],
                ),
                const SizedBox(width: 8),
                Text(
                  '${currentPlan['name']} Plan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currentPlan['price'] == 0.0 
                ? 'Free forever'
                : 'Next billing: \$${currentPlan['price'].toStringAsFixed(2)} on ${DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0]}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showManageSubscriptionDialog(context),
                    child: const Text('Manage Subscription'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/billing-history'),
                    child: const Text('Billing History'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showManageSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Subscription'),
        content: const Text('Subscription management features will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
