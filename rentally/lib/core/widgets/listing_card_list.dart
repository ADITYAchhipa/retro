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
import '../../app/auth_router.dart';
import 'listing_card.dart' show ListingViewModel; // reuse the same ViewModel
import 'listing_badges.dart' show ListingBadgeType;

class ListingListCard extends rp.ConsumerWidget {
  final ListingViewModel model;
  final bool isDark;
  final double width;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showWishlistButton;
  final bool chipOnImage;
  final bool showInfoChip;
  final bool chipBelowImage;

  const ListingListCard({
    super.key,
    required this.model,
    required this.isDark,
    this.width = double.infinity,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.onTap,
    this.onLongPress,
    this.showWishlistButton = true,
    this.chipOnImage = false,
    this.showInfoChip = true,
    this.chipBelowImage = false,
  });

  @override
  Widget build(BuildContext context, rp.WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final viewHistoryService = pv.Provider.of<ViewHistoryService>(context, listen: false);
        viewHistoryService.trackView(
          id: model.id,
          title: model.title,
          type: model.isVehicle ? 'vehicle' : 'property',
          imageUrl: model.imageUrl,
          price: _extractPriceFromLabel(model.priceLabel),
          location: model.location,
        );
        if (onTap != null) {
          onTap!.call();
        } else {
          context.push('${Routes.listing}/${model.id}');
        }
      },
      onLongPress: onLongPress,
      child: Semantics(
        button: true,
        label: '${model.isVehicle ? 'Vehicle' : 'Property'} list card for ${model.title}',
        child: Container(
          width: width,
          margin: margin,
          padding: const EdgeInsets.all(8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? EnterpriseDarkTheme.cardBackground : EnterpriseLightTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.8) : Colors.grey.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? EnterpriseDarkTheme.primaryShadow.withOpacity(0.25) : EnterpriseLightTheme.cardShadow.withOpacity(0.08),
                blurRadius: isDark ? 7 : 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with wishlist and optional chip below image
              SizedBox(
                width: 112,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Container(
                            width: 112,
                            height: 72,
                            color: isDark ? EnterpriseDarkTheme.surfaceBackground : EnterpriseLightTheme.surfaceBackground,
                            child: model.imageUrl != null
                                ? (() {
                                    final url = model.imageUrl!.trim();
                                    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
                                    if (isNetwork) {
                                      var resolvedUrl = url;
                                      // On Android emulator, map localhost to 10.0.2.2
                                      if (!kIsWeb && Platform.isAndroid) {
                                        if (resolvedUrl.startsWith('http://localhost')) {
                                          resolvedUrl = resolvedUrl.replaceFirst('http://localhost', 'http://10.0.2.2');
                                        } else if (resolvedUrl.startsWith('http://127.0.0.1')) {
                                          resolvedUrl = resolvedUrl.replaceFirst('http://127.0.0.1', 'http://10.0.2.2');
                                        }
                                      }
                                      // On Web, prefer https to avoid mixed content
                                      if (kIsWeb && resolvedUrl.startsWith('http://')) {
                                        resolvedUrl = resolvedUrl.replaceFirst('http://', 'https://');
                                      }
                                      // Encode spaces to avoid 404s
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
                                                color: isDark
                                                    ? EnterpriseDarkTheme.surfaceBackground
                                                    : EnterpriseLightTheme.surfaceBackground,
                                              ),
                                              Center(
                                                child: SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      isDark
                                                          ? EnterpriseDarkTheme.primaryAccent
                                                          : EnterpriseLightTheme.primaryAccent,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          if (kDebugMode) {
                                            debugPrint('Wishlist ListCard network image error for $resolvedUrl: $error');
                                          }
                                          return Center(
                                            child: Icon(
                                              Icons.image_not_supported_outlined,
                                              size: 24,
                                              color: isDark
                                                  ? EnterpriseDarkTheme.secondaryText
                                                  : EnterpriseLightTheme.secondaryText,
                                            ),
                                          );
                                        },
                                      );
                                    } else {
                                      final isAsset = url.startsWith('assets/') || url.startsWith('packages/');
                                      if (isAsset) {
                                        return Image.asset(
                                          url,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.image_not_supported_outlined,
                                                size: 24,
                                                color: isDark
                                                    ? EnterpriseDarkTheme.secondaryText
                                                    : EnterpriseLightTheme.secondaryText,
                                              ),
                                            );
                                          },
                                        );
                                      }
                                      if (url.startsWith('content://')) {
                                        // Content URIs aren't directly supported here; show fallback icon
                                        return Center(
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 24,
                                            color: isDark
                                                ? EnterpriseDarkTheme.secondaryText
                                                : EnterpriseLightTheme.secondaryText,
                                          ),
                                        );
                                      }
                                      if (!kIsWeb) {
                                        final path = url.startsWith('file://') ? url.substring(7) : url;
                                        return Image.file(
                                          File(path),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            if (kDebugMode) {
                                              debugPrint('Wishlist ListCard file image error for $path: $error');
                                            }
                                            return Center(
                                              child: Icon(
                                                Icons.image_not_supported_outlined,
                                                size: 24,
                                                color: isDark
                                                    ? EnterpriseDarkTheme.secondaryText
                                                    : EnterpriseLightTheme.secondaryText,
                                              ),
                                            );
                                          },
                                        );
                                      }
                                      // Web non-network fallback
                                      return Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 24,
                                          color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                                        ),
                                      );
                                    }
                                  })()
                                : Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 24,
                                      color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                                    ),
                                  ),
                          ),
                          if (chipOnImage && model.chips.isNotEmpty)
                            Positioned(
                              top: 4,
                              left: 4,
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
                          if (showWishlistButton)
                            Positioned(
                              top: 4,
                              right: 4,
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
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 2.5,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isLiked ? Icons.favorite : Icons.favorite_border,
                                      size: 14,
                                      color: isLiked ? Colors.red : Colors.black87,
                                    ),
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                    if (chipBelowImage && model.chips.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
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
                          if (model.badges.contains(ListingBadgeType.verified)) ...[
                            const SizedBox(width: 6),
                            const Tooltip(
                              message: 'Verified Host',
                              child: Icon(
                                Icons.verified,
                                size: 14,
                                color: Color(0xFF20C997),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Details
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // Details content
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 2, bottom: 44),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showInfoChip && model.chips.isNotEmpty) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                                    if (model.badges.contains(ListingBadgeType.verified)) ...[
                                      const SizedBox(width: 6),
                                      const Tooltip(
                                        message: 'Verified Host',
                                        child: Icon(
                                          Icons.verified,
                                          size: 14,
                                          color: Color(0xFF20C997),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],  //####
                              Text(
                                model.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? EnterpriseDarkTheme.primaryText : EnterpriseLightTheme.primaryText,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (model.rating > 0) ...[
                                    const Icon(Icons.star, size: 11, color: Colors.amber),
                                    const SizedBox(width: 3),
                                    Text(
                                      model.rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? EnterpriseDarkTheme.primaryText : EnterpriseLightTheme.primaryText,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('•', style: TextStyle(fontSize: 10, color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText)),
                                    const SizedBox(width: 6),
                                  ],
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 11,
                                    color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      model.location,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? EnterpriseDarkTheme.secondaryText : EnterpriseLightTheme.secondaryText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                        // Bottom-right overlay row: share button left of price chip
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: 'Share',
                                child: GestureDetector(
                                  onTap: () {
                                    final shareText = 'Check out ${model.title} in ${model.location} — ${model.priceLabel}\nvia Rentally';
                                    Share.share(shareText, subject: 'Rentally: ${model.title}');
                                  },
                                  child: Container(
                                        width: 28,
                                        height: 28,
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
                                    child: const Icon(Icons.share, color: Colors.black87, size: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? EnterpriseDarkTheme.primaryAccent.withOpacity(0.1) : const Color(0xFF1E3A8A).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? EnterpriseDarkTheme.primaryAccent : const Color(0xFF1E3A8A),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  model.priceLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? EnterpriseDarkTheme.primaryAccent : const Color(0xFF1E3A8A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
