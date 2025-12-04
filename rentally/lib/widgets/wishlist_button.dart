import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/wishlist_service.dart';

/// Core toggle logic builder
typedef _WishlistBuilder = Widget Function(bool isLiked, VoidCallback onToggle);

class _WishlistToggle extends ConsumerWidget {
  final String listingId;
  final bool isVehicle;
  final _WishlistBuilder builder;
  const _WishlistToggle({required this.listingId, this.isVehicle = false, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked = ref.watch(wishlistProvider).isInWishlist(listingId);
    void onToggle() {
      final wasLiked = isLiked;
      ref.read(wishlistProvider.notifier).toggleWishlist(listingId, isVehicle: isVehicle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasLiked ? 'Removed from wishlist' : 'Added to wishlist'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    }
    return builder(isLiked, onToggle);
  }
}

/// Simple inline icon-only button (no background)
class WishlistIconButton extends StatelessWidget {
  final String listingId;
  final bool isVehicle;
  final double size;
  final Color? color;
  final Color? activeColor;
  const WishlistIconButton({super.key, required this.listingId, this.isVehicle = false, this.size = 24, this.color, this.activeColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _WishlistToggle(
      listingId: listingId,
      isVehicle: isVehicle,
      builder: (isLiked, onToggle) => IconButton(
        onPressed: onToggle,
        icon: Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          size: size,
          color: isLiked ? (activeColor ?? Colors.red) : (color ?? theme.iconTheme.color),
        ),
      ),
    );
  }
}

/// Circular overlay heart with optimistic animated fade + scale (for cards)
class WishlistOverlayHeart extends StatelessWidget {
  final String listingId;
  final bool isVehicle;
  final double size;
  const WishlistOverlayHeart({super.key, required this.listingId, this.isVehicle = false, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return _WishlistToggle(
      listingId: listingId,
      isVehicle: isVehicle,
      builder: (isLiked, onToggle) => GestureDetector(
        onTap: onToggle,
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
              color: isLiked ? Colors.red.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 2)),
              ],
            ),
            child: Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: size, color: isLiked ? Colors.red : Colors.grey),
          ),
        ),
      ),
    );
  }
}

/// Legacy alias for inline circle icon with background
class WishlistButton extends StatelessWidget {
  final String listingId;
  final bool isVehicle;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  const WishlistButton({super.key, required this.listingId, this.isVehicle = false, this.size = 24.0, this.activeColor, this.inactiveColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _WishlistToggle(
      listingId: listingId,
      isVehicle: isVehicle,
      builder: (isLiked, onToggle) => GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            size: size,
            color: isLiked ? (activeColor ?? Colors.red) : (inactiveColor ?? theme.iconTheme.color),
          ),
        ),
      ),
    );
  }
}

