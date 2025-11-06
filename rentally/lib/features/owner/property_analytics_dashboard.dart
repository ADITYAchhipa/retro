// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/tab_back_handler.dart';

class PropertyAnalytics {
  final String propertyId;
  final String propertyTitle;
  final double totalEarnings;
  final int totalBookings;
  final double averageRating;
  final int totalReviews;
  final double occupancyRate;
  final Map<String, double> monthlyEarnings;
  final Map<String, int> monthlyBookings;
  final List<String> topKeywords;
  final double averageDailyRate;
  final int viewsThisMonth;
  final int inquiriesThisMonth;
  final double conversionRate;

  const PropertyAnalytics({
    required this.propertyId,
    required this.propertyTitle,
    required this.totalEarnings,
    required this.totalBookings,
    required this.averageRating,
    required this.totalReviews,
    required this.occupancyRate,
    required this.monthlyEarnings,
    required this.monthlyBookings,
    required this.topKeywords,
    required this.averageDailyRate,
    required this.viewsThisMonth,
    required this.inquiriesThisMonth,
    required this.conversionRate,
  });
}

class AnalyticsService extends StateNotifier<List<PropertyAnalytics>> {
  AnalyticsService() : super(_mockAnalytics);

  static final List<PropertyAnalytics> _mockAnalytics = [
    const PropertyAnalytics(
      propertyId: '1',
      propertyTitle: 'Modern Downtown Apartment',
      totalEarnings: 12450.0,
      totalBookings: 28,
      averageRating: 4.7,
      totalReviews: 23,
      occupancyRate: 0.78,
      monthlyEarnings: {
        'Jan': 980.0,
        'Feb': 1120.0,
        'Mar': 1350.0,
        'Apr': 1280.0,
        'May': 1450.0,
        'Jun': 1680.0,
        'Jul': 1890.0,
        'Aug': 1750.0,
        'Sep': 1420.0,
        'Oct': 1230.0,
        'Nov': 1100.0,
        'Dec': 1200.0,
      },
      monthlyBookings: {
        'Jan': 2,
        'Feb': 3,
        'Mar': 3,
        'Apr': 2,
        'May': 3,
        'Jun': 4,
        'Jul': 4,
        'Aug': 3,
        'Sep': 2,
        'Oct': 2,
        'Nov': 1,
        'Dec': 2,
      },
      topKeywords: ['downtown', 'modern', 'clean', 'convenient', 'spacious'],
      averageDailyRate: 145.0,
      viewsThisMonth: 342,
      inquiriesThisMonth: 28,
      conversionRate: 0.32,
    ),
    const PropertyAnalytics(
      propertyId: '2',
      propertyTitle: 'Cozy Beach House',
      totalEarnings: 18750.0,
      totalBookings: 35,
      averageRating: 4.9,
      totalReviews: 31,
      occupancyRate: 0.85,
      monthlyEarnings: {
        'Jan': 1200.0,
        'Feb': 1350.0,
        'Mar': 1580.0,
        'Apr': 1750.0,
        'May': 2100.0,
        'Jun': 2350.0,
        'Jul': 2680.0,
        'Aug': 2450.0,
        'Sep': 1980.0,
        'Oct': 1650.0,
        'Nov': 1320.0,
        'Dec': 1340.0,
      },
      monthlyBookings: {
        'Jan': 2,
        'Feb': 2,
        'Mar': 3,
        'Apr': 3,
        'May': 4,
        'Jun': 4,
        'Jul': 5,
        'Aug': 4,
        'Sep': 3,
        'Oct': 3,
        'Nov': 2,
        'Dec': 2,
      },
      topKeywords: ['beach', 'ocean view', 'relaxing', 'family-friendly', 'sunset'],
      averageDailyRate: 185.0,
      viewsThisMonth: 456,
      inquiriesThisMonth: 42,
      conversionRate: 0.28,
    ),
  ];

  PropertyAnalytics? getAnalyticsForProperty(String propertyId) {
    try {
      return state.firstWhere((analytics) => analytics.propertyId == propertyId);
    } catch (e) {
      return null;
    }
  }

  double getTotalPortfolioEarnings() {
    return state.fold(0.0, (sum, analytics) => sum + analytics.totalEarnings);
  }

  int getTotalPortfolioBookings() {
    return state.fold(0, (sum, analytics) => sum + analytics.totalBookings);
  }

  double getAveragePortfolioRating() {
    if (state.isEmpty) return 0.0;
    final sum = state.fold(0.0, (sum, analytics) => sum + analytics.averageRating);
    return sum / state.length;
  }
}

final analyticsServiceProvider = StateNotifierProvider<AnalyticsService, List<PropertyAnalytics>>((ref) {
  return AnalyticsService();
});

class PropertyAnalyticsDashboard extends ConsumerStatefulWidget {
  final String? propertyId;

  const PropertyAnalyticsDashboard({
    super.key,
    this.propertyId,
  });

  @override
  ConsumerState<PropertyAnalyticsDashboard> createState() => _PropertyAnalyticsDashboardState();
}

