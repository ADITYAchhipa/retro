// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/loading_states.dart';
import '../../core/providers/ui_visibility_provider.dart';

import '../../widgets/responsive_layout.dart';
// Uses a local _showAddListingDialog() to open the add selector dialog
import '../../widgets/error_boundary.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';
import '../../core/config/production_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../services/monetization_service.dart';
import '../../models/monetization_models.dart';
import '../../services/owner_activity_service.dart';
import '../../core/widgets/tab_back_handler.dart';
import '../../app/app_state.dart';
import '../../services/owner_earnings_service.dart';
import '../../services/kyc/kyc_service.dart';

/// **CleanOwnerDashboardScreen**
/// 
/// Clean owner dashboard with comprehensive business management features
/// 
/// **Features:**
/// - Responsive design for all screen sizes
/// - Error boundaries with crash protection
/// - Real-time analytics and earnings tracking
/// - Property management integration
/// - Booking request handling
/// - Performance metrics visualization
class CleanOwnerDashboardScreen extends ConsumerStatefulWidget {
  const CleanOwnerDashboardScreen({super.key});

  @override
  ConsumerState<CleanOwnerDashboardScreen> createState() => _CleanOwnerDashboardScreenState();
}

class _CleanOwnerDashboardScreenState extends ConsumerState<CleanOwnerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  
  bool _isLoading = false;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  bool _earningsShowNet = true;
  int? _earningsHoverIndex; // for crosshair highlight
  
  // New time-range selection for the earnings chart
  int _earningsDays = 30; // Supported presets: 7, 30, 90; custom uses _earningsCustomRange
  DateTimeRange? _earningsCustomRange;
  
  // Pref keys for persisting the selection
  static const String _kEarningsDaysKey = 'owner_earnings_days';
  static const String _kEarningsCustomStartKey = 'owner_earnings_custom_start';
  static const String _kEarningsCustomEndKey = 'owner_earnings_custom_end';
  // Earnings data state
  bool _comparePrevious = false;
  bool _earningsDataLoading = false;
  String? _earningsDataError;
  List<double> _seriesGross = [];
  List<double> _seriesPrevGross = [];
  List<String> _seriesLabels = [];
  
  // Mock dashboard data
  final Map<String, dynamic> _dashboardData = {
    'totalEarnings': 15420.50,
    'monthlyEarnings': 3240.75,
    'totalBookings': 127,
    'activeListings': 8,
    'pendingRequests': 5,
    'averageRating': 4.8,
    'occupancyRate': 0.85,
    // Added for overview metrics and deltas
    'conversionRate': 0.25, // 25%
    'healthScore': 0.85,    // 85%
    'monthlyEarningsChange': 0.12,     // +12%
    'conversionRateChange': 0.032,     // +3.2%
    // Earnings-specific mock data
    'monthlyBookings': 18,
    'refundsCount': 1,
    'refundsAmount': 120.0,
    'pendingPayouts': 5400.0,
    'lastPayoutAmount': 2100.0,
    'lastPayoutDate': '2024-01-22',
    'nextPayoutEtaDays': 5,
    'recentBookings': [
      {
        'id': '1',
        'guestName': 'John Doe',
        'propertyTitle': 'Modern Downtown Apartment',
        'checkIn': '2024-01-15',
        'checkOut': '2024-01-18',
        'amount': 450.0,
        'status': 'confirmed',
      },
      {
        'id': '2',
        'guestName': 'Sarah Wilson',
        'propertyTitle': 'Cozy Beach House',
        'checkIn': '2024-01-20',
        'checkOut': '2024-01-25',
        'amount': 750.0,
        'status': 'pending',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _loadDashboardData();
    _loadEarningsRangePrefs();
    _loadGrowthTaskState();
  }

  Widget _buildCommissionSummary(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final monet = ref.watch(monetizationServiceProvider);
    final rate = _currentCommissionRate(monet);
    // Cache locale-aware date formatter once for performance
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.MMMd(locale);
    // Use a compact header action on ultra-narrow widths; computed per-header via LayoutBuilder below
    final all = [...monet.transactions.where((t) => t.type == TransactionType.commission)];
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = all.take(5).toList();

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final mtd = all
        .where((t) => !t.createdAt.isBefore(startOfMonth))
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    String fmtDate(DateTime d) => dateFmt.format(d);

    Widget row({required IconData icon, required Color color, required String label, required String value}) {
      return Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, cons) {
                final headerCompact = cons.maxWidth < 360;
                final veryNarrow = cons.maxWidth < 300;
                return Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        label: 'Commission Summary',
                        child: Text(
                          'Commission Summary',
                          style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                    if (headerCompact)
                      IconButton(
                        tooltip: 'View all',
                        onPressed: () {
                          ref.read(immersiveRouteOpenProvider.notifier).state = true;
                          context.push('/transactions').whenComplete(() {
                            if (!mounted) return;
                            ref.read(immersiveRouteOpenProvider.notifier).state = false;
                          });
                        },
                        icon: const Icon(Icons.receipt_long_outlined, size: 18),
                        color: theme.colorScheme.primary,
                      )
                    else
                      TextButton.icon(
                        onPressed: () {
                          ref.read(immersiveRouteOpenProvider.notifier).state = true;
                          context.push('/transactions').whenComplete(() {
                            if (!mounted) return;
                            ref.read(immersiveRouteOpenProvider.notifier).state = false;
                          });
                        },
                        icon: const Icon(Icons.receipt_long_outlined, size: 18),
                        label: Text(veryNarrow ? 'All' : 'View all'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          padding: EdgeInsets.symmetric(horizontal: isPhone ? 6 : 10, vertical: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: isPhone ? 6 : 8),
            row(
              icon: Icons.percent,
              color: Colors.redAccent,
              label: 'Current commission rate',
              value: '${(rate * 100).toStringAsFixed(0)}% applied on host gross',
            ),
            const SizedBox(height: 6),
            row(
              icon: Icons.stacked_line_chart,
              color: Colors.orange,
              label: 'Month-to-date commissions',
              value: '-${CurrencyFormatter.formatPrice(mtd)}',
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              Text('No commission transactions yet', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor))
            else ...[
              Text('Recent', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...recent.map((t) {
                final bookingId = t.metadata != null ? (t.metadata!['booking_id']?.toString() ?? '-') : '-';
                final rUsed = t.metadata != null ? (t.metadata!['rate'] as num?)?.toDouble() : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.percent, color: Colors.redAccent, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking ${bookingId == '-' ? '' : '#$bookingId'}',
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                            Text(
                              '${fmtDate(t.createdAt)} • ${rUsed != null ? '${(rUsed * 100).toStringAsFixed(0)}% rate' : 'commission'}',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '-${CurrencyFormatter.formatPrice(t.amount)}',
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _refreshEarningsData() async {
    // Determine selected date range
    DateTime startDate;
    DateTime endDate;
    if (_earningsCustomRange != null) {
      final range = _earningsCustomRange!;
      startDate = DateTime(range.start.year, range.start.month, range.start.day);
      endDate = DateTime(range.end.year, range.end.month, range.end.day);
    } else {
      final today = DateTime.now();
      endDate = DateTime(today.year, today.month, today.day);
      startDate = endDate.subtract(Duration(days: _earningsDays - 1));
    }

    setState(() {
      _earningsDataLoading = true;
      _earningsDataError = null;
    });

    try {
      // Capture any context-dependent values BEFORE awaits
      final capturedLocale = Localizations.localeOf(context).toString();
      final df = DateFormat.MMMd(capturedLocale);

      final service = OwnerEarningsService.instance;
      final currentGross = await service.getDailyGross(start: startDate, end: endDate);

      // Previous period
      final prevStart = startDate.subtract(Duration(days: currentGross.length));
      final prevEnd = startDate.subtract(const Duration(days: 1));
      final prevGross = await service.getDailyGross(start: prevStart, end: prevEnd);

      // Build labels and aggregate if needed
      final int days = currentGross.length;

      if (days > 120) {
        // Weekly aggregation
        final aggCurr = _aggregateWeekly(currentGross);
        final aggPrev = _aggregateWeekly(prevGross);
        final weeks = aggCurr.length;
        final labels = List.generate(weeks, (i) {
          final d = startDate.add(Duration(days: i * 7));
          return df.format(d);
        });
        if (!mounted) return;
        setState(() {
          _seriesGross = aggCurr;
          _seriesPrevGross = aggPrev;
          _seriesLabels = labels;
          _earningsDataLoading = false;
        });
      } else {
        final labels = List.generate(days, (i) => df.format(startDate.add(Duration(days: i))));
        if (!mounted) return;
        setState(() {
          _seriesGross = currentGross;
          _seriesPrevGross = prevGross;
          _seriesLabels = labels;
          _earningsDataLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _earningsDataLoading = false;
        _earningsDataError = 'Failed to load earnings: $e';
      });
    }
  }

  List<double> _aggregateWeekly(List<double> daily) {
    final List<double> out = [];
    for (int i = 0; i < daily.length; i += 7) {
      final end = (i + 7 < daily.length) ? i + 7 : daily.length;
      double sum = 0;
      for (int j = i; j < end; j++) {
        sum += daily[j];
      }
      out.add(sum);
    }
    return out;
  }

  Future<void> _loadEarningsRangePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDays = prefs.getInt(_kEarningsDaysKey);
      final startMs = prefs.getInt(_kEarningsCustomStartKey);
      final endMs = prefs.getInt(_kEarningsCustomEndKey);
      if (!mounted) return;
      setState(() {
        if (savedDays != null && (savedDays == 7 || savedDays == 30 || savedDays == 90)) {
          _earningsDays = savedDays;
        }
        if (startMs != null && endMs != null && endMs >= startMs) {
          final start = DateTime.fromMillisecondsSinceEpoch(startMs);
          final end = DateTime.fromMillisecondsSinceEpoch(endMs);
          _earningsCustomRange = DateTimeRange(start: start, end: end);
          _earningsDays = end.difference(DateTime(start.year, start.month, start.day)).inDays + 1;
        }
      });
      // Refresh series after loading prefs
      await _refreshEarningsData();
    } catch (_) {
      // ignore errors, keep defaults
    }
  }

  Future<void> _saveEarningsRangePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kEarningsDaysKey, _earningsDays);
      if (_earningsCustomRange != null) {
        await prefs.setInt(_kEarningsCustomStartKey, DateTime(_earningsCustomRange!.start.year, _earningsCustomRange!.start.month, _earningsCustomRange!.start.day).millisecondsSinceEpoch);
        await prefs.setInt(_kEarningsCustomEndKey, DateTime(_earningsCustomRange!.end.year, _earningsCustomRange!.end.month, _earningsCustomRange!.end.day).millisecondsSinceEpoch);
      } else {
        await prefs.remove(_kEarningsCustomStartKey);
        await prefs.remove(_kEarningsCustomEndKey);
      }
    } catch (_) {
      // ignore persistence errors
    }
  }

  Widget _buildMiniTrendIcon(bool positive) {
    return Icon(
      positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
      size: 12,
      color: positive ? Colors.green : Colors.red,
    );
  }

  Widget _legendChip({required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _shareEarningsPdf() async {
    final file = await _exportEarningsPdf();
    if (file == null) return;
    await Share.shareXFiles([XFile(file.path)], text: 'Earnings Statement');
  }

  Future<File?> _exportEarningsPdf() async {
    try {
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/earnings_statement_$ts.pdf');

      final monthly = (_dashboardData['monthlyEarnings'] as num).toDouble();
      final total = (_dashboardData['totalEarnings'] as num).toDouble();
      final bookings = (_dashboardData['monthlyBookings'] as num?)?.toDouble() ?? 0;
      final aov = bookings > 0 ? (monthly / bookings) : 0.0;
      final refunds = (_dashboardData['refundsAmount'] as num?)?.toDouble() ?? 0.0;
      final rate = _currentCommissionRate(ref.watch(monetizationServiceProvider));
      final commission = monthly * rate;
      final taxes = (monthly - commission) * 0.18;
      final net = monthly - commission - taxes;

      // Data for trend table
      final data = _mockEarningsLast6Months();
      final now = DateTime.now();
      final labels = List.generate(6, (i) => DateFormat('yyyy-MM').format(DateTime(now.year, now.month - (5 - i), 1)));

      final pdf = pw.Document();
      pw.MemoryImage? logoImg;
      try {
        final logoData = await rootBundle.load('assets/icons/app_icon.png');
        logoImg = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (_) {}

      pw.Widget header() => pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImg != null)
                pw.Container(
                  width: 32,
                  height: 32,
                  margin: const pw.EdgeInsets.only(right: 10),
                  child: pw.Image(logoImg),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Earnings Statement', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Generated: ${DateFormat.yMMMd().add_jm().format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                ],
              )
            ],
          );

      pw.Widget kpiRow() => pw.Wrap(spacing: 12, runSpacing: 12, children: [
            _pdfKpi('Monthly', CurrencyFormatter.formatPrice(monthly)),
            _pdfKpi('Total', CurrencyFormatter.formatPrice(total)),
            _pdfKpi('AOV', CurrencyFormatter.formatPrice(aov)),
            _pdfKpi('Refunds', CurrencyFormatter.formatPrice(refunds)),
          ]);

      final trendTable = pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
        cellAlignment: pw.Alignment.centerLeft,
        headerAlignment: pw.Alignment.centerLeft,
        headers: ['Month', 'Earnings'],
        data: [
          for (int i = 0; i < labels.length; i++) [labels[i], CurrencyFormatter.formatPrice(data[i])]
        ],
      );

      final breakdownTable = pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.lightBlue),
        cellAlignment: pw.Alignment.centerLeft,
        headers: ['Metric', 'Value'],
        data: [
          ['Commission (${(rate * 100).toStringAsFixed(0)}%)', '-${CurrencyFormatter.formatPrice(commission)}'],
          ['Taxes (18%)', '-${CurrencyFormatter.formatPrice(taxes)}'],
          ['Net', CurrencyFormatter.formatPrice(net)],
        ],
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            header(),
            pw.SizedBox(height: 12),
            kpiRow(),
            pw.SizedBox(height: 16),
            pw.Text('Monthly Trend', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            trendTable,
            pw.SizedBox(height: 16),
            pw.Text('Breakdown', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            breakdownTable,
          ],
        ),
      );

      await file.writeAsBytes(await pdf.save());
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF exported to ${file.path}')),
      );
      return file;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $e')),
      );
      return null;
    }
  }

  pw.Widget _pdfKpi(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ]),
    );
  }

  Future<void> _exportEarningsCsv() async {
    try {
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/earnings_export_$ts.csv');

      final monthly = (_dashboardData['monthlyEarnings'] as num).toDouble();
      final total = (_dashboardData['totalEarnings'] as num).toDouble();
      final bookings = (_dashboardData['monthlyBookings'] as num?)?.toDouble() ?? 0;
      final aov = bookings > 0 ? (monthly / bookings) : 0.0;
      final refunds = (_dashboardData['refundsAmount'] as num?)?.toDouble() ?? 0.0;

      final rate = _currentCommissionRate(ref.watch(monetizationServiceProvider));
      final commission = monthly * rate;
      final taxes = (monthly - commission) * 0.18;
      final net = monthly - commission - taxes;

      // Chart data for last 6 months (oldest to latest)
      final data = _mockEarningsLast6Months();
      final now = DateTime.now();
      const header = 'date,label,amount\n';
      final buffer = StringBuffer(header);
      for (int i = 0; i < data.length; i++) {
        final date = DateTime(now.year, now.month - (5 - i), 1);
        final dateStr = DateFormat('yyyy-MM').format(date);
        buffer.writeln('$dateStr,Monthly Earnings,${data[i].toStringAsFixed(2)}');
      }
      buffer.writeln(',,');
      buffer.writeln('metric,value');
      buffer.writeln('Total Earnings,${total.toStringAsFixed(2)}');
      buffer.writeln('Monthly Earnings,${monthly.toStringAsFixed(2)}');
      buffer.writeln('AOV,${aov.toStringAsFixed(2)}');
      buffer.writeln('Refunds,${refunds.toStringAsFixed(2)}');
      buffer.writeln('Commission (${(rate * 100).toStringAsFixed(0)}%),${commission.toStringAsFixed(2)}');
      buffer.writeln('Taxes (18%),${taxes.toStringAsFixed(2)}');
      buffer.writeln('Net,${net.toStringAsFixed(2)}');

      await file.writeAsString(buffer.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exported to ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export: $e')),
      );
    }
  }

  // Smooth number tweener used for animated stat values
  Widget _animatedCounterText({required double target, required Widget Function(double v) builder, Duration duration = const Duration(milliseconds: 800)}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => builder(value),
    );
  }

  // Skeletons for other tabs while loading
  Widget _buildEarningsSkeleton(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final bottomPad = (isPhone ? 56.0 : 72.0) + MediaQuery.of(context).padding.bottom + (isPhone ? 8.0 : 12.0);
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: isPhone ? 12 : 16,
            right: isPhone ? 12 : 16,
            bottom: bottomPad,
          ),
          child: Column(
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(isPhone ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLoader(width: 180, height: 18, borderRadius: BorderRadius.all(Radius.circular(6))),
                      SizedBox(height: isPhone ? 8 : 12),
                      const SkeletonLoader(width: double.infinity, height: 180, borderRadius: BorderRadius.all(Radius.circular(12))),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isPhone ? 12 : 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(isPhone ? 12 : 16),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(width: 160, height: 18, borderRadius: BorderRadius.all(Radius.circular(6))),
                      SizedBox(height: 10),
                      SkeletonLoader(width: 180, height: 14, borderRadius: BorderRadius.all(Radius.circular(6))),
                      SizedBox(height: 8),
                      SkeletonLoader(width: 160, height: 14, borderRadius: BorderRadius.all(Radius.circular(6))),
                      SizedBox(height: 8),
                      SkeletonLoader(width: 140, height: 14, borderRadius: BorderRadius.all(Radius.circular(6))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  

  Widget _buildGrowSkeleton(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final bottomPad = MediaQuery.of(context).padding.bottom + (isPhone ? 6.0 : 12.0);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: isPhone ? 12 : 16,
        right: isPhone ? 12 : 16,
        bottom: bottomPad,
      ),
      child: Column(
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(isPhone ? 12 : 16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: 200, height: 18, borderRadius: BorderRadius.all(Radius.circular(6))),
                  SizedBox(height: 10),
                  SkeletonLoader(width: double.infinity, height: 100, borderRadius: BorderRadius.all(Radius.circular(8))),
                ],
              ),
            ),
          ),
          SizedBox(height: isPhone ? 12 : 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(isPhone ? 12 : 16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: 220, height: 18, borderRadius: BorderRadius.all(Radius.circular(6))),
                  SizedBox(height: 10),
                  SkeletonLoader(width: double.infinity, height: 44, borderRadius: BorderRadius.all(Radius.circular(10))),
                ],
              ),
            ),
          ),
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

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock data is already loaded
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard: $error')),
      );
    }
  }

  // -------------------- Grow Tab: Checklist State --------------------
  static const String _prefsKeyGrowthTasksDone = 'owner_growth_tasks_done';
  final List<Map<String, String>> _growthTasks = const [
    {'id': 'photos', 'title': 'Add 8+ high-quality photos for each listing'},
    {'id': 'desc', 'title': 'Complete descriptions (amenities, house rules)'},
    {'id': 'discounts', 'title': 'Set weekly/monthly discounts'},
    {'id': 'instant', 'title': 'Enable instant booking'},
    {'id': 'response', 'title': 'Respond within 15 minutes (notifications on)'},
    {'id': 'reviews', 'title': 'Request 5 reviews from recent guests'},
  ];
  Set<String> _completedGrowthTaskIds = {};

  Future<void> _loadGrowthTaskState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKeyGrowthTasksDone) ?? [];
      if (!mounted) return;
      setState(() => _completedGrowthTaskIds = list.toSet());
    } catch (_) {}
  }

  Future<void> _toggleGrowthTask(String id, bool? value) async {
    setState(() {
      if (value == true) {
        _completedGrowthTaskIds.add(id);
      } else {
        _completedGrowthTaskIds.remove(id);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKeyGrowthTasksDone, _completedGrowthTaskIds.toList());
  }

  List<String> _dynamicGrowthTips() {
    final tips = <String>[];
    final occ = ((_dashboardData['occupancyRate'] as num?) ?? 0).toDouble();
    final rating = ((_dashboardData['averageRating'] as num?) ?? 0).toDouble();
    final pending = (_dashboardData['pendingRequests'] as int?) ?? 0;
    if (occ < 0.7) tips.add('Occupancy below 70% • Try seasonal/length-of-stay discounts.');
    if (rating < 4.7) tips.add('Average rating under 4.7 • Improve checkout/cleanliness and ask for reviews.');
    if (pending > 3) tips.add('Many pending requests • Respond faster or enable instant booking.');
    return tips;
  }

  Future<void> _onRefresh() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ErrorBoundary(
      onError: (details) {
        debugPrint('Owner dashboard screen error: ${details.exception}');
      },
      child: ResponsiveLayout(
        padding: EdgeInsets.zero,
        maxWidth: MediaQuery.sizeOf(context).width,
        child: TabBackHandler(
          tabController: _tabController,
          child: Scaffold(
          backgroundColor: isDark ? EnterpriseDarkTheme.primaryBackground : EnterpriseLightTheme.primaryBackground,
          appBar: _buildAppBar(theme),
          body: _buildBody(theme, isDark),
          floatingActionButton: null,
          ),
        ),
      ),
    );
  }

  // Skeletons for Overview while loading
  Widget _buildOverviewSkeleton(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final bottomPad = MediaQuery.of(context).padding.bottom + (isPhone ? 6.0 : 12.0);
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: isPhone ? 12 : 16,
        right: isPhone ? 12 : 16,
        bottom: bottomPad,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats grid skeleton
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: isPhone ? 12 : 16,
            mainAxisSpacing: isPhone ? 12 : 16,
            childAspectRatio: isPhone ? 1.45 : 1.5,
            children: List.generate(4, (index) =>
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(isPhone ? 12 : 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SkeletonLoader(width: 28, height: 28, borderRadius: BorderRadius.all(Radius.circular(8))),
                      SizedBox(height: isPhone ? 6 : 8),
                      SkeletonLoader(width: isPhone ? 80 : 110, height: isPhone ? 16 : 18, borderRadius: const BorderRadius.all(Radius.circular(6))),
                      SizedBox(height: isPhone ? 3 : 4),
                      SkeletonLoader(width: isPhone ? 60 : 80, height: isPhone ? 12 : 14, borderRadius: const BorderRadius.all(Radius.circular(6))),
                    ],
                  ),
                ),
              )
            ),
          ),
          SizedBox(height: isPhone ? 4 : 6),
          // Recent bookings skeleton list
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isPhone ? 12 : 16,
                isPhone ? 6 : 10,
                isPhone ? 12 : 16,
                isPhone ? 12 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: isPhone ? 120 : 160, height: isPhone ? 16 : 18, borderRadius: const BorderRadius.all(Radius.circular(6))),
                  SizedBox(height: isPhone ? 4 : 6),
                  ...List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const SkeletonLoader(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
                            SizedBox(width: isPhone ? 10 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SkeletonLoader(width: isPhone ? 120 : 160, height: 14, borderRadius: const BorderRadius.all(Radius.circular(6))),
                                  const SizedBox(height: 6),
                                  SkeletonLoader(width: isPhone ? 150 : 200, height: 12, borderRadius: const BorderRadius.all(Radius.circular(6))),
                                  const SizedBox(height: 6),
                                  SkeletonLoader(width: isPhone ? 100 : 140, height: 12, borderRadius: const BorderRadius.all(Radius.circular(6))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SkeletonLoader(width: isPhone ? 60 : 80, height: 20, borderRadius: const BorderRadius.all(Radius.circular(12))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Charts
  Widget _buildEarningsLineChart(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final data = _mockEarningsLast6Months();
    final spots = [
      for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i] / 1000.0),
    ];
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 0.5),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isPhone ? 28 : 36,
              interval: 0.5,
              getTitlesWidget: (value, meta) => Text('${value.toStringAsFixed(1)}k', style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.grey[600])),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isPhone ? 18 : 22,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_monthShortLabel(idx), style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.grey[600])),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: theme.colorScheme.primary,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary.withOpacity(0.25), theme.colorScheme.primary.withOpacity(0.05)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: FlDotData(show: true, getDotPainter: (spot, p, bar, i) => FlDotCirclePainter(
              radius: isPhone ? 2.5 : 3,
              color: theme.colorScheme.primary,
              strokeWidth: 0,
            )),
          ),
        ],
        minY: 0,
      ),
    );
  }

  

  List<double> _mockEarningsLast6Months() {
    final base = (_dashboardData['monthlyEarnings'] as num).toDouble();
    return [base * 0.88, base * 0.93, base * 0.97, base * 0.9, base * 1.02, base * 1.0];
  }

  String _monthShortLabel(int indexFromStart) {
    // index 0 is oldest, 5 is latest
    final now = DateTime.now();
    final monthDate = DateTime(now.year, now.month - (5 - indexFromStart), 1);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[monthDate.month - 1];
  }

  String _monthShortLabelDynamic(int indexFromStart, int totalPeriods) {
    // index 0 is oldest
    final now = DateTime.now();
    final monthDate = DateTime(now.year, now.month - (totalPeriods - 1 - indexFromStart), 1);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[monthDate.month - 1];
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return AppBar(
      title: Text(
        ProductionConfig.appName,
        style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          height: 1.0,
        ),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
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
      toolbarHeight: isPhone ? 40 : null,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      actions: [
        if (!isPhone)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton.icon(
              onPressed: () {
                ref.read(immersiveRouteOpenProvider.notifier).state = true;
                context.push('/subscription-plans').whenComplete(() {
                  if (!mounted) return;
                  ref.read(immersiveRouteOpenProvider.notifier).state = false;
                });
              },
              icon: const Icon(Icons.lock_open),
              label: const Text('Upgrade'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ),
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: Icon(Icons.notifications, size: isPhone ? 22 : 24),
          tooltip: 'Notifications',
        ),
        Builder(builder: (context) {
          final auth = ref.watch(authProvider);
          final avatarUrl = auth.user?.profileImageUrl;
          final name = auth.user?.name ?? '';
          final String initial = (name.isNotEmpty ? name.trim()[0] : 'U').toUpperCase();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.push('/profile'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white70,
                        width: 1.2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: isPhone ? 15 : 17,
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(
                              initial,
                              style: TextStyle(fontSize: isPhone ? 11 : 12, fontWeight: FontWeight.w700),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: isPhone ? 11 : 13,
                      height: isPhone ? 11 : 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                        border: Border.all(color: theme.colorScheme.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
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
                  child: Icon(Icons.attach_money, size: isPhone ? 14 : 16, color: Colors.lightGreenAccent),
                ),
                const SizedBox(height: 2),
                const Text('Earnings', style: TextStyle(color: Colors.lightGreenAccent)),
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
                  child: Icon(Icons.trending_up, size: isPhone ? 14 : 16, color: Colors.orangeAccent),
                ),
                const SizedBox(height: 2),
                const Text('Grow', style: TextStyle(color: Colors.orangeAccent)),
              ],
            ),
          ),
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
          _buildEarningsTab(theme, isDark),
          _buildGrowTab(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return _buildOverviewSkeleton(theme);
    }

    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final bottomPad = MediaQuery.of(context).padding.bottom + (isPhone ? 6.0 : 12.0);
    final monet = ref.watch(monetizationServiceProvider);
    final hasSub = monet.currentSubscription?.isValid == true;
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: isPhone ? 12 : 16,
        right: isPhone ? 12 : 16,
        bottom: bottomPad,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<KycProfile>(
            future: KycService.instance.getProfile(),
            builder: (context, snapshot) {
              final auth = ref.watch(authProvider);
              final isVerifiedAuth = auth.user?.isKycVerified == true;
              if (!snapshot.hasData && !isVerifiedAuth) {
                return const SizedBox.shrink();
              }
              final status = snapshot.data?.status ?? KycStatus.notStarted;
              final verified = isVerifiedAuth || status == KycStatus.verified;
              Color baseColor;
              String label;
              IconData icon;
              String? ctaLabel;
              switch (verified ? KycStatus.verified : status) {
                case KycStatus.verified:
                  baseColor = Colors.green; label = 'KYC Verified'; icon = Icons.verified; ctaLabel = null; break;
                case KycStatus.submitted:
                  baseColor = Colors.amber; label = 'KYC Submitted'; icon = Icons.hourglass_bottom; ctaLabel = 'View Status'; break;
                case KycStatus.inProgress:
                  baseColor = Colors.blue; label = 'KYC In Progress'; icon = Icons.pending_actions; ctaLabel = 'Resume KYC'; break;
                case KycStatus.rejected:
                  baseColor = Colors.red; label = 'KYC Rejected'; icon = Icons.error_outline; ctaLabel = 'Fix & Resubmit'; break;
                case KycStatus.notStarted:
                default:
                  baseColor = Colors.orange; label = 'KYC Required'; icon = Icons.verified_user_outlined; ctaLabel = 'Start KYC'; break;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: baseColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: baseColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: baseColor),
                          const SizedBox(width: 6),
                          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    if (!verified && ctaLabel != null)
                      OutlinedButton(
                        onPressed: () => context.push('/kyc'),
                        child: Text(ctaLabel),
                      ),
                  ],
                ),
              );
            },
          ),
          if (hasSub) _buildPlanPill(theme),
          _buildStatsGrid(theme, isDark),
          SizedBox(height: isPhone ? 6 : 10),
          if (!hasSub) _buildSubscriptionPromptCard(theme),
          SizedBox(height: isPhone ? 12 : 16),
          _buildRecentActivityCard(theme),
          SizedBox(height: isPhone ? 12 : 16),
          _buildQuickActionsGrid(theme),
        ],
      ),
    );
  }

  Widget _buildOverviewStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
    required bool isPhone,
    String? changeText,
    Color? changeColor,
    double? valueNumber,
    String Function(double)? valueFormatter,
    String? tooltip,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 8 : 16),
        child: LayoutBuilder(
          builder: (context, cons) {
            final tileXS = cons.maxWidth < 180 || cons.maxHeight < 96;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon chip
                    Tooltip(
                      message: tooltip ?? title,
                      preferBelow: false,
                      child: Container(
                        width: isPhone ? 24 : 32,
                        height: isPhone ? 24 : 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Icon(icon, color: color, size: isPhone ? 14 : 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (changeText != null && tileXS)
                      _buildMiniTrendIcon(changeText.trim().startsWith('+')),
                  ],
                ),
                SizedBox(height: isPhone ? 2 : 6),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: (valueNumber != null && valueFormatter != null)
                          ? _animatedCounterText(
                              target: valueNumber,
                              builder: (v) => Text(
                                valueFormatter(v),
                                style: (isPhone
                                        ? theme.textTheme.titleMedium?.copyWith(fontSize: 13, height: 1.1)
                                        : theme.textTheme.titleLarge)
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            )
                          : Text(
                              value,
                              style: (isPhone
                                      ? theme.textTheme.titleMedium?.copyWith(fontSize: 13, height: 1.1)
                                      : theme.textTheme.titleLarge)
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                    ),
                  ),
                ),
                if (changeText != null && !tileXS) ...[
                  SizedBox(height: isPhone ? 2 : 6),
                  _buildTrendPill(changeText, theme, positive: changeText.trim().startsWith('+')),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubscriptionPromptCard(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.secondary.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: EdgeInsets.fromLTRB(
          isPhone ? 10 : 12,
          isPhone ? 8 : 12,
          isPhone ? 10 : 12,
          isPhone ? 8 : 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: isPhone ? 18 : 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Active Subscription', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('Upgrade to unlock premium features and reduce commission rates.', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                ref.read(immersiveRouteOpenProvider.notifier).state = true;
                context.push('/subscription-plans').whenComplete(() {
                  if (!mounted) return;
                  ref.read(immersiveRouteOpenProvider.notifier).state = false;
                });
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: isPhone ? 12 : 16, vertical: isPhone ? 8 : 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Upgrade'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final asyncActivities = ref.watch(ownerActivityProvider);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: isPhone ? 8 : 12),
            asyncActivities.when(
              loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, st) => Text('Failed to load activity: $e', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              data: (items) {
                if (items.isEmpty) {
                  return Text('No recent activity', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor));
                }
                return Column(
                  children: items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: isPhone ? 16 : 20,
                              backgroundColor: theme.primaryColor.withOpacity(0.1),
                              child: Icon(
                                item.icon,
                                size: isPhone ? 16 : 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            SizedBox(width: isPhone ? 10 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(item.timeAgo, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (i != items.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),
                          ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- UI helpers ---
  Widget _buildPlanPill(ThemeData theme) {
    final monet = ref.watch(monetizationServiceProvider);
    final sub = monet.currentSubscription;
    if (sub == null || !sub.isValid) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium, size: 16),
                const SizedBox(width: 6),
                Text('${sub.plan.name} • active', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendPill(String text, ThemeData theme, {required bool positive}) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final Color fg = positive ? Colors.green : Colors.red;
    final Color bg = positive ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12);
    final IconData arrow = positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isPhone ? 6 : 8, vertical: isPhone ? 2 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(arrow, size: isPhone ? 10 : 14, color: fg),
          SizedBox(width: isPhone ? 3 : 4),
          Text(text, style: (isPhone ? theme.textTheme.labelSmall : theme.textTheme.bodySmall)?.copyWith(color: fg, fontWeight: FontWeight.w700, height: 1.0)),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(ThemeData theme) {
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 600;
    final isXS = width < 360;
  // Verified handled via KYC route; no item lookup needed here
    Widget tile({required Color color, required IconData icon, required String label, required VoidCallback onTap}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: isPhone ? 20 : 18),
              const SizedBox(height: 2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Responsive breakpoints for Quick Actions grid
    final isTablet = width >= 600 && width < 900;
    final isLaptop = width >= 900 && width < 1400;

    // More columns and flatter aspect on larger screens to avoid huge tiles
    final int qaCols = isPhone ? 2 : isTablet ? 3 : isLaptop ? 4 : 6;
    final double qaAspect = isPhone
        ? (isXS ? 1.35 : 1.9)
        : isTablet
            ? 2.6
            : isLaptop
                ? 4.0
                : 5.0; // desktop+

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isPhone ? 8 : 12,
          isPhone ? 4 : 10,
          isPhone ? 8 : 12,
          isPhone ? 4 : 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: isPhone ? 2 : 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: qaCols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: qaAspect,
              children: [
                tile(
                  color: Colors.indigo,
                  icon: Icons.analytics_outlined,
                  label: 'Analytics',
                  onTap: () => context.push('/owner/analytics'),
                ),
                tile(
                  color: Colors.orange,
                  icon: Icons.rocket_launch_outlined,
                  label: 'Boost Listing',
                  onTap: () async {
                    try {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(duration: Duration(milliseconds: 800), content: Text('Opening Promote Listing...')));
                      }
                      ref.read(immersiveRouteOpenProvider.notifier).state = true;
                      await context.push('/promote-listing');
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open Promote Listing: $e')));
                      }
                    } finally {
                      ref.read(immersiveRouteOpenProvider.notifier).state = false;
                    }
                  },
                ),
                tile(
                  color: Colors.purple,
                  icon: Icons.verified_outlined,
                  label: 'Get Verified',
                  onTap: () async {
                    final isKycVerified = ref.read(authProvider).user?.isKycVerified == true;
                    if (!isKycVerified) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete KYC to buy the Verified badge')));
                      }
                      ref.read(immersiveRouteOpenProvider.notifier).state = true;
                      await context.push('/kyc').whenComplete(() {
                        if (!mounted) return;
                        ref.read(immersiveRouteOpenProvider.notifier).state = false;
                      });
                      return;
                    }
                    // Purchase only after verified
                    final monetState = ref.read(monetizationServiceProvider);
                    final verifiedItem = monetState.microtransactionItems.firstWhere(
                      (i) => i.type == MicrotransactionType.verifiedBadge,
                      orElse: () => const MicrotransactionItem(id: 'verified_badge', type: MicrotransactionType.verifiedBadge, name: 'Verified Badge', description: '', price: 499, icon: '✅', isOneTime: true),
                    );
                    final ok = await ref.read(monetizationServiceProvider.notifier).purchaseMicrotransaction(verifiedItem);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Verified badge purchased' : 'Purchase failed')));
                    }
                  },
                ),
                tile(
                  color: Colors.indigo,
                  icon: Icons.account_balance_outlined,
                  label: 'Payouts',
                  onTap: () {
                    ref.read(immersiveRouteOpenProvider.notifier).state = true;
                    context.push('/payouts').whenComplete(() {
                      if (!mounted) return;
                      ref.read(immersiveRouteOpenProvider.notifier).state = false;
                    });
                  },
                ),
                tile(
                  color: Colors.teal,
                  icon: Icons.download_outlined,
                  label: 'Withdraw',
                  onTap: () {
                    ref.read(immersiveRouteOpenProvider.notifier).state = true;
                    context.push('/payouts/withdraw').whenComplete(() {
                      if (!mounted) return;
                      ref.read(immersiveRouteOpenProvider.notifier).state = false;
                    });
                  },
                ),
                tile(
                  color: Colors.deepPurple,
                  icon: Icons.campaign_outlined,
                  label: 'Promote',
                  onTap: () => context.push('/promote-listing'),
                ),
              ],
            ),
          ],
        ),
      ),
  );
}

