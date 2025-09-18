import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/referral_service.dart';
import '../../core/constants/app_constants.dart';
import '../../services/error_handling_service.dart';
import '../../core/widgets/tab_back_handler.dart';

class ReferralDashboardScreen extends ConsumerStatefulWidget {
  const ReferralDashboardScreen({super.key});

  @override
  ConsumerState<ReferralDashboardScreen> createState() => _ReferralDashboardScreenState();
}

class _ReferralDashboardScreenState extends ConsumerState<ReferralDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _redeemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();
    _redeemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final referralStats = ref.watch(referralServiceProvider);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return TabBackHandler(
      tabController: _tabController,
      child: Scaffold(
      appBar: AppBar(
        title: Text(t.referralAndEarn),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.onPrimary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
          labelStyle: TextStyle(fontSize: isPhone ? 12 : 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: isPhone ? 12 : 14),
          tabs: [
            Tab(text: t.dashboard),
            Tab(text: t.rewards),
            Tab(text: t.history),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.down,
        physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
        children: [
          _buildDashboardTab(theme, t, referralStats),
          _buildRewardsTab(theme, t, referralStats),
          _buildHistoryTab(theme, t, referralStats),
        ],
      ),
      ),
    );
  }

  Widget _buildDashboardTab(ThemeData theme, AppLocalizations t, UserReferralStats stats) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: t.totalTokens,
                  value: stats.totalTokens.toString(),
                  icon: Icons.stars,
                  color: Colors.amber,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: t.totalReferrals,
                  value: stats.totalReferrals.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                  theme: theme,
                ),
              ),
            ],
          ),
          SizedBox(height: isPhone ? 12 : 24),

          // Referral Code Section
          _buildReferralCodeSection(theme, t, stats),
          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(theme, t),
          const SizedBox(height: 24),

          // Referral Level & Boost
          _buildReferralLevelCard(theme),
          const SizedBox(height: 24),

          // Earnings Trend (last 6 months)
          _buildEarningsChart(theme, t),
          const SizedBox(height: 24),

          // How it works
          _buildHowItWorks(theme),
          const SizedBox(height: 24),

          // Leaderboard (mock)
          _buildLeaderboard(theme),
          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(theme, t, stats),
        ],
      ),
    );
  }

  Widget _buildRewardsTab(ThemeData theme, AppLocalizations t, UserReferralStats stats) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Token Balance
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isPhone ? 16 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: isPhone ? 36 : 48,
                  color: theme.colorScheme.onPrimary,
                ),
                SizedBox(height: isPhone ? 8 : 12),
                Text(
                  '${stats.totalTokens} Tokens',
                  style: (isPhone ? theme.textTheme.titleLarge : theme.textTheme.headlineMedium)?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  t.availableBalance,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isPhone ? 10 : 16),
          // Used vs Available summary
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isPhone ? 10 : 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Used Tokens', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${ref.read(referralServiceProvider.notifier).getUsedTokens()}',
                          style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isPhone ? 10 : 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${stats.totalTokens}',
                          style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isPhone ? 16 : 24),

          // Reward Structure
          Text(
            t.earnTokensFor,
            style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isPhone ? 10 : 16),
          
          ..._buildRewardItems(theme, t),
          SizedBox(height: isPhone ? 16 : 24),

          // Redeem Tokens
          _buildRedeemSection(theme, t, stats),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme, AppLocalizations t, UserReferralStats stats) {
    final transactions = stats.transactions;

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              t.noTransactionsYet,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.startReferringToSeeHistory,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return ListView.builder(
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionItem(theme, t, transaction);
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: isPhone ? 24 : 32),
          SizedBox(height: isPhone ? 8 : 12),
          Text(
            value,
            style: (isPhone ? theme.textTheme.titleLarge : theme.textTheme.headlineMedium)?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: (isPhone ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection(ThemeData theme, AppLocalizations t, UserReferralStats stats) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.yourReferralCode,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(height: isPhone ? 8 : 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isPhone ? 10 : 16, vertical: isPhone ? 8 : 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    stats.referralCode,
                    style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _copyReferralCode(stats.referralCode),
                  icon: const Icon(Icons.copy),
                  tooltip: t.copyCode,
                ),
                SizedBox(width: isPhone ? 2 : 4),
                IconButton(
                  onPressed: _shareReferralCode,
                  icon: const Icon(Icons.share),
                  tooltip: t.shareCode,
                ),
              ],
            ),
          ),
          SizedBox(height: isPhone ? 8 : 12),
          // Deep link + QR actions
          Builder(
            builder: (_) {
              final link = '${AppConstants.referralBaseUrl}/${stats.referralCode}';
              return Container(
                padding: EdgeInsets.all(isPhone ? 8 : 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your referral link', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text(link, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _copyText(link, 'Link copied'),
                      icon: const Icon(Icons.link),
                      label: const Text('Copy link'),
                    ),
                    SizedBox(width: isPhone ? 4 : 6),
                    OutlinedButton.icon(
                      onPressed: () => _showQrDialog(link),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('QR'),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: isPhone ? 4 : 8),
          Text(
            t.shareCodeToEarnTokens,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(ThemeData theme, AppLocalizations t, ReferralTransaction transaction, {bool isCompact = false}) {
    final isEarning = transaction.tokensEarned > 0;
    
    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 4 : 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isEarning 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isEarning ? Icons.add : Icons.remove,
              color: isEarning ? Colors.green : Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(transaction.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${isEarning ? '+' : ''}${transaction.tokensEarned}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isEarning ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(ReferralRewardType type) {
    switch (type) {
      case ReferralRewardType.signup:
        return Icons.person_add;
      case ReferralRewardType.firstBooking:
        return Icons.book_online;
      case ReferralRewardType.hostRegistration:
        return Icons.home;
      case ReferralRewardType.propertyListing:
        return Icons.add_home;
      case ReferralRewardType.review:
        return Icons.star;
    }
  }

  // Compact quick actions
  Widget _buildQuickActions(ThemeData theme, AppLocalizations t) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.quickActions,
          style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isPhone ? 10 : 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: t.shareCode,
                icon: Icons.share,
                color: Colors.green,
                onTap: _shareReferralCode,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: t.inviteFriends,
                icon: Icons.person_add,
                color: Colors.blue,
                onTap: _inviteFriends,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'Copy Link',
                icon: Icons.link,
                color: Colors.purple,
                onTap: _copyReferralLink,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'WhatsApp',
                icon: Icons.chat,
                color: Colors.teal,
                onTap: _shareWhatsApp,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'Email',
                icon: Icons.email,
                color: Colors.deepOrange,
                onTap: _shareEmail,
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Referral Level card
  Widget _buildReferralLevelCard(ThemeData theme) {
    final level = ref.read(referralServiceProvider.notifier).getReferralLevel();
    final active = ref.read(referralServiceProvider.notifier).getActiveReferralCount(days: 30);
    String label;
    Color color;
    double boost;
    switch (level) {
      case ReferralLevel.elite:
        label = 'Elite'; color = Colors.purple; boost = 0.50; break;
      case ReferralLevel.gold:
        label = 'Gold'; color = Colors.amber; boost = 0.25; break;
      case ReferralLevel.silver:
        label = 'Silver'; color = Colors.blueGrey; boost = 0.10; break;
      case ReferralLevel.bronze:
      default:
        label = 'Bronze'; color = Colors.brown; boost = 0.0; break;
    }
    int nextTarget;
    switch (level) {
      case ReferralLevel.elite:
        nextTarget = 0; break;
      case ReferralLevel.gold:
        nextTarget = 10; break;
      case ReferralLevel.silver:
        nextTarget = 6; break;
      case ReferralLevel.bronze:
        nextTarget = 3; break;
    }
    final toNext = nextTarget > 0 ? (nextTarget - active).clamp(0, 1 << 31) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: color, size: 18),
                const SizedBox(width: 6),
                Text('Level: $label', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active referrals (30d): $active', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text('Reward boost: +${(boost * 100).round()}%', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                if (toNext > 0)
                  Text('To next level: $toNext more in 30 days', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: isPhone ? 24 : 32),
            SizedBox(height: isPhone ? 6 : 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: isPhone ? 12 : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Compact earnings chart
  Widget _buildEarningsChart(ThemeData theme, AppLocalizations t) {
    final earningsMap = ref.read(referralServiceProvider.notifier).getMonthlyEarnings();
    final entries = earningsMap.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    final last6 = entries.take(6).toList().reversed.toList();
    if (last6.isEmpty) return const SizedBox.shrink();
    final maxValue = (last6.map((e) => e.value).fold<int>(0, (m, v) => v > m ? v : m)).clamp(1, 1 << 31);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(t.rewards, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('Last 6 months', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          SizedBox(height: isPhone ? 8 : 12),
          ...last6.map((e) {
            final monthLabel = _formatMonthLabel(e.key);
            final ratio = (e.value / maxValue).clamp(0.0, 1.0);
            return Padding(
              padding: EdgeInsets.symmetric(vertical: isPhone ? 4 : 6),
              child: Row(
                children: [
                  SizedBox(
                    width: isPhone ? 44 : 52,
                    child: Text(monthLabel, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  SizedBox(width: isPhone ? 6 : 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: isPhone ? 8 : 12,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: ratio > 0 ? ratio : 0.02,
                          child: Container(
                            height: isPhone ? 8 : 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [theme.colorScheme.primary.withOpacity(0.9), theme.colorScheme.secondary.withOpacity(0.9)]),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isPhone ? 6 : 8),
                  SizedBox(
                    width: isPhone ? 48 : 56,
                    child: Text('+${e.value}', textAlign: TextAlign.right, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // How it works section
  Widget _buildHowItWorks(ThemeData theme) {
    Widget step(IconData icon, String title, String desc, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 10),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('How it works', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            step(Icons.person_add_alt, 'Invite friends', 'Share your link or code with friends and family.', Colors.indigo),
            const SizedBox(width: 12),
            step(Icons.how_to_reg, 'They sign up', 'They create an account using your referral.', Colors.green),
            const SizedBox(width: 12),
            step(Icons.stars, 'Earn tokens', 'Earn rewards for each successful action.', Colors.amber),
          ],
        ),
      ],
    );
  }

  // Leaderboard
  Widget _buildLeaderboard(ThemeData theme) {
    final mock = [
      {'name': 'Sarah J.', 'tokens': 540},
      {'name': 'Mike C.', 'tokens': 420},
      {'name': 'Emma W.', 'tokens': 310},
      {'name': 'David B.', 'tokens': 260},
      {'name': 'Lisa G.', 'tokens': 180},
    ];
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Top referrers (demo)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: isPhone ? 8 : 12),
          ...mock.asMap().entries.map((e) {
            final idx = e.key + 1;
            final item = e.value;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: isPhone ? 4 : 6),
              child: Row(
                children: [
                  Container(
                    width: isPhone ? 24 : 28,
                    height: isPhone ? 24 : 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.12), shape: BoxShape.circle),
                    child: Text('$idx', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item['name'] as String, style: theme.textTheme.bodyMedium)),
                  Text('+${item['tokens']} tokens', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Recent activity
  Widget _buildRecentActivity(ThemeData theme, AppLocalizations t, UserReferralStats stats) {
    final recentTransactions = stats.transactions.take(3).toList();
    if (recentTransactions.isEmpty) return const SizedBox.shrink();

    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.recentActivity,
          style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: isPhone ? 10 : 16),
        ...recentTransactions.map((tx) => _buildTransactionItem(theme, t, tx, isCompact: true)),
      ],
    );
  }

  // Rewards list
  List<Widget> _buildRewardItems(ThemeData theme, AppLocalizations t) {
    final rewardItems = [
      {'type': ReferralRewardType.signup, 'title': t.userSignup, 'tokens': 50},
      {'type': ReferralRewardType.firstBooking, 'title': t.firstBooking, 'tokens': 100},
      {'type': ReferralRewardType.hostRegistration, 'title': t.hostRegistration, 'tokens': 200},
      {'type': ReferralRewardType.propertyListing, 'title': t.propertyListing, 'tokens': 150},
      {'type': ReferralRewardType.review, 'title': t.firstReview, 'tokens': 25},
    ];
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return rewardItems
        .map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(isPhone ? 12 : 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isPhone ? 6 : 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getRewardIcon(item['type'] as ReferralRewardType), color: theme.colorScheme.primary),
                  ),
                  SizedBox(width: isPhone ? 10 : 16),
                  Expanded(
                    child: Text(item['title'] as String, style: isPhone ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isPhone ? 10 : 12, vertical: isPhone ? 4 : 6),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Text(
                      '+${item['tokens']} tokens',
                      style: (isPhone ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  // Redeem section (compact)
  Widget _buildRedeemSection(ThemeData theme, AppLocalizations t, UserReferralStats stats) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.all(isPhone ? 14 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.redeemTokens, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: isPhone ? 10 : 16),
          TextField(
            controller: _redeemController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t.tokensToRedeem,
              hintText: '${t.available}: ${stats.totalTokens}',
              border: const OutlineInputBorder(),
              suffixText: 'tokens',
            ),
          ),
          SizedBox(height: isPhone ? 10 : 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: stats.totalTokens > 0 ? _redeemTokens : null,
              child: Text(t.redeemNow, style: TextStyle(fontSize: isPhone ? 13 : null, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // QR dialog
  void _showQrDialog(String link) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Referral QR'),
          content: SizedBox(
            width: 260,
            height: 260,
            child: Center(
              child: QrImageView(
                data: link,
                version: QrVersions.auto,
                size: 220.0,
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  void _copyText(String text, String successMsg) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg)));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatMonthLabel(String key) {
    // key is 'YYYY-MM'
    try {
      final parts = key.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[m - 1]}\n${y.toString().substring(2)}';
    } catch (_) {
      return key;
    }
  }

  void _copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      context.showSuccess('Referral code copied to clipboard!');
    }
  }

  void _shareReferralCode() {
    final stats = ref.read(referralServiceProvider);
    final link = '${AppConstants.referralBaseUrl}/${stats.referralCode}';
    try {
      Share.share('Join me on Rentally and earn rewards! Use my code: ${stats.referralCode}\n$link');
    } catch (_) {
      _copyText(link, 'Link copied');
      if (mounted) context.showInfo('Share sheet unavailable. Link copied to clipboard.');
    }
  }

  void _inviteFriends() {
    final stats = ref.read(referralServiceProvider);
    final link = '${AppConstants.referralBaseUrl}/${stats.referralCode}';
    try {
      Share.share('Join me on Rentally and earn rewards! Use my code: ${stats.referralCode}\n$link');
    } catch (_) {
      _copyText(link, 'Link copied');
      if (mounted) context.showInfo('Share sheet unavailable. Link copied to clipboard.');
    }
  }

  void _shareWhatsApp() async {
    final stats = ref.read(referralServiceProvider);
    final link = '${AppConstants.referralBaseUrl}/${stats.referralCode}';
    final text = 'Join me on Rentally and earn rewards! Use my code: ${stats.referralCode}\n$link';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _copyText(link, 'Link copied');
    }
  }

  void _shareEmail() async {
    final stats = ref.read(referralServiceProvider);
    final link = '${AppConstants.referralBaseUrl}/${stats.referralCode}';
    final subject = Uri.encodeComponent('Join me on Rentally and earn rewards');
    final body = Uri.encodeComponent('Use my referral code: ${stats.referralCode}\n$link');
    final uri = Uri.parse('mailto:?subject=$subject&body=$body');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _copyText(link, 'Link copied');
    }
  }

  void _copyReferralLink() {
    final stats = ref.read(referralServiceProvider);
    final link = '${AppConstants.referralBaseUrl}/${stats.referralCode}';
    _copyText(link, 'Link copied');
  }

  void _redeemTokens() async {
    final amount = int.tryParse(_redeemController.text);
    if (amount == null || amount <= 0) {
      context.showError('Please enter a valid token amount', type: ErrorType.validation);
      return;
    }

    final success = await ref.read(referralServiceProvider.notifier).redeemTokens(
      amount,
      'Discount redemption',
    );

    if (success) {
      _redeemController.clear();
      if (mounted) {
        context.showSuccess('Successfully redeemed $amount tokens!');
      }
    } else {
      if (mounted) {
        context.showError('Insufficient tokens for redemption');
      }
    }
  }

}