class _PropertyAnalyticsDashboardState extends ConsumerState<PropertyAnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Year';
  String _selectedRange = '12M'; // 7D, 30D, 90D, 12M, All
  String _selectedGranularity = 'Monthly'; // future: Weekly
  String _selectedPropertyId = 'All';
  bool _compact = true;
  final bool _interactiveCharts = true;
  bool _compare = false;
  String? _comparePropertyId;
  
  final GlobalKey _keyMetricsKey = GlobalKey();
  final GlobalKey _revenueKey = GlobalKey();
  final GlobalKey _demandKey = GlobalKey();
  final GlobalKey _occupancyKey = GlobalKey();
  final GlobalKey _heatmapKey = GlobalKey();
  final GlobalKey _tableKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
      _selectedPropertyId = widget.propertyId!;
    }
    _loadAnalyticsPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsService = ref.watch(analyticsServiceProvider.notifier);
    final allAnalytics = ref.watch(analyticsServiceProvider);
    final theme = Theme.of(context);
    // final t = AppLocalizations.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    
    return TabBackHandler(
      tabController: _tabController,
      child: Scaffold(
        appBar: AppBar(
        title: Text(
          'Analytics',
          style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            height: 1.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: isPhone ? 40 : null,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white, size: isPhone ? 22 : 24),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Select period',
            icon: const Icon(Icons.calendar_view_month_outlined),
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'This Week', child: Text('This Week')),
              PopupMenuItem(value: 'This Month', child: Text('This Month')),
              PopupMenuItem(value: 'This Year', child: Text('This Year')),
              PopupMenuItem(value: 'All Time', child: Text('All Time')),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'export_csv') {
                await _exportAnalyticsCsv(allAnalytics);
              } else if (value == 'export_pdf') {
                final file = await _exportAnalyticsPdf(allAnalytics);
                if (file == null) return;
                try {
                  await Share.shareXFiles([XFile(file.path)], text: 'Property Analytics Report');
                } catch (_) {}
              } else if (value == 'share') {
                await _shareAnalyticsCsv(allAnalytics);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'export_csv', child: ListTile(leading: Icon(Icons.download_outlined), title: Text('Export CSV'))),
              PopupMenuItem(value: 'export_pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf_outlined), title: Text('Export PDF'))),
              PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share_outlined), title: Text('Share CSV'))),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelStyle: TextStyle(fontSize: isPhone ? 11 : 12, height: 1.0, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: isPhone ? 11 : 12, height: 1.0),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelPadding: EdgeInsets.zero,
          indicatorWeight: isPhone ? 2.0 : 4.0,
          tabs: [
            Tab(
              height: isPhone ? 38 : 44,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isPhone ? 22 : 24,
                    height: isPhone ? 22 : 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.28),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 1),
                    ),
                    child: Icon(Icons.dashboard, size: isPhone ? 14 : 16, color: Colors.amberAccent),
                  ),
                  const SizedBox(height: 2),
                  const Text('Overview', style: TextStyle(color: Colors.amberAccent)),
                ],
              ),
            ),
            Tab(
              height: isPhone ? 38 : 44,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isPhone ? 22 : 24,
                    height: isPhone ? 22 : 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.28),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 1),
                    ),
                    child: Icon(Icons.show_chart, size: isPhone ? 14 : 16, color: Colors.cyanAccent),
                  ),
                  const SizedBox(height: 2),
                  const Text('Performance', style: TextStyle(color: Colors.cyanAccent)),
                ],
              ),
            ),
            Tab(
              height: isPhone ? 38 : 44,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isPhone ? 22 : 24,
                    height: isPhone ? 22 : 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.28),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 1),
                    ),
                    child: Icon(Icons.lightbulb_outline, size: isPhone ? 14 : 16, color: Colors.orangeAccent),
                  ),
                  const SizedBox(height: 2),
                  const Text('Insights', style: TextStyle(color: Colors.orangeAccent)),
                ],
              ),
            ),
          ],
        ),
        ),
        body: TabBarView(
          controller: _tabController,
          dragStartBehavior: DragStartBehavior.down,
          physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
          children: [
            _buildOverviewTab(analyticsService, allAnalytics, theme),
            _buildPerformanceTabModern(analyticsService, allAnalytics, theme),
            _buildInsightsTab(analyticsService, allAnalytics, theme),
          ],
        ),
      ),
    );
    
  }

  Widget _buildOverviewTab(AnalyticsService service, List<PropertyAnalytics> analytics, ThemeData theme) {
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      primary: false,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portfolio Summary
          _buildPortfolioSummary(service, theme),
          const SizedBox(height: 16),

          // Properties List
          Text(
            'Properties Performance',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 16),
          ...analytics.map((propertyAnalytics) {
            return _buildPropertyCard(propertyAnalytics, theme);
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(AnalyticsService service, List<PropertyAnalytics> analytics, ThemeData theme) {
    // Delegate to modern performance tab implementation
    return _buildPerformanceTabModern(service, analytics, theme);
  }

  Widget _buildInsightsTab(AnalyticsService service, List<PropertyAnalytics> analytics, ThemeData theme) {
    return SafeArea(
      bottom: true,
      child: ListView(
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildMarketInsights(theme),
          const SizedBox(height: 24),
          _buildOptimizationTips(theme),
          const SizedBox(height: 24),
          _buildCompetitorAnalysis(theme),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  Widget _quickNavBar(ThemeData theme) {
    final chipStyle = (_compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(fontWeight: FontWeight.w600);
    return Wrap(
      spacing: _compact ? 6 : 8,
      runSpacing: _compact ? 6 : 8,
      children: [
        ActionChip(label: Text('Metrics', style: chipStyle), onPressed: () => _scrollTo(_keyMetricsKey)),
        ActionChip(label: Text('Revenue', style: chipStyle), onPressed: () => _scrollTo(_revenueKey)),
        ActionChip(label: Text('Demand', style: chipStyle), onPressed: () => _scrollTo(_demandKey)),
        ActionChip(label: Text('Occupancy', style: chipStyle), onPressed: () => _scrollTo(_occupancyKey)),
        ActionChip(label: Text('Heatmap', style: chipStyle), onPressed: () => _scrollTo(_heatmapKey)),
        ActionChip(label: Text('Summary', style: chipStyle), onPressed: () => _scrollTo(_tableKey)),
      ],
    );
  }

  Widget _sectionHeader(ThemeData theme, String title, IconData icon, {Key? key}) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: _compact ? 6 : 8),
      child: Row(
        children: [
          Icon(icon, size: _compact ? 16 : 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(title, style: (_compact ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Expanded(child: Divider(height: 1, color: theme.dividerColor.withOpacity(0.4))),
        ],
      ),
    );
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  // ---------------- Modern Performance Tab ----------------
  Widget _buildPerformanceTabModern(AnalyticsService service, List<PropertyAnalytics> analytics, ThemeData theme) {
    final selectedList = _selectedPropertyId == 'All'
        ? analytics
        : analytics.where((a) => a.propertyId == _selectedPropertyId).toList();
    final aggregated = _aggregateAnalytics(selectedList);
    const pad = 16.0;
    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterBar(theme, analytics),
            const SizedBox(height: 16),
            _quickNavBar(theme),
            const SizedBox(height: 16),
            _sectionHeader(theme, 'Key Metrics', Icons.dashboard_outlined, key: _keyMetricsKey),
            _buildKeyMetrics(
              aggregated,
              theme,
              baseline: _selectedPropertyId == 'All' ? null : _aggregateAnalytics(analytics),
            ),
            const SizedBox(height: 16),
            _sectionHeader(theme, 'Revenue Trend', Icons.trending_up, key: _revenueKey),
            _buildEarningsChart(aggregated, theme),
            const SizedBox(height: 16),
            _sectionHeader(theme, 'Demand Analysis', Icons.trending_up, key: _demandKey),
            _buildDemandChart(aggregated, theme),
            const SizedBox(height: 16),
            _sectionHeader(theme, 'Occupancy Analysis', Icons.home_outlined, key: _occupancyKey),
            _buildOccupancyChart(aggregated, theme),
            const SizedBox(height: 16),
            _sectionHeader(theme, 'Performance Heatmap', Icons.calendar_view_month, key: _heatmapKey),
            _buildPerformanceHeatmap(aggregated, theme),
            const SizedBox(height: 16),
            _sectionHeader(theme, 'Monthly Summary', Icons.table_chart_outlined, key: _tableKey),
            _buildMonthlyTableCard(aggregated, theme),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioSummary(AnalyticsService service, ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.all(isPhone ? 14 : 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Earnings',
                  CurrencyFormatter.formatPrice(service.getTotalPortfolioEarnings()),
                  Icons.attach_money,
                  theme.colorScheme.onPrimaryContainer,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Total Bookings',
                  '${service.getTotalPortfolioBookings()}',
                  Icons.book,
                  theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Avg Rating',
                  service.getAveragePortfolioRating().toStringAsFixed(1),
                  Icons.star,
                  theme.colorScheme.onPrimaryContainer,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Properties',
                  '${ref.watch(analyticsServiceProvider).length}',
                  Icons.home,
                  theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontSize: isPhone ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isPhone ? 16 : 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(PropertyAnalytics analytics, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.35), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    analytics.propertyTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getOccupancyColor(analytics.occupancyRate).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(analytics.occupancyRate * 100).toInt()}% occupied',
                    style: TextStyle(
                      color: _getOccupancyColor(analytics.occupancyRate),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Earnings',
                    CurrencyFormatter.formatPrice(analytics.totalEarnings),
                    Icons.attach_money,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Bookings',
                    '${analytics.totalBookings}',
                    Icons.book,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Rating',
                    '${analytics.averageRating}',
                    Icons.star,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Avg monthly rate',
                    CurrencyFormatter.formatPricePerUnit(analytics.averageDailyRate * 30, 'month'),
                    Icons.trending_up,
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

  Widget _buildMetricItem(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsChart(PropertyAnalytics analytics, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.trending_up, color: Colors.green, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Monthly Earnings',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text('${(value / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 9)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final months = analytics.monthlyEarnings.keys.toList();
                        if (value.toInt() < months.length) {
                          return Text(months[value.toInt()].substring(0, 3), style: const TextStyle(fontSize: 9));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: analytics.monthlyEarnings.entries.toList().asMap().entries.map((e) => 
                      FlSpot(e.key.toDouble(), e.value.value)).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsChart(PropertyAnalytics analytics, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.calendar_month, color: Colors.blue, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Monthly Bookings',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: _buildSimpleChart(
              analytics.monthlyBookings.map((key, value) => MapEntry(key, value.toDouble())),
              theme,
              false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(Map<String, double> data, ThemeData theme, bool isCurrency) {
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.entries.map((entry) {
        final height = (entry.value / maxValue) * 160;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isCurrency ? CurrencyFormatter.formatPrice(entry.value) : '${entry.value.toInt()}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    entry.key,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyMetrics(PropertyAnalytics analytics, ThemeData theme, {PropertyAnalytics? baseline}) {
    return LayoutBuilder(builder: (context, cons) {
      final w = cons.maxWidth;
      final cols = w >= 900 ? 4 : w >= 600 ? 2 : 1;
      const gap = 12.0;
      String? pctDelta(num current, num base) {
        if (base <= 0) return null;
        final d = ((current - base) / base) * 100.0;
        final s = d >= 0 ? '+${d.toStringAsFixed(1)}%' : '${d.toStringAsFixed(1)}%';
        return s;
      }
      Color? deltaColor(String? delta) {
        if (delta == null) return null;
        return delta.trim().startsWith('-') ? Colors.red : Colors.green;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.dashboard, color: theme.colorScheme.primary, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Key Performance Metrics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: cols == 1 ? 3.2 : (cols == 2 ? 2.8 : 2.4),
              crossAxisSpacing: gap * 2,
              mainAxisSpacing: gap,
            children: [
              _buildKPICard(
                'Views This Month',
                '${analytics.viewsThisMonth}',
                Icons.visibility,
                Colors.blue,
                theme,
                deltaText: baseline != null ? pctDelta(analytics.viewsThisMonth, baseline.viewsThisMonth) : null,
                deltaColor: deltaColor(baseline != null ? pctDelta(analytics.viewsThisMonth, baseline.viewsThisMonth) : null),
              ),
              _buildKPICard(
                'Inquiries',
                '${analytics.inquiriesThisMonth}',
                Icons.message,
                Colors.orange,
                theme,
                deltaText: baseline != null ? pctDelta(analytics.inquiriesThisMonth, baseline.inquiriesThisMonth) : null,
                deltaColor: deltaColor(baseline != null ? pctDelta(analytics.inquiriesThisMonth, baseline.inquiriesThisMonth) : null),
              ),
              _buildKPICard(
                'Conversion Rate',
                '${(analytics.conversionRate * 100).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.green,
                theme,
                deltaText: baseline != null ? pctDelta(analytics.conversionRate, baseline.conversionRate) : null,
                deltaColor: deltaColor(baseline != null ? pctDelta(analytics.conversionRate, baseline.conversionRate) : null),
              ),
              _buildKPICard(
                'Occupancy Rate',
                '${(analytics.occupancyRate * 100).toStringAsFixed(0)}%',
                Icons.home,
                Colors.purple,
                theme,
                deltaText: baseline != null ? pctDelta(analytics.occupancyRate, baseline.occupancyRate) : null,
                deltaColor: deltaColor(baseline != null ? pctDelta(analytics.occupancyRate, baseline.occupancyRate) : null),
              ),
            ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, ThemeData theme, {String? deltaText, Color? deltaColor}) {
    return InkWell(
      onTap: () => _showKPIDetails(title, value, icon, color),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.08),
              color.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const Spacer(),
                if (deltaText != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (deltaColor ?? Colors.grey).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            deltaText.trim().startsWith('-') ? Icons.trending_down : Icons.trending_up,
                            size: 10,
                            color: deltaColor ?? Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              deltaText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: deltaColor ?? Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showKPIDetails(String title, String value, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Value: $value',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Trend Analysis:'),
              const Text('• Performance is trending upward'),
              const Text('• Above industry average'),
              const Text('• Consistent growth pattern'),
              const SizedBox(height: 16),
              const Text('Recommendations:'),
              const Text('• Continue current strategies'),
              const Text('• Monitor weekly performance'),
              const Text('• Consider promotional campaigns'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Analyzing $title in detail...')),
                );
              },
              child: const Text('View Details'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOccupancyChart(PropertyAnalytics analytics, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.home, color: Colors.purple, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Occupancy Rate',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(analytics.occupancyRate * 100).toInt()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    value: analytics.occupancyRate * 100,
                    color: Colors.purple,
                    title: '${(analytics.occupancyRate * 100).toInt()}%',
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    radius: 50,
                  ),
                  PieChartSectionData(
                    value: (1 - analytics.occupancyRate) * 100,
                    color: Colors.grey.withOpacity(0.3),
                    title: 'Available',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    radius: 40,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandChart(PropertyAnalytics analytics, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.trending_up, color: Colors.orange, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Views vs Inquiries',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 9)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0: return const Text('Views', style: TextStyle(fontSize: 9));
                          case 1: return const Text('Inquiries', style: TextStyle(fontSize: 9));
                          default: return const Text('');
                        }
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: analytics.viewsThisMonth.toDouble(),
                        color: Colors.blue,
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: analytics.inquiriesThisMonth.toDouble(),
                        color: Colors.orange,
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceHeatmap(PropertyAnalytics analytics, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.calendar_view_month, color: Colors.teal, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Performance (Last 30 Days)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: 30,
            itemBuilder: (context, index) {
              final intensity = ((index + 1) % 6) / 5.0;
              final performance = (analytics.occupancyRate * 100 + (intensity - 0.5) * 20).clamp(0, 100).toInt();
              return Container(
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.2 + intensity * 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${index + 1}', style: TextStyle(fontSize: 8, color: intensity > 0.5 ? Colors.white : Colors.black87)),
                      Text('$performance%', style: TextStyle(fontSize: 6, color: intensity > 0.5 ? Colors.white70 : Colors.black54)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low Performance', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.teal.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.teal.withOpacity(0.6), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.teal.withOpacity(0.9), borderRadius: BorderRadius.circular(2))),
                ],
              ),
              Text('High Performance', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  // Export Analytics PDF (summary report of current selection)
  Future<File?> _exportAnalyticsPdf(List<PropertyAnalytics> list) async {
    try {
      final pdf = pw.Document();
      final sel = _selectedPropertyId == 'All'
          ? list
          : list.where((a) => a.propertyId == _selectedPropertyId).toList();
      final agg = _aggregateAnalytics(sel);
      final e = _applyRangeMonthlyDouble(agg.monthlyEarnings);
      final b = _applyRangeMonthlyInt(agg.monthlyBookings);
      pw.Widget header(String text) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      );
      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Text('Property Analytics Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Property: ${_selectedPropertyId == 'All' ? 'All Properties' : 'Property #$_selectedPropertyId'}'),
            pw.Text('Range: $_selectedRange • Granularity: $_selectedGranularity'),
            pw.SizedBox(height: 12),
            header('Key Metrics'),
            pw.TableHelper.fromTextArray(
              headers: ['Metric', 'Value'],
              data: [
                ['Views This Month', '${agg.viewsThisMonth}'],
                ['Inquiries', '${agg.inquiriesThisMonth}'],
                ['Conversion Rate', '${(agg.conversionRate * 100).toStringAsFixed(1)}%'],
                ['Occupancy Rate', '${(agg.occupancyRate * 100).toStringAsFixed(0)}%'],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 12),
            header('Monthly Summary'),
            pw.TableHelper.fromTextArray(
              headers: const ['Month', 'Earnings', 'Bookings', 'ADR'],
              data: [
                for (final m in e.keys)
                  [
                    m,
                    e[m]!.toStringAsFixed(2),
                    '${b[m] ?? 0}',
                    (b[m] ?? 0) > 0 ? (e[m]! / (b[m]!.toDouble())).toStringAsFixed(2) : '-',
                  ],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      );
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/analytics_report_$ts.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (_) {
      return null;
    }
  }

  Widget _buildMarketInsights(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Insights',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _buildInsightItem(
              'Peak Season',
              'July-August shows highest demand with 25% increase',
              Icons.trending_up,
              Colors.green,
              theme,
            ),
            _buildInsightItem(
              'Pricing Opportunity',
              'Your rates are 12% below market average',
              Icons.attach_money,
              Colors.orange,
              theme,
            ),
            _buildInsightItem(
              'Competition',
              '15 similar properties within 2km radius',
              Icons.location_on,
              Colors.blue,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationTips(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optimization Tips',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _buildTipItem('Add more photos to increase booking rate by 23%', Icons.photo_camera),
            _buildTipItem('Enable instant booking to improve visibility', Icons.flash_on),
            _buildTipItem('Update amenities list - WiFi is most searched', Icons.wifi),
            _buildTipItem('Respond to messages within 1 hour for better ranking', Icons.message),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitorAnalysis(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Competitor Analysis',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text('Metric', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
                Expanded(child: Text('You', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
                Expanded(child: Text('Market Avg', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
              ],
            ),
            const Divider(height: 16),
            _buildComparisonRow('Daily Rate', CurrencyFormatter.formatPrice(145), CurrencyFormatter.formatPrice(162), theme),
            _buildComparisonRow('Rating', '4.7', '4.3', theme),
            _buildComparisonRow('Response Time', '2 hrs', '4 hrs', theme),
            _buildComparisonRow('Occupancy', '78%', '65%', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String description, IconData icon, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String metric, String yourValue, String marketValue, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(metric, style: theme.textTheme.bodySmall)),
          Expanded(child: Text(yourValue, style: theme.textTheme.bodySmall)),
          Expanded(child: Text(marketValue, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  // ---------------- Modern Cards & Charts ----------------
  Widget _buildFilterBar(ThemeData theme, List<PropertyAnalytics> analytics) {
    final props = ['All', ...analytics.map((a) => a.propertyId)];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Range Filters
          Row(
            children: [
              Icon(Icons.tune, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              _buildCompactSegmented(theme, const ['7D', '30D', '90D', '12M', 'All'], _selectedRange, (v) => setState(() => _selectedRange = v)),
            ],
          ),
          const SizedBox(height: 12),
          // Property and View Options
          Column(
            children: [
              // Property Dropdown
              _buildCompactDropdown(
                theme,
                'Property',
                _selectedPropertyId == 'All' && (widget.propertyId ?? '').isNotEmpty ? widget.propertyId! : _selectedPropertyId,
                props.map((p) => DropdownMenuItem(value: p, child: Text(p == 'All' ? 'All Properties' : 'Property #$p'))).toList(),
                (v) => setState(() => _selectedPropertyId = v ?? 'All'),
              ),
              const SizedBox(height: 8),
              // Toggle Options
              const Row(
                children: [
                  Spacer(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSegmented(ThemeData theme, List<String> items, String selected, ValueChanged<String> onChange) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final isSelected = item == selected;
          return GestureDetector(
            onTap: () => onChange(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompactDropdown<T>(ThemeData theme, String label, T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          onChanged: onChanged,
          items: items,
          isDense: true,
          isExpanded: true,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          icon: Icon(Icons.keyboard_arrow_down, size: 16, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildToggleChip(ThemeData theme, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipLegend({required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: _compact ? 11 : 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _earningsLineChartAnnotated(ThemeData theme, List<double> primary, List<double> secondary, List<String> labels, Color lineColor, Color secondaryColor) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final spots = [for (int i = 0; i < primary.length; i++) FlSpot(i.toDouble(), primary[i] / 1000.0)];
    final compSpots = [for (int i = 0; i < secondary.length; i++) FlSpot(i.toDouble(), secondary[i] / 1000.0)];
    double yMax = 0;
    for (final v in [...primary, ...secondary]) { if (v > yMax) yMax = v; }
    double avg = 0;
    if (primary.isNotEmpty) { avg = primary.reduce((a, b) => a + b) / primary.length; }
    int minIdx = 0, maxIdx = 0; double minVal = primary.isNotEmpty ? primary.first : 0, maxVal = primary.isNotEmpty ? primary.first : 0;
    for (int i = 1; i < primary.length; i++) { final v = primary[i]; if (v < minVal) { minVal = v; minIdx = i; } if (v > maxVal) { maxVal = v; maxIdx = i; } }
    final chart = LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: true, verticalInterval: 1, horizontalInterval: 0.5, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1, dashArray: const [4, 4]), getDrawingVerticalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.12), strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: _compact ? (isPhone ? 24 : 30) : (isPhone ? 28 : 36), interval: 0.5, getTitlesWidget: (v, m) => Text('${v.toStringAsFixed(1)}k', style: TextStyle(fontSize: _compact ? (isPhone ? 9 : 10) : (isPhone ? 10 : 11), color: Colors.grey[600])))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: _compact ? (isPhone ? 14 : 18) : (isPhone ? 18 : 22), getTitlesWidget: (value, meta) { final idx = value.toInt(); if (idx < 0 || idx >= labels.length) return const SizedBox.shrink(); return Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[idx], style: TextStyle(fontSize: _compact ? (isPhone ? 9 : 10) : (isPhone ? 10 : 11), color: Colors.grey[600]))); })),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          enabled: _interactiveCharts,
          handleBuiltInTouches: _interactiveCharts,
          touchTooltipData: _interactiveCharts
              ? LineTouchTooltipData(getTooltipItems: (spots) {
                  return spots.map((s) {
                    final val = s.y * 1000.0;
                    return LineTooltipItem(CurrencyFormatter.formatPrice(val), const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                  }).toList();
                })
              : const LineTouchTooltipData(),
        ),
        borderData: FlBorderData(show: false),
        clipData: const FlClipData.all(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: lineColor,
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [lineColor.withOpacity(0.25), lineColor.withOpacity(0.05)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) { final isExtreme = i == minIdx || i == maxIdx; return FlDotCirclePainter(radius: isExtreme ? (_compact ? (isPhone ? 3.0 : 3.5) : (isPhone ? 3.5 : 4)) : (_compact ? (isPhone ? 2.0 : 2.5) : (isPhone ? 2.5 : 3)), color: isExtreme ? Colors.white : lineColor, strokeColor: isExtreme ? lineColor : Colors.transparent, strokeWidth: isExtreme ? 2 : 0); }),
          ),
          LineChartBarData(spots: compSpots, isCurved: true, barWidth: 2, color: secondaryColor, dashArray: const [8, 4], dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: false)),
        ],
        minY: 0,
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (avg > 0) HorizontalLine(y: avg / 1000.0, color: Colors.grey.withOpacity(0.35), strokeWidth: 1, dashArray: const [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topLeft, padding: const EdgeInsets.only(left: 4, bottom: 2), style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.grey[700], fontWeight: FontWeight.w600), labelResolver: (line) => 'Avg ${CurrencyFormatter.formatPrice(avg)}')),
          ],
          verticalLines: [
            if (primary.isNotEmpty) VerticalLine(x: minIdx.toDouble(), color: Colors.redAccent.withOpacity(0.45), strokeWidth: 1, dashArray: const [6, 6], label: VerticalLineLabel(show: true, alignment: Alignment.bottomLeft, padding: const EdgeInsets.only(left: 4, top: 2), style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.redAccent, fontWeight: FontWeight.w600), labelResolver: (line) => 'Min ${CurrencyFormatter.formatPrice(minVal)}')),
            if (primary.isNotEmpty) VerticalLine(x: maxIdx.toDouble(), color: Colors.green.withOpacity(0.45), strokeWidth: 1, dashArray: const [6, 6], label: VerticalLineLabel(show: true, alignment: Alignment.topRight, padding: const EdgeInsets.only(right: 4, bottom: 2), style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.green, fontWeight: FontWeight.w600), labelResolver: (line) => 'Max ${CurrencyFormatter.formatPrice(maxVal)}')),
          ],
        ),
      ),
    );
    return _chartWrapper(child: chart);
  }

  Widget _buildEarningsChartModern(PropertyAnalytics analytics, ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final filteredE = _applyRangeMonthlyDouble(analytics.monthlyEarnings);
    final labels = filteredE.keys.toList();
    final values = filteredE.values.toList();
    // secondary: compare property if chosen, otherwise naive previous period
    List<double> secondary;
    String secondaryLabel;
    if (_compare && _comparePropertyId != null) {
      final all = ref.read(analyticsServiceProvider);
      final cmp = all.firstWhere((a) => a.propertyId == _comparePropertyId, orElse: () => analytics);
      final cmpFiltered = _applyRangeMonthlyDouble(cmp.monthlyEarnings);
      secondary = cmpFiltered.values.toList();
      secondaryLabel = 'Compare';
    } else {
      secondary = List<double>.generate(values.length, (i) => i == 0 ? values[0] * 0.9 : values[i - 1]);
      secondaryLabel = 'Prev period';
    }
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.all(_compact ? (isPhone ? 10 : 12) : (isPhone ? 12 : 16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Earnings Trend', style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(fontWeight: FontWeight.bold))),
            Wrap(spacing: 8, children: [
              _chipLegend(color: theme.colorScheme.primary, label: 'This period'),
              _chipLegend(color: theme.colorScheme.onSurface.withOpacity(0.4), label: secondaryLabel),
            ])
          ]),
          const SizedBox(height: 8),
          SizedBox(height: _compact ? (isPhone ? 170 : 200) : (isPhone ? 220 : 260), child: _earningsLineChartAnnotated(theme, values, secondary, labels, theme.colorScheme.primary, theme.colorScheme.onSurface.withOpacity(0.4))),
        ]),
      ),
    );
  }

  Widget _buildBookingsChartModern(PropertyAnalytics analytics, ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final filteredB = _applyRangeMonthlyInt(analytics.monthlyBookings);
    final labels = filteredB.keys.toList();
    final values = filteredB.values.map((e) => e.toDouble()).toList();
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(_compact ? (isPhone ? 10 : 12) : (isPhone ? 12 : 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bookings', style: (_compact ? theme.textTheme.titleSmall : (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge))?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: _compact ? (isPhone ? 170 : 200) : (isPhone ? 220 : 260),
              child: _chartWrapper(child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(enabled: _interactiveCharts),
                  gridData: FlGridData(show: true, horizontalInterval: 2, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: isPhone ? 34 : 40, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: TextStyle(fontSize: isPhone ? 9 : 10, color: Colors.grey[600])))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: isPhone ? 18 : 22, getTitlesWidget: (v, m) { final i = v.toInt(); if (i < 0 || i >= labels.length) return const SizedBox.shrink(); return Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[i], style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.grey[600]))); })),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (int i = 0; i < labels.length; i++)
                      BarChartGroupData(x: i, barRods: [BarChartRodData(toY: values[i], color: theme.colorScheme.primary, width: isPhone ? 10 : 14, borderRadius: BorderRadius.circular(6))]),
                  ],
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  // Compact chart wrapper (adds clipping and optional pan/zoom if needed later)
  Widget _chartWrapper({required Widget child}) {
    final clipped = ClipRRect(borderRadius: BorderRadius.circular(8), child: child);
    if (_interactiveCharts) {
      return InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(24),
        minScale: 1.0,
        maxScale: 3.0,
        panEnabled: false,
        scaleEnabled: true,
        child: clipped,
      );
    }
    return clipped;
  }

  // ADR chart derived from earnings/bookings
  Widget _buildAdrChartModern(PropertyAnalytics analytics, ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final earnings = _applyRangeMonthlyDouble(analytics.monthlyEarnings);
    final bookings = _applyRangeMonthlyInt(analytics.monthlyBookings);
    final labels = earnings.keys.toList();
    final adr = [for (final k in labels) (bookings[k] ?? 0) > 0 ? (earnings[k]! / (bookings[k]!.toDouble())) : 0.0];
    final spots = [for (int i = 0; i < adr.length; i++) FlSpot(i.toDouble(), adr[i])];
    final avg = adr.isNotEmpty ? adr.reduce((a, b) => a + b) / adr.length : 0.0;
    final data = LineChartData(
      minY: 0,
      lineTouchData: LineTouchData(enabled: _interactiveCharts),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: isPhone ? 34 : 40, getTitlesWidget: (v, m) => Text(CurrencyFormatter.formatPrice(v), style: TextStyle(fontSize: isPhone ? 9 : 10, color: Colors.grey[600])))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: isPhone ? 18 : 22, getTitlesWidget: (v, m) { final i = v.toInt(); if (i < 0 || i >= labels.length) return const SizedBox.shrink(); return Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[i], style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.grey[600]))); })),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.12), dashArray: const [4, 4])),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(horizontalLines: [if (avg > 0) HorizontalLine(y: avg, color: Colors.grey.withOpacity(0.35), dashArray: const [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topLeft, padding: const EdgeInsets.only(left: 4, bottom: 2), style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.grey[700], fontWeight: FontWeight.w600), labelResolver: (_) => 'Avg ${CurrencyFormatter.formatPrice(avg)}'))]),
      lineBarsData: [LineChartBarData(spots: spots, isCurved: true, barWidth: 3, color: Colors.teal, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [Colors.teal.withOpacity(0.22), Colors.teal.withOpacity(0.05)], begin: Alignment.topCenter, end: Alignment.bottomCenter)))],
    );
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.all(_compact ? (isPhone ? 10 : 12) : (isPhone ? 12 : 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Average Daily Rate (ADR)', style: (_compact ? theme.textTheme.titleSmall : (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge))?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: _compact ? (isPhone ? 170 : 200) : (isPhone ? 220 : 260),
              child: _chartWrapper(child: LineChart(data)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsCancellationsChart(PropertyAnalytics analytics, ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final b = _applyRangeMonthlyInt(analytics.monthlyBookings);
    final labels = b.keys.toList();
    final values = b.values.map((e) => e.toDouble()).toList();
    final cancellations = [for (final v in values) (v * 0.12)];
    final data = BarChartData(
      gridData: FlGridData(show: true, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1)),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: isPhone ? 28 : 36, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.grey[600])))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: isPhone ? 18 : 22, getTitlesWidget: (v, m) { final i = v.toInt(); if (i < 0 || i >= labels.length) return const SizedBox.shrink(); return Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[i], style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.grey[600]))); })),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barTouchData: BarTouchData(enabled: _interactiveCharts),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (int i = 0; i < labels.length; i++)
          BarChartGroupData(
            x: i,
            barsSpace: isPhone ? 4 : 6,
            barRods: [
              BarChartRodData(toY: values[i], color: theme.colorScheme.primary, width: isPhone ? 8 : 10, borderRadius: BorderRadius.circular(6)),
              BarChartRodData(toY: cancellations[i], color: Colors.redAccent, width: isPhone ? 8 : 10, borderRadius: BorderRadius.circular(6)),
            ],
          ),
      ],
    );
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(_compact ? (isPhone ? 10 : 12) : (isPhone ? 12 : 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('Bookings vs Cancellations', style: (_compact ? theme.textTheme.titleSmall : (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge))?.copyWith(fontWeight: FontWeight.bold))),
              Wrap(spacing: 8, children: [
                _chipLegend(color: theme.colorScheme.primary, label: 'Bookings'),
                _chipLegend(color: Colors.redAccent, label: 'Cancellations'),
              ]),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: _compact ? (isPhone ? 170 : 200) : (isPhone ? 220 : 260),
              child: _chartWrapper(child: BarChart(data)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyHeatmapCard(PropertyAnalytics analytics, ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final b = _applyRangeMonthlyInt(analytics.monthlyBookings);
    final labels = b.keys.toList();
    final values = b.values.map((e) => e.toDouble()).toList();
    final maxVal = values.isEmpty ? 1.0 : values.reduce((a, c) => a > c ? a : c);
    Color colorFor(double t) {
      t = t.clamp(0.0, 1.0);
      return Colors.green.withOpacity(0.15 + 0.7 * t);
    }
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Occupancy Heatmap', style: (_compact ? theme.textTheme.titleSmall : (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge))?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, cons) {
            const spacing = 4.0;
            final cols = labels.length;
            final cellSize = ((cons.maxWidth - (cols - 1) * spacing) / cols).clamp(8.0, _compact ? (isPhone ? 14.0 : 18.0) : (isPhone ? 18.0 : 22.0));
            const rows = 4; // 4 weeks representation
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: rows * cellSize + (rows - 1) * spacing,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int c = 0; c < cols; c++)
                        Padding(
                          padding: EdgeInsets.only(right: c == cols - 1 ? 0 : spacing),
                          child: Column(
                            children: [
                              for (int r = 0; r < rows; r++)
                                Padding(
                                  padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : spacing),
                                  child: Container(
                                    width: cellSize,
                                    height: cellSize,
                                    decoration: BoxDecoration(
                                      color: colorFor((values[c] / maxVal)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Month labels
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (int i = 0; i < labels.length; i++)
                      SizedBox(
                        width: cellSize,
                        child: Center(child: Text(labels[i], style: TextStyle(fontSize: isPhone ? 10 : 11, color: theme.colorScheme.onSurfaceVariant))),
                      ),
                  ]),
                ),
              ],
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildMonthlyTableCard(PropertyAnalytics analytics, ThemeData theme) {
    final e = _applyRangeMonthlyDouble(analytics.monthlyEarnings);
    final b = _applyRangeMonthlyInt(analytics.monthlyBookings);
    final labels = e.keys.toList();
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Monthly Summary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DataTable(columns: const [
            DataColumn(label: Text('Month')),
            DataColumn(label: Text('Earnings')),
            DataColumn(label: Text('Bookings')),
            DataColumn(label: Text('ADR')),
          ], rows: [
            for (final m in labels)
              DataRow(cells: [
                DataCell(Text(m)),
                DataCell(Text(CurrencyFormatter.formatPrice(e[m] ?? 0))),
                DataCell(Text('${b[m] ?? 0}')),
                DataCell(Text((b[m] ?? 0) > 0 ? CurrencyFormatter.formatPrice((e[m] ?? 0) / (b[m]!.toDouble())) : '-')),
              ]),
          ]),
        ]),
      ),
    );
  }

  Widget _buildOccupancyAndFunnelRow(PropertyAnalytics analytics, ThemeData theme) {
    return LayoutBuilder(builder: (context, cons) {
      final w = cons.maxWidth;
      final twoCol = w > 700;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(width: twoCol ? (w - 12) / 2 : w, child: _buildOccupancyCard(analytics, theme)),
        SizedBox(width: twoCol ? (w - 12) / 2 : w, child: _buildFunnelCard(analytics, theme)),
      ]);
    });
  }

  Widget _buildOccupancyCard(PropertyAnalytics analytics, ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Occupancy', style: (_compact ? theme.textTheme.titleSmall : (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge))?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: _compact ? (isPhone ? 160 : 180) : (isPhone ? 180 : 200),
            child: PieChart(PieChartData(pieTouchData: PieTouchData(enabled: _interactiveCharts), sectionsSpace: 2, centerSpaceRadius: 40, startDegreeOffset: -90, sections: [
              PieChartSectionData(value: analytics.occupancyRate, color: Colors.green, title: '${(analytics.occupancyRate * 100).toStringAsFixed(0)}%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), radius: isPhone ? 52 : 56),
              PieChartSectionData(value: 1 - analytics.occupancyRate, color: Colors.grey[300], title: '', radius: isPhone ? 52 : 56),
            ])),
          ),
        ]),
      ),
    );
  }

  Widget _buildFunnelCard(PropertyAnalytics analytics, ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final views = analytics.viewsThisMonth.toDouble();
    final inquiries = analytics.inquiriesThisMonth.toDouble();
    final bookings = analytics.monthlyBookings.isEmpty ? 0.0 : analytics.monthlyBookings.values.last.toDouble();
    final maxVal = [views, inquiries, bookings].fold<double>(0, (p, c) => c > p ? c : p);
    double rel(double v) => maxVal == 0 ? 0 : v / maxVal;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Conversion Funnel', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _funnelStep(theme, 'Views', views.toInt().toString(), Colors.blue, rel(views)),
          const SizedBox(height: 8),
          _funnelStep(theme, 'Inquiries', inquiries.toInt().toString(), Colors.orange, rel(inquiries)),
          const SizedBox(height: 8),
          _funnelStep(theme, 'Bookings', bookings.toInt().toString(), Colors.green, rel(bookings)),
        ]),
      ),
    );
  }

  Widget _funnelStep(ThemeData theme, String title, String value, Color color, double ratio) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(title, style: theme.textTheme.bodySmall)),
        Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(value: ratio, minHeight: 10, backgroundColor: color.withOpacity(0.15), valueColor: AlwaysStoppedAnimation(color)),
      ),
    ]);
  }

  Widget _buildTopKeywordsCard(PropertyAnalytics analytics, ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Top Keywords', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: analytics.topKeywords.map((k) => Chip(label: Text(k))).toList()),
        ]),
      ),
    );
  }

  PropertyAnalytics _aggregateAnalytics(List<PropertyAnalytics> list) {
    if (list.isEmpty) {
      return const PropertyAnalytics(
        propertyId: 'All',
        propertyTitle: 'All Properties',
        totalEarnings: 0,
        totalBookings: 0,
        averageRating: 0,
        totalReviews: 0,
        occupancyRate: 0,
        monthlyEarnings: {},
        monthlyBookings: {},
        topKeywords: [],
        averageDailyRate: 0,
        viewsThisMonth: 0,
        inquiriesThisMonth: 0,
        conversionRate: 0,
      );
    }
    final months = list.first.monthlyEarnings.keys.toList();
    final earnings = <String, double>{ for (final m in months) m: 0 };
    final bookings = <String, int>{ for (final m in list.first.monthlyBookings.keys) m: 0 };
    double totalE = 0; int totalB = 0; double avgRatingSum = 0; int totalR = 0; double occSum = 0; double adrSum = 0; int views = 0; int inquiries = 0;
    final Map<String, int> kwFreq = {};
    for (final a in list) {
      a.monthlyEarnings.forEach((k, v) { earnings[k] = (earnings[k] ?? 0) + v; });
      a.monthlyBookings.forEach((k, v) { bookings[k] = (bookings[k] ?? 0) + v; });
      totalE += a.totalEarnings;
      totalB += a.totalBookings;
      avgRatingSum += a.averageRating;
      totalR += a.totalReviews;
      occSum += a.occupancyRate;
      adrSum += a.averageDailyRate;
      views += a.viewsThisMonth;
      inquiries += a.inquiriesThisMonth;
      for (final kw in a.topKeywords) { kwFreq[kw] = (kwFreq[kw] ?? 0) + 1; }
    }
    final avgRating = avgRatingSum / list.length;
    final avgOcc = occSum / list.length;
    final avgAdr = adrSum / list.length;
    final conv = inquiries > 0 ? (totalB / inquiries) : 0.0;
    final topKw = kwFreq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topKeywords = topKw.take(10).map((e) => e.key).toList();
    return PropertyAnalytics(
      propertyId: 'All',
      propertyTitle: 'All Properties',
      totalEarnings: totalE,
      totalBookings: totalB,
      averageRating: avgRating,
      totalReviews: totalR,
      occupancyRate: avgOcc,
      monthlyEarnings: earnings,
      monthlyBookings: bookings,
      topKeywords: topKeywords,
      averageDailyRate: avgAdr,
      viewsThisMonth: views,
      inquiriesThisMonth: inquiries,
      conversionRate: conv,
    );
  }

  Future<File?> _exportAnalyticsCsv(List<PropertyAnalytics> list) async {
    try {
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/analytics_export_$ts.csv');
      final buffer = StringBuffer();
      buffer.writeln('Property ID,Title,Total Earnings,Total Bookings,Avg Rating,Total Reviews,Occupancy');
      for (final a in list) {
        buffer.writeln('${a.propertyId},"${a.propertyTitle}",${a.totalEarnings.toStringAsFixed(2)},${a.totalBookings},${a.averageRating.toStringAsFixed(2)},${a.totalReviews},${(a.occupancyRate * 100).toStringAsFixed(1)}%');
      }
      buffer.writeln();
      final agg = _aggregateAnalytics(list);
      buffer.writeln('Month,Aggregated Earnings,Aggregated Bookings');
      for (final m in agg.monthlyEarnings.keys) {
        buffer.writeln('$m,${agg.monthlyEarnings[m]!.toStringAsFixed(2)},${agg.monthlyBookings[m] ?? 0}');
      }
      await file.writeAsString(buffer.toString());
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareAnalyticsCsv(List<PropertyAnalytics> list) async {
    final file = await _exportAnalyticsCsv(list);
    if (file == null) return;
    try {
      await Share.shareXFiles([XFile(file.path)], text: 'Property Analytics Export');
    } catch (_) {}
  }

  // ---------------- Utilities ----------------
  Color _getOccupancyColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.orange;
    return Colors.red;
  }

  int _rangeMonths(String r) {
    switch (r) {
      case '7D':
        return 1;
      case '30D':
        return 1;
      case '90D':
        return 3;
      case '12M':
        return 12;
      case 'All':
      default:
        return 999;
    }
  }

  Future<void> _loadAnalyticsPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _compact = prefs.getBool('analytics_compact') ?? _compact;
        _selectedRange = prefs.getString('analytics_range') ?? _selectedRange;
        _selectedGranularity = prefs.getString('analytics_granularity') ?? _selectedGranularity;
        if ((widget.propertyId ?? '').isEmpty) {
          _selectedPropertyId = prefs.getString('analytics_property') ?? _selectedPropertyId;
        }
        _compare = prefs.getBool('analytics_compare') ?? _compare;
        _comparePropertyId = prefs.getString('analytics_compare_property');
      });
    } catch (_) {}
  }

  Future<void> _saveAnalyticsPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('analytics_compact', _compact);
      await prefs.setString('analytics_range', _selectedRange);
      await prefs.setString('analytics_granularity', _selectedGranularity);
      await prefs.setString('analytics_property', _selectedPropertyId);
      await prefs.setBool('analytics_compare', _compare);
      if (_comparePropertyId != null) {
        await prefs.setString('analytics_compare_property', _comparePropertyId!);
      } else {
        await prefs.remove('analytics_compare_property');
      }
    } catch (_) {}
  }

  Map<String, double> _applyRangeMonthlyDouble(Map<String, double> monthly) {
    final keys = monthly.keys.toList();
    final n = _rangeMonths(_selectedRange);
    final start = (keys.length - n).clamp(0, keys.length);
    final slice = keys.sublist(start);
    return {for (final k in slice) k: monthly[k] ?? 0.0};
  }

  Map<String, int> _applyRangeMonthlyInt(Map<String, int> monthly) {
    final keys = monthly.keys.toList();
    final n = _rangeMonths(_selectedRange);
    final start = (keys.length - n).clamp(0, keys.length);
    final slice = keys.sublist(start);
    return {for (final k in slice) k: monthly[k] ?? 0};
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
