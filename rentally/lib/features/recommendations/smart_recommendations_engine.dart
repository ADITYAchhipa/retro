import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../core/widgets/tab_back_handler.dart';
import 'ai_recommendation_adapter.dart';

// Recommendation Models
class UserPreferences {
  final double maxBudget;
  final int minBedrooms;
  final int maxBedrooms;
  final List<String> preferredAmenities;
  final List<String> preferredLocations;
  final String propertyType;
  final double maxCommute;
  final List<String> lifestyle;
  final Map<String, double> priorities;

  UserPreferences({
    required this.maxBudget,
    required this.minBedrooms,
    required this.maxBedrooms,
    required this.preferredAmenities,
    required this.preferredLocations,
    required this.propertyType,
    required this.maxCommute,
    required this.lifestyle,
    required this.priorities,
  });
}

class PropertyRecommendation {
  final String id;
  final String title;
  final String location;
  final double price;
  final int bedrooms;
  final int bathrooms;
  final List<String> amenities;
  final List<String> images;
  final double matchScore;
  final Map<String, double> scoreBreakdown;
  final List<String> matchReasons;
  final String aiInsight;

  PropertyRecommendation({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.amenities,
    required this.images,
    required this.matchScore,
    required this.scoreBreakdown,
    required this.matchReasons,
    required this.aiInsight,
  });
}

class RecommendationCategory {
  final String name;
  final String description;
  final IconData icon;
  final List<PropertyRecommendation> properties;

  RecommendationCategory({
    required this.name,
    required this.description,
    required this.icon,
    required this.properties,
  });
}

// Smart Recommendations Service
class SmartRecommendationsService extends StateNotifier<List<RecommendationCategory>> {
  SmartRecommendationsService() : super([]);

  void generateRecommendations(UserPreferences preferences) {
    // Consolidated: use AI engine via adapter and map to UI categories
    _generateFromAi(preferences);
  }

  Future<void> _generateFromAi(UserPreferences preferences) async {
    final available = _fakeAvailableProperties(preferences);
    final adapterCategories = await AiRecommendationAdapter.buildCategoriesFromAi(
      userId: 'current',
      availableProperties: available,
      userMaxBudget: preferences.maxBudget,
    );
    final mapped = _mapAdapterToLocal(adapterCategories);
    state = mapped;
  }

  List<Map<String, dynamic>> _fakeAvailableProperties(UserPreferences p) {
    final locations = p.preferredLocations.isNotEmpty ? p.preferredLocations : ['Downtown'];
    final amenitiesBase = p.preferredAmenities.isNotEmpty ? p.preferredAmenities : ['WiFi', 'Parking'];
    final minBeds = p.minBedrooms;
    final maxBeds = p.maxBedrooms >= p.minBedrooms ? p.maxBedrooms : p.minBedrooms;
    return List.generate(30, (i) {
      final loc = locations[i % locations.length];
      final price = (p.maxBudget > 0 ? p.maxBudget : 2000) * (0.5 + (i % 7) * 0.1);
      final beds = (minBeds + (i % ((maxBeds - minBeds + 1).clamp(1, 4)))).clamp(1, 5);
      final baths = beds >= 3 ? 2 : 1;
      return {
        'id': 'p${i + 1}',
        'title': '${p.propertyType} #${i + 1}',
        'location': loc,
        'price': price,
        'bedrooms': beds,
        'bathrooms': baths,
        'type': p.propertyType.toLowerCase(),
        'amenities': [...amenitiesBase.take(5)],
        'rating': 4.2,
        'images': ['img_${i + 1}.jpg'],
      };
    });
  }

  List<RecommendationCategory> _mapAdapterToLocal(List<AdapterCategory> cats) {
    return cats.map((c) {
      return RecommendationCategory(
        name: c.name,
        description: c.description,
        icon: _iconForCategory(c.name),
        properties: c.properties.map((p) => PropertyRecommendation(
          id: p.id,
          title: p.title,
          location: p.location,
          price: p.price,
          bedrooms: p.bedrooms,
          bathrooms: p.bathrooms,
          amenities: p.amenities,
          images: p.images,
          matchScore: p.matchScore,
          scoreBreakdown: p.scoreBreakdown,
          matchReasons: p.matchReasons,
          aiInsight: p.aiInsight,
        )).toList(),
      );
    }).toList();
  }

  IconData _iconForCategory(String name) {
    if (name.contains('Perfect')) return Icons.star;
    if (name.contains('Good')) return Icons.thumb_up;
    if (name.contains('Trending')) return Icons.trending_up;
    if (name.contains('Highly')) return Icons.reviews;
    if (name.contains('Budget')) return Icons.attach_money;
    return Icons.home;
  }

}

// Provider
final smartRecommendationsProvider = StateNotifierProvider<SmartRecommendationsService, List<RecommendationCategory>>(
  (ref) => SmartRecommendationsService(),
);

