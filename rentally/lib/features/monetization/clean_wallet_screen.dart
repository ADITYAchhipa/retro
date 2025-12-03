import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/coupon_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/currency_formatter.dart' as core_currency;
import '../../services/user_preferences_service.dart';

import '../../widgets/error_boundary.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';
import '../../core/widgets/tab_back_handler.dart';
import '../../app/auth_router.dart';

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
  String _txFilter = 'all';
  double? _baseAvailableBalance;
  double _balanceOffset = 0.0;
  List<Map<String, dynamic>> _mergedTransactions = [];
  
  // Mock wallet data
  final Map<String, dynamic> _walletData = {
    'balance': 1250.75,
    'pendingRewards': 85.50,
    'totalEarned': 3420.25,
    'transactions': [
      {
        'id': '1',
        'type': 'earning',
        'amount': 100.0,
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

  Widget _buildEarningsSummary(ThemeData theme, bool isDark) {
    final txs = _mergedTransactions.isNotEmpty
        ? _mergedTransactions
        : List<Map<String, dynamic>>.from(_walletData['transactions'] as List);
    final now = DateTime.now();
    final isPhone = MediaQuery.of(context).size.width < 600;

    double totalAll = (_walletData['totalEarned'] is num)
        ? (_walletData['totalEarned'] as num).toDouble()
        : txs.where((t) => t['type'] == 'earning').fold<double>(0, (s, t) => s + (t['amount'] as num).toDouble());

    double thisMonth = 0;
    for (final t in txs.where((t) => t['type'] == 'earning')) {
      final d = DateTime.tryParse((t['date'] ?? '').toString());
      if (d != null && d.year == now.year && d.month == now.month) {
        thisMonth += (t['amount'] as num).toDouble();
      }
    }

    double payouts = 0;
    for (final t in txs.where((t) => t['type'] == 'withdrawal')) {
      payouts += (t['amount'] as num).abs().toDouble();
    }

    Widget pill(String label, String value, IconData icon, Color base) {
      final bg = isDark ? base.withValues(alpha: 0.18) : base.withValues(alpha: 0.12);
      final border = base.withValues(alpha: 0.35);
      return Container(
        padding: EdgeInsets.symmetric(vertical: isPhone ? 8 : 10, horizontal: isPhone ? 10 : 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isPhone ? 14 : 16, color: base.withValues(alpha: 0.9)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: isPhone ? 13 : 14,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: isPhone ? 10 : 11,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        pill('Total Earned', '\$${totalAll.toStringAsFixed(2)}', Icons.trending_up_rounded, theme.colorScheme.primary),
        pill('This Month', '\$${thisMonth.toStringAsFixed(2)}', Icons.calendar_month_rounded, Colors.indigo),
        pill('Payouts', '\$${payouts.toStringAsFixed(2)}', Icons.payments_rounded, Colors.teal),
      ],
    );
  }

  Widget _buildAvailableCoupons(ThemeData theme, bool isDark) {
    return Consumer(
      builder: (context, ref, _) {
        final now = DateTime.now();
        final coupons = ref.watch(couponServiceProvider)
            .where((c) => c.isValidNow(now))
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Coupons',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (coupons.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200, width: 1),
                  boxShadow: _homeStyleShadows(theme, isDark),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.card_giftcard_rounded,
                        size: 48,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No coupons available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              for (int i = 0; i < coupons.length; i++)
                _buildCouponItem(
                  context,
                  coupons[i].title,
                  coupons[i].code,
                  theme,
                  isDark,
                  description: coupons[i].description,
                  validUntil: coupons[i].validUntil,
                  isLast: i == coupons.length - 1,
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCouponItem(
    BuildContext context,
    String title,
    String code,
    ThemeData theme,
    bool isDark, {
    String? description,
    DateTime? validUntil,
    bool isLast = false,
  }) {
    final int? daysLeft = (validUntil?.difference(DateTime.now()))?.inDays;
    final String? expiryText = daysLeft != null
        ? (() {
            final int left = daysLeft <= 0 ? 0 : daysLeft;
            final String unit = left == 1 ? 'day' : 'days';
            return '$left $unit left';
          })()
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200, width: 1),
        boxShadow: _homeStyleShadows(theme, isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_offer_rounded, color: Colors.amber.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.confirmation_number_rounded, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied "$code"')),
                  );
                },
                icon: const Icon(Icons.content_copy_rounded, size: 18),
                label: const Text('Copy'),
              ),
            ],
          ),
          if (expiryText != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  expiryText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Consumer(
                  builder: (context, ref, _) => FilledButton.icon(
                    onPressed: () {
                      ref.read(selectedCouponCodeProvider.notifier).state = code;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Coupon "$code" applied!')),
                      );
                      context.go(Routes.search);
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Apply'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
      // Load persisted local adjustments
      final prefs = await SharedPreferences.getInstance();
      final offset = prefs.getDouble('wallet.balanceOffset') ?? 0.0;
      final extraJson = prefs.getString('wallet.extraTx');
      List<Map<String, dynamic>> extraTx = [];
      if (extraJson != null && extraJson.isNotEmpty) {
        try {
          final list = jsonDecode(extraJson) as List<dynamic>;
          extraTx = list.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            if (m['amount'] is num) m['amount'] = (m['amount'] as num).toDouble();
            return m;
          }).toList();
        } catch (_) {}
      }
      // Capture base available once
      _baseAvailableBalance ??= (_walletData['balance'] as num).toDouble();
      _balanceOffset = offset;
      // Merge transactions (persisted first, then base/mock)
      final baseTx = List<Map<String, dynamic>>.from(_walletData['transactions'] as List);
      _mergedTransactions = [...extraTx, ...baseTx];
      
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

  void _openWalletMethods(BuildContext context, String tab) {
    try {
      context.pushNamed('wallet-methods', queryParameters: {'tab': tab});
      return;
    } catch (_) {}
    try {
      context.push('${Routes.walletMethods}?tab=$tab');
      return;
    } catch (_) {}
    if (tab == 'add') {
      context.push(Routes.paymentMethods);
    } else {
      context.push(Routes.payoutMethods);
    }
  }

  // Home screen style neumorphic shadows
  List<BoxShadow> _homeStyleShadows(ThemeData theme, bool isDark) {
    return [
      BoxShadow(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        blurRadius: 10,
        offset: const Offset(-5, -5),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: (isDark
            ? EnterpriseDarkTheme.primaryAccent
            : EnterpriseLightTheme.primaryAccent)
            .withValues(alpha: isDark ? 0.18 : 0.12),
        blurRadius: 10,
        offset: const Offset(5, 5),
        spreadRadius: 0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ErrorBoundary(
      onError: (details) {
        debugPrint('Wallet screen error: ${details.exception}');
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final page = TabBackHandler(
            tabController: _tabController,
            child: Scaffold(
              backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
              appBar: _buildAppBar(theme, isDark),
              body: _buildBody(theme, isDark),
            ),
          );
          return page;
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      title: const Text('Wallet & Rewards'),
      elevation: 0,
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      foregroundColor: theme.colorScheme.onSurface,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: theme.colorScheme.primary,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.account_balance_wallet_outlined)),
          Tab(text: 'Transactions', icon: Icon(Icons.history_outlined)),
          Tab(text: 'Rewards', icon: Icon(Icons.card_giftcard_outlined)),
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

    final isPhone = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      controller: _scrollController,
      padding: EdgeInsets.all(isPhone ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(theme, isDark),
          SizedBox(height: isPhone ? 20 : 28),
          _buildQuickActions(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme, bool isDark) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    final available = (_baseAvailableBalance ?? (_walletData['balance'] as num).toDouble()) + _balanceOffset;
    final totalBalance = available + (_walletData['pendingRewards'] as num).toDouble();
    
    return Consumer(builder: (context, ref, _) {
      final currency = ref.watch(currentCurrencyProvider);
      final totalStr = core_currency.CurrencyFormatter.formatPrice(totalBalance, currency: currency);
      final availableStr = core_currency.CurrencyFormatter.formatPrice(available, currency: currency);
      final pendingStr = core_currency.CurrencyFormatter.formatPrice((_walletData['pendingRewards'] as num).toDouble(), currency: currency);
      return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 20 : 28,
        vertical: isPhone ? 20 : 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.9),
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: isPhone ? 28 : 32,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Total Balance Label
          Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: isPhone ? 13 : 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          
          // Total Balance Amount
          Text(
            totalStr,
            style: TextStyle(
              color: Colors.white,
              fontSize: isPhone ? 32 : 40,
              fontWeight: FontWeight.bold,
              height: 1.1,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 18),
          
          // Breakdown Cards
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildBalanceBreakdownItem(
                    title: 'Available',
                    value: availableStr,
                    icon: Icons.check_circle_rounded,
                    isPhone: isPhone,
                  ),
                ),
                Container(
                  width: 1.5,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildBalanceBreakdownItem(
                    title: 'Pending',
                    value: pendingStr,
                    icon: Icons.schedule_rounded,
                    isPhone: isPhone,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    });
  }
  
  Widget _buildBalanceBreakdownItem({
    required String title,
    required String value,
    required IconData icon,
    required bool isPhone,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.9),
          size: 18,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isPhone ? 16 : 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isPhone ? 10 : 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Add Money',
                icon: Icons.add_circle_rounded,
                color: Colors.green,
                onTap: () => _openWalletMethods(context, 'add'),
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'Withdraw',
                icon: Icons.arrow_circle_down_rounded,
                color: Colors.blue,
                onTap: () => _openWalletMethods(context, 'withdraw'),
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isPhone ? 14 : 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: isDark ? 0.15 : 0.1),
              color.withValues(alpha: isDark ? 0.08 : 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: isPhone ? 24 : 28),
            ),
            SizedBox(height: isPhone ? 8 : 10),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white : color.withValues(alpha: 0.9),
                fontWeight: FontWeight.bold,
                fontSize: isPhone ? 13 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    final txs = _mergedTransactions.isNotEmpty
        ? _mergedTransactions
        : List<Map<String, dynamic>>.from(_walletData['transactions'] as List);
    switch (_txFilter) {
      case 'earning':
        return txs.where((t) => t['type'] == 'earning').toList();
      case 'withdrawal':
      case 'payout':
        return txs.where((t) => t['type'] == 'withdrawal').toList();
      case 'reward':
        return txs.where((t) => t['type'] == 'reward').toList();
      case 'all':
      default:
        return txs;
    }
  }

  Widget _buildTransactionFilters(ThemeData theme, bool isDark) {
    final items = [
      {'key': 'all', 'label': 'All'},
      {'key': 'earning', 'label': 'Earnings'},
      {'key': 'withdrawal', 'label': 'Payouts'},
      {'key': 'reward', 'label': 'Rewards'},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((it) {
        final selected = _txFilter == it['key'];
        return ChoiceChip(
          label: Text(it['label'] as String),
          selected: selected,
          onSelected: (_) => setState(() => _txFilter = it['key'] as String),
          showCheckmark: false,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          backgroundColor: isDark ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  Widget _buildTransactionsTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final title = _txFilter == 'earning'
        ? 'Earnings'
        : (_txFilter == 'withdrawal' || _txFilter == 'payout')
            ? 'Payout History'
            : _txFilter == 'reward'
                ? 'Rewards'
                : 'All Transactions';

    final filtered = _getFilteredTransactions();

    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildTransactionFilters(theme, isDark),
          if (_txFilter == 'earning') ...[
            const SizedBox(height: 12),
            _buildEarningsSummary(theme, isDark),
          ],
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
              ),
              child: Text(
                'No transactions found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...filtered.map((transaction) => _buildTransactionItem(transaction, theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction, ThemeData theme, bool isDark) {
    final isPositive = transaction['amount'] > 0;
    final isCompleted = transaction['status'] == 'completed';
    final isWithdrawal = (transaction['type'] == 'withdrawal');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200, width: 1),
        boxShadow: _homeStyleShadows(theme, isDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPositive 
                    ? [Colors.green, Colors.green.shade600]
                    : [Colors.red, Colors.red.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 22,
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      transaction['date'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Consumer(builder: (context, ref, _) {
                final currency = ref.watch(currentCurrencyProvider);
                final amountStr = core_currency.CurrencyFormatter.formatPrice((transaction['amount'] as num).abs().toDouble(), currency: currency);
                return Text(
                  '${isPositive ? '+' : ''}$amountStr',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                );
              }),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? Colors.green.withValues(alpha: 0.12) 
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted 
                        ? Colors.green.withValues(alpha: 0.3) 
                        : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  transaction['status'],
                  style: TextStyle(
                    color: isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isWithdrawal && !isCompleted) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _completePendingWithdrawal(transaction),
                      child: const Text('Mark Completed'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _cancelPendingWithdrawal(transaction),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _completePendingWithdrawal(Map<String, dynamic> tx) async {
    if ((tx['status'] ?? '') != 'pending' || (tx['type'] ?? '') != 'withdrawal') return;
    try {
      await _updateExtraTxStatus(tx['id'] as String, 'completed');
      await _loadWalletData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal marked as completed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update withdrawal: $e')),
        );
      }
    }
  }

  Future<void> _cancelPendingWithdrawal(Map<String, dynamic> tx) async {
    if ((tx['status'] ?? '') != 'pending' || (tx['type'] ?? '') != 'withdrawal') return;
    try {
      final amount = ((tx['amount'] as num?) ?? 0).toDouble().abs();
      await _removeExtraTx(tx['id'] as String);
      await _changeBalanceOffset(amount); // return funds to available
      await _loadWalletData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal cancelled and funds returned.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel withdrawal: $e')),
        );
      }
    }
  }

  Future<void> _updateExtraTxStatus(String id, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'wallet.extraTx';
    final listJson = prefs.getString(key);
    if (listJson == null || listJson.isEmpty) return;
    final list = List<Map<String, dynamic>>.from((jsonDecode(listJson) as List).map((e) => Map<String, dynamic>.from(e as Map)));
    for (final m in list) {
      if (m['id'] == id) {
        m['status'] = newStatus;
        break;
      }
    }
    await prefs.setString(key, jsonEncode(list));
  }

  Future<void> _removeExtraTx(String id) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'wallet.extraTx';
    final listJson = prefs.getString(key);
    if (listJson == null || listJson.isEmpty) return;
    final list = List<Map<String, dynamic>>.from((jsonDecode(listJson) as List).map((e) => Map<String, dynamic>.from(e as Map)));
    list.removeWhere((m) => m['id'] == id);
    await prefs.setString(key, jsonEncode(list));
  }

  Future<void> _changeBalanceOffset(double delta) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'wallet.balanceOffset';
    final current = prefs.getDouble(key) ?? 0.0;
    await prefs.setDouble(key, current + delta);
  }

  Widget _buildRewardsTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isPhone = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Refer Friends Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/referral'),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.all(isPhone ? 16 : 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Refer Friends & Earn More',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isPhone ? 15 : 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Available Coupons
          _buildAvailableCoupons(theme, isDark),
        ],
      ),
    );
  }

  void showAddMoneyDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_circle_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Add Money',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter amount to add to your wallet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Amount Input
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark 
                      ? theme.colorScheme.surface 
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 16),
              // Quick amount buttons
              Wrap(
                spacing: 8,
                children: [
                  _buildQuickAmountChip('\$10', () => amountController.text = '10', theme),
                  _buildQuickAmountChip('\$25', () => amountController.text = '25', theme),
                  _buildQuickAmountChip('\$50', () => amountController.text = '50', theme),
                  _buildQuickAmountChip('\$100', () => amountController.text = '100', theme),
                ],
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // TODO: Implement add money logic
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Adding \$${amountController.text}...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(String label, VoidCallback onTap, ThemeData theme) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: theme.colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void showWithdrawDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_circle_down_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Withdraw Money',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Available Balance: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '\$${_walletData['balance'].toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Amount Input
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark 
                      ? theme.colorScheme.surface 
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  helperText: 'Minimum withdrawal: \$10',
                ),
              ),
              const SizedBox(height: 16),
              // Bank Account Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? theme.colorScheme.surface 
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank Account',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '****1234 (Primary)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Show bank account selection
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // TODO: Implement withdraw logic
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Withdrawing \$${amountController.text}...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Withdraw'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
