import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Advanced filter widget with multiple filter options
class AdvancedFilterWidget extends ConsumerStatefulWidget {
  final Function(FilterOptions) onFiltersChanged;
  final FilterOptions initialFilters;

  const AdvancedFilterWidget({
    super.key,
    required this.onFiltersChanged,
    required this.initialFilters,
  });

  @override
  ConsumerState<AdvancedFilterWidget> createState() => _AdvancedFilterWidgetState();
}

class _AdvancedFilterWidgetState extends ConsumerState<AdvancedFilterWidget>
    with TickerProviderStateMixin {
  
  late FilterOptions _filters;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _updateFilters() {
    widget.onFiltersChanged(_filters);
  }
  
  void _resetFilters() {
    setState(() {
      _filters = FilterOptions();
    });
    _updateFilters();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryTypeFilter(theme),
                    const SizedBox(height: 24),
                    _buildPropertyTypeFilter(theme),
                    const SizedBox(height: 24),
                    _buildPriceRangeFilter(theme),
                    const SizedBox(height: 24),
                    _buildAreaRangeFilter(theme),
                    const SizedBox(height: 24),
                    _buildFurnishedFilter(theme),
                    const SizedBox(height: 24),
                    _buildBedroomsBathroomsFilter(theme),
                    const SizedBox(height: 24),
                    _buildAmenitiesFilter(theme),
                    const SizedBox(height: 24),
                    _buildEssentialAmenitiesFilter(theme),
                    const SizedBox(height: 24),
                    _buildVenueFilter(theme),
                    const SizedBox(height: 24),
                    _buildRatingFilter(theme),
                    const SizedBox(height: 24),
                    _buildLocationFilter(theme),
                    const SizedBox(height: 24),
                    _buildAvailabilityFilter(theme),
                  ],
                ),
              ),
            ),
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Filters',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }
  
  /// Category type filter (residential, commercial, venue)
  Widget _buildCategoryTypeFilter(ThemeData theme) {
    final types = ['Any', 'Residential', 'Commercial', 'Venue'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            final value = type == 'Any' ? null : type.toLowerCase();
            final isSelected = _filters.categoryType == value;
            
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filters = _filters.copyWith(
                    categoryType: selected ? value : null,
                    propertyTypes: [], // Reset property types when category changes
                  );
                });
                _updateFilters();
              },
              selectedColor: theme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: theme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  /// Get property types based on selected category type
  /// Returns list of display names for UI
  List<String> _getPropertyTypesForCategory() {
    switch (_filters.categoryType) {
      case 'residential':
        return [
          'Any', 'Apartment', 'Independent House', 'Independent Villa', 
          '1RK/Studio House', 'Townhouse', 'Condo', 'Room', 'PG/Co-Living', 
          'Hostel', 'Duplex', 'Penthouse', 'Bungalow'
        ];
      case 'commercial':
        return [
          'Any', 'Office', 'Shop', 'Warehouse', 'Co-Working Space', 
          'Showroom', 'Clinic/Healthcare', 'Restaurant/Cafe'
        ];
      case 'venue':
        return [
          'Any', 'Banquet Hall', 'Wedding Venue', 'Party Hall', 
          'Conference Room', 'Meeting Room', 'Auditorium/Theater', 
          'Outdoor Lawn/Garden', 'Rooftop Venue', 'Hotel Ballroom', 
          'Resort Venue', 'Farmhouse/Villa Event Space', 'Studio', 
          'Exhibition Center', 'Club/Lounge Event Space', 'Private Dining Room'
        ];
      default:
        // Show all when no category type selected
        return ['Any'];
    }
  }
  
  /// Convert display name to backend value(s)
  /// Some display names map to multiple backend values (OR logic)
  List<String> _toBackendCategories(String displayName) {
    // Special mappings for OR cases
    final Map<String, List<String>> specialMappings = {
      // Residential mappings
      'Independent House': ['house'],
      'Independent Villa': ['villa'],
      '1RK/Studio House': ['studio'],
      'PG/Co-Living': ['pg'],
      // Commercial mappings
      'Co-Working Space': ['coworking'],
      'Clinic/Healthcare': ['clinic'],
      'Restaurant/Cafe': ['restaurant', 'cafe'],
      // Venue mappings
      'Banquet Hall': ['banquet_hall'],
      'Wedding Venue': ['wedding_venue'],
      'Party Hall': ['party_hall'],
      'Conference Room': ['conference_room'],
      'Meeting Room': ['meeting_room'],
      'Auditorium/Theater': ['auditorium', 'theater'],
      'Outdoor Lawn/Garden': ['garden'],
      'Rooftop Venue': ['rooftop'],
      'Hotel Ballroom': ['ballroom'],
      'Resort Venue': ['resort'],
      'Farmhouse/Villa Event Space': ['farmhouse', 'villa'],
      'Studio': ['studio_venue'],
      'Exhibition Center': ['exhibition'],
      'Club/Lounge Event Space': ['club'],
      'Private Dining Room': ['dining_room'],
    };
    
    if (specialMappings.containsKey(displayName)) {
      return specialMappings[displayName]!;
    }
    
    // Default: convert to lowercase with underscores
    return [displayName.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_')];
  }
  
  /// Convert display name to backend value (simple version for single values)
  String _toBackendCategory(String displayName) {
    return _toBackendCategories(displayName).first;
  }
  
  Widget _buildPriceRangeFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget (per day)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '₹${_filters.minPrice.round()} - ₹${_filters.maxPrice.round()}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        RangeSlider(
          values: RangeValues(_filters.minPrice, _filters.maxPrice),
          min: 0,
          max: 50000,
          divisions: 100,
          labels: RangeLabels(
            '₹${_filters.minPrice.round()}',
            '₹${_filters.maxPrice.round()}',
          ),
          onChanged: (values) {
            // Ensure min <= max
            if (values.start <= values.end) {
              setState(() {
                _filters = _filters.copyWith(
                  minPrice: values.start,
                  maxPrice: values.end,
                );
              });
            }
          },
          onChangeEnd: (values) => _updateFilters(),
        ),
      ],
    );
  }
  
  /// Built-up area filter with min/max validation
  Widget _buildAreaRangeFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Built-up Area (sq ft)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_filters.minArea.round()} - ${_filters.maxArea.round()} sq ft',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        RangeSlider(
          values: RangeValues(_filters.minArea, _filters.maxArea),
          min: 0,
          max: 10000,
          divisions: 100,
          labels: RangeLabels(
            '${_filters.minArea.round()}',
            '${_filters.maxArea.round()}',
          ),
          onChanged: (values) {
            // Ensure min <= max
            if (values.start <= values.end) {
              setState(() {
                _filters = _filters.copyWith(
                  minArea: values.start,
                  maxArea: values.end,
                );
              });
            }
          },
          onChangeEnd: (values) => _updateFilters(),
        ),
      ],
    );
  }
  
  /// Furnished status filter
  Widget _buildFurnishedFilter(ThemeData theme) {
    final options = ['Any', 'Unfurnished', 'Semi-Furnished', 'Furnished'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Furnished Status',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final value = option == 'Any' ? null : option.toLowerCase().replaceAll('-', '-');
            final isSelected = _filters.furnished == value;
            
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filters = _filters.copyWith(
                    furnished: selected ? value : null,
                  );
                });
                _updateFilters();
              },
              selectedColor: theme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: theme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  /// Essential amenities filter
  Widget _buildEssentialAmenitiesFilter(ThemeData theme) {
    final amenities = [
      'WiFi', 'Parking', 'AC', 'Gym', 'Swimming Pool', 
      'Power Backup', 'Lift', 'Security', 'Garden', 
      'Water Supply', 'Gas', 'CCTV'
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Essential Amenities',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            final backendValue = amenity.toLowerCase().replaceAll(' ', '_');
            final isSelected = _filters.essentialAmenities.contains(backendValue);
            
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final list = List<String>.from(_filters.essentialAmenities);
                  if (selected) {
                    list.add(backendValue);
                  } else {
                    list.remove(backendValue);
                  }
                  _filters = _filters.copyWith(essentialAmenities: list);
                });
                _updateFilters();
              },
              selectedColor: theme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: theme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }


  Widget _buildVenueFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Venue Filters',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Minimum Seated Capacity: ${_filters.minSeatedCapacity == 0 ? 'Any' : _filters.minSeatedCapacity}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _filters.minSeatedCapacity.toDouble(),
          min: 0,
          max: 1000,
          divisions: 20,
          label: _filters.minSeatedCapacity == 0 ? 'Any' : _filters.minSeatedCapacity.toString(),
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(minSeatedCapacity: value.round());
            });
          },
          onChangeEnd: (_) => _updateFilters(),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('In-house Catering'),
          value: _filters.venueInHouseCatering,
          onChanged: (v) {
            setState(() {
              _filters = _filters.copyWith(venueInHouseCatering: v);
            });
            _updateFilters();
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Outside Catering Allowed'),
          value: _filters.venueOutsideCateringAllowed,
          onChanged: (v) {
            setState(() {
              _filters = _filters.copyWith(venueOutsideCateringAllowed: v);
            });
            _updateFilters();
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Alcohol Allowed'),
          value: _filters.venueAlcoholAllowed,
          onChanged: (v) {
            setState(() {
              _filters = _filters.copyWith(venueAlcoholAllowed: v);
            });
            _updateFilters();
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('AC Required'),
          subtitle: const Text('Also selects the AC amenity'),
          value: _filters.amenities.contains('AC'),
          onChanged: (v) {
            setState(() {
              final list = List<String>.from(_filters.amenities);
              if (v) {
                if (!list.contains('AC')) list.add('AC');
              } else {
                list.remove('AC');
              }
              _filters = _filters.copyWith(amenities: list);
            });
            _updateFilters();
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Open Air Allowed'),
          value: _filters.venueOpenAirAllowed,
          onChanged: (v) {
            setState(() {
              _filters = _filters.copyWith(venueOpenAirAllowed: v);
            });
            _updateFilters();
          },
        ),
      ],
    );
  }
  
  Widget _buildPropertyTypeFilter(ThemeData theme) {
    // Get dynamic property types based on selected category type
    final types = _getPropertyTypesForCategory();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            // Get all backend values for this type (handles OR mappings)
            final backendValues = _toBackendCategories(type);
            // Check if any of the backend values are selected
            final isSelected = type == 'Any' 
                ? _filters.propertyTypes.isEmpty 
                : backendValues.any((v) => _filters.propertyTypes.contains(v));
            
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (type == 'Any') {
                    _filters = _filters.copyWith(propertyTypes: []);
                  } else {
                    final typesList = List<String>.from(_filters.propertyTypes);
                    if (selected) {
                      // Add all backend values for this type
                      for (final v in backendValues) {
                        if (!typesList.contains(v)) typesList.add(v);
                      }
                    } else {
                      // Remove all backend values for this type
                      for (final v in backendValues) {
                        typesList.remove(v);
                      }
                    }
                    _filters = _filters.copyWith(propertyTypes: typesList);
                  }
                });
                _updateFilters();
              },
              selectedColor: theme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: theme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildBedroomsBathroomsFilter(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bedrooms',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildNumberSelector(
                value: _filters.minBedrooms,
                onChanged: (value) {
                  setState(() {
                    _filters = _filters.copyWith(minBedrooms: value);
                  });
                  _updateFilters();
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bathrooms',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildNumberSelector(
                value: _filters.minBathrooms,
                onChanged: (value) {
                  setState(() {
                    _filters = _filters.copyWith(minBathrooms: value);
                  });
                  _updateFilters();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildNumberSelector({
    required int value,
    required Function(int) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Text(
              value == 0 ? 'Any' : value.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: value < 10 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAmenitiesFilter(ThemeData theme) {
    final amenities = [
      'WiFi', 'Parking', 'Pool', 'Gym', 'AC', 'Heating',
      'Kitchen', 'Washer', 'TV', 'Elevator', 'Security', 'Pet Friendly'
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            final isSelected = _filters.amenities.contains(amenity);
            
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final amenitiesList = List<String>.from(_filters.amenities);
                  if (selected) {
                    amenitiesList.add(amenity);
                  } else {
                    amenitiesList.remove(amenity);
                  }
                  _filters = _filters.copyWith(amenities: amenitiesList);
                });
                _updateFilters();
              },
              selectedColor: theme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: theme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildRatingFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = rating <= _filters.minRating;
            
            return IconButton(
              onPressed: () {
                setState(() {
                  _filters = _filters.copyWith(
                    minRating: rating == _filters.minRating ? 0 : rating,
                  );
                });
                _updateFilters();
              },
              icon: Icon(
                isSelected ? Icons.star : Icons.star_border,
                color: theme.primaryColor,
                size: 32,
              ),
            );
          }),
        ),
      ],
    );
  }
  
  Widget _buildLocationFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distance',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Within ${_filters.maxDistance.round()} km',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Slider(
          value: _filters.maxDistance,
          min: 1,
          max: 50,
          divisions: 49,
          label: '${_filters.maxDistance.round()} km',
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(maxDistance: value);
            });
          },
          onChangeEnd: (value) => _updateFilters(),
        ),
      ],
    );
  }
  
  Widget _buildAvailabilityFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Instant Booking'),
          subtitle: const Text('Properties available for immediate booking'),
          value: _filters.instantBookingOnly,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(instantBookingOnly: value);
            });
            _updateFilters();
          },
        ),
        SwitchListTile(
          title: const Text('Verified Properties'),
          subtitle: const Text('Only show verified listings'),
          value: _filters.verifiedOnly,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(verifiedOnly: value);
            });
            _updateFilters();
          },
        ),
      ],
    );
  }
  
  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetFilters,
              child: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter options model
