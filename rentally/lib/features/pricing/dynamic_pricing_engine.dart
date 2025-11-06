import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

// Pricing factors and models
class PricingFactors {
  final double basePrice;
  final double seasonalMultiplier;
  final double demandMultiplier;
  final double competitionMultiplier;
  final double eventMultiplier;
  final double weekendMultiplier;
  final double occupancyMultiplier;
  final double reviewScoreMultiplier;

  const PricingFactors({
    required this.basePrice,
    this.seasonalMultiplier = 1.0,
    this.demandMultiplier = 1.0,
    this.competitionMultiplier = 1.0,
    this.eventMultiplier = 1.0,
    this.weekendMultiplier = 1.0,
    this.occupancyMultiplier = 1.0,
    this.reviewScoreMultiplier = 1.0,
  });

  double get suggestedPrice {
    return basePrice *
        seasonalMultiplier *
        demandMultiplier *
        competitionMultiplier *
        eventMultiplier *
        weekendMultiplier *
        occupancyMultiplier *
        reviewScoreMultiplier;
  }
}

class PricingRecommendation {
  final double currentPrice;
  final double suggestedPrice;
  final double potentialRevenue;
  final String confidence;
  final List<String> factors;
  final Map<String, double> breakdown;

  PricingRecommendation({
    required this.currentPrice,
    required this.suggestedPrice,
    required this.potentialRevenue,
    required this.confidence,
    required this.factors,
    required this.breakdown,
  });

  double get priceChange => suggestedPrice - currentPrice;
  double get percentageChange => (priceChange / currentPrice) * 100;
}

// Dynamic Pricing Service
class DynamicPricingService extends StateNotifier<List<PricingRecommendation>> {
  DynamicPricingService() : super([]);

  PricingRecommendation calculatePricing({
    required String propertyId,
    required double currentPrice,
    required DateTime date,
    required String location,
    required String propertyType,
    required double rating,
    required int reviewCount,
    required double occupancyRate,
  }) {
    // Simulate market analysis
    final marketAnalysis = _analyzeMarketFactors(
      date: date,
      location: location,
      propertyType: propertyType,
      rating: rating,
      occupancyRate: occupancyRate,
    );

    final pricingFactors = PricingFactors(
      basePrice: currentPrice,
      seasonalMultiplier: marketAnalysis['seasonal']!,
      demandMultiplier: marketAnalysis['demand']!,
      competitionMultiplier: marketAnalysis['competition']!,
      eventMultiplier: marketAnalysis['events']!,
      weekendMultiplier: marketAnalysis['weekend']!,
      occupancyMultiplier: marketAnalysis['occupancy']!,
      reviewScoreMultiplier: marketAnalysis['reviews']!,
    );

    final suggestedPrice = pricingFactors.suggestedPrice;
    final potentialRevenue = _calculatePotentialRevenue(currentPrice, suggestedPrice);
    final confidence = _calculateConfidence(marketAnalysis);
    final factorsList = _generateFactorsList(marketAnalysis);

    return PricingRecommendation(
      currentPrice: currentPrice,
      suggestedPrice: suggestedPrice,
      potentialRevenue: potentialRevenue,
      confidence: confidence,
      factors: factorsList,
      breakdown: marketAnalysis,
    );
  }

