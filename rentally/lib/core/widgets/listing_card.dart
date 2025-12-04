import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:provider/provider.dart' as pv;
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/enterprise_dark_theme.dart';
import '../theme/enterprise_light_theme.dart';
import '../theme/listing_card_theme.dart';
import '../neo/neo.dart';
import '../../services/view_history_service.dart';
import '../../services/wishlist_service.dart';
import '../../services/recently_viewed_service.dart';
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
  final String? originalPriceLabel; // original price per unit, when discounted
  final int? discountPercent; // percent off, when discounted
  final String? rentalUnit; // e.g., 'hour', 'day', 'night', 'month'
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
    this.originalPriceLabel,
    this.discountPercent,
    this.rentalUnit,
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
  final double? imageAspectRatio;

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
    this.imageAspectRatio,
  });

  @override
  Widget build(BuildContext context, rp.WidgetRef ref) {
    final bool isCompact = compact || width <= 140; // ultra compact threshold for smaller cards
    final cardTheme = Theme.of(context).extension<ListingCardTheme>();
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
        // Also record for Recently Viewed section
        final parsedPrice = _extractPriceFromLabel(model.priceLabel) ?? 0.0;
        RecentlyViewedService.addFromFields(
          id: model.id,
          title: model.title,
          location: model.location,
          price: parsedPrice,
          imageUrl: model.imageUrl,
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
              color: isDark ? EnterpriseDarkTheme.cardBackground : Colors.white,
              borderRadius: BorderRadius.circular(cardTheme?.cardRadius ?? 12),
              border: Border.all(
                color: cardTheme?.cardBorderColor ?? (isDark
                    ? EnterpriseDarkTheme.primaryBorder.withValues(alpha: 0.35)
                    : EnterpriseLightTheme.secondaryBorder),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                  blurRadius: 10,
                  offset: const Offset(-5, -5),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: (isDark
                          ? EnterpriseDarkTheme.primaryAccent
                          : EnterpriseLightTheme.primaryAccent)
                      .withValues(alpha: isDark ? 0.18 : 0.12),
                  blurRadius: 10,
                  offset: const Offset(5, 5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image + favorite icon
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(cardTheme?.cardRadius ?? 12)),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: imageAspectRatio ?? (isCompact ? 3.8 : 3.2), // allow override for contexts like Featured
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
                                    return CachedNetworkImage(
                                      imageUrl: resolvedUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Stack(
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
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: isDark ? EnterpriseDarkTheme.surfaceBackground : EnterpriseLightTheme.surfaceBackground,
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 32,
                                            color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                                          ),
                                        ),
                                      ),
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
                          child: Row(
                            children: model.chips.take(2).map((chip) => Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cardTheme?.chipBackgroundColor ?? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: cardTheme?.chipBorderColor ?? (isDark
                                          ? EnterpriseDarkTheme.primaryBorder.withValues(alpha: 0.5)
                                          : Colors.grey.withValues(alpha: 0.4)),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    chip,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: cardTheme?.chipTextColor ?? (isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText),
                                    ),
                                  ),
                                )).toList(),
                          ),
                        ),
                      // Heart icon for wishlist (functional)
                      if (showWishlistButton)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: rp.Consumer(builder: (context, ref, _) {
                            final isLiked = ref.watch(wishlistProvider).isInWishlist(model.id);
                            return AnimatedScale(
                              scale: isLiked ? 1.12 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOutBack,
                              child: GestureDetector(
                                onTap: () {
                                  final wasLiked = isLiked;
                                  ref.read(wishlistProvider.notifier).toggleWishlist(model.id, isVehicle: model.isVehicle);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(wasLiked ? 'Removed from wishlist' : 'Added to wishlist'),
                                      duration: const Duration(milliseconds: 900),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: isLiked
                                      ? null
                                      : BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          shape: BoxShape.circle,
                                        ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 18,
                                    color: isLiked ? Colors.red : Colors.white,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Category and mode labels (up to 2 chips)
                    if (showInfoChip && model.chips.isNotEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...model.chips.take(2).map((chip) => Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cardTheme?.chipBackgroundColor ?? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: cardTheme?.chipBorderColor ?? (isDark ? EnterpriseDarkTheme.primaryBorder.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.4)),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  chip,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: cardTheme?.chipTextColor ?? (isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText),
                                  ),
                                ),
                              )),
                        ],
                      ),
                      const SizedBox(height: 1),
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
                                color: cardTheme?.titleColor ?? (isDark ? EnterpriseDarkTheme.primaryText : EnterpriseLightTheme.primaryText),
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!priceBottomLeft) ...[
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text(
                                    model.priceLabel,
                                    style: TextStyle(
                                      fontSize: isCompact ? 13 : 14,
                                      fontWeight: FontWeight.w700,
                                      color: cardTheme?.priceColor ?? Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                if (model.originalPriceLabel != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    model.originalPriceLabel!,
                                    style: TextStyle(
                                      fontSize: isCompact ? 11 : 12,
                                      color: (isDark
                                              ? EnterpriseDarkTheme.secondaryText
                                              : EnterpriseLightTheme.secondaryText)
                                          .withValues(alpha: 0.9),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  if (model.discountPercent != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: cardTheme?.discountBadgeBackgroundColor ?? (isDark ? const Color(0xFFE11D48).withValues(alpha: 0.22) : const Color(0xFFE11D48).withValues(alpha: 0.12)),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: cardTheme?.discountBadgeBorderColor ?? (isDark ? const Color(0xFFE11D48).withValues(alpha: 0.35) : const Color(0xFFE11D48).withValues(alpha: 0.35))),
                                      ),
                                      child: Text(
                                        '-${model.discountPercent}%',
                                        style: TextStyle(
                                          fontSize: isCompact ? 11 : 12,
                                          fontWeight: FontWeight.w700,
                                          color: cardTheme?.discountBadgeTextColor ?? const Color(0xFFBE123C),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ],
                          if (!shareBottomRight && showShareButton) ...[
                            const SizedBox(width: 8),
                            NeoIconButton(
                              icon: Icons.share,
                              size: isCompact ? 28 : 30,
                              iconSize: isCompact ? 16 : 18,
                              iconColor: cardTheme?.actionIconColor ?? (isDark ? EnterpriseDarkTheme.primaryText : Colors.black87),
                              spread: cardTheme?.actionSpread ?? 0.0,
                              tooltip: 'Share',
                              backgroundColor: cardTheme?.actionBackgroundColor ?? Colors.transparent,
                              borderColor: cardTheme?.actionBorderColor ?? Colors.transparent,
                              onTap: () {
                                final shareText = 'Check out ${model.title} in ${model.location} — ${model.priceLabel}\nvia Rentally';
                                Share.share(shareText, subject: 'Rentally: ${model.title}');
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
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
                                    color: cardTheme?.ratingColor ?? (isDark ? EnterpriseDarkTheme.primaryText : EnterpriseLightTheme.primaryText),
                                    height: 1.1,
                                  ),
                                ),
                                if (model.reviewCount != null && model.rating > 0) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${model.reviewCount})',
                                    style: TextStyle(
                                      fontSize: isCompact ? 10 : 11,
                                      color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                                      height: 1.1,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            const Spacer(),
                            if (chipInRatingRowRight && model.chips.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...model.chips.take(2).map((c) => Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: _chip(c, isDark),
                                      )),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 1),
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
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: width > 260 ? 3 : 1),
                      // Feature row (meta items)
                      SizedBox(
                        height: isCompact ? 14 : 16,
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
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (priceBottomLeft)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                            child: Text(
                                              model.priceLabel,
                                              style: TextStyle(
                                                fontSize: isCompact ? 13 : 14,
                                                fontWeight: FontWeight.w700,
                                                color: cardTheme?.priceColor ?? Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          if (model.originalPriceLabel != null) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              model.originalPriceLabel!,
                                              style: TextStyle(
                                                fontSize: isCompact ? 11 : 12,
                                                color: (isDark
                                                        ? EnterpriseDarkTheme.secondaryText
                                                        : EnterpriseLightTheme.secondaryText)
                                                    .withValues(alpha: 0.9),
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                          if (model.discountPercent != null) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (cardTheme?.discountBadgeBackgroundColor ?? const Color(0xFFE11D48)).withValues(alpha: isDark ? 0.22 : 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: (cardTheme?.discountBadgeBorderColor ?? const Color(0xFFE11D48)).withValues(alpha: 0.35)),
                                              ),
                                              child: Text(
                                                '-${model.discountPercent}%',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: cardTheme?.discountBadgeTextColor ?? const Color(0xFFBE123C),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
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
                                      NeoIconButton(
                                        tooltip: 'Share',
                                        icon: Icons.share,
                                        size: 32,
                                        iconSize: isCompact ? 16 : 18,
                                        iconColor: cardTheme?.actionIconColor ?? (isDark ? EnterpriseDarkTheme.primaryText : Colors.black87),
                                        spread: cardTheme?.actionSpread ?? 0.0,
                                        backgroundColor: cardTheme?.actionBackgroundColor ?? Colors.transparent,
                                        borderColor: cardTheme?.actionBorderColor ?? Colors.transparent,
                                        onTap: () {
                                          final shareText = 'Check out ${model.title} in ${model.location} — ${model.priceLabel}\nvia Rentally';
                                          Share.share(shareText, subject: 'Rentally: ${model.title}');
                                        },
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
                colors: [EnterpriseDarkTheme.primaryAccent.withValues(alpha: 0.2), EnterpriseDarkTheme.primaryAccent.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [const Color(0xFF1E3A8A).withValues(alpha: 0.1), const Color(0xFF3B82F6).withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? EnterpriseDarkTheme.primaryAccent.withValues(alpha: 0.3) : const Color(0xFF1E3A8A).withValues(alpha: 0.2),
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
