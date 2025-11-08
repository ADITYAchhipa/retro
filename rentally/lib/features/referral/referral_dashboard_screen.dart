import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/referral_service.dart';
import '../../core/constants/app_constants.dart';
import '../../services/error_handling_service.dart';
import '../../core/widgets/tab_back_handler.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';

class ReferralDashboardScreen extends ConsumerStatefulWidget {
  const ReferralDashboardScreen({super.key});

  @override
  ConsumerState<ReferralDashboardScreen> createState() => _ReferralDashboardScreenState();
}

class _ReferralDashboardScreenState extends ConsumerState<ReferralDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  // Home screen style neumorphic shadows
  List<BoxShadow> _homeStyleShadows(ThemeData theme, bool isDark) {
    return [
      BoxShadow(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        blurRadius: 10,
        offset: const Offset(-5, -5),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: (isDark
            ? EnterpriseDarkTheme.primaryAccent
            : EnterpriseLightTheme.primaryAccent)
            .withOpacity(isDark ? 0.18 : 0.12),
        blurRadius: 10,
        offset: const Offset(5, 5),
        spreadRadius: 0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final referralStats = ref.watch(referralServiceProvider);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    final isDark = theme.brightness == Brightness.dark;
    return TabBackHandler(
      tabController: _tabController,
      child: Scaffold(
      backgroundColor: isDark ? theme.colorScheme.background : Colors.white,
      appBar: AppBar(
        title: Text(t.referralAndEarn),
        elevation: 0,
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        foregroundColor: theme.colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          labelStyle: TextStyle(fontSize: isPhone ? 12 : 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: isPhone ? 12 : 14),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 3,
          splashBorderRadius: BorderRadius.circular(8),
          overlayColor: MaterialStateProperty.all(theme.colorScheme.primary.withOpacity(0.1)),
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
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: EdgeInsets.all(isPhone ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Stats Section with gradient background
          _buildHeroStatsCard(theme, t, stats, isPhone, isDark),
          SizedBox(height: isPhone ? 20 : 28),

          // Referral Code Section
          _buildReferralCodeSection(theme, t, stats),
          SizedBox(height: isPhone ? 20 : 28),

          // Quick Actions
          _buildQuickActions(theme, t),
          SizedBox(height: isPhone ? 20 : 28),

          // Referral Level & Boost
          _buildReferralLevelCard(theme),
          const SizedBox(height: 24),

          // Earnings Trend (last 6 months)
          _buildEarningsChart(theme, t),
          const SizedBox(height: 24),

          // How it works
          _buildHowItWorks(theme),
          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(theme, t, stats),
        ],
      ),
    );
  }

  Widget _buildRewardsTab(ThemeData theme, AppLocalizations t, UserReferralStats stats) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final isDark = theme.brightness == Brightness.dark;
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
              boxShadow: _homeStyleShadows(theme, isDark),
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

          // How to Use Tokens
          _buildTokenUsageGuide(theme, t),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme, AppLocalizations t, UserReferralStats stats) {
    final transactions = stats.transactions;

    if (transactions.isEmpty) {
      final isDark = theme.brightness == Brightness.dark;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t.noTransactionsYet,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.startReferringToSeeHistory,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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

  // Hero Stats Card - Combined stats with gradient
  Widget _buildHeroStatsCard(ThemeData theme, AppLocalizations t, UserReferralStats stats, bool isPhone, bool isDark) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.wallet_giftcard_rounded,
                  color: Colors.white,
                  size: isPhone ? 28 : 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Rewards',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isPhone ? 14 : 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Earn tokens by referring friends',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: isPhone ? 11 : 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isPhone ? 20 : 24),
          Row(
            children: [
              Expanded(
                child: _buildHeroStatItem(
                  title: t.totalTokens,
                  value: stats.totalTokens.toString(),
                  icon: Icons.stars_rounded,
                  iconColor: Colors.amber.shade300,
                  isPhone: isPhone,
                ),
              ),
              Container(
                width: 1,
                height: isPhone ? 60 : 70,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildHeroStatItem(
                  title: t.totalReferrals,
                  value: stats.totalReferrals.toString(),
                  icon: Icons.people_rounded,
                  iconColor: Colors.lightBlue.shade300,
                  isPhone: isPhone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatItem({
    required String title,
    required String value,
    required IconData icon,
    required bool isPhone,
    Color? iconColor,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isPhone ? 10 : 12),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.white).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: isPhone ? 24 : 28,
          ),
        ),
        SizedBox(height: isPhone ? 8 : 12),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isPhone ? 28 : 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: isPhone ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReferralCodeSection(ThemeData theme, AppLocalizations t, UserReferralStats stats) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(isPhone ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200, width: 1),
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
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.yourReferralCode,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Share with friends to earn rewards',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isPhone ? 16 : 20),
          Container(
            padding: EdgeInsets.all(isPhone ? 16 : 20),
            decoration: BoxDecoration(
              color: isDark 
                  ? theme.colorScheme.surface.withOpacity(0.5)
                  : theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CODE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary.withOpacity(0.7),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats.referralCode,
                        style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _copyReferralCode(stats.referralCode),
                    icon: const Icon(Icons.content_copy_rounded, color: Colors.white),
                    iconSize: 20,
                    tooltip: t.copyCode,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _shareReferralCode,
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    iconSize: 20,
                    tooltip: t.shareCode,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isPhone ? 12 : 16),
          // Deep link + QR actions
          Builder(
            builder: (_) {
              final link = '${AppConstants.referralBaseUrl}/${stats.referralCode}';
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyText(link, 'Link copied'),
                      icon: const Icon(Icons.link_rounded, size: 20),
                      label: const Text('Copy Link'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: isPhone ? 12 : 16, vertical: isPhone ? 10 : 12),
                        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showQrDialog(link),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                    label: const Text('QR'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: isPhone ? 12 : 16, vertical: isPhone ? 10 : 12),
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(ThemeData theme, AppLocalizations t, ReferralTransaction transaction, {bool isCompact = false}) {
    final isEarning = transaction.tokensEarned > 0;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 4 : 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200, width: 1),
        boxShadow: _homeStyleShadows(theme, isDark),
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
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    String label;
    Color color;
    double boost;
    IconData levelIcon;
    switch (level) {
      case ReferralLevel.elite:
        label = 'Elite'; color = Colors.purple; boost = 0.50; levelIcon = Icons.workspace_premium_rounded; break;
      case ReferralLevel.gold:
        label = 'Gold'; color = Colors.amber; boost = 0.25; levelIcon = Icons.military_tech_rounded; break;
      case ReferralLevel.silver:
        label = 'Silver'; color = Colors.blueGrey; boost = 0.10; levelIcon = Icons.shield_rounded; break;
      case ReferralLevel.bronze:
      default:
        label = 'Bronze'; color = Colors.brown; boost = 0.0; levelIcon = Icons.badge_rounded; break;
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
    final progress = nextTarget > 0 ? (active / nextTarget).clamp(0.0, 1.0) : 1.0;

    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(isPhone ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(levelIcon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            '+${(boost * 100).round()}% Boost',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$active active referrals (30 days)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (toNext > 0) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress to next level',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$toNext more needed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ],
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200, width: 1),
        boxShadow: _homeStyleShadows(theme, isDark),
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

  // How it works section - Compact horizontal design
  Widget _buildHowItWorks(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    
    return Container(
      padding: EdgeInsets.all(isPhone ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200, width: 1),
        boxShadow: _homeStyleShadows(theme, isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'How it Works',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Compact step items
          _buildCompactStep(
            theme,
            isDark,
            '1',
            Icons.share_rounded,
            'Share Your Code',
            'Send referral link to friends',
            Colors.indigo,
          ),
          const SizedBox(height: 12),
          _buildCompactStep(
            theme,
            isDark,
            '2',
            Icons.person_add_alt_1_rounded,
            'Friend Signs Up',
            'They create account using your link',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildCompactStep(
            theme,
            isDark,
            '3',
            Icons.stars_rounded,
            'Earn Rewards',
            'Get tokens for each successful referral',
            Colors.amber,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactStep(
    ThemeData theme,
    bool isDark,
    String stepNumber,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Row(
      children: [
        // Step number badge
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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

    final isDark = theme.brightness == Brightness.dark;
    return rewardItems
        .map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(isPhone ? 12 : 16),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200, width: 1),
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

  // Token Usage Guide - Modern design with gradient cards
  Widget _buildTokenUsageGuide(ThemeData theme, AppLocalizations t) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(isPhone ? 18 : 24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: _homeStyleShadows(theme, isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.redeem_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to Use Tokens',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Get instant discounts on bookings',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Modern step cards
          _buildModernStep(
            theme,
            isDark,
            Colors.blue,
            Icons.search_rounded,
            'Browse Properties',
            'Explore and find your perfect rental',
            isPhone,
          ),
          const SizedBox(height: 12),
          _buildModernStep(
            theme,
            isDark,
            Colors.green,
            Icons.check_circle_rounded,
            'Checkout Process',
            'Tokens auto-apply for maximum savings',
            isPhone,
          ),
          const SizedBox(height: 12),
          _buildModernStep(
            theme,
            isDark,
            Colors.orange,
            Icons.celebration_rounded,
            'Enjoy Discounts',
            'Save money on every booking!',
            isPhone,
          ),
          const SizedBox(height: 20),
          
          // Modern info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(isDark ? 0.15 : 0.1),
                  Colors.orange.withOpacity(isDark ? 0.1 : 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.amber.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tokens automatically apply at checkout for best value',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.amber.shade100 : Colors.amber.shade900,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernStep(
    ThemeData theme,
    bool isDark,
    Color accentColor,
    IconData icon,
    String title,
    String subtitle,
    bool isPhone,
  ) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 14 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(isDark ? 0.15 : 0.08),
            accentColor.withOpacity(isDark ? 0.08 : 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: accentColor.withOpacity(0.5),
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

}