class FilterOptions {
  final String? categoryType; // 'residential', 'commercial', 'venue'
  final double minPrice;
  final double maxPrice;
  final List<String> propertyTypes;
  final int minBedrooms;
  final int minBathrooms;
  final List<String> amenities;
  final List<String> essentialAmenities;
  final int minRating;
  final double maxDistance;
  final bool instantBookingOnly;
  final bool verifiedOnly;
  final String? furnished; // 'unfurnished', 'semi-furnished', 'furnished'
  final double minArea;
  final double maxArea;
  // Venue-specific
  final int minSeatedCapacity;
  final bool venueInHouseCatering;
  final bool venueOutsideCateringAllowed;
  final bool venueAlcoholAllowed;
  final bool venueOpenAirAllowed;
  final DateTime? checkIn;
  final DateTime? checkOut;

  FilterOptions({
    this.categoryType,
    this.minPrice = 0,
    this.maxPrice = 50000,
    this.propertyTypes = const [],
    this.minBedrooms = 0,
    this.minBathrooms = 0,
    this.amenities = const [],
    this.essentialAmenities = const [],
    this.minRating = 0,
    this.maxDistance = 25,
    this.instantBookingOnly = false,
    this.verifiedOnly = false,
    this.furnished,
    this.minArea = 0,
    this.maxArea = 10000,
    this.minSeatedCapacity = 0,
    this.venueInHouseCatering = false,
    this.venueOutsideCateringAllowed = false,
    this.venueAlcoholAllowed = false,
    this.venueOpenAirAllowed = false,
    this.checkIn,
    this.checkOut,
  });