Widget _buildStatsGrid(ThemeData theme, bool isDark) {
  final size = MediaQuery.sizeOf(context);
  final isPhone = size.width < 600;
  // Responsive columns/aspect for better desktop usage
  final bool isXL = size.width >= 1600;
  final bool isLG = size.width >= 1200;
  final bool isMD = size.width >= 900;
  final int columns = isXL ? 6 : isLG ? 4 : isMD ? 3 : 2;
  // Flatter aspect on phones to give more height and avoid overflow
  final bool isXS = size.width < 360;
  final double aspect = isXS
      ? 1.05
      : isPhone
          ? 1.20
          : isXL
              ? 1.90
              : isLG
                  ? 1.75
                  : isMD
                      ? 1.60
                      : 1.55;
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: columns,
    crossAxisSpacing: isPhone ? 12 : 16,
    mainAxisSpacing: isPhone ? 4 : 16,
    childAspectRatio: aspect,
    children: [
      _buildStatCard(
        'Total Earnings',
        CurrencyFormatter.formatPrice((_dashboardData['totalEarnings'] as num).toDouble()),
        Icons.attach_money,
        Colors.green,
        theme,
        isDark,
      ),
      _buildStatCard(
        'Monthly Earnings',
        CurrencyFormatter.formatPrice((_dashboardData['monthlyEarnings'] as num).toDouble()),
        Icons.trending_up,
        Colors.blue,
        theme,
        isDark,
      ),
      _buildStatCard(
        'Total Bookings',
        '${_dashboardData['totalBookings']}',
        Icons.book,
        Colors.orange,
        theme,
        isDark,
      ),
      _buildStatCard(
        'Active Listings',
        '${_dashboardData['activeListings']}',
        Icons.home,
        Colors.purple,
        theme,
        isDark,
      ),
    ],
  );
}

Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeData theme, bool isDark) {
  final size = MediaQuery.sizeOf(context);
  final isPhone = size.width < 600;
  final outline = theme.colorScheme.outline.withOpacity(isDark ? 0.75 : 0.55);
  return Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: outline, width: 2.0),
    ),
    child: LayoutBuilder(
      builder: (ctx, cons) {
        final compact = cons.maxHeight < 120; // tighten when vertical space is constrained
        final padAll = isPhone ? (compact ? 8.0 : 10.0) : 14.0;
        final box = isPhone ? (compact ? 30.0 : 34.0) : 40.0;
        final iconSizeLocal = isPhone ? (compact ? 16.0 : 18.0) : 22.0;
        final topGap = isPhone ? (compact ? 7.0 : 10.0) : 12.0;
        final preValueGap = isPhone ? (compact ? 5.0 : 8.0) : 12.0;
        return Padding(
          padding: EdgeInsets.all(padAll),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: box,
                height: box,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.24), width: 1),
                ),
                child: Icon(icon, color: color, size: iconSizeLocal),
              ),
              SizedBox(height: topGap),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withOpacity(0.80),
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                softWrap: false,
              ),
              SizedBox(height: preValueGap),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.1,
                    fontSize: isPhone ? (compact ? 14.0 : 15.0) : null,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: false,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

  Widget _buildBookingItem(Map<String, dynamic> booking, ThemeData theme, bool isDark) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: isPhone ? 16 : 20,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Text(
              booking['guestName'][0],
              style: TextStyle(fontSize: isPhone ? 12 : 14, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: isPhone ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['guestName'],
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  booking['propertyTitle'],
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${booking['checkIn']} - ${booking['checkOut']}',
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
                CurrencyFormatter.formatPrice((booking['amount'] as num).toDouble()),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isPhone ? 6 : 8, vertical: 2),
                decoration: BoxDecoration(
                  color: booking['status'] == 'confirmed' ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking['status'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isPhone ? 11 : 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isPhone ? 12 : 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Manage Bookings',
                    Icons.calendar_today,
                    () => context.push('/owner/requests'),
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
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isPhone ? 18 : 22),
      label: Text(
        title,
        style: TextStyle(fontSize: isPhone ? 13 : 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: isPhone ? 10 : 14, horizontal: 12),
        minimumSize: Size(double.infinity, isPhone ? 40 : 48),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }

  Widget _buildEarningsTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return _buildEarningsSkeleton(theme);
    }

    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final bottomPad = (isPhone ? 56.0 : 72.0) + MediaQuery.of(context).padding.bottom + (isPhone ? 8.0 : 12.0);
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: isPhone ? 12 : 16,
        right: isPhone ? 12 : 16,
        bottom: bottomPad,
      ),
      child: Column(
        children: [
          _buildEarningsKpisRow(theme),
          SizedBox(height: isPhone ? 6 : 10),
          _buildEarningsChartSection(theme),
          SizedBox(height: isPhone ? 12 : 16),
          _buildPayoutSummary(theme),
          SizedBox(height: isPhone ? 12 : 16),
          _buildCommissionSummary(theme),
          SizedBox(height: isPhone ? 12 : 16),
          _buildEarningsBreakdown(theme),
          SizedBox(height: isPhone ? 12 : 16),
          _buildEarningsActions(theme),
        ],
      ),
    );
  }

  // Reusable industrial-grade KPI card for Earnings section
  Widget _buildEarningsKpiCard({
    required ThemeData theme,
    required bool isPhone,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    String? deltaText,
    bool? deltaPositive,
  }) {
    final outline = theme.colorScheme.outline.withOpacity(theme.brightness == Brightness.dark ? 0.75 : 0.55);
    final isXSLocal = MediaQuery.sizeOf(context).width < 360;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: outline, width: 2.0),
      ),
      child: LayoutBuilder(
        builder: (ctx, cons) {
          final compact = cons.maxHeight < 140; // hide subtitle when compact
          final micro = cons.maxHeight < 140; // optionally hide delta when very tight
          final padAll = isPhone ? (compact ? 8.0 : 10.0) : 14.0;
          final box = isPhone ? (compact ? 30.0 : 34.0) : 40.0;
          final iconSizeLocal = isPhone ? (compact ? 16.0 : 18.0) : 22.0;
          final topGap = isPhone ? (compact ? 1.0 : 3.0) : 4.0;
          final preValueGap = isPhone ? (compact ? 3.0 : 4.0) : 8.0;
          final showDelta = deltaText != null && deltaPositive != null && !micro;
          final showSubtitle = subtitle != null && !isXSLocal && !compact;
          return Padding(
            padding: EdgeInsets.all(padAll),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: box,
                  height: box,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.24), width: 1),
                  ),
                  child: Icon(icon, color: color, size: iconSizeLocal),
                ),
                SizedBox(height: topGap),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withOpacity(0.80),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  softWrap: false,
                ),
                if (showDelta) ...[
                  SizedBox(height: isPhone ? 2 : 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isPhone ? 5 : 8, vertical: isPhone ? 1 : 2),
                    decoration: BoxDecoration(
                      color: (deltaPositive ? Colors.green : Colors.red).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: (deltaPositive ? Colors.green : Colors.red).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(deltaPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: isPhone ? 9 : 12, color: deltaPositive ? Colors.green : Colors.red),
                        const SizedBox(width: 3),
                        Text(deltaText, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: deltaPositive ? Colors.green : Colors.red, height: 1.0)),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: preValueGap),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.2,
                      fontSize: isPhone ? (compact ? 14.0 : 15.0) : null,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: false,
                  ),
                ),
                if (showSubtitle) ...[
                  SizedBox(height: isPhone ? 2 : 4),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEarningsKpisRow(ThemeData theme) {
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 600;
    final isXS = width < 360;
    final monthly = (_dashboardData['monthlyEarnings'] as num).toDouble();
    final monthlyDelta = (_dashboardData['monthlyEarningsChange'] as num?)?.toDouble() ?? 0.0;
    final total = (_dashboardData['totalEarnings'] as num).toDouble();
    final bookings = (_dashboardData['monthlyBookings'] as num?)?.toDouble() ?? 0;
    final aov = bookings > 0 ? (monthly / bookings) : 0.0;
    final refunds = (_dashboardData['refundsAmount'] as num?)?.toDouble() ?? 0;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isPhone ? 2 : 4,
      crossAxisSpacing: isPhone ? 12 : 16,
      mainAxisSpacing: isPhone ? 8 : 12,
      childAspectRatio: isXS ? 0.95 : (isPhone ? 1.1 : 1.70),
      children: [
        _buildEarningsKpiCard(
          theme: theme,
          isPhone: isPhone,
          title: 'Monthly Earnings',
          value: CurrencyFormatter.formatPrice(monthly),
          icon: Icons.attach_money,
          color: Colors.green,
          subtitle: 'Last 30 days',
          deltaText: '${(monthlyDelta * 100).toStringAsFixed(0)}%',
          deltaPositive: monthlyDelta >= 0,
        ),
        _buildEarningsKpiCard(
          theme: theme,
          isPhone: isPhone,
          title: 'Total Earnings',
          value: CurrencyFormatter.formatPrice(total),
          icon: Icons.savings_outlined,
          color: Colors.blue,
          subtitle: 'Lifetime total',
        ),
        _buildEarningsKpiCard(
          theme: theme,
          isPhone: isPhone,
          title: 'AOV',
          value: CurrencyFormatter.formatPrice(aov),
          icon: Icons.calculate_outlined,
          color: Colors.orange,
          subtitle: 'Avg per booking',
        ),
        _buildEarningsKpiCard(
          theme: theme,
          isPhone: isPhone,
          title: 'Refunds',
          value: CurrencyFormatter.formatPrice(refunds),
          icon: Icons.receipt_long_outlined,
          color: Colors.purple,
          subtitle: 'Last 30 days',
        ),
      ],
    );
  }

  Widget _buildEarningsChartSection(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    // Selected preset for SegmentedButton consistency
    final selectedPresetDays = ([_earningsDays].where((d) => d == 7 || d == 30 || d == 90).isNotEmpty) ? _earningsDays : 30;
    final locale = Localizations.localeOf(context).toString();
    final df = DateFormat.MMMd(locale);
    // Monetization state for net calculation
    final monet = ref.watch(monetizationServiceProvider);
    final rate = _currentCommissionRate(monet);
    final currentGross = _seriesGross;
    final prevGross = _seriesPrevGross;
    final currentNet = _computeNetFromGross(currentGross, rate);
    final prevNet = _computeNetFromGross(prevGross, rate);
    final primary = _earningsShowNet ? currentNet : currentGross;
    final secondary = _comparePrevious ? (_earningsShowNet ? prevNet : prevGross) : List<double>.filled(primary.length, 0.0);
    final labels = _seriesLabels;
    final outline = theme.colorScheme.outline.withOpacity(theme.brightness == Brightness.dark ? 0.75 : 0.55);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: outline, width: 2.0)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isPhone ? 10 : 12,
          isPhone ? 8 : 12,
          isPhone ? 10 : 12,
          isPhone ? 10 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Earnings Trend', style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7d')),
                    ButtonSegment(value: 30, label: Text('30d')),
                    ButtonSegment(value: 90, label: Text('90d')),
                  ],
                  selected: {selectedPresetDays},
                  onSelectionChanged: (s) {
                    setState(() { _earningsDays = s.first; _earningsCustomRange = null; });
                    _saveEarningsRangePrefs();
                    _refreshEarningsData();
                  },
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
                      lastDate: DateTime.now(),
                      helpText: 'Select custom range',
                    );
                    if (picked != null) {
                      setState(() {
                        _earningsCustomRange = picked;
                        final start = DateTime(picked.start.year, picked.start.month, picked.start.day);
                        final end = DateTime(picked.end.year, picked.end.month, picked.end.day);
                        _earningsDays = end.difference(start).inDays + 1;
                      });
                      _saveEarningsRangePrefs();
                      _refreshEarningsData();
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(_earningsCustomRange == null ? 'Custom' : 'Custom (${df.format(_earningsCustomRange!.start)} - ${df.format(_earningsCustomRange!.end)})'),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Gross')),
                    ButtonSegment(value: true, label: Text('Net')),
                  ],
                  selected: {_earningsShowNet},
                  onSelectionChanged: (s) => setState(() => _earningsShowNet = s.first),
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                ),
                FilterChip(
                  selected: _comparePrevious,
                  onSelected: (v) => setState(() => _comparePrevious = v),
                  label: const Text('Compare previous'),
                ),
              ],
            ),
            SizedBox(height: isPhone ? 8 : 12),
            if (_earningsDataLoading)
              SizedBox(
                height: isPhone ? 168 : 232,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (_earningsDataError != null)
              SizedBox(
                height: isPhone ? 168 : 232,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(height: 8),
                      Text(_earningsDataError!, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(onPressed: _refreshEarningsData, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else
              AnimatedSwitcher(
              duration: const Duration(milliseconds: 650),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: SizedBox(
                key: ValueKey('chart-$_earningsDays-$_earningsShowNet-${_earningsCustomRange?.start.millisecondsSinceEpoch ?? 0}-${_earningsCustomRange?.end.millisecondsSinceEpoch ?? 0}'),
                height: isPhone ? 168 : 232,
                child: _buildEarningsLineChart2(
                  theme,
                  primary,
                  secondary,
                  labels,
                  _earningsHoverIndex,
                  _earningsShowNet ? Colors.green : theme.colorScheme.primary,
                  theme.colorScheme.onSurface.withOpacity(0.35),
                  showSecondary: _comparePrevious,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 6, children: [
              _legendChip(color: _earningsShowNet ? Colors.green : theme.colorScheme.primary, label: 'Current ${_earningsShowNet ? '(Net)' : '(Gross)'}'),
              if (_comparePrevious)
                _legendChip(color: theme.colorScheme.onSurface.withOpacity(0.35), label: 'Previous ${_earningsShowNet ? '(Net)' : '(Gross)'}'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutSummary(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final pending = (_dashboardData['pendingPayouts'] as num?)?.toDouble() ?? 0;
    final lastAmt = (_dashboardData['lastPayoutAmount'] as num?)?.toDouble() ?? 0;
    final lastDate = _dashboardData['lastPayoutDate'] as String? ?? '-';
    final etaDays = (_dashboardData['nextPayoutEtaDays'] as num?)?.toInt() ?? 0;
    Widget item(IconData icon, Color color, String label, String value) {
      return Row(children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
      ]);
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Payouts Summary',
                    style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(immersiveRouteOpenProvider.notifier).state = true;
                    context.push('/payouts').whenComplete(() {
                      if (!mounted) return;
                      ref.read(immersiveRouteOpenProvider.notifier).state = false;
                    });
                  },
                  child: const Text('View Payouts'),
                ),
              ],
            ),
            SizedBox(height: isPhone ? 8 : 12),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > 640;
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: wide ? (c.maxWidth - 32) / 3 : c.maxWidth,
                      child: item(Icons.timelapse, Colors.orange, 'Pending Payouts', CurrencyFormatter.formatPrice(pending)),
                    ),
                    SizedBox(
                      width: wide ? (c.maxWidth - 32) / 3 : c.maxWidth,
                      child: item(Icons.payments_outlined, Colors.green, 'Last Payout', '${CurrencyFormatter.formatPrice(lastAmt)} • $lastDate'),
                    ),
                    SizedBox(
                      width: wide ? (c.maxWidth - 32) / 3 : c.maxWidth,
                      child: item(Icons.schedule, Colors.blue, 'Next Payout ETA', etaDays > 0 ? '$etaDays days' : 'Queued'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdown(ThemeData theme) {
    final monet = ref.watch(monetizationServiceProvider);
    final rate = _currentCommissionRate(monet);
    final gross = (_dashboardData['monthlyEarnings'] as num).toDouble();
    final commission = gross * rate;
    final taxes = (gross - commission) * 0.18;
    final net = gross - commission - taxes;
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    Widget cell(String title, String val, Color color, IconData icon) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(isPhone ? 12 : 16),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      val,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Breakdown',
              style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isPhone ? 10 : 12),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > 640;
                final w = wide ? (c.maxWidth - 24) / 2 : c.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: w,
                      child: cell('Gross', CurrencyFormatter.formatPrice(gross), Colors.blueGrey, Icons.stacked_bar_chart),
                    ),
                    SizedBox(
                      width: w,
                      child: cell('Commission (${(rate * 100).toStringAsFixed(0)}%)', '-${CurrencyFormatter.formatPrice(commission)}', Colors.red, Icons.percent),
                    ),
                    SizedBox(
                      width: w,
                      child: cell('Taxes (18%)', '-${CurrencyFormatter.formatPrice(taxes)}', Colors.orange, Icons.receipt_long),
                    ),
                    SizedBox(
                      width: w,
                      child: cell('Net', CurrencyFormatter.formatPrice(net), Colors.green, Icons.ssid_chart_outlined),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsActions(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout request submitted')));
              },
              icon: const Icon(Icons.request_page),
              label: const Text('Request Payout'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await _exportEarningsPdf();
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export PDF'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await _shareEarningsPdf();
              },
              icon: const Icon(Icons.share),
              label: const Text('Share PDF'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await _exportSelectedRangeCsv();
              },
              icon: const Icon(Icons.file_download),
              label: const Text('Export CSV'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/owner/analytics'),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Analytics'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
              },
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Filter'),
            ),
          ],
        ),
      ),
    );
  }

  double _currentCommissionRate(MonetizationState monet) {
    // Delegate to central monetization service which accounts for current plan
    final svc = ref.read(monetizationServiceProvider.notifier);
    return svc.getOwnerCommissionRate();
  }

  List<double> _mockEarningsLast6Weeks() {
    final base = ((_dashboardData['monthlyEarnings'] as num).toDouble()) / 6.0;
    return [base * 0.9, base * 1.1, base * 1.05, base * 0.95, base * 1.2, base * 1.0];
  }

  // Dynamic generators for 6/12 periods
  List<double> _mockEarningsMonths(int periods) {
    final base = (_dashboardData['monthlyEarnings'] as num).toDouble();
    // Repeating multipliers to simulate seasonality
    final multipliers = [
      0.88, 0.93, 0.97, 0.90, 1.02, 1.00, 1.05, 0.96, 1.08, 0.92, 1.10, 0.98,
    ];
    return List.generate(periods, (i) {
      final trend = 1.0 + (i - (periods - 1) / 2) * 0.005; // mild linear trend
      return base * multipliers[i % multipliers.length] * trend;
    });
  }

  List<double> _mockEarningsWeeks(int periods) {
    final weeklyBase = ((_dashboardData['monthlyEarnings'] as num).toDouble()) / 6.0;
    final multipliers = [
      0.90, 1.10, 1.05, 0.95, 1.20, 1.00, 1.03, 0.98, 1.12, 0.94, 1.06, 0.99,
    ];
    return List.generate(periods, (i) {
      final trend = 1.0 + (i - (periods - 1) / 2) * 0.004;
      return weeklyBase * multipliers[i % multipliers.length] * trend;
    });
  }

  // Generate mock daily earnings for the given number of days (ending today)
  List<double> _mockEarningsDays(int days) {
    final today = DateTime.now();
    final baseDaily = ((_dashboardData['monthlyEarnings'] as num).toDouble()) / 30.0;
    final randMultipliers = [
      0.92, 0.98, 1.03, 1.05, 0.96, 1.08, 0.94,
      1.01, 0.99, 1.07, 0.93, 1.10, 0.97, 1.02,
    ];
    return List.generate(days, (i) {
      final d = today.subtract(Duration(days: days - 1 - i));
      // Weekly seasonality bump for weekends
      final isWeekend = d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
      final seasonal = isWeekend ? 1.15 : 1.0;
      final trend = 1.0 + (i - (days - 1) / 2) * 0.0015; // subtle drift
      final noise = randMultipliers[i % randMultipliers.length];
      return baseDaily * seasonal * trend * noise;
    });
  }

  Widget _buildEarningsLineChart2(ThemeData theme, List<double> primary, List<double> secondary, List<String> labels, int? hoverIndex, Color lineColor, Color secondaryColor, {bool showSecondary = true}) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final spots = [for (int i = 0; i < primary.length; i++) FlSpot(i.toDouble(), primary[i] / 1000.0)];
    final compSpots = [for (int i = 0; i < secondary.length; i++) FlSpot(i.toDouble(), secondary[i] / 1000.0)];
    double yMax = 0;
    for (final v in [...primary, ...secondary]) { if (v > yMax) yMax = v; }
    double avg = 0;
    if (primary.isNotEmpty) {
      avg = primary.reduce((a, b) => a + b) / primary.length;
    }
    // Find min/max indices and values on primary series
    int minIdx = 0, maxIdx = 0;
    double minVal = primary.isNotEmpty ? primary.first : 0, maxVal = primary.isNotEmpty ? primary.first : 0;
    for (int i = 1; i < primary.length; i++) {
      final v = primary[i];
      if (v < minVal) { minVal = v; minIdx = i; }
      if (v > maxVal) { maxVal = v; maxIdx = i; }
    }
    int labelStep = (labels.length / (isPhone ? 6 : 10)).ceil();
    if (labelStep < 1) labelStep = 1;
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: 1,
          horizontalInterval: 0.5,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1, dashArray: [4, 4]),
          getDrawingVerticalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.12), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: isPhone ? 28 : 36, interval: 0.5, getTitlesWidget: (v, m) => Text('${v.toStringAsFixed(1)}k', style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.grey[600])))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: isPhone ? 18 : 22, getTitlesWidget: (value, meta) { final idx = value.toInt(); if (idx < 0 || idx >= labels.length) return const SizedBox.shrink(); if (idx % labelStep != 0 && idx != labels.length - 1) return const SizedBox.shrink(); return Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[idx], style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.grey[600]))); })),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (event.isInterestedForInteractions) {
              final spots = response?.lineBarSpots;
              if (spots != null && spots.isNotEmpty) {
                final spot = spots.first;
                setState(() => _earningsHoverIndex = spot.x.toInt());
              } else {
                setState(() => _earningsHoverIndex = null);
              }
            } else {
              setState(() => _earningsHoverIndex = null);
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final val = s.y * 1000.0;
                final idx = s.x.toInt();
                final label = (idx >= 0 && idx < labels.length) ? labels[idx] : '';
                return LineTooltipItem(
                  '$label\n${CurrencyFormatter.formatPrice(val)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
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
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, p, b, i) {
                final isExtreme = i == minIdx || i == maxIdx;
                return FlDotCirclePainter(
                  radius: isExtreme ? (isPhone ? 3.5 : 4) : (isPhone ? 2.5 : 3),
                  color: isExtreme ? Colors.white : lineColor,
                  strokeColor: isExtreme ? lineColor : Colors.transparent,
                  strokeWidth: isExtreme ? 2 : 0,
                );
              },
            ),
          ),
          if (showSecondary)
            LineChartBarData(
              spots: compSpots,
              isCurved: true,
              barWidth: 2,
              color: secondaryColor,
              dashArray: const [8, 4],
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
        ],
        minY: 0,
        maxY: (yMax / 1000.0) * 1.4,
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (avg > 0)
              HorizontalLine(
                y: avg / 1000.0,
                color: Colors.grey.withOpacity(0.35),
                strokeWidth: 1,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
                  labelResolver: (line) => 'Avg ${CurrencyFormatter.formatPrice(avg)}',
                ),
              ),
          ],
          verticalLines: [
            if (primary.isNotEmpty)
              VerticalLine(
                x: minIdx.toDouble(),
                color: Colors.redAccent.withOpacity(0.45),
                strokeWidth: 1,
                dashArray: const [6, 6],
                label: VerticalLineLabel(
                  show: true,
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.only(left: 4, top: 2),
                  style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
                  labelResolver: (line) => 'Min ${CurrencyFormatter.formatPrice(minVal)}',
                ),
              ),
            if (primary.isNotEmpty)
              VerticalLine(
                x: maxIdx.toDouble(),
                color: Colors.green.withOpacity(0.45),
                strokeWidth: 1,
                dashArray: const [6, 6],
                label: VerticalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 4, bottom: 2),
                  style: TextStyle(fontSize: isPhone ? 10 : 11, color: Colors.green, fontWeight: FontWeight.w600),
                  labelResolver: (line) => 'Max ${CurrencyFormatter.formatPrice(maxVal)}',
                ),
              ),
            if (hoverIndex != null && hoverIndex >= 0 && hoverIndex < labels.length)
              VerticalLine(
                x: hoverIndex.toDouble(),
                color: theme.colorScheme.primary.withOpacity(0.35),
                strokeWidth: 1,
                dashArray: const [2, 2],
                label: VerticalLineLabel(
                  show: true,
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 2),
                  style: TextStyle(fontSize: isPhone ? 10 : 11, color: theme.hintColor, fontWeight: FontWeight.w600),
                  labelResolver: (line) {
                    final v = primary[hoverIndex];
                    return '${labels[hoverIndex]}  ${CurrencyFormatter.formatPrice(v)}';
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<double> _computeNetFromGross(List<double> gross, double rate) {
    final List<double> out = [];
    for (final g in gross) {
      final commission = g * rate;
      final taxes = (g - commission) * 0.18;
      out.add(g - commission - taxes);
    }
    return out;
  }

  Future<void> _exportSelectedRangeCsv() async {
    try {
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/earnings_selected_$ts.csv');
      final monet = ref.read(monetizationServiceProvider);
      final rate = _currentCommissionRate(monet);
      final currentGross = _seriesGross;
      final prevGross = _seriesPrevGross;
      final currentNet = _computeNetFromGross(currentGross, rate);
      final prevNet = _computeNetFromGross(prevGross, rate);
      final labels = _seriesLabels;
      final buffer = StringBuffer('date,current_gross,current_net,previous_gross,previous_net\n');
      for (int i = 0; i < labels.length; i++) {
        final cg = i < currentGross.length ? currentGross[i] : 0.0;
        final cn = i < currentNet.length ? currentNet[i] : 0.0;
        final pg = i < prevGross.length ? prevGross[i] : 0.0;
        final pn = i < prevNet.length ? prevNet[i] : 0.0;
        buffer.writeln('${labels[i]},${cg.toStringAsFixed(2)},${cn.toStringAsFixed(2)},${pg.toStringAsFixed(2)},${pn.toStringAsFixed(2)}');
      }
      await file.writeAsString(buffer.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exported to ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
      );
    }
  }

  

  Widget _buildGrowTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return _buildGrowSkeleton(theme);
    }

    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final isTablet = MediaQuery.sizeOf(context).width >= 600 && MediaQuery.sizeOf(context).width < 1200;
    final bottomPad = MediaQuery.of(context).padding.bottom + (isPhone ? 6.0 : 12.0);

    // Monetization state
    final monet = ref.watch(monetizationServiceProvider);
    final sub = monet.currentSubscription;
    final hasSub = sub?.isValid == true;
    String? planStatus;
    if (hasSub) {
      final end = DateFormat.yMMMd().format(sub!.endDate);
      planStatus = '${sub.plan.name} · valid till $end';
    }
    final boostItem = monet.microtransactionItems.firstWhere(
      (i) => i.type == MicrotransactionType.boostListing,
      orElse: () => const MicrotransactionItem(id: 'boost_listing', type: MicrotransactionType.boostListing, name: 'Boost Listing', description: '', price: 299, icon: '🚀', duration: Duration(days: 7)),
    );
    final verifiedItem = monet.microtransactionItems.firstWhere(
      (i) => i.type == MicrotransactionType.verifiedBadge,
      orElse: () => const MicrotransactionItem(id: 'verified_badge', type: MicrotransactionType.verifiedBadge, name: 'Verified Badge', description: '', price: 499, icon: '✅', isOneTime: true),
    );
    String freeBoostsText = '';
    if (hasSub) {
      if (sub!.plan.tier == SubscriptionTier.elite) freeBoostsText = 'Unlimited boosts included';
      if (sub.plan.tier == SubscriptionTier.pro) freeBoostsText = '2 free boosts/month included';
    }

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: isPhone ? 12 : 16,
            right: isPhone ? 12 : 16,
            bottom: bottomPad,
          ),
          child: Column(
            children: [
              // Modern Header with Gradient Background
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isPhone ? 20 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.secondary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.trending_up_rounded,
                            color: theme.colorScheme.primary,
                            size: isPhone ? 24 : 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grow Your Business',
                                style: (isPhone ? theme.textTheme.headlineSmall : theme.textTheme.headlineMedium)?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Unlock premium features and boost your listings',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                      ],
                    ),
                    if (planStatus != null || freeBoostsText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (planStatus != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user, size: 16, color: theme.colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Text(planStatus, style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  )),
                                ],
                              ),
                            ),
                          if (freeBoostsText.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.rocket_launch, size: 16, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Text(freeBoostsText, style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  )),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
              
              // Premium Features: responsive layout
              if (isPhone)
                Column(
                  children: [
                    _buildPremiumCard(theme, isPhone, hasSub),
                    const SizedBox(height: 16),
                    _buildBoostCard(theme, isPhone, monet, boostItem, freeBoostsText),
                    const SizedBox(height: 16),
                    _buildVerifiedCard(theme, isPhone, monet, verifiedItem),
                  ],
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 16.0;
                    double cardWidth;
                    int perRow;
                    if (isTablet) {
                      perRow = 2;
                      final w = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
                      final clamped = w.clamp(280.0, 340.0);
                      cardWidth = clamped.toDouble();
                    } else {
                      // Desktop: adapt per-row to available width, favoring 3 per row
                      const minW = 360.0;
                      const maxW = 440.0;
                      if (constraints.maxWidth >= minW * 3 + spacing * 2) {
                        perRow = 3;
                      } else if (constraints.maxWidth >= minW * 2 + spacing * 1) {
                        perRow = 2;
                      } else {
                        perRow = 1;
                      }
                      final w = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
                      final clamped = w.clamp(minW, maxW);
                      cardWidth = clamped.toDouble();
                    }
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      alignment: isTablet ? WrapAlignment.start : WrapAlignment.center,
                      children: [
                        SizedBox(width: cardWidth, child: _buildPremiumCard(theme, isPhone, hasSub)),
                        SizedBox(width: cardWidth, child: _buildBoostCard(theme, isPhone, monet, boostItem, freeBoostsText)),
                        SizedBox(width: cardWidth, child: _buildVerifiedCard(theme, isPhone, monet, verifiedItem)),
                      ],
                    );
                  },
                ),


              SizedBox(height: isPhone ? 12 : 16),

              // Growth Tips
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(isPhone ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Growth Tips', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: isPhone ? 8 : 12),
                      _buildTipItem(Icons.schedule_outlined, Colors.amber, 'Respond to inquiries within 1 hour for better ranking', theme),
                      _buildTipItem(Icons.photo_library_outlined, Colors.indigo, 'Add at least 5 high‑quality photos per listing', theme),
                      _buildTipItem(Icons.event_available_outlined, Colors.teal, 'Keep your calendar updated to avoid cancellations', theme),
                      _buildTipItem(Icons.reviews_outlined, Colors.green, 'Encourage guests to leave reviews after checkout', theme),
                    ],
                  ),
                ),
              ),

              // Dynamic Tips
              ..._dynamicGrowthTips().isEmpty
                  ? []
                  : [
                      SizedBox(height: isPhone ? 12 : 16),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: EdgeInsets.all(isPhone ? 12 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.insights_outlined, color: Colors.purple),
                                const SizedBox(width: 8),
                                Text('Personalized Suggestions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ]),
                              SizedBox(height: isPhone ? 8 : 12),
                              ..._dynamicGrowthTips().map((t) => _buildBenefit(theme, Icons.bolt_outlined, t)),
                            ],
                          ),
                        ),
                      ),
                    ],

              SizedBox(height: isPhone ? 12 : 16),
              _buildGrowthChecklistCard(theme),
              SizedBox(height: isPhone ? 12 : 16),

              // Resources
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isPhone ? 12 : 16,
                    isPhone ? 12 : 16,
                    isPhone ? 12 : 16,
                    isPhone ? 0 : 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resources & Programs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: isPhone ? 8 : 12),
                      _buildBenefit(theme, Icons.help_outline, 'Visit Support Center for best practices'),
                      _buildBenefit(theme, Icons.school_outlined, 'Read host education and safety guidelines'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTipItem(IconData icon, Color color, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildBenefit(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildGrowthChecklistCard(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final total = _growthTasks.length;
    final completed = _completedGrowthTaskIds.length.clamp(0, total);
    final progress = total == 0 ? 0.0 : completed / total;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: theme.colorScheme.primary,
                    size: isPhone ? 24 : 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Growth Checklist',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isPhone ? 8 : 12),
            LinearProgressIndicator(value: progress, minHeight: 6),
            SizedBox(height: isPhone ? 8 : 12),
            ..._growthTasks.map((task) {
              final id = task['id']!;
              final title = task['title']!;
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: _completedGrowthTaskIds.contains(id),
                onChanged: (v) => _toggleGrowthTask(id, v),
                title: Text(title, style: theme.textTheme.bodySmall),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  for (final t in _growthTasks) {
                    await _toggleGrowthTask(t['id']!, true);
                  }
                },
                child: const Text('Mark all done'),
              ),
            )
          ],
        ),
      ),
    );
  }

  // _buildFloatingActionButton removed: No FAB on Owner Dashboard

  void _showAddListingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        final theme = Theme.of(ctx);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Text('Add New Listing', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(onPressed: () => ctx.pop(), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('What would you like to list?', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                _listingOption(ctx, title: 'Property/Room', description: 'List apartments, houses, rooms, and other properties', icon: Icons.home, color: Colors.blue, onTap: () {
                  ctx.pop();
                  context.push('/add-listing');
                }),
                const SizedBox(height: 16),
                _listingOption(ctx, title: 'Vehicle', description: 'List cars, bikes, scooters, and other vehicles', icon: Icons.directions_car, color: Colors.green, onTap: () {
                  ctx.pop();
                  context.push('/add-vehicle-listing');
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _listingOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  // Modern Premium Card
  Widget _buildPremiumCard(ThemeData theme, bool isPhone, bool hasSub) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1200;
    return Container(
      padding: EdgeInsets.all(isPhone ? 16 : (isDesktop ? 16 : 12)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.primary.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isPhone ? 10 : (isDesktop ? 10 : 8)),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.workspace_premium,
              color: theme.colorScheme.primary,
              size: isPhone ? 24 : (isDesktop ? 22 : 18),
            ),
          ),
          SizedBox(height: isPhone ? 16 : (isDesktop ? 12 : 10)),
          Text(
            'Premium Features',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isPhone ? 8 : (isDesktop ? 6 : 4)),
          Text(
            'Reduce commission rates, priority support, advanced analytics',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: isPhone ? 12 : (isDesktop ? 10 : 8)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(immersiveRouteOpenProvider.notifier).state = true;
                context.push('/subscription-plans').whenComplete(() {
                  if (!mounted) return;
                  ref.read(immersiveRouteOpenProvider.notifier).state = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: isPhone ? 12 : (isDesktop ? 12 : 8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isPhone ? 12 : (isDesktop ? 10 : 8)),
                ),
              ),
              child: Text(
                hasSub ? 'Manage Plan' : 'View Plans',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Boost Card
  Widget _buildBoostCard(ThemeData theme, bool isPhone, monet, boostItem, String freeBoostsText) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1200;
    return Container(
      padding: EdgeInsets.all(isPhone ? 16 : (isDesktop ? 16 : 12)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.08),
            Colors.orange.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isPhone ? 10 : (isDesktop ? 10 : 8)),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.rocket_launch,
              color: Colors.orange,
              size: isPhone ? 24 : (isDesktop ? 22 : 16),
            ),
          ),
          SizedBox(height: isPhone ? 16 : (isDesktop ? 12 : 10)),
          Text(
            'Boost Listings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isPhone ? 8 : (isDesktop ? 6 : 4)),
          Text(
            'Increase visibility and get more bookings',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (freeBoostsText.isNotEmpty) ...[
            SizedBox(height: isPhone ? 8 : (isDesktop ? 6 : 4)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                freeBoostsText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          SizedBox(height: isPhone ? 12 : (isDesktop ? 10 : 8)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(duration: Duration(milliseconds: 800), content: Text('Opening Promote Listing...')));
                  }
                  ref.read(immersiveRouteOpenProvider.notifier).state = true;
                  await context.push('/promote-listing');
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open Promote Listing: $e')));
                  }
                } finally {
                  ref.read(immersiveRouteOpenProvider.notifier).state = false;
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isPhone ? 12 : (isDesktop ? 12 : 8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isPhone ? 12 : (isDesktop ? 10 : 8)),
                ),
              ),
              child: Text(
                'Boost - ₹${boostItem.price.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Verified Card
  Widget _buildVerifiedCard(ThemeData theme, bool isPhone, monet, verifiedItem) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1200;
    return Container(
      padding: EdgeInsets.all(isPhone ? 16 : (isDesktop ? 16 : 12)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.08),
            Colors.green.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isPhone ? 10 : (isDesktop ? 10 : 8)),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.verified,
              color: Colors.green,
              size: isPhone ? 24 : (isDesktop ? 22 : 18),
            ),
          ),
          SizedBox(height: isPhone ? 16 : (isDesktop ? 12 : 10)),
          Text(
            'Verified Badge',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isPhone ? 8 : (isDesktop ? 6 : 4)),
          Text(
            'Build trust with guests and increase bookings',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: isPhone ? 12 : (isDesktop ? 10 : 8)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final isKycVerified = ref.read(authProvider).user?.isKycVerified == true;
                if (!isKycVerified) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete KYC to buy the Verified badge')));
                  }
                  ref.read(immersiveRouteOpenProvider.notifier).state = true;
                  await context.push('/kyc').whenComplete(() {
                    if (!mounted) return;
                    ref.read(immersiveRouteOpenProvider.notifier).state = false;
                  });
                  return;
                }
                final ok = await ref.read(monetizationServiceProvider.notifier).purchaseMicrotransaction(verifiedItem);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Verified badge purchased' : 'Purchase failed')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isPhone ? 12 : (isDesktop ? 12 : 8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isPhone ? 12 : (isDesktop ? 10 : 8)),
                ),
              ),
              child: Text(
                'Get Verified - ₹${verifiedItem.price.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
