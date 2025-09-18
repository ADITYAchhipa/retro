import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/wishlist_service.dart';

class WishlistButton extends ConsumerWidget {
  final String listingId;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const WishlistButton({
    super.key,
    required this.listingId,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);
    final isInWishlist = wishlistState.isInWishlist(listingId);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => ref.read(wishlistProvider.notifier).toggleWishlist(listingId),
      child: Icon(
        isInWishlist ? Icons.favorite : Icons.favorite_border,
        size: size,
        color: isInWishlist 
            ? (activeColor ?? Colors.red)
            : (inactiveColor ?? theme.iconTheme.color),
      ),
    );
  }
}

class WishlistIconButton extends ConsumerWidget {
  final String listingId;
  final VoidCallback? onPressed;

  const WishlistIconButton({
    super.key,
    required this.listingId,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);
    final isInWishlist = wishlistState.isInWishlist(listingId);

    return IconButton(
      onPressed: () {
        ref.read(wishlistProvider.notifier).toggleWishlist(listingId);
        onPressed?.call();
      },
      icon: Icon(
        isInWishlist ? Icons.favorite : Icons.favorite_border,
        color: isInWishlist ? Colors.red : null,
      ),
    );
  }
}
