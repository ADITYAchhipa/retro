import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/widgets/loading_states.dart';
import '../../widgets/responsive_layout.dart';
import '../../core/widgets/tab_back_handler.dart';
import '../../core/utils/currency_formatter.dart';

/// Industrial-grade analytics dashboard with comprehensive metrics
class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedPeriod = '30d';
  
  final List<String> _periods = ['24h', '7d', '30d', '90d', '1y', 'custom'];
  static const String _prefsSelectedPeriodKey = 'analytics_selected_period';
  static const String _prefsComparePrevKey = 'analytics_compare_prev';
  static const String _prefsCustomStartKey = 'analytics_custom_start';
  static const String _prefsCustomEndKey = 'analytics_custom_end';
  bool _comparePrev = false;
  final GlobalKey _revenueChartKey = GlobalKey();
  final GlobalKey _bookingChartKey = GlobalKey();
  final GlobalKey _monthlyChartKey = GlobalKey();
  final GlobalKey _occupancyChartKey = GlobalKey();
  final GlobalKey _categoryChartKey = GlobalKey();
  DateTimeRange? _customRange;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSavedPrefs().whenComplete(_loadAnalytics);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSelectedPeriod(String period) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsSelectedPeriodKey, period);
    } catch (_) {}
  }

  Future<void> _loadSavedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsSelectedPeriodKey);
      if (saved != null && _periods.contains(saved) && mounted) {
        setState(() => _selectedPeriod = saved);
      }
      final cmp = prefs.getBool(_prefsComparePrevKey);
      if (cmp != null && mounted) {
        setState(() => _comparePrev = cmp);
      }
      // Load custom range if available
      final startIso = prefs.getString(_prefsCustomStartKey);
      final endIso = prefs.getString(_prefsCustomEndKey);
      if (startIso != null && endIso != null) {
        try {
          final start = DateTime.parse(startIso);
          final end = DateTime.parse(endIso);
          if (mounted) {
            setState(() => _customRange = DateTimeRange(start: start, end: end));
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _saveComparePrev(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsComparePrevKey, value);
    } catch (_) {}
  }

  Future<void> _onSelectPeriod(String period) async {
    if (period == 'custom') {
      await _pickCustomDateRange();
      return;
    }
    setState(() => _selectedPeriod = period);
    await _saveSelectedPeriod(period);
    _loadAnalytics();
  }

  Future<void> _pickCustomDateRange() async {
    final initialStart = _customRange?.start ?? DateTime.now().subtract(const Duration(days: 29));
    final initialEnd = _customRange?.end ?? DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      saveText: 'Apply',
    );
    if (picked != null) {
      // Normalize end to be same-day end if needed (charts use index only).
      setState(() {
        _customRange = DateTimeRange(start: DateTime(picked.start.year, picked.start.month, picked.start.day), end: DateTime(picked.end.year, picked.end.month, picked.end.day));
        _selectedPeriod = 'custom';
      });
      await _saveSelectedPeriod('custom');
      await _saveCustomRange(_customRange!);
      _loadAnalytics();
    }
  }

  Future<void> _saveCustomRange(DateTimeRange range) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsCustomStartKey, range.start.toIso8601String());
      await prefs.setString(_prefsCustomEndKey, range.end.toIso8601String());
    } catch (_) {}
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TabBackHandler(
      tabController: _tabController,
      child: Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Analytics Dashboard'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        toolbarHeight: 60,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (period) async => _onSelectPeriod(period),
            itemBuilder: (context) => _periods.map((period) => 
              PopupMenuItem(
                value: period,
                child: Text(_formatPeriod(period)),
              ),
            ).toList(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Chip(
                label: Text(_formatPeriod(_selectedPeriod)),
                avatar: const Icon(Icons.calendar_today, size: 16),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Revenue'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.home), text: 'Properties'),
          ],
        ),
      ),
      body: ResponsiveLayout(
        child: _isLoading
            ? _buildLoadingState()
            : Column(
                children: [
                  _buildPeriodChips(theme),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      dragStartBehavior: DragStartBehavior.down,
                      physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
                      children: [
                        _buildOverviewTab(theme),
                        _buildRevenueTab(theme),
                        _buildUsersTab(theme),
                        _buildPropertiesTab(theme),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
  }

  Widget _buildPeriodChips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ..._periods.map((period) {
              final selected = _selectedPeriod == period;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _wishlistStyleChip(
                  theme: theme,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  label: _formatPeriod(period),
                  selected: selected,
                  onTap: () => _onSelectPeriod(period),
                ),
              );
            }),
            _wishlistStyleChip(
              theme: theme,
              isDark: Theme.of(context).brightness == Brightness.dark,
              label: 'Compare prev',
              selected: _comparePrev,
              onTap: () async {
                setState(() => _comparePrev = !_comparePrev);
                await _saveComparePrev(_comparePrev);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _wishlistStyleChip({
    required ThemeData theme,
    required bool isDark,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : (isDark ? theme.colorScheme.surface.withValues(alpha: 0.08) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                    blurRadius: 6,
                    offset: const Offset(-3, -3),
                  ),
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(3, 3),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // ===== Helpers: Legends and period resolution =====
  Widget _buildSeriesLegend({required Color current, Color? previous}) {
    return Row(
      children: [
        _legendEntry(current, 'Current'),
        if (_comparePrev && previous != null) _legendEntry(previous, 'Previous', dashed: true),
      ],
    );
  }

  Widget _legendEntry(Color color, String label, {bool dashed = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  int _pointsForPeriod() {
    switch (_selectedPeriod) {
      case '24h':
        return 24;
      case '7d':
        return 7;
      case '30d':
        return 30;
      case '90d':
        return 90;
      case '1y':
        return 52; // weekly or aggregated
      case 'custom':
        if (_customRange != null) {
          return _customRange!.end.difference(_customRange!.start).inDays + 1;
        }
        return 30;
      default:
        return 30;
    }
  }

  int _pointsForOccupancy() {
    switch (_selectedPeriod) {
      case '24h':
        return 7; // show a week snapshot for occupancy
      case '7d':
        return 7;
      case '30d':
        return 12; // roughly weeks
      case '90d':
        return 18; // bi-weekly
      case '1y':
        return 26; // bi-weekly
      case 'custom':
        if (_customRange != null) {
          // For simplicity, show daily points for custom as well
          return _customRange!.end.difference(_customRange!.start).inDays + 1;
        }
        return 12;
      default:
        return 12;
    }
  }
  
  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics grid skeleton
          LoadingStates.gridShimmer(context, itemCount: 4),
          const SizedBox(height: 16),
          // Revenue chart skeleton
          _buildChartSkeleton(height: 200),
          const SizedBox(height: 16),
          // Two side-by-side chart skeletons on wide screens
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: _buildChartSkeleton(height: 150)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildChartSkeleton(height: 150)),
                  ],
                );
              }
              return Column(
                children: [
                  _buildChartSkeleton(height: 150),
                  const SizedBox(height: 16),
                  _buildChartSkeleton(height: 150),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // List skeleton
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(5, (i) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SkeletonLoader(
                        width: 40,
                        height: 40,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLoader(width: 160, height: 14),
                            SizedBox(height: 6),
                            SkeletonLoader(width: 100, height: 12),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      SkeletonLoader(width: 60, height: 12),
                    ],
                  ),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSkeleton({double height = 200}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SkeletonLoader(width: double.infinity, height: height, borderRadius: const BorderRadius.all(Radius.circular(12)));
      },
    );
  }
  
  Widget _buildOverviewTab(ThemeData theme) {
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsGrid(theme),
          const SizedBox(height: 24),
          _buildRevenueChart(theme),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              if (isTablet) {
                return Row(
                  children: [
                    Expanded(child: _buildBookingTrendChart(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildUserDistributionPieChart(theme)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildBookingTrendChart(theme),
                    const SizedBox(height: 16),
                    _buildUserDistributionPieChart(theme),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          _buildTopPerformers(theme),
        ],
      ),
    );
  }
  
  Widget _buildRevenueTab(ThemeData theme) {
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRevenueChart(theme),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              if (isTablet) {
                return Row(
                  children: [
                    Expanded(child: _buildRevenueByCategory(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMonthlyComparisonChart(theme)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildRevenueByCategory(theme),
                    const SizedBox(height: 16),
                    _buildMonthlyComparisonChart(theme),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          _buildRevenueHeatmap(theme),
        ],
      ),
    );
  }
  
  Widget _buildMetricsGrid(ThemeData theme) {
    final metrics = [
      MetricCard(
        title: 'Total Revenue',
        value: CurrencyFormatter.formatPrice(45230),
        change: '+12.5%',
        isPositive: true,
        icon: Icons.attach_money,
        color: Colors.green,
      ),
      MetricCard(
        title: 'Active Users',
        value: '2,847',
        change: '+8.2%',
        isPositive: true,
        icon: Icons.people,
        color: Colors.blue,
      ),
      MetricCard(
        title: 'Bookings',
        value: '156',
        change: '+15.3%',
        isPositive: true,
        icon: Icons.book_online,
        color: Colors.orange,
      ),
      MetricCard(
        title: 'Properties',
        value: '89',
        change: '+3.1%',
        isPositive: true,
        icon: Icons.home,
        color: Colors.purple,
      ),
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        childAspectRatio: 2.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) => _buildMetricCard(metrics[index], theme),
    );
  }
  
  Widget _buildMetricCard(MetricCard metric, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced from 16 to 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(metric.icon, color: metric.color, size: 20), // Reduced icon size
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Smaller badge
                  decoration: BoxDecoration(
                    color: metric.isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    metric.change,
                    style: TextStyle(
                      color: metric.isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 10, // Smaller font
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  style: theme.textTheme.titleLarge?.copyWith( // Smaller than headlineSmall
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  metric.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 11, // Slightly smaller
                  ),
                ),
                const SizedBox(height: 8),
                _buildSparkline(metric.color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkline(Color color) {
    return SizedBox(
      height: 28,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(8, (i) => FlSpot(i.toDouble(), (i * 2 + (i % 3) * 1.5).toDouble())),
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
            ),
          ],
          minY: 0,
        ),
      ),
    );
  }

  Widget _buildRevenueChart(ThemeData theme) {
    final symbol = CurrencyFormatter.currencySymbolFor(CurrencyFormatter.defaultCurrency);
    final points = _pointsForPeriod();
    final isHourly = _selectedPeriod == '24h';
    final int step = (points / 6).ceil().clamp(1, points).toInt();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Fix broken Padding call
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Revenue Trend',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Chart actions',
                  onSelected: (value) async {
                    if (value == 'export_csv') {
                      await _exportRevenueCsv();
                    } else if (value == 'share_image') {
                      await _shareRepaintBoundaryAsImage(_revenueChartKey, 'revenue_chart.png');
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'export_csv', child: ListTile(leading: Icon(Icons.download_outlined), title: Text('Export CSV'))),
                    PopupMenuItem(value: 'share_image', child: ListTile(leading: Icon(Icons.image_outlined), title: Text('Share Image'))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedPeriod == 'custom' && _customRange != null)
              Text(
                '${_customRange!.start.month}/${_customRange!.start.day} - ${_customRange!.end.month}/${_customRange!.end.day}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            _buildSeriesLegend(current: theme.primaryColor, previous: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                key: ValueKey('revenue_${_selectedPeriod}_$_comparePrev'),
                height: 200,
                child: points <= 0
                    ? Center(child: Text('No data available for selected period', style: theme.textTheme.bodySmall))
                    : RepaintBoundary(
                  key: _revenueChartKey,
                  child: LineChart(
                    LineChartData(
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots
                          .map((s) => LineTooltipItem(
                                CurrencyFormatter.formatPrice(s.y),
                                TextStyle(color: theme.colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
                              ))
                          .toList(),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '$symbol${value ~/ 1000}k', // Use symbol here
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx % step != 0 && idx != points - 1) return const SizedBox.shrink();
                          String label;
                          if (isHourly) {
                            label = 'H${idx + 1}';
                          } else if (_selectedPeriod == 'custom' && _customRange != null) {
                            final d = _customRange!.start.add(Duration(days: idx));
                            label = '${d.month}/${d.day}';
                          } else {
                            label = 'D${idx + 1}';
                          }
                          return Text(label, style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateRevenueData(points),
                      isCurved: true,
                      color: theme.primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    if (_comparePrev)
                      LineChartBarData(
                        spots: _generateRevenueDataPrev(points),
                        isCurved: true,
                        color: theme.colorScheme.secondary,
                        barWidth: 2,
                        dashArray: const [8, 4],
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                  ],
                  ),
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformers(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Performing Properties',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  child: Text('${index + 1}'),
                ),
                title: Text('Modern Apartment ${index + 1}'),
                subtitle: const Text('Downtown District'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatPrice((2500 - index * 200).toDouble()), // Use CurrencyFormatter here
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${95 - index * 2}% occupied',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueByCategory(ThemeData theme) {
    final symbol = CurrencyFormatter.currencySymbolFor(CurrencyFormatter.defaultCurrency);
    const titles = ['Apt', 'House', 'Villa', 'Studio'];
    final current = _generateRevenueByCategoryCurrent();
    final prev = _generateRevenueByCategoryPrev();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Revenue by Property Type',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Chart actions',
                  onSelected: (value) async {
                    if (value == 'export_csv') {
                      await _exportRevenueByCategoryCsv(titles, current, prev);
                    } else if (value == 'share_image') {
                      await _shareRepaintBoundaryAsImage(_categoryChartKey, 'revenue_by_category.png');
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'export_csv', child: ListTile(leading: Icon(Icons.download_outlined), title: Text('Export CSV'))),
                    PopupMenuItem(value: 'share_image', child: ListTile(leading: Icon(Icons.image_outlined), title: Text('Share Image'))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: RepaintBoundary(
                key: _categoryChartKey,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 20000,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                          '$symbol${rod.toY.toInt()}',
                          TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(titles[value.toInt() % titles.length]);
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            '$symbol${value ~/ 1000}k',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(titles.length, (i) {
                      final rods = <BarChartRodData>[
                        BarChartRodData(toY: current[i], color: theme.primaryColor),
                      ];
                      if (_comparePrev) {
                        rods.add(BarChartRodData(toY: prev[i], color: theme.colorScheme.secondary, width: 7));
                      }
                      return BarChartGroupData(x: i, barRods: rods);
                    }),
                  ),
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }
  
  Widget _buildUsersTab(ThemeData theme) {
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildUserGrowthChart(theme),
          const SizedBox(height: 24),
          _buildUserSegmentation(theme),
        ],
      ),
    );
  }
  
  Widget _buildUserGrowthChart(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Growth',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          'W${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateUserGrowthData(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserSegmentation(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Segmentation',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSegmentItem('Property Seekers', 1847, Colors.blue, theme),
            _buildSegmentItem('Property Owners', 523, Colors.green, theme),
            _buildSegmentItem('Admin Users', 12, Colors.orange, theme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSegmentItem(String title, int count, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title),
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPropertiesTab(ThemeData theme) {
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPropertyMetrics(theme),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              if (isTablet) {
                return Row(
                  children: [
                    Expanded(child: _buildPropertyTypeDistribution(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildOccupancyTrendChart(theme)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildPropertyTypeDistribution(theme),
                    const SizedBox(height: 16),
                    _buildOccupancyTrendChart(theme),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          _buildPropertyPerformance(theme),
        ],
      ),
    );
  }
  
  Widget _buildPropertyMetrics(ThemeData theme) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        childAspectRatio: 2.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: [
        _buildPropertyMetricCard('Total Properties', '89', '+5', Colors.blue, theme),
        _buildPropertyMetricCard('Active Listings', '76', '+3', Colors.green, theme),
        _buildPropertyMetricCard('Avg. Occupancy', '78%', '+2%', Colors.orange, theme),
        _buildPropertyMetricCard('Avg. Rating', '4.6', '+0.1', Colors.purple, theme),
      ],
    );
  }
  
  Widget _buildPropertyMetricCard(String title, String value, String change, Color color, ThemeData theme) {
    return Card(
      elevation: 1, // Reduced elevation
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced from 16 to 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.home, color: color, size: 20), // Reduced icon size
                const Spacer(),
                Text(
                  change,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 10, // Smaller font
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith( // Smaller than headlineSmall
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11, // Slightly smaller
                  ),
                ),
                const SizedBox(height: 8),
                _buildSparkline(color),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPropertyPerformance(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property Performance',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) => Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  onTap: () => _showPropertyDetails(context, index),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://picsum.photos/100/100?random=$index',
                    ),
                  ),
                  title: Text('Property ${index + 1}'),
                  subtitle: Text('${85 + index * 2}% occupancy'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '4.${8 - index}★',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            CurrencyFormatter.formatPricePerUnit((150 + index * 50).toDouble(), 'month'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.analytics_outlined),
                        onPressed: () => _showPropertyAnalytics(context, index),
                        tooltip: 'View Analytics',
                      ),
                    ],
                  ),
                ),
              ),
            ),
  
          ],
        ),
      ),
    );
  }
  
  // ===== NEW CHART METHODS =====
  
  Widget _buildBookingTrendChart(ThemeData theme) {
    final points = _pointsForPeriod();
    final isHourly = _selectedPeriod == '24h';
    final int step = (points / 6).ceil().clamp(1, points).toInt();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Booking Trends', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                PopupMenuButton<String>(
                  tooltip: 'Chart actions',
                  onSelected: (value) async {
                    if (value == 'export_csv') {
                      await _exportBookingCsv();
                    } else if (value == 'share_image') {
                      await _shareRepaintBoundaryAsImage(_bookingChartKey, 'booking_trends.png');
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'export_csv', child: ListTile(leading: Icon(Icons.download_outlined), title: Text('Export CSV'))),
                    PopupMenuItem(value: 'share_image', child: ListTile(leading: Icon(Icons.image_outlined), title: Text('Share Image'))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedPeriod == 'custom' && _customRange != null)
              Text(
                '${_customRange!.start.month}/${_customRange!.start.day} - ${_customRange!.end.month}/${_customRange!.end.day}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            _buildSeriesLegend(current: Colors.orange, previous: theme.colorScheme.secondary),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                key: ValueKey('booking_${_selectedPeriod}_$_comparePrev'),
                height: 150,
                child: points <= 0
                    ? Center(child: Text('No data available for selected period', style: theme.textTheme.bodySmall))
                    : RepaintBoundary(
                  key: _bookingChartKey,
                  child: LineChart(
                    LineChartData(
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) => touchedSpots
                            .map((s) => LineTooltipItem(
                                  s.y.toInt().toString(),
                                  TextStyle(color: theme.colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
                                ))
                            .toList(),
                      ),
                    ),
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
                      )),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx % step != 0 && idx != points - 1) return const SizedBox.shrink();
                          String label;
                          if (isHourly) {
                            label = '${idx + 1}h';
                          } else if (_selectedPeriod == 'custom' && _customRange != null) {
                            final d = _customRange!.start.add(Duration(days: idx));
                            label = '${d.month}/${d.day}';
                          } else {
                            label = '${idx + 1}d';
                          }
                          return Text(label, style: const TextStyle(fontSize: 10));
                        },
                      )),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _generateBookingData(points),
                        isCurved: true,
                        color: Colors.orange,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: Colors.orange.withValues(alpha: 0.1)),
                      ),
                      if (_comparePrev)
                        LineChartBarData(
                          spots: _generateBookingDataPrev(points),
                          isCurved: true,
                          color: theme.colorScheme.secondary,
                          barWidth: 2,
                          dashArray: const [8, 4],
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDistributionPieChart(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Distribution', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(value: 70, color: Colors.blue, title: '70%', titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    PieChartSectionData(value: 25, color: Colors.green, title: '25%', titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    PieChartSectionData(value: 5, color: Colors.orange, title: '5%', titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Seekers', Colors.blue),
                _buildLegendItem('Owners', Colors.green),
                _buildLegendItem('Admin', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyComparisonChart(ThemeData theme) {
    final symbol = CurrencyFormatter.currencySymbolFor(CurrencyFormatter.defaultCurrency);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final current = _generateMonthlyComparisonCurrent();
    final prev = _generateMonthlyComparisonPrev();
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Monthly Comparison', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Chart actions',
                  onSelected: (value) async {
                    if (value == 'export_csv') {
                      await _exportMonthlyComparisonCsv(months, current, prev);
                    } else if (value == 'share_image') {
                      await _shareRepaintBoundaryAsImage(_monthlyChartKey, 'monthly_comparison.png');
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'export_csv', child: ListTile(leading: Icon(Icons.download_outlined), title: Text('Export CSV'))),
                    PopupMenuItem(value: 'share_image', child: ListTile(leading: Icon(Icons.image_outlined), title: Text('Share Image'))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: RepaintBoundary(
                key: _monthlyChartKey,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 25000,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                          CurrencyFormatter.formatPrice(rod.toY),
                          TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(months[value.toInt() % months.length], style: const TextStyle(fontSize: 10));
                        },
                      )),
                      leftTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text('$symbol${value ~/ 1000}k', style: const TextStyle(fontSize: 10)),
                      )),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(months.length, (index) {
                      final rods = <BarChartRodData>[
                        BarChartRodData(toY: current[index], color: theme.primaryColor),
                      ];
                      if (_comparePrev) {
                        rods.add(BarChartRodData(toY: prev[index], color: theme.colorScheme.secondary, width: 7));
                      }
                      return BarChartGroupData(x: index, barRods: rods);
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueHeatmap(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revenue Heatmap (Last 30 Days)', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: 28,
                itemBuilder: (context, index) {
                  final intensity = (index % 5) / 4.0;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2 + intensity * 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text('${index + 1}', style: TextStyle(fontSize: 10, color: intensity > 0.5 ? Colors.white : Colors.black54)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyTypeDistribution(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Property Types', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: [
                    PieChartSectionData(value: 45, color: Colors.blue, title: '45%', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    PieChartSectionData(value: 30, color: Colors.green, title: '30%', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    PieChartSectionData(value: 15, color: Colors.orange, title: '15%', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    PieChartSectionData(value: 10, color: Colors.purple, title: '10%', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildLegendItem('Apartments', Colors.blue),
                _buildLegendItem('Houses', Colors.green),
                _buildLegendItem('Villas', Colors.orange),
                _buildLegendItem('Studios', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyTrendChart(ThemeData theme) {
    final points = _pointsForOccupancy();
    final int step = (points / 6).ceil().clamp(1, points).toInt();
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Occupancy Trend', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                PopupMenuButton<String>(
                  tooltip: 'Chart actions',
                  onSelected: (value) async {
                    if (value == 'export_csv') {
                      await _exportOccupancyCsv();
                    } else if (value == 'share_image') {
                      await _shareRepaintBoundaryAsImage(_occupancyChartKey, 'occupancy_trend.png');
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'export_csv', child: ListTile(leading: Icon(Icons.download_outlined), title: Text('Export CSV'))),
                    PopupMenuItem(value: 'share_image', child: ListTile(leading: Icon(Icons.image_outlined), title: Text('Share Image'))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedPeriod == 'custom' && _customRange != null)
              Text(
                '${_customRange!.start.month}/${_customRange!.start.day} - ${_customRange!.end.month}/${_customRange!.end.day}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            _buildSeriesLegend(current: Colors.purple, previous: theme.colorScheme.secondary),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                key: ValueKey('occupancy_${_selectedPeriod}_$_comparePrev'),
                height: 150,
                child: points <= 0
                    ? Center(child: Text('No data available for selected period', style: theme.textTheme.bodySmall))
                    : RepaintBoundary(
                  key: _occupancyChartKey,
                  child: LineChart(
                    LineChartData(
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: const TextStyle(fontSize: 10)),
                      )),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx % step != 0 && idx != points - 1) return const SizedBox.shrink();
                          String label;
                          if (_selectedPeriod == 'custom' && _customRange != null) {
                            final d = _customRange!.start.add(Duration(days: idx));
                            label = '${d.month}/${d.day}';
                          } else {
                            label = 'W${idx + 1}';
                          }
                          return Text(label, style: const TextStyle(fontSize: 10));
                        },
                      )),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _generateOccupancyData(points),
                        isCurved: true,
                        color: Colors.purple,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: Colors.purple.withValues(alpha: 0.1)),
                      ),
                      if (_comparePrev)
                        LineChartBarData(
                          spots: _generateOccupancyDataPrev(points),
                          isCurved: true,
                          color: theme.colorScheme.secondary,
                          barWidth: 2,
                          dashArray: const [8, 4],
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ],
        ),
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

  // ===== DATA GENERATION METHODS =====
  
  List<FlSpot> _generateRevenueData([int points = 7]) {
    return List.generate(points, (index) {
      final y = 5000 + (index * 1000) + (index % 2 * 500);
      return FlSpot(index.toDouble(), y.toDouble());
    });
  }

  List<FlSpot> _generateRevenueDataPrev([int points = 7]) {
    // Simulate previous period with slightly lower values and variation
    return List.generate(points, (index) {
      final y = 4800 + (index * 900) + ((index + 1) % 3 * 400);
      return FlSpot(index.toDouble(), y.toDouble());
    });
  }

  Future<void> _exportRevenueCsv() async {
    try {
      final n = _pointsForPeriod();
      final current = _generateRevenueData(n);
      final prev = _generateRevenueDataPrev(n);
      final isHourly = _selectedPeriod == '24h';
      final useDates = _selectedPeriod == 'custom' && _customRange != null;
      final header = isHourly ? 'Hour' : (useDates ? 'Date' : 'Day');
      final symbol = CurrencyFormatter.currencySymbolFor(CurrencyFormatter.defaultCurrency);
      final buffer = StringBuffer('$header,Current($symbol),Previous($symbol)\n');
      for (var i = 0; i < current.length; i++) {
        final c = current[i].y.toStringAsFixed(2);
        final p = i < prev.length ? prev[i].y.toStringAsFixed(2) : '';
        String label;
        if (useDates) {
          final d = _customRange!.start.add(Duration(days: i));
          label = _csvDate(d);
        } else if (isHourly) {
          label = '${i + 1}';
        } else {
          label = '${i + 1}';
        }
        buffer.writeln('$label,$c,$p');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/revenue_export.csv');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'Revenue data export');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
      );
    }
  }

  Future<void> _shareRepaintBoundaryAsImage(GlobalKey key, String filename) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw 'Chart not ready yet';
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Analytics chart');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share image: $e')),
      );
    }
  }

  List<FlSpot> _generateBookingData([int points = 7]) {
    return List.generate(points, (index) {
      final y = 10 + (index * 3) + (index % 3 * 2);
      return FlSpot(index.toDouble(), y.toDouble());
    });
  }

  List<FlSpot> _generateOccupancyData([int points = 8]) {
    return List.generate(points, (index) {
      final y = 65 + (index * 2) + (index % 2 * 5);
      return FlSpot(index.toDouble(), y.toDouble());
    });
  }

  // ===== ADDED: PREVIOUS/COMPARE DATA + EXPORT HELPERS =====

  // Booking compare (previous period)
  List<FlSpot> _generateBookingDataPrev([int points = 7]) {
    return List.generate(points, (index) {
      final y = 9 + (index * 2.6) + ((index + 1) % 3 * 1.5);
      return FlSpot(index.toDouble(), y.toDouble());
    });
  }

  Future<void> _exportBookingCsv() async {
    try {
      final n = _pointsForPeriod();
      final current = _generateBookingData(n);
      final prev = _generateBookingDataPrev(n);
      final isHourly = _selectedPeriod == '24h';
      final useDates = _selectedPeriod == 'custom' && _customRange != null;
      final header = isHourly ? 'Hour' : (useDates ? 'Date' : 'Day');
      final buffer = StringBuffer('$header,Current,Previous\n');
      for (var i = 0; i < current.length; i++) {
        final c = current[i].y.toStringAsFixed(0);
        final p = i < prev.length ? prev[i].y.toStringAsFixed(0) : '';
        String label;
        if (useDates) {
          final d = _customRange!.start.add(Duration(days: i));
          label = _csvDate(d);
        } else if (isHourly) {
          label = '${i + 1}';
        } else {
          label = '${i + 1}';
        }
        buffer.writeln('$label,$c,$p');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/booking_trends.csv');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'Booking trends export');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
      );
    }
  }

  // Occupancy compare
  List<FlSpot> _generateOccupancyDataPrev([int points = 8]) {
    return List.generate(points, (index) {
      final y = 63 + (index * 1.8) + ((index + 1) % 2 * 4);
      return FlSpot(index.toDouble(), y.toDouble());
    });
  }

  Future<void> _exportOccupancyCsv() async {
    try {
      final n = _pointsForOccupancy();
      final current = _generateOccupancyData(n);
      final prev = _generateOccupancyDataPrev(n);
      final useDates = _selectedPeriod == 'custom' && _customRange != null;
      final header = useDates ? 'Date' : 'Week';
      final buffer = StringBuffer('$header,Current(%),Previous(%)\n');
      for (var i = 0; i < current.length; i++) {
        final c = current[i].y.toStringAsFixed(1);
        final p = i < prev.length ? prev[i].y.toStringAsFixed(1) : '';
        String label;
        if (useDates) {
          final d = _customRange!.start.add(Duration(days: i));
          label = _csvDate(d);
        } else {
          label = '${i + 1}';
        }
        buffer.writeln('$label,$c,$p');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/occupancy_trend.csv');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'Occupancy trend export');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
      );
    }
  }

  // Monthly comparison (bar) datasets
  List<double> _generateMonthlyComparisonCurrent() {
    return List.generate(6, (index) => (15000 + index * 2000).toDouble());
  }

  List<double> _generateMonthlyComparisonPrev() {
    return List.generate(6, (index) => (14000 + index * 1800).toDouble());
  }

  Future<void> _exportMonthlyComparisonCsv(List<String> months, List<double> current, List<double> prev) async {
    try {
      final symbol = CurrencyFormatter.currencySymbolFor(CurrencyFormatter.defaultCurrency);
      final buffer = StringBuffer('Month,Current($symbol),Previous($symbol)\n');
      for (var i = 0; i < months.length; i++) {
        final c = i < current.length ? current[i].toStringAsFixed(2) : '';
        final p = i < prev.length ? prev[i].toStringAsFixed(2) : '';
        buffer.writeln('${months[i]},$c,$p');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/monthly_comparison.csv');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'Monthly comparison export');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
      );
    }
  }

  // Revenue by category datasets
  List<double> _generateRevenueByCategoryCurrent() {
    return [15000.0, 12000.0, 18000.0, 8000.0];
  }

  List<double> _generateRevenueByCategoryPrev() {
    return [14000.0, 11000.0, 16500.0, 7500.0];
  }

  Future<void> _exportRevenueByCategoryCsv(List<String> titles, List<double> current, List<double> prev) async {
    try {
      final symbol = CurrencyFormatter.currencySymbolFor(CurrencyFormatter.defaultCurrency);
      final buffer = StringBuffer('Category,Current($symbol),Previous($symbol)\n');
      for (var i = 0; i < titles.length; i++) {
        final c = i < current.length ? current[i].toStringAsFixed(2) : '';
        final p = i < prev.length ? prev[i].toStringAsFixed(2) : '';
        buffer.writeln('${titles[i]},$c,$p');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/revenue_by_category.csv');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'Revenue by category export');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
      );
    }
  }
  
  List<FlSpot> _generateUserGrowthData() {
    return List.generate(12, (index) {
      return FlSpot(index.toDouble(), 100 + (index * 50) + (index % 3 * 20));
    });
  }
  
  String _formatPeriod(String period) {
    switch (period) {
      case '24h': return 'Last 24 Hours';
      case '7d': return 'Last 7 Days';
      case '30d': return 'Last 30 Days';
      case '90d': return 'Last 90 Days';
      case '1y': return 'Last Year';
      case 'custom':
        if (_customRange != null) {
          final s = _customRange!.start;
          final e = _customRange!.end;
          return 'Custom: ${s.month}/${s.day} - ${e.month}/${e.day}';
        }
        return 'Custom';
      default: return period;
    }
  }

  String _csvDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // ===== BUTTON FUNCTIONALITY METHODS =====
  
  void _showPropertyDetails(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Property ${index + 1} Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Occupancy: ${85 + index * 2}%'),
              Text('Rating: 4.${8 - index}★'),
              Text('Price: ${CurrencyFormatter.formatPricePerUnit((150 + index * 50).toDouble(), 'month')}'),
              const SizedBox(height: 16),
              const Text('Recent Performance:'),
              const Text('• 12 bookings this month'),
              const Text('• Average stay: 3.5 nights'),
              const Text('• Revenue: \$4,200'),
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
                // Navigate to detailed property view
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to property details...')),
                );
              },
              child: const Text('View Full Details'),
            ),
          ],
        );
      },
    );
  }

  void _showPropertyAnalytics(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Property ${index + 1} Analytics',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          // Quick stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickStat('Revenue', '\$${4200 + index * 500}', Icons.attach_money),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickStat('Bookings', '${12 + index * 2}', Icons.book_online),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Mini chart
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Revenue Trend (Last 7 Days)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 150,
                                    child: LineChart(
                                      LineChartData(
                                        gridData: const FlGridData(show: false),
                                        titlesData: const FlTitlesData(show: false),
                                        borderData: FlBorderData(show: false),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: List.generate(7, (i) => FlSpot(i.toDouble(), 100 + i * 20 + index * 10)),
                                            isCurved: true,
                                            color: Theme.of(context).primaryColor,
                                            barWidth: 3,
                                            dotData: const FlDotData(show: false),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickStat(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class MetricCard {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });
}
