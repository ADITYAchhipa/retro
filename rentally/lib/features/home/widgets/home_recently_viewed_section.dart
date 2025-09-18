import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../core/widgets/loading_states.dart';
import '../../../core/providers/listing_feed_provider.dart';
import '../../../core/widgets/listing_card.dart';
import '../../../core/widgets/listing_card_list.dart';
// import '../../../core/widgets/hover_scale.dart'; // no longer used

class HomeRecentlyViewedSection extends StatefulWidget {
  final ThemeData theme;
  final bool isDark;
  final TabController tabController;
  final String selectedCategory;

  const HomeRecentlyViewedSection({
    super.key,
    required this.theme,
    required this.isDark,
    required this.tabController,
    required this.selectedCategory,
  });

  @override
  State<HomeRecentlyViewedSection> createState() => _HomeRecentlyViewedSectionState();
}

class _HomeRecentlyViewedSectionState extends State<HomeRecentlyViewedSection> {
  // Hover state handled by HoverScale; no explicit state needed here

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = widget.isDark;
    final bool isPropertyTab = widget.tabController.index == 0;
    return pv.Consumer<ListingFeedProvider>(builder: (context, feed, _) {
      var items = feed.recently.where((vm) => isPropertyTab ? !vm.isVehicle : vm.isVehicle).toList();
      bool matchesCategory(ListingViewModel vm) {
        if (isPropertyTab) {
          if (widget.selectedCategory == 'All') return true;
        } else {
          if (widget.selectedCategory == 'Cars') return true;
        }
        final cat = widget.selectedCategory.toLowerCase();
        final candidates = <String>[vm.title, ...vm.chips];
        return candidates.any((s) {
          final t = s.toLowerCase();
          return t.contains(cat) || (cat.endsWith('s') && t.contains(cat.substring(0, cat.length - 1)));
        });
      }
      items = items.where(matchesCategory).toList();

      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                isPropertyTab ? 'Recently Viewed' : 'Recently Viewed Vehicles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? theme.colorScheme.onBackground : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        items.isEmpty
            ? _buildShimmerList()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, index) => _buildRecentlyViewedItem(index, items[index], theme, isDark),
              ),
      ],
    );
    });
  }

  Widget _buildRecentlyViewedItem(int index, ListingViewModel item, ThemeData theme, bool isDark) {
    return ListingListCard(
      model: item,
      isDark: isDark,
      margin: const EdgeInsets.only(bottom: 12),
      chipOnImage: false,
      showInfoChip: false,
      chipBelowImage: true,
      // width will expand within the ListView padding
    );
  }

  // (legacy) removed local mock generator; using ListingFeedProvider instead

  Widget _buildShimmerList() {
    final isDark = widget.isDark;
    final theme = widget.theme;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? theme.colorScheme.outline.withOpacity(0.6)
                  : Colors.grey.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: const Row(
            children: [
              SkeletonLoader(width: 84, height: 84, borderRadius: BorderRadius.all(Radius.circular(12))),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 180, height: 16),
                    SizedBox(height: 8),
                    SkeletonLoader(width: 140, height: 14),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SkeletonLoader(width: 60, height: 24, borderRadius: BorderRadius.all(Radius.circular(8))),
            ],
          ),
        );
      },
    );
  }
}
