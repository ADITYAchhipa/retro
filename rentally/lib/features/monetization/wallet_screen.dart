import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/monetization_service.dart';
import '../../models/monetization_models.dart';
import '../../utils/snackbar_utils.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/tab_back_handler.dart';
import 'package:go_router/go_router.dart';
import '../../app/auth_router.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isWatchingAd = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final transactions = ref.watch(monetizationServiceProvider).transactions;

    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return TabBackHandler(
      tabController: _tabController,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Wallet & Rewards'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.onPrimary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.8),
          labelStyle: TextStyle(fontSize: isPhone ? 12 : 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: isPhone ? 12 : 14),
          tabs: const [
            Tab(text: 'Balance', icon: Icon(Icons.account_balance_wallet)),
            Tab(text: 'Earn', icon: Icon(Icons.star)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: wallet == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              dragStartBehavior: DragStartBehavior.down,
              physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
              children: [
                _buildBalanceTab(context, wallet, transactions),
                _buildEarnTab(context, wallet),
                _buildHistoryTab(context, transactions),
              ],
            ),
      ),
    );
  }

  Widget _buildBalanceTab(BuildContext context, UserWallet wallet, List<Transaction> transactions) {
    final theme = Theme.of(context);
    final recentTransactions = transactions.take(5).toList();

    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: MediaQuery.sizeOf(context).width < 600 ? 22 : 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Wallet Balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: MediaQuery.sizeOf(context).width < 600 ? 14 : 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.sizeOf(context).width < 600 ? 12 : 16),
                Text(
                  CurrencyFormatter.formatPrice(wallet.balance, currency: wallet.currency),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.sizeOf(context).width < 600 ? 26 : 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${wallet.currency} • Last updated ${_formatDate(wallet.lastUpdated)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Earned',
                  CurrencyFormatter.formatPrice(wallet.totalEarned, currency: wallet.currency),
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Spent',
                  CurrencyFormatter.formatPrice(wallet.totalSpent, currency: wallet.currency),
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: MediaQuery.sizeOf(context).width < 600 ? 10 : 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Add Money',
                          Icons.add,
                          Colors.blue,
                          () => _showAddMoneyDialog(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'Withdraw',
                          Icons.remove,
                          Colors.orange,
                          () => _showWithdrawDialog(context, wallet.balance),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Recent Transactions
          if (recentTransactions.isNotEmpty) ...[
            Text(
              'Recent Transactions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: recentTransactions.map((transaction) =>
                    _buildTransactionItem(transaction, isLast: transaction == recentTransactions.last)
                ).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: const Text('View All Transactions'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarnTab(BuildContext context, UserWallet wallet) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earn Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isPhone ? 14 : 20),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.star, color: Colors.orange, size: isPhone ? 36 : 48),
                SizedBox(height: isPhone ? 8 : 12),
                Text(
                  'Earn Rewards',
                  style: (isPhone ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.headlineSmall)?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete activities to earn credits for your wallet',
                  style: TextStyle(color: Colors.orange[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: isPhone ? 16 : 24),

          // Rewarded Ads
          _buildEarnCard(
            'Watch Ads',
            'Earn ₹50 credit for each ad you watch',
            Icons.play_circle_filled,
            Colors.green,
            'Watch Ad',
            _isWatchingAd,
            () => _watchRewardedAd(),
          ),

          const SizedBox(height: 16),

          // Daily Check-in
          _buildEarnCard(
            'Daily Check-in',
            'Get ₹25 credit for checking in daily',
            Icons.calendar_today,
            Colors.blue,
            'Check In',
            false,
            () => _dailyCheckIn(),
          ),

          const SizedBox(height: 16),

          // Referral Bonus
          _buildEarnCard(
            'Invite Friends',
            'Earn ₹100 for each friend who signs up',
            Icons.people,
            Colors.purple,
            'Invite',
            false,
            () => context.push(Routes.referrals),
          ),

          const SizedBox(height: 16),

          // Complete Profile
          _buildEarnCard(
            'Complete Profile',
            'Get ₹75 credit for completing your profile',
            Icons.person,
            Colors.teal,
            'Complete',
            false,
            () => context.push(Routes.profile),
          ),

          const SizedBox(height: 16),

          // Write Review
          _buildEarnCard(
            'Write Reviews',
            'Earn ₹30 credit for each property review',
            Icons.rate_review,
            Colors.indigo,
            'Review',
            false,
            () => _showReviewDialog(),
          ),

          SizedBox(height: isPhone ? 16 : 24),

          // Bonus Opportunities
          _buildBonusSection(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction history will appear here',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return ListView.builder(
      dragStartBehavior: DragStartBehavior.down,
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.only(bottom: isPhone ? 6 : 8),
          child: _buildTransactionItem(transactions[index]),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: isPhone ? 20 : 24),
            SizedBox(height: isPhone ? 6 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isPhone ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isPhone ? 2 : 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isPhone ? 11 : 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: isPhone ? 20 : 24),
            SizedBox(height: isPhone ? 6 : 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: isPhone ? 12 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnCard(
    String title,
    String description,
    IconData icon,
    Color color,
    String buttonText,
    bool isLoading,
    VoidCallback onTap,
  ) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isPhone ? 10 : 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: isPhone ? 20 : 24),
            ),
            SizedBox(width: isPhone ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isPhone ? 14 : 16,
                    ),
                  ),
                  SizedBox(height: isPhone ? 2 : 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isPhone ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusSection() {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Bonus Opportunities',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isPhone ? 14 : 16,
                    color: Colors.amber[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: isPhone ? 8 : 12),
            _buildBonusItem('Weekend Bonus: Double rewards on weekends'),
            _buildBonusItem('Monthly Challenge: Complete 10 activities for ₹500 bonus'),
            _buildBonusItem('Streak Bonus: 7-day streak earns ₹200 extra'),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusItem(String text) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isPhone ? 3 : 4),
      child: Row(
        children: [
          Icon(Icons.star, size: isPhone ? 14 : 16, color: Colors.amber[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.amber[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction, {bool isLast = false}) {
    final isCredit = transaction.type == TransactionType.reward || 
                     transaction.description.contains('earned') ||
                     transaction.description.contains('refund');
    
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isPhone ? 6 : 8),
            decoration: BoxDecoration(
              color: isCredit ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCredit ? Icons.add : Icons.remove,
              color: isCredit ? Colors.green : Colors.red,
              size: 16,
            ),
          ),
          SizedBox(width: isPhone ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: isPhone ? 1 : 2),
                Text(
                  _formatDate(transaction.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isPhone ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${CurrencyFormatter.formatPrice(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: isPhone ? 1.5 : 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(transaction.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: isPhone ? 9 : 10,
                    color: _getStatusColor(transaction.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.refunded:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAddMoneyDialog(BuildContext context) {
    final amounts = [100, 500, 1000, 2000, 5000];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Money to Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select amount to add:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: amounts.map((amount) => 
                ActionChip(
                  label: Text('₹$amount'),
                  onPressed: () {
                    Navigator.pop(context);
                    _addMoney(amount.toDouble());
                  },
                ),
              ).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, double availableBalance) {
    if (availableBalance < 100) {
      SnackBarUtils.showWarning(context, 'Minimum withdrawal amount is ₹100');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available balance: ₹${availableBalance.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            const Text('Withdrawal will be processed within 2-3 business days.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _withdrawMoney(availableBalance);
            },
            child: const Text('Withdraw All'),
          ),
        ],
      ),
    );
  }

  void _addMoney(double amount) async {
    await ref.read(walletProvider.notifier).addFunds(amount, 'Manual Add');
    if (mounted) {
      SnackBarUtils.showSuccess(context, '₹${amount.toStringAsFixed(0)} added to wallet');
    }
  }

  void _withdrawMoney(double amount) async {
    final success = await ref.read(walletProvider.notifier).deductFunds(amount, 'Withdrawal');
    if (mounted) {
      if (success) {
        SnackBarUtils.showSuccess(context, 'Withdrawal request submitted');
      } else {
        SnackBarUtils.showError(context, 'Withdrawal failed');
      }
    }
  }

  void _watchRewardedAd() async {
    setState(() => _isWatchingAd = true);
    
    // Simulate watching ad
    await Future.delayed(const Duration(seconds: 3));
    
    await ref.read(walletProvider.notifier).earnFromAd(50);
    
    if (mounted) {
      setState(() => _isWatchingAd = false);
      SnackBarUtils.showSuccess(context, '₹50 earned from watching ad!');
    }
  }

  void _dailyCheckIn() async {
    await ref.read(walletProvider.notifier).addFunds(25, 'Daily Check-in');
    if (mounted) {
      SnackBarUtils.showSuccess(context, '₹25 earned from daily check-in!');
    }
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Write a Review'),
        content: const Text('Complete a property review to earn ₹30 credit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(Routes.bookingHistory);
            },
            child: const Text('Go to Bookings'),
          ),
        ],
      ),
    );
  }
}
