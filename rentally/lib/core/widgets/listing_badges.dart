import 'package:flutter/material.dart';

/// Badge types for listings
enum ListingBadgeType {
  verified,
  instantBook,
  superhost,
  newListing,
  topRated,
  featured,
}

/// Individual badge widget for listings
class ListingBadge extends StatelessWidget {
  final ListingBadgeType type;
  final bool isDark;
  final double? fontSize;

  const ListingBadge({
    super.key,
    required this.type,
    required this.isDark,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getBadgeConfig(type, isDark);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: config.borderColor != null 
            ? Border.all(color: config.borderColor!, width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.icon != null) ...[
            Icon(
              config.icon,
              size: (fontSize ?? 10) + 1,
              color: config.textColor,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            config.label,
            style: TextStyle(
              fontSize: fontSize ?? 10,
              fontWeight: FontWeight.w600,
              color: config.textColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getBadgeConfig(ListingBadgeType type, bool isDark) {
    switch (type) {
      case ListingBadgeType.verified:
        return _BadgeConfig(
          label: 'Verified',
          icon: Icons.verified,
          backgroundColor: const Color(0xFF20C997).withOpacity(0.1),
          textColor: const Color(0xFF20C997),
          borderColor: const Color(0xFF20C997).withOpacity(0.3),
        );
      case ListingBadgeType.instantBook:
        return _BadgeConfig(
          label: 'Instant Book',
          icon: Icons.flash_on,
          backgroundColor: const Color(0xFF6F42C1).withOpacity(0.1),
          textColor: const Color(0xFF6F42C1),
          borderColor: const Color(0xFF6F42C1).withOpacity(0.3),
        );
      case ListingBadgeType.superhost:
        return _BadgeConfig(
          label: 'Superhost',
          icon: Icons.star,
          backgroundColor: const Color(0xFFFFB800).withOpacity(0.1),
          textColor: const Color(0xFFFFB800),
          borderColor: const Color(0xFFFFB800).withOpacity(0.3),
        );
      case ListingBadgeType.newListing:
        return _BadgeConfig(
          label: 'New',
          backgroundColor: isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.withOpacity(0.1),
          textColor: Colors.blue,
          borderColor: Colors.blue.withOpacity(0.3),
        );
      case ListingBadgeType.topRated:
        return _BadgeConfig(
          label: 'Top Rated',
          icon: Icons.trending_up,
          backgroundColor: const Color(0xFFE91E63).withOpacity(0.1),
          textColor: const Color(0xFFE91E63),
          borderColor: const Color(0xFFE91E63).withOpacity(0.3),
        );
      case ListingBadgeType.featured:
        return _BadgeConfig(
          label: 'Featured',
          icon: Icons.star_border,
          backgroundColor: isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.withOpacity(0.1),
          textColor: Colors.orange,
          borderColor: Colors.orange.withOpacity(0.3),
        );
    }
  }
}

/// Badge configuration data class
class _BadgeConfig {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const _BadgeConfig({
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });
}

/// Badge row widget for multiple badges
class ListingBadgeRow extends StatelessWidget {
  final List<ListingBadgeType> badges;
  final bool isDark;
  final double? fontSize;
  final int maxBadges;

  const ListingBadgeRow({
    super.key,
    required this.badges,
    required this.isDark,
    this.fontSize,
    this.maxBadges = 3,
  });

  @override
  Widget build(BuildContext context) {
    final displayBadges = badges.take(maxBadges).toList();
    
    if (displayBadges.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: displayBadges.map((badge) => ListingBadge(
        type: badge,
        isDark: isDark,
        fontSize: fontSize,
      )).toList(),
    );
  }
}
