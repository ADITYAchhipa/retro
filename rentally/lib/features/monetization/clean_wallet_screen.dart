import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/responsive_layout.dart';
import '../../widgets/error_boundary.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';
import '../../core/widgets/tab_back_handler.dart';

/// **CleanWalletScreen**
/// 
/// Clean wallet and rewards management screen
/// 
/// **Features:**
/// - Responsive design for all screen sizes
/// - Error boundaries with crash protection
/// - Wallet balance and transaction history
/// - Rewards and cashback tracking
/// - Payment method management
class CleanWalletScreen extends StatefulWidget {
  const CleanWalletScreen({super.key});

  @override
  State<CleanWalletScreen> createState() => _CleanWalletScreenState();
}

class _CleanWalletScreenState extends State<CleanWalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  
  bool _isLoading = false;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  
  // Mock wallet data
  final Map<String, dynamic> _walletData = {
    'balance': 1250.75,
    'pendingRewards': 85.50,
    'totalEarned': 3420.25,
    'transactions': [
      {
        'id': '1',
        'type': 'earning',
        'amount': 150.0,
        'description': 'Booking commission',
        'date': '2024-01-15',
        'status': 'completed',
      },
      {
        'id': '2',
        'type': 'withdrawal',
        'amount': -75.0,
        'description': 'Bank transfer',
        'date': '2024-01-14',
        'status': 'completed',
      },
      {
        'id': '3',
        'type': 'reward',
        'amount': 25.0,
        'description': 'Referral bonus',
        'date': '2024-01-13',
        'status': 'pending',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _loadWalletData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
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
          SnackBar(content: Text('Error loading wallet: $error')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadWalletData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ErrorBoundary(
      onError: (details) {
        debugPrint('Wallet screen error: ${details.exception}');
      },
      child: ResponsiveLayout(
        child: TabBackHandler(
          tabController: _tabController,
          child: Scaffold(
          backgroundColor: isDark ? EnterpriseDarkTheme.primaryBackground : EnterpriseLightTheme.primaryBackground,
          appBar: _buildAppBar(theme),
          body: _buildBody(theme, isDark),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('Wallet & Rewards'),
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: const Icon(Icons.notifications),
          tooltip: 'Notifications',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.account_balance_wallet)),
          Tab(text: 'Transactions', icon: Icon(Icons.history)),
          Tab(text: 'Rewards', icon: Icon(Icons.card_giftcard)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _onRefresh,
      child: TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.down,
        physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
        children: [
          _buildOverviewTab(theme, isDark),
          _buildTransactionsTab(theme, isDark),
          _buildRewardsTab(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(theme, isDark),
          const SizedBox(height: 24),
          _buildQuickActions(theme, isDark),
          const SizedBox(height: 24),
          _buildRecentTransactions(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme, bool isDark) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              theme.primaryColor,
              theme.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Balance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${_walletData['balance'].toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending Rewards',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '\$${_walletData['pendingRewards'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Earned',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '\$${_walletData['totalEarned'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Add Money',
                    Icons.add,
                    () => _showAddMoneyDialog(context),
                    theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Withdraw',
                    Icons.money,
                    () => _showWithdrawDialog(context),
                    theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onPressed, ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildRecentTransactions(ThemeData theme, bool isDark) {
    final recentTransactions = (_walletData['transactions'] as List).take(3).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recentTransactions.map((transaction) => 
              _buildTransactionItem(transaction, theme, isDark)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Transactions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...(_walletData['transactions'] as List).map((transaction) => 
                    _buildTransactionItem(transaction, theme, isDark)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction, ThemeData theme, bool isDark) {
    final isPositive = transaction['amount'] > 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            child: Icon(
              isPositive ? Icons.add : Icons.remove,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'],
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  transaction['date'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}\$${transaction['amount'].abs().toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: transaction['status'] == 'completed' ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaction['status'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rewards Program',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Pending Rewards: \$${_walletData['pendingRewards'].toStringAsFixed(2)}'),
                  Text('Total Earned: \$${_walletData['totalEarned'].toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/referral'),
                    child: const Text('Refer Friends & Earn'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Money'),
        content: const Text('Add money functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Money'),
        content: const Text('Withdraw functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}
