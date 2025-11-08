import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/featured_provider.dart';
import '../../../core/widgets/listing_card.dart';
import '../../../core/widgets/loading_states.dart';

/// Featured section widget with category switching
class FeaturedSection extends ConsumerWidget {
  const FeaturedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredState = ref.watch(featuredProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with category switcher
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Category toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _CategoryButton(
                      label: 'Properties',
                      isSelected: featuredState.category == FeaturedCategory.property,
                      onTap: () => ref.read(featuredProvider.notifier)
                          .switchCategory(FeaturedCategory.property),
                    ),
                    _CategoryButton(
                      label: 'Vehicles',
                      isSelected: featuredState.category == FeaturedCategory.vehicle,
                      onTap: () => ref.read(featuredProvider.notifier)
                          .switchCategory(FeaturedCategory.vehicle),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content
        if (featuredState.isLoading && featuredState.items.isEmpty)
          const SizedBox(
            height: 200,
            child: Center(child: LoadingSpinner()),
          )
        else if (featuredState.error != null && featuredState.items.isEmpty)
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load featured items',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(featuredProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (featuredState.items.isEmpty)
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No featured ${featuredState.category == FeaturedCategory.property ? 'properties' : 'vehicles'} available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 280,
            child: Stack(
              children: [
                ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: featuredState.items.length,
                  itemBuilder: (context, index) {
                    final listing = featuredState.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 280,
                        child: ListingCard(listing: listing),
                      ),
                    );
                  },
                ),
                // Loading overlay when switching categories
                if (featuredState.isLoading && featuredState.items.isNotEmpty)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: const Center(
                        child: LoadingSpinner(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Category button widget
class _CategoryButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[300] : Colors.grey[700]),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
