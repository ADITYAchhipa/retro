import '../ai/ai_recommendation_engine.dart';

class AdapterProperty {
  final String id;
  final String title;
  final String location;
  final double price;
  final int bedrooms;
  final int bathrooms;
  final List<String> amenities;
  final List<String> images;
  final double matchScore; // 0..1
  final Map<String, double> scoreBreakdown;
  final List<String> matchReasons;
  final String aiInsight;

  AdapterProperty({
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

class AdapterCategory {
  final String name;
  final String description;
  final List<AdapterProperty> properties;

  AdapterCategory({
    required this.name,
    required this.description,
    required this.properties,
  });
}

class AiRecommendationAdapter {
  static Future<List<AdapterCategory>> buildCategoriesFromAi({
    required String userId,
    required List<Map<String, dynamic>> availableProperties,
    double? userMaxBudget,
  }) async {
    final engine = AIRecommendationEngine.instance;

    final recs = await engine.generateRecommendations(
      userId: userId,
      availableProperties: availableProperties,
    );

    // Map properties by id for enrichment
    final byId = {
      for (final p in availableProperties)
        (p['id'] as String): p,
    };

    // Group by type
    final Map<RecommendationType, List<AdapterProperty>> grouped = {};

    for (final r in recs) {
      final src = byId[r.propertyId] ?? const <String, dynamic>{};
      final title = (src['title'] as String?) ?? 'Property ${r.propertyId}';
      final location = (src['location'] as String?) ?? 'Unknown';
      final price = ((src['price'] as num?)?.toDouble()) ?? 100.0;
      final bedrooms = (src['bedrooms'] as int?) ?? 2;
      final bathrooms = (src['bathrooms'] as int?) ?? 2;
      final amenities = List<String>.from(src['amenities'] ?? const <String>[]);
      final images = List<String>.from(src['images'] ?? const <String>[]);

      final prop = AdapterProperty(
        id: r.propertyId,
        title: title,
        location: location,
        price: price,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        amenities: amenities,
        images: images,
        matchScore: r.score,
        scoreBreakdown: {'Overall': r.score},
        matchReasons: r.reasons,
        aiInsight: _composeInsight(r, title, location),
      );

      grouped.putIfAbsent(r.category, () => <AdapterProperty>[]).add(prop);
    }

    final categories = <AdapterCategory>[];

    void addCat(String name, String desc, RecommendationType type) {
      final props = grouped[type] ?? const <AdapterProperty>[];
      if (props.isNotEmpty) {
        categories.add(AdapterCategory(name: name, description: desc, properties: props));
      }
    }

    addCat('Perfect Matches', 'Properties that match all your criteria', RecommendationType.perfectMatch);
    addCat('Good Matches', 'Strong alignment with your preferences', RecommendationType.goodMatch);
    addCat('Trending Now', 'Popular properties gaining attention', RecommendationType.popular);
    addCat('Highly Rated', 'Top rated places guests love', RecommendationType.highlyRated);

    // General fallback
    final generalProps = grouped[RecommendationType.general] ?? const <AdapterProperty>[];
    if (generalProps.isNotEmpty) {
      categories.add(AdapterCategory(
        name: 'Recommended',
        description: 'Good options based on your profile',
        properties: generalProps,
      ));
    }

    // Derive Budget Friendly using userMaxBudget if provided
    if (userMaxBudget != null && userMaxBudget > 0) {
      final allProps = <AdapterProperty>[];
      for (final list in grouped.values) {
        allProps.addAll(list);
      }
      final budgetFriendly = allProps
          .where((p) => p.price <= userMaxBudget * 0.7)
          .toList()
        ..sort((a, b) => a.price.compareTo(b.price));
      if (budgetFriendly.isNotEmpty) {
        categories.add(AdapterCategory(
          name: 'Budget Friendly',
          description: 'Great value properties within your budget',
          properties: budgetFriendly.take(10).toList(),
        ));
      }
    }

    return categories;
  }

  static String _composeInsight(PropertyRecommendation rec, String title, String location) {
    final reason = rec.reasons.isNotEmpty ? rec.reasons.first : 'Matches your profile';
    final conf = (rec.confidence * 100).toStringAsFixed(0);
    return '$title in $location is recommended because: $reason. Confidence $conf%.';
  }
}