  Map<String, double> _analyzeMarketFactors({
    required DateTime date,
    required String location,
    required String propertyType,
    required double rating,
    required double occupancyRate,
  }) {
    final random = math.Random(date.millisecondsSinceEpoch);
    
    // Seasonal analysis
    final month = date.month;
    double seasonal = 1.0;
    if ([6, 7, 8, 12].contains(month)) {
      seasonal = 1.2 + (random.nextDouble() * 0.3); // Peak season
    } else if ([3, 4, 5, 9, 10].contains(month)) {
      seasonal = 1.0 + (random.nextDouble() * 0.2); // Medium season
    } else {
      seasonal = 0.8 + (random.nextDouble() * 0.2); // Low season
    }

    // Demand analysis (simulated based on location popularity)
    final locationMultipliers = {
      'downtown': 1.3,
      'beach': 1.4,
      'city center': 1.2,
      'airport': 1.1,
      'suburbs': 0.9,
    };
    
    double demand = 1.0;
    for (final entry in locationMultipliers.entries) {
      if (location.toLowerCase().contains(entry.key)) {
        demand = entry.value + (random.nextDouble() * 0.2 - 0.1);
        break;
      }
    }

    // Competition analysis
    double competition = 0.95 + (random.nextDouble() * 0.1); // Slight price pressure

    // Event analysis (simulate local events)
    double events = 1.0;
    if (random.nextDouble() < 0.15) { // 15% chance of local event
      events = 1.5 + (random.nextDouble() * 0.5); // Major event boost
    } else if (random.nextDouble() < 0.3) { // 30% chance of minor event
      events = 1.1 + (random.nextDouble() * 0.2);
    }

    // Weekend analysis
    double weekend = 1.0;
    if ([DateTime.friday, DateTime.saturday, DateTime.sunday].contains(date.weekday)) {
      weekend = 1.15 + (random.nextDouble() * 0.15);
    }

    // Occupancy analysis
    double occupancyMultiplier = 1.0;
    if (occupancyRate > 0.8) {
      occupancyMultiplier = 1.1 + (occupancyRate - 0.8) * 0.5;
    } else if (occupancyRate < 0.5) {
      occupancyMultiplier = 0.9 - (0.5 - occupancyRate) * 0.3;
    }

    // Review score analysis
    double reviewMultiplier = 1.0;
    if (rating >= 4.5) {
      reviewMultiplier = 1.05 + ((rating - 4.5) / 0.5) * 0.1;
    } else if (rating < 4.0) {
      reviewMultiplier = 0.95 - ((4.0 - rating) / 4.0) * 0.15;
    }

    return {
      'seasonal': seasonal,
      'demand': demand,
      'competition': competition,
      'events': events,
      'weekend': weekend,
      'occupancy': occupancyMultiplier,
      'reviews': reviewMultiplier,
    };
  }

  double _calculatePotentialRevenue(double currentPrice, double suggestedPrice) {
    // Simulate potential revenue increase based on price optimization
    final priceChange = (suggestedPrice - currentPrice) / currentPrice;
    const demandElasticity = -0.5; // Assume moderate price elasticity
    final occupancyChange = priceChange * demandElasticity;
    
    // Calculate potential monthly revenue (assuming 30 days)
    final currentRevenue = currentPrice * 30 * 0.7; // 70% occupancy
    final newOccupancy = math.max(0.1, math.min(1.0, 0.7 + occupancyChange));
    final newRevenue = suggestedPrice * 30 * newOccupancy;
    
    return newRevenue - currentRevenue;
  }

  String _calculateConfidence(Map<String, double> factors) {
    // Calculate confidence based on factor variance
    final values = factors.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    
    if (variance < 0.05) return 'High';
    if (variance < 0.15) return 'Medium';
    return 'Low';
  }

  List<String> _generateFactorsList(Map<String, double> factors) {
    final factorsList = <String>[];
    
    factors.forEach((key, value) {
      if (value > 1.1) {
        factorsList.add('${_formatFactorName(key)} driving prices up (+${((value - 1) * 100).toStringAsFixed(0)}%)');
      } else if (value < 0.9) {
        factorsList.add('${_formatFactorName(key)} reducing prices (-${((1 - value) * 100).toStringAsFixed(0)}%)');
      }
    });

    if (factorsList.isEmpty) {
      factorsList.add('Market conditions are stable');
    }

    return factorsList;
  }

  String _formatFactorName(String key) {
    switch (key) {
      case 'seasonal': return 'Seasonal demand';
      case 'demand': return 'Location demand';
      case 'competition': return 'Competition';
      case 'events': return 'Local events';
      case 'weekend': return 'Weekend premium';
      case 'occupancy': return 'Occupancy rate';
      case 'reviews': return 'Review score';
      default: return key;
    }
  }

