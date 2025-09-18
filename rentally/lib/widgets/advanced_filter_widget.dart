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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
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
                    _buildPriceRangeFilter(theme),
                    const SizedBox(height: 24),
                    _buildPropertyTypeFilter(theme),
                    const SizedBox(height: 24),
                    _buildBedroomsBathroomsFilter(theme),
                    const SizedBox(height: 24),
                    _buildAmenitiesFilter(theme),
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
  
  Widget _buildPriceRangeFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '\$${_filters.minPrice.round()} - \$${_filters.maxPrice.round()}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        RangeSlider(
          values: RangeValues(_filters.minPrice, _filters.maxPrice),
          min: 0,
          max: 5000,
          divisions: 50,
          labels: RangeLabels(
            '\$${_filters.minPrice.round()}',
            '\$${_filters.maxPrice.round()}',
          ),
          onChanged: (values) {
            setState(() {
              _filters = _filters.copyWith(
                minPrice: values.start,
                maxPrice: values.end,
              );
            });
          },
          onChangeEnd: (values) => _updateFilters(),
        ),
      ],
    );
  }
  
  Widget _buildPropertyTypeFilter(ThemeData theme) {
    final types = ['All', 'Apartment', 'House', 'Villa', 'Studio', 'Room'];
    
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
            final isSelected = _filters.propertyTypes.contains(type) || 
                              (_filters.propertyTypes.isEmpty && type == 'All');
            
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (type == 'All') {
                    _filters = _filters.copyWith(propertyTypes: []);
                  } else {
                    final types = List<String>.from(_filters.propertyTypes);
                    if (selected) {
                      types.add(type);
                    } else {
                      types.remove(type);
                    }
                    _filters = _filters.copyWith(propertyTypes: types);
                  }
                });
                _updateFilters();
              },
              selectedColor: theme.primaryColor.withOpacity(0.2),
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
              selectedColor: theme.primaryColor.withOpacity(0.2),
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
  final double minPrice;
  final double maxPrice;
  final List<String> propertyTypes;
  final int minBedrooms;
  final int minBathrooms;
  final List<String> amenities;
  final int minRating;
  final double maxDistance;
  final bool instantBookingOnly;
  final bool verifiedOnly;
  final DateTime? checkIn;
  final DateTime? checkOut;

  FilterOptions({
    this.minPrice = 0,
    this.maxPrice = 5000,
    this.propertyTypes = const [],
    this.minBedrooms = 0,
    this.minBathrooms = 0,
    this.amenities = const [],
    this.minRating = 0,
    this.maxDistance = 25,
    this.instantBookingOnly = false,
    this.verifiedOnly = false,
    this.checkIn,
    this.checkOut,
  });

  FilterOptions copyWith({
    double? minPrice,
    double? maxPrice,
    List<String>? propertyTypes,
    int? minBedrooms,
    int? minBathrooms,
    List<String>? amenities,
    int? minRating,
    double? maxDistance,
    bool? instantBookingOnly,
    bool? verifiedOnly,
    DateTime? checkIn,
    DateTime? checkOut,
  }) {
    return FilterOptions(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      propertyTypes: propertyTypes ?? this.propertyTypes,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      minBathrooms: minBathrooms ?? this.minBathrooms,
      amenities: amenities ?? this.amenities,
      minRating: minRating ?? this.minRating,
      maxDistance: maxDistance ?? this.maxDistance,
      instantBookingOnly: instantBookingOnly ?? this.instantBookingOnly,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
    );
  }

  bool get hasActiveFilters {
    return minPrice > 0 ||
           maxPrice < 5000 ||
           propertyTypes.isNotEmpty ||
           minBedrooms > 0 ||
           minBathrooms > 0 ||
           amenities.isNotEmpty ||
           minRating > 0 ||
           maxDistance < 25 ||
           instantBookingOnly ||
           verifiedOnly;
  }

  int get activeFilterCount {
    int count = 0;
    if (minPrice > 0 || maxPrice < 5000) count++;
    if (propertyTypes.isNotEmpty) count++;
    if (minBedrooms > 0) count++;
    if (minBathrooms > 0) count++;
    if (amenities.isNotEmpty) count++;
    if (minRating > 0) count++;
    if (maxDistance < 25) count++;
    if (instantBookingOnly) count++;
    if (verifiedOnly) count++;
    return count;
  }
}