// Smart Recommendations Screen
class SmartRecommendationsScreen extends ConsumerStatefulWidget {
  const SmartRecommendationsScreen({super.key});

  @override
  ConsumerState<SmartRecommendationsScreen> createState() => _SmartRecommendationsScreenState();
}

class _SmartRecommendationsScreenState extends ConsumerState<SmartRecommendationsScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  bool _isLoading = true;
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _loadingController.repeat();
    _generateRecommendations();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  void _generateRecommendations() {
    // Simulate user preferences
    final preferences = UserPreferences(
      maxBudget: 2500,
      minBedrooms: 1,
      maxBedrooms: 3,
      preferredAmenities: ['WiFi', 'Parking', 'Gym', 'Pool', 'Laundry'],
      preferredLocations: ['Downtown', 'Marina District', 'Arts Quarter'],
      propertyType: 'Apartment',
      maxCommute: 30,
      lifestyle: ['Urban', 'Active', 'Social'],
      priorities: {
        'Budget': 0.3,
        'Location': 0.25,
        'Amenities': 0.2,
        'Size': 0.15,
        'Style': 0.1,
      },
    );

    ref.read(smartRecommendationsProvider.notifier).generateRecommendations(preferences);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final categories = ref.read(smartRecommendationsProvider);
        if (categories.isEmpty) {
          setState(() => _isLoading = false);
          _loadingController.stop();
          return;
        }
        _tabController = TabController(length: categories.length, vsync: this);
        setState(() => _isLoading = false);
        _loadingController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(smartRecommendationsProvider);

    final body = _isLoading
        ? _buildLoadingScreen(theme)
        : (categories.isEmpty
            ? _buildEmptyRecommendations(theme)
            : _buildRecommendationsContent(categories, theme));

    return TabBackHandler(
      tabController: (_isLoading || categories.isEmpty) ? null : _tabController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recommendations'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          actions: [
            IconButton(
              onPressed: _showPreferencesDialog,
              icon: const Icon(Icons.tune),
            ),
            IconButton(
              onPressed: _refreshRecommendations,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: body,
      ),
    );
  }

  Widget _buildEmptyRecommendations(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_alt, color: theme.colorScheme.primary, size: 36),
            const SizedBox(height: 12),
            Text(
              'No recommendations yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your preferences or exploring a few listings to help our AI learn your taste.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingController.value * 2 * math.pi,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: theme.colorScheme.onPrimary,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Analyzing Your Preferences',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Our AI is finding the perfect properties for you...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          LinearProgressIndicator(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsContent(List<RecommendationCategory> categories, ThemeData theme) {
    return Column(
      children: [
        Container(
          color: theme.colorScheme.surface,
          child: TabBar(
            controller: _tabController!,
            isScrollable: true,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: theme.colorScheme.primary,
            tabs: categories.map((category) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(category.icon, size: 20),
                    const SizedBox(width: 8),
                    Text(category.name),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController!,
            dragStartBehavior: DragStartBehavior.down,
            physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
            children: categories.map((category) {
              return _buildCategoryContent(category, theme);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryContent(RecommendationCategory category, ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(category.icon, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            category.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${category.properties.length} properties found',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final property = category.properties[index];
              return _buildPropertyCard(property, theme);
            },
            childCount: category.properties.length,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(PropertyRecommendation property, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.purple.shade300],
                    ),
                  ),
                  child: const Icon(
                    Icons.home,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getMatchScoreColor(property.matchScore),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${(property.matchScore * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: IconButton(
                    onPressed: () => _toggleFavorite(property),
                    icon: const Icon(Icons.favorite_border, color: Colors.white),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$${property.price.toStringAsFixed(0)}/mo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        property.location,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const Spacer(),
                      Text('${property.bedrooms} bed • ${property.bathrooms} bath'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'AI Insight',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          property.aiInsight,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: property.matchReasons.map((reason) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          reason,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showMatchBreakdown(property),
                          child: const Text('Match Details'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _viewProperty(property),
                          child: const Text('View Property'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMatchScoreColor(double score) {
    if (score >= 0.9) return Colors.green;
    if (score >= 0.8) return Colors.orange;
    return Colors.red;
  }

  void _showPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Preferences'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Preference settings would be implemented here'),
            SizedBox(height: 16),
            Text('• Budget range'),
            Text('• Preferred locations'),
            Text('• Required amenities'),
            Text('• Property type'),
            Text('• Lifestyle preferences'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _refreshRecommendations();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _refreshRecommendations() {
    setState(() => _isLoading = true);
    _loadingController.repeat();
    _generateRecommendations();
  }

  void _toggleFavorite(PropertyRecommendation property) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${property.title} added to favorites'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showMatchBreakdown(PropertyRecommendation property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match Breakdown',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              property.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: property.scoreBreakdown.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${(entry.value * 100).round()}%',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: entry.value,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getMatchScoreColor(entry.value),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewProperty(PropertyRecommendation property) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${property.title} details...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
