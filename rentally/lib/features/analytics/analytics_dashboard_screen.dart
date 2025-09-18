import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
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
  
  final List<String> _periods = ['24h', '7d', '30d', '90d', '1y'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
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
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TabBackHandler(
      tabController: _tabController,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (period) {
              setState(() => _selectedPeriod = period);
              _loadAnalytics();
            },
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
          : TabBarView(
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
    ),
  );
  }
  
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading analytics...'),
        ],
      ),
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
          _buildRevenueByCategory(theme),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) => _buildMetricCard(metrics[index], theme),
    );
  }
  
  Widget _buildMetricCard(MetricCard metric, ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(metric.icon, color: metric.color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: metric.isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    metric.change,
                    style: TextStyle(
                      color: metric.isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              metric.value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              metric.title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(ThemeData theme) {
    final symbol = CurrencyFormatter.currencySymbolFor(CurrencyFormatter.defaultCurrency);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Fix broken Padding call
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Trend',
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
                          '$symbol${value ~/ 1000}k', // Use symbol here
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          'Day ${value.toInt()}',
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
                      spots: _generateRevenueData(),
                      isCurved: true,
                      color: theme.primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.primaryColor.withOpacity(0.1),
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

  Widget _buildTopPerformers(ThemeData theme) {
    return Card(
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
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue by Property Type',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 20000,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = ['Apt', 'House', 'Villa', 'Studio'];
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
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 15000, color: Colors.blue)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 12000, color: Colors.green)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 18000, color: Colors.orange)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 8000, color: Colors.purple)]),
                  ],
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
          _buildPropertyPerformance(theme),
        ],
      ),
    );
  }
  
  Widget _buildPropertyMetrics(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.home, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall,
            ),
            Text(
              change,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
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
              itemBuilder: (context, index) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://picsum.photos/100/100?random=$index',
                  ),
                ),
                title: Text('Property ${index + 1}'),
                subtitle: Text('${85 + index * 2}% occupancy'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '4.${8 - index}★',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyFormatter.formatPricePerUnit((150 + index * 50).toDouble(), 'night'),
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
  
  List<FlSpot> _generateRevenueData() {
    return List.generate(7, (index) {
      return FlSpot(index.toDouble(), 5000 + (index * 1000) + (index % 2 * 500));
    });
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
      default: return period;
    }
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
