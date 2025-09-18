import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:provider/provider.dart' as pv;
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/enterprise_dark_theme.dart';
import '../theme/enterprise_light_theme.dart';
import '../../services/view_history_service.dart';
import '../../services/wishlist_service.dart';
import 'listing_badges.dart';
import '../../app/auth_router.dart';

class ListingMetaItem {
  final IconData icon;
  final String text;
  const ListingMetaItem({required this.icon, required this.text});
}

class ListingViewModel {
  final String id;
  final String title;
  final String location;
  final String priceLabel;
  final String? imageUrl;
  final double rating;
  final int? reviewCount;
  final List<String> chips; // optional label chips
  final List<ListingMetaItem> metaItems; // icon + text items
  final IconData fallbackIcon;
  final bool isVehicle; // optional type flag for filtering
  final double? latitude;
  final double? longitude;
  final double? distanceKm; // computed at runtime when user location is available
  final List<ListingBadgeType> badges; // optional trust/safety badges
  final bool isFavorite; // favorite status

  const ListingViewModel({
    required this.id,
    required this.title,
    required this.location,
    required this.priceLabel,
    required this.imageUrl,
    required this.rating,
    this.reviewCount,
    this.chips = const [],
    this.metaItems = const [],
    this.fallbackIcon = Icons.home,
    this.isVehicle = false,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.badges = const [],
    this.isFavorite = false,
  });
}

class ListingCard extends rp.ConsumerWidget {
  final ListingViewModel model;
  final bool isDark;
  final double width;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showWishlistButton;
  final bool showShareButton;
  final bool compact;
  final bool chipOnImage;
  final bool showInfoChip;
  final bool chipInRatingRowRight;
  final bool priceBottomLeft;
  final bool shareBottomRight;

  const ListingCard({
    super.key,
    required this.model,
    required this.isDark,
    this.width = 280,
    this.margin = const EdgeInsets.only(right: 12),
    this.onTap,
    this.onLongPress,
    this.showWishlistButton = true,
    this.showShareButton = true,
    this.compact = false,
    this.chipOnImage = false,
    this.showInfoChip = true,
    this.chipInRatingRowRight = false,
    this.priceBottomLeft = false,
    this.shareBottomRight = false,
  });

