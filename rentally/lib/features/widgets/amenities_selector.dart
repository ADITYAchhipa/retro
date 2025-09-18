import 'package:flutter/material.dart';

class AmenitiesSelector extends StatefulWidget {
  final List<String> selectedAmenities;
  final Function(List<String>) onAmenitiesChanged;
  final List<String>? availableAmenities;

  const AmenitiesSelector({
    super.key,
    required this.selectedAmenities,
    required this.onAmenitiesChanged,
    this.availableAmenities,
  });

  @override
  State<AmenitiesSelector> createState() => _AmenitiesSelectorState();
}

class _AmenitiesSelectorState extends State<AmenitiesSelector> {
  static const List<String> _defaultAmenities = [
    'WiFi',
    'Air Conditioning',
    'Heating',
    'Kitchen',
    'Washing Machine',
    'Parking',
    'Pool',
    'Gym',
    'Balcony',
    'Garden',
    'Pet Friendly',
    'Smoking Allowed',
    'TV',
    'Dishwasher',
    'Elevator',
    'Security',
    'Hot Tub',
    'Fireplace',
    'Workspace',
    'BBQ Grill',
  ];

  static final Map<String, IconData> _amenityIcons = {
    'WiFi': Icons.wifi,
    'Air Conditioning': Icons.ac_unit,
    'Heating': Icons.local_fire_department,
    'Kitchen': Icons.kitchen,
    'Washing Machine': Icons.local_laundry_service,
    'Parking': Icons.local_parking,
    'Pool': Icons.pool,
    'Gym': Icons.fitness_center,
    'Balcony': Icons.balcony,
    'Garden': Icons.grass,
    'Pet Friendly': Icons.pets,
    'Smoking Allowed': Icons.smoking_rooms,
    'TV': Icons.tv,
    'Dishwasher': Icons.kitchen,
    'Elevator': Icons.elevator,
    'Security': Icons.security,
    'Hot Tub': Icons.hot_tub,
    'Fireplace': Icons.fireplace,
    'Workspace': Icons.desk,
    'BBQ Grill': Icons.outdoor_grill,
  };

  List<String> get amenities => widget.availableAmenities ?? _defaultAmenities;

  void _toggleAmenity(String amenity) {
    final updatedAmenities = [...widget.selectedAmenities];
    if (updatedAmenities.contains(amenity)) {
      updatedAmenities.remove(amenity);
    } else {
      updatedAmenities.add(amenity);
    }
    widget.onAmenitiesChanged(updatedAmenities);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Amenities',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            final isSelected = widget.selectedAmenities.contains(amenity);
            final icon = _amenityIcons[amenity] ?? Icons.check_circle_outline;
            
            return FilterChip(
              avatar: Icon(
                icon,
                size: 18,
                color: isSelected 
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              label: Text(
                amenity,
                style: TextStyle(
                  color: isSelected 
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _toggleAmenity(amenity),
              selectedColor: theme.colorScheme.primaryContainer,
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              checkmarkColor: theme.colorScheme.onPrimaryContainer,
              side: BorderSide(
                color: isSelected 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
            );
          }).toList(),
        ),
        if (widget.selectedAmenities.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${widget.selectedAmenities.length} amenities selected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class AmenitiesDisplayWidget extends StatelessWidget {
  final List<String> amenities;
  final int maxDisplay;
  final bool showIcons;

  const AmenitiesDisplayWidget({
    super.key,
    required this.amenities,
    this.maxDisplay = 6,
    this.showIcons = true,
  });

  static final Map<String, IconData> _amenityIcons = {
    'WiFi': Icons.wifi,
    'Air Conditioning': Icons.ac_unit,
    'Heating': Icons.local_fire_department,
    'Kitchen': Icons.kitchen,
    'Washing Machine': Icons.local_laundry_service,
    'Parking': Icons.local_parking,
    'Pool': Icons.pool,
    'Gym': Icons.fitness_center,
    'Balcony': Icons.balcony,
    'Garden': Icons.grass,
    'Pet Friendly': Icons.pets,
    'Smoking Allowed': Icons.smoking_rooms,
    'TV': Icons.tv,
    'Dishwasher': Icons.kitchen,
    'Elevator': Icons.elevator,
    'Security': Icons.security,
    'Hot Tub': Icons.hot_tub,
    'Fireplace': Icons.fireplace,
    'Workspace': Icons.desk,
    'BBQ Grill': Icons.outdoor_grill,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayAmenities = amenities.take(maxDisplay).toList();
    final remainingCount = amenities.length - maxDisplay;

    if (amenities.isEmpty) {
      return Text(
        'No amenities listed',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...displayAmenities.map((amenity) {
          final icon = _amenityIcons[amenity] ?? Icons.check_circle_outline;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcons) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  amenity,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
        if (remainingCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Text(
              '+$remainingCount more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