  FilterOptions copyWith({
    String? categoryType,
    double? minPrice,
    double? maxPrice,
    List<String>? propertyTypes,
    int? minBedrooms,
    int? minBathrooms,
    List<String>? amenities,
    List<String>? essentialAmenities,
    int? minRating,
    double? maxDistance,
    bool? instantBookingOnly,
    bool? verifiedOnly,
    String? furnished,
    double? minArea,
    double? maxArea,
    // Venue-specific
    int? minSeatedCapacity,
    bool? venueInHouseCatering,
    bool? venueOutsideCateringAllowed,
    bool? venueAlcoholAllowed,
    bool? venueOpenAirAllowed,
    DateTime? checkIn,
    DateTime? checkOut,
  }) {
    return FilterOptions(
      categoryType: categoryType ?? this.categoryType,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      propertyTypes: propertyTypes ?? this.propertyTypes,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      minBathrooms: minBathrooms ?? this.minBathrooms,
      amenities: amenities ?? this.amenities,
      essentialAmenities: essentialAmenities ?? this.essentialAmenities,
      minRating: minRating ?? this.minRating,
      maxDistance: maxDistance ?? this.maxDistance,
      instantBookingOnly: instantBookingOnly ?? this.instantBookingOnly,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      furnished: furnished ?? this.furnished,
      minArea: minArea ?? this.minArea,
      maxArea: maxArea ?? this.maxArea,
      // Venue-specific
      minSeatedCapacity: minSeatedCapacity ?? this.minSeatedCapacity,
      venueInHouseCatering: venueInHouseCatering ?? this.venueInHouseCatering,
      venueOutsideCateringAllowed: venueOutsideCateringAllowed ?? this.venueOutsideCateringAllowed,
      venueAlcoholAllowed: venueAlcoholAllowed ?? this.venueAlcoholAllowed,
      venueOpenAirAllowed: venueOpenAirAllowed ?? this.venueOpenAirAllowed,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
    );
  }