  @override
  Widget build(BuildContext context, rp.WidgetRef ref) {
    final bool isCompact = compact || width <= 280;
    return GestureDetector(
      onTap: () {
        // Track view when card is tapped
        final viewHistoryService = pv.Provider.of<ViewHistoryService>(context, listen: false);
        viewHistoryService.trackView(
          id: model.id,
          title: model.title,
          type: model.isVehicle ? 'vehicle' : 'property',
          imageUrl: model.imageUrl,
          price: _extractPriceFromLabel(model.priceLabel),
          location: model.location,
        );
        
        // Call original onTap if provided
        if (onTap != null) {
          onTap!.call();
        } else {
          // Default navigation to detail page
          context.push('${Routes.listing}/${model.id}');
        }
      },
      onLongPress: onLongPress,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          label: '${model.isVehicle ? 'Vehicle' : 'Property'} card for ${model.title}',
          child: Container(
            width: width,
            margin: margin,
            decoration: BoxDecoration(
              color: isDark ? EnterpriseDarkTheme.cardBackground : EnterpriseLightTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.8) : Colors.grey.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? EnterpriseDarkTheme.primaryShadow.withOpacity(0.35)
                      : EnterpriseLightTheme.cardShadow.withOpacity(0.12),
                  blurRadius: isDark ? 10 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image + favorite icon
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 2.0, // 2:1 to reduce photo height and overall card height
                        child: Container(
                          color: isDark ? EnterpriseDarkTheme.surfaceBackground : EnterpriseLightTheme.surfaceBackground,
                          child: model.imageUrl != null
                              ? (() {
                                  final url = model.imageUrl!.trim();
                                  final isNetwork = url.startsWith('http://') || url.startsWith('https://');
                                  if (isNetwork) {
                                    var resolvedUrl = url;
                                    // Android emulator loopback mapping
                                    if (!kIsWeb && Platform.isAndroid) {
                                      if (resolvedUrl.startsWith('http://localhost')) {
                                        resolvedUrl = resolvedUrl.replaceFirst('http://localhost', 'http://10.0.2.2');
                                      } else if (resolvedUrl.startsWith('http://127.0.0.1')) {
                                        resolvedUrl = resolvedUrl.replaceFirst('http://127.0.0.1', 'http://10.0.2.2');
                                      }
                                    }
                                    // Web: avoid mixed content
                                    if (kIsWeb && resolvedUrl.startsWith('http://')) {
                                      resolvedUrl = resolvedUrl.replaceFirst('http://', 'https://');
                                    }
                                    // Encode spaces
                                    if (resolvedUrl.contains(' ')) {
                                      resolvedUrl = resolvedUrl.replaceAll(' ', '%20');
                                    }
                                    return Image.network(
                                      resolvedUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Container(
                                              color: isDark ? EnterpriseDarkTheme.surfaceBackground : EnterpriseLightTheme.surfaceBackground,
                                            ),
                                            Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    isDark ? EnterpriseDarkTheme.primaryAccent : EnterpriseLightTheme.primaryAccent,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: isDark ? EnterpriseDarkTheme.surfaceBackground : EnterpriseLightTheme.surfaceBackground,
                                          child: Center(
                                            child: Icon(
                                              Icons.image_not_supported_outlined,
                                              size: 32,
                                              color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  } else {
                                    final path = url.startsWith('file://') ? url.substring(7) : url;
                                    return Image.file(
                                      File(path),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: isDark ? EnterpriseDarkTheme.surfaceBackground : EnterpriseLightTheme.surfaceBackground,
                                          child: Center(
                                            child: Icon(
                                              Icons.image_not_supported_outlined,
                                              size: 32,
                                              color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                })()
                              : Container(
                                  color: isDark ? EnterpriseDarkTheme.surfaceBackground : EnterpriseLightTheme.surfaceBackground,
                                  child: Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 32,
                                      color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (chipOnImage && model.chips.isNotEmpty)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.5)
                                    : Colors.grey.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              model.chips.first,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                              ),
                            ),
                          ),
                        ),
                      // Heart icon for wishlist (functional)
                      if (showWishlistButton)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: rp.Consumer(builder: (context, ref, _) {
                            final isLiked = ref.watch(wishlistProvider).isInWishlist(model.id);
                            return GestureDetector(
                              onTap: () {
                                final wasLiked = isLiked;
                                ref.read(wishlistProvider.notifier).toggleWishlist(model.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(wasLiked ? 'Removed from wishlist' : 'Added to wishlist'),
                                    duration: const Duration(milliseconds: 900),
                                  ),
                                );
                              },
                              child: AnimatedScale(
                                scale: isLiked ? 1.12 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOutBack,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isLiked
                                        ? Colors.red.withOpacity(0.15)
                                        : Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 18,
                                    color: isLiked ? Colors.red : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      
                      // Rating moved to info section (no overlay on image)
                    ],
                  ),
                ),
                // Compact details section (auto height)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Category label (first chip)
                    if (showInfoChip && model.chips.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.5) : Colors.grey.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          model.chips.first,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                      // Header: Title, Price and Share
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              model.title,
                              style: TextStyle(
                                fontSize: isCompact ? 13 : 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? EnterpriseDarkTheme.primaryText : EnterpriseLightTheme.primaryText,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!priceBottomLeft) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? EnterpriseDarkTheme.primaryAccent.withOpacity(0.1) : const Color(0xFF1E3A8A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark ? EnterpriseDarkTheme.primaryAccent : const Color(0xFF1E3A8A),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                model.priceLabel,
                                style: TextStyle(
                                  fontSize: isCompact ? 13 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? EnterpriseDarkTheme.primaryAccent : const Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ],
                          if (!shareBottomRight && showShareButton) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                final shareText = 'Check out ${model.title} in ${model.location} — ${model.priceLabel}\nvia Rentally';
                                Share.share(shareText, subject: 'Rentally: ${model.title}');
                              },
                              child: Icon(
                                Icons.share,
                                size: isCompact ? 18 : 20,
                                color: isDark ? EnterpriseDarkTheme.primaryText : EnterpriseLightTheme.primaryText,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Rating row (with optional chip on the right)
                      if (model.rating > 0 || (chipInRatingRowRight && model.chips.isNotEmpty)) ...[
                        Row(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: isCompact ? 12 : 13,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (model.rating > 0 ? model.rating.toStringAsFixed(1) : '—'),
                                  style: TextStyle(
                                    fontSize: isCompact ? 11 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? EnterpriseDarkTheme.primaryText : EnterpriseLightTheme.primaryText,
                                  ),
                                ),
                                if (model.reviewCount != null && model.rating > 0) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${model.reviewCount})',
                                    style: TextStyle(
                                      fontSize: isCompact ? 10 : 11,
                                      color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            const Spacer(),
                            if (chipInRatingRowRight && model.chips.isNotEmpty)
                              _chip(model.chips.first, isDark),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      // Location row
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: isCompact ? 13 : 14,
                            color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              model.location,
                              style: TextStyle(
                                fontSize: isCompact ? 11 : 12,
                                color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: width > 260 ? 6 : 4),
                      // Feature row (meta items)
                      SizedBox(
                        height: isCompact ? 18 : 20,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: model.metaItems
                                .take(3)
                                .map((m) => Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            m.icon,
                                            size: isCompact ? 13 : 14,
                                            color: isDark
                                                ? EnterpriseDarkTheme.secondaryText
                                                : EnterpriseLightTheme.secondaryText,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            m.text,
                                            style: TextStyle(
                                              fontSize: isCompact ? 11 : 12,
                                              color: isDark
                                                  ? EnterpriseDarkTheme.secondaryText
                                                  : EnterpriseLightTheme.secondaryText,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                      // Bottom row: price (left) and share (right)
                              if (priceBottomLeft || (shareBottomRight && showShareButton)) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (priceBottomLeft)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isDark ? EnterpriseDarkTheme.primaryAccent.withOpacity(0.1) : const Color(0xFF1E3A8A).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isDark ? EnterpriseDarkTheme.primaryAccent : const Color(0xFF1E3A8A),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            model.priceLabel,
                                            style: TextStyle(
                                            fontSize: isCompact ? 13 : 14,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? EnterpriseDarkTheme.primaryAccent : const Color(0xFF1E3A8A),
                                            ),
                                          ),
                                        ),
                                    if (priceBottomLeft && model.badges.contains(ListingBadgeType.verified)) ...[
                                      const SizedBox(width: 8),
                                      Tooltip(
                                        message: 'Verified Host',
                                        child: Icon(
                                          Icons.verified,
                                          size: isCompact ? 16 : 18,
                                          color: const Color(0xFF20C997),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    if (shareBottomRight && showShareButton)
                                      Tooltip(
                                        message: 'Share',
                                        child: GestureDetector(
                                          onTap: () {
                                            final shareText = 'Check out ${model.title} in ${model.location} — ${model.priceLabel}\nvia Rentally';
                                            Share.share(shareText, subject: 'Rentally: ${model.title}');
                                          },
                                          child: Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.96),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.12),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(Icons.share, size: isCompact ? 18 : 20, color: Colors.black87),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: isDark 
            ? LinearGradient(
                colors: [EnterpriseDarkTheme.primaryAccent.withOpacity(0.2), EnterpriseDarkTheme.primaryAccent.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [const Color(0xFF1E3A8A).withOpacity(0.1), const Color(0xFF3B82F6).withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? EnterpriseDarkTheme.primaryAccent.withOpacity(0.3) : const Color(0xFF1E3A8A).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? EnterpriseDarkTheme.primaryAccent : const Color(0xFF1E3A8A),
        ),
      ),
    );
  }

  /// Get responsive content height based on card width and content density
  // ignore: unused_element
  double _getCardContentHeight(double cardWidth, ListingViewModel model) {
    // Base height by width breakpoint
    double base;
    if (cardWidth >= 260) {
      base = 104; // Desktop/tablet: compact baseline with buffer
    } else if (cardWidth >= 220) {
      base = 96; // Medium: compact baseline with buffer
    } else {
      base = 90; // Mobile: compact baseline with buffer
    }
    // Add allowance when chips/meta are present to prevent clipping
    // Note: badges row is not rendered in the new compact card design
    if (model.chips.isNotEmpty) base += 16;  // category label chip at top
    if (model.metaItems.isNotEmpty) base += 20; // feature row (icons + labels)
    return base;
  }

  /// Extract numeric price from formatted price label
  double? _extractPriceFromLabel(String priceLabel) {
    final regex = RegExp(r'[\d,]+\.?\d*');
    final match = regex.firstMatch(priceLabel);
    if (match != null) {
      final priceStr = match.group(0)?.replaceAll(',', '');
      return double.tryParse(priceStr ?? '');
    }
    return null;
  }
}