  void updatePricingRecommendations(List<PricingRecommendation> recommendations) {
    state = recommendations;
  }
}

// Provider
final dynamicPricingServiceProvider = StateNotifierProvider<DynamicPricingService, List<PricingRecommendation>>(
  (ref) => DynamicPricingService(),
);

// Dynamic Pricing Screen
class DynamicPricingScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const DynamicPricingScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
  });

  @override
  ConsumerState<DynamicPricingScreen> createState() => _DynamicPricingScreenState();
}

class _DynamicPricingScreenState extends ConsumerState<DynamicPricingScreen> {
  late PricingRecommendation _currentRecommendation;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPricingData();
  }

  void _loadPricingData() {
    setState(() => _isLoading = true);
    
    // Simulate API call delay
    Future.delayed(const Duration(seconds: 2), () {
      final service = ref.read(dynamicPricingServiceProvider.notifier);
      _currentRecommendation = service.calculatePricing(
        propertyId: widget.propertyId,
        currentPrice: 150.0, // Mock current price
        date: _selectedDate,
        location: 'Downtown Manhattan',
        propertyType: 'Apartment',
        rating: 4.7,
        reviewCount: 89,
        occupancyRate: 0.75,
      );
      
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Pricing'),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            onPressed: _loadPricingData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildPricingContent(theme),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Analyzing market conditions...'),
        ],
      ),
    );
  }

  Widget _buildPricingContent(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPropertyHeader(theme),
          const SizedBox(height: 24),
          _buildDateSelector(theme),
          const SizedBox(height: 24),
          _buildPricingRecommendation(theme),
          const SizedBox(height: 24),
          _buildFactorsAnalysis(theme),
          const SizedBox(height: 24),
          _buildRevenueProjection(theme),
          const SizedBox(height: 24),
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildPropertyHeader(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.propertyTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  'Downtown Manhattan',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Date',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                  _loadPricingData();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: theme.colorScheme.outline),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingRecommendation(ThemeData theme) {
    final isIncrease = _currentRecommendation.priceChange > 0;
    final changeColor = isIncrease ? Colors.green : Colors.red;
    
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
                  'Pricing Recommendation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(_currentRecommendation.confidence).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentRecommendation.confidence} Confidence',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getConfidenceColor(_currentRecommendation.confidence),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Price',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      Text(
                        '\$${_currentRecommendation.currentPrice.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.outline,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Suggested Price',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      Text(
                        '\$${_currentRecommendation.suggestedPrice.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isIncrease ? Icons.trending_up : Icons.trending_down,
                    color: changeColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isIncrease ? '+' : ''}\$${_currentRecommendation.priceChange.toStringAsFixed(0)} (${_currentRecommendation.percentageChange.toStringAsFixed(1)}%)',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: changeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorsAnalysis(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Factors',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._currentRecommendation.factors.map((factor) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      factor,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueProjection(ThemeData theme) {
    final isPositive = _currentRecommendation.potentialRevenue > 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Impact',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projected Monthly Change',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      Text(
                        '${isPositive ? '+' : ''}\$${_currentRecommendation.potentialRevenue.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              _showApplyPricingDialog();
            },
            icon: const Icon(Icons.check),
            label: const Text('Apply Suggested Pricing'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _showCustomPricingDialog();
            },
            icon: const Icon(Icons.edit),
            label: const Text('Set Custom Price'),
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(String confidence) {
    switch (confidence) {
      case 'High': return Colors.green;
      case 'Medium': return Colors.orange;
      case 'Low': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showApplyPricingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Suggested Pricing'),
        content: Text(
          'Are you sure you want to update your price to \$${_currentRecommendation.suggestedPrice.toStringAsFixed(0)} per month?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pricing updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showCustomPricingDialog() {
    final controller = TextEditingController(
      text: _currentRecommendation.currentPrice.toStringAsFixed(0),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Custom Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly price',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Suggested: \$${_currentRecommendation.suggestedPrice.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Price updated to \$${controller.text}!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