  bool get hasActiveFilters {
    return categoryType != null ||
           minPrice > 0 ||
           maxPrice < 50000 ||
           propertyTypes.isNotEmpty ||
           minBedrooms > 0 ||
           minBathrooms > 0 ||
           amenities.isNotEmpty ||
           essentialAmenities.isNotEmpty ||
           minRating > 0 ||
           maxDistance < 25 ||
           instantBookingOnly ||
           verifiedOnly ||
           furnished != null ||
           minArea > 0 ||
           maxArea < 10000 ||
           // Venue-specific
           minSeatedCapacity > 0 ||
           venueInHouseCatering ||
           venueOutsideCateringAllowed ||
           venueAlcoholAllowed ||
           venueOpenAirAllowed;
  }

  int get activeFilterCount {
    int count = 0;
    if (categoryType != null) count++;
    if (minPrice > 0 || maxPrice < 50000) count++;
    if (propertyTypes.isNotEmpty) count++;
    if (minBedrooms > 0) count++;
    if (minBathrooms > 0) count++;
    if (amenities.isNotEmpty) count++;
    if (essentialAmenities.isNotEmpty) count++;
    if (minRating > 0) count++;
    if (maxDistance < 25) count++;
    if (instantBookingOnly) count++;
    if (verifiedOnly) count++;
    if (furnished != null) count++;
    if (minArea > 0 || maxArea < 10000) count++;
    // Venue-specific
    if (minSeatedCapacity > 0) count++;
    if (venueInHouseCatering) count++;
    if (venueOutsideCateringAllowed) count++;
    if (venueAlcoholAllowed) count++;
    if (venueOpenAirAllowed) count++;
    return count;
  }
  
  /// Convert to API request body
  Map<String, dynamic> toApiBody() {
    return {
      if (categoryType != null) 'categoryType': categoryType,
      if (propertyTypes.isNotEmpty) 'category': propertyTypes,
      if (minPrice > 0) 'minPrice': minPrice,
      if (maxPrice < 50000) 'maxPrice': maxPrice,
      if (minArea > 0) 'minArea': minArea,
      if (maxArea < 10000) 'maxArea': maxArea,
      if (furnished != null) 'furnished': furnished,
      if (amenities.isNotEmpty) 'amenities': amenities,
      if (essentialAmenities.isNotEmpty) 'essentialAmenities': essentialAmenities,
    };
  }
}

