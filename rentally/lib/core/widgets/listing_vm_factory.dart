import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/price_unit_helper.dart';
import '../utils/currency_formatter.dart';
import '../widgets/listing_card.dart' show ListingViewModel, ListingMetaItem; 
import '../widgets/listing_badges.dart' show ListingBadgeType; 
import '../database/models/property_model.dart';
import '../database/models/vehicle_model.dart';
import '../../services/listing_service.dart' as ls;

class ListingViewModelFactory {
  static ListingViewModel fromProperty(PropertyModel p) {
    final res = PriceUnitHelper.forProperty(p);
    return ListingViewModel(
      id: p.id,
      title: p.title,
      location: p.location,
      priceLabel: PriceUnitHelper.format(res),
      originalPriceLabel: PriceUnitHelper.formatOriginal(res),
      discountPercent: res.discountPercent,
      rentalUnit: res.unit,
      imageUrl: p.images.isNotEmpty ? p.images.first : null,
      rating: p.rating,
      reviewCount: p.reviewCount,
      chips: [p.type.displayName, if (p.amenities.isNotEmpty) p.amenities.first],
      metaItems: [
        ListingMetaItem(icon: Icons.bed, text: '${p.bedrooms} bd'),
        ListingMetaItem(icon: Icons.bathtub, text: '${p.bathrooms} ba'),
        ListingMetaItem(icon: Icons.person, text: '${p.maxGuests} guests'),
      ],
      fallbackIcon: Icons.home,
      isVehicle: false,
      badges: [
        if (p.isFeatured) ListingBadgeType.featured,
        if (p.rating >= 4.7 && p.reviewCount > 25) ListingBadgeType.topRated,
        if (DateTime.now().difference(p.createdAt).inDays <= 30) ListingBadgeType.newListing,
      ],
    );
  }

  static ListingViewModel fromVehicle(VehicleModel v) {
    final res = PriceUnitHelper.forVehicle(v);
    return ListingViewModel(
      id: v.id,
      title: v.title,
      location: v.location,
      priceLabel: PriceUnitHelper.format(res),
      originalPriceLabel: PriceUnitHelper.formatOriginal(res),
      discountPercent: res.discountPercent,
      rentalUnit: res.unit,
      imageUrl: v.images.isNotEmpty ? v.images.first : null,
      rating: v.rating,
      reviewCount: v.reviewCount,
      chips: ['${v.category} • ${v.seats} seats'],
      metaItems: [
        ListingMetaItem(icon: Icons.airline_seat_recline_normal, text: '${v.seats}'),
        ListingMetaItem(icon: Icons.settings, text: v.transmission),
        ListingMetaItem(icon: v.fuel.toLowerCase() == 'electric' ? Icons.electric_bolt : Icons.local_gas_station, text: v.fuel),
      ],
      fallbackIcon: Icons.directions_car,
      isVehicle: true,
      badges: [
        if (v.isFeatured) ListingBadgeType.featured,
        if (v.rating >= 4.7 && v.reviewCount > 25) ListingBadgeType.topRated,
      ],
    );
  }

  /// Generic raw builder for places like Advanced Search where we don't have full models.
  /// Computes discount from listingProvider (if available) and applies to price.
  static ListingViewModel fromRaw(
    WidgetRef ref, {
    required String id,
    required String title,
    required String location,
    required double price,
    required String rentalUnit,
    String? imageUrl,
    double rating = 0,
    int? reviewCount,
    List<String> chips = const [],
    List<ListingMetaItem> metaItems = const [],
    IconData fallbackIcon = Icons.home,
    bool isVehicle = false,
    bool isFavorite = false,
    List<ListingBadgeType> badges = const [],
  }) {
    double? pct;
    var unitLocal = rentalUnit;
    try {
      final listingsState = ref.read(ls.listingProvider);
      final all = [...listingsState.listings, ...listingsState.userListings];
      ls.Listing? found;
      try {
        found = all.firstWhere((l) => l.id == id);
      } catch (_) {
        found = null;
      }
      pct = found?.discountPercent;
      // Prefer provider rentalUnit if present
      final ru = found?.rentalUnit?.trim();
      if (ru != null && ru.isNotEmpty) {
        unitLocal = ru.toLowerCase();
      }
    } catch (_) {}

    final hasDiscount = (pct ?? 0) > 0;
    final discounted = hasDiscount ? (price * (1 - (pct ?? 0) / 100)) : price;

    return ListingViewModel(
      id: id,
      title: title,
      location: location,
      priceLabel: _format(discounted, unitLocal),
      originalPriceLabel: hasDiscount ? _format(price, unitLocal) : null,
      discountPercent: hasDiscount ? (pct!.round()) : null,
      rentalUnit: unitLocal,
      imageUrl: imageUrl,
      rating: rating,
      reviewCount: reviewCount,
      chips: chips,
      metaItems: metaItems,
      fallbackIcon: fallbackIcon,
      isVehicle: isVehicle,
      badges: badges,
      isFavorite: isFavorite,
    );
  }

  static String _format(double amount, String unit) {
    return CurrencyFormatter.formatPricePerUnit(amount, unit);
  }
}
