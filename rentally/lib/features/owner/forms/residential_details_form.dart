import 'package:flutter/material.dart';

class ResidentialDetailsForm extends StatelessWidget {
  final String propertyType; // apartment, house, villa, studio, townhouse, condo, room, duplex, penthouse, bungalow

  // Furnishing
  final String furnishing;
  final List<String> furnishingOptions;
  final ValueChanged<String> onFurnishingChanged;

  // Apartment configuration
  final String apartmentBhk;
  final List<String> bhkOptions;
  final ValueChanged<String> onApartmentBhkChanged;

  // Beds/Baths
  final int bedrooms;
  final ValueChanged<int> onBedroomsChanged;
  final int bathrooms;
  final ValueChanged<int> onBathroomsChanged;

  // Room-specific
  final String roomBathroomType;
  final List<String> roomBathroomOptions;
  final ValueChanged<String> onRoomBathroomTypeChanged;

  // Controllers for various types
  final TextEditingController studioSizeController;
  final TextEditingController floorController;
  final TextEditingController totalFloorsController;
  final TextEditingController plotAreaController; // for house/villa/bungalow
  final TextEditingController parkingSpacesController; // for house/villa/bungalow
  final TextEditingController hoaFeeController; // condo
  final TextEditingController carpetAreaController; // apartment/condo/townhouse/duplex/penthouse
  final TextEditingController terraceAreaController; // penthouse

  // PG/Hostel
  final TextEditingController pgOccupancyController;
  final String pgGender;
  final List<String> pgGenderOptions;
  final ValueChanged<String> onPgGenderChanged;
  final String pgMeals;
  final List<String> pgMealsOptions;
  final ValueChanged<String> onPgMealsChanged;
  final bool pgAttachedBathroom;
  final ValueChanged<bool> onPgAttachedBathroomChanged;

  const ResidentialDetailsForm({
    super.key,
    required this.propertyType,
    required this.furnishing,
    required this.furnishingOptions,
    required this.onFurnishingChanged,
    required this.apartmentBhk,
    required this.bhkOptions,
    required this.onApartmentBhkChanged,
    required this.bedrooms,
    required this.onBedroomsChanged,
    required this.bathrooms,
    required this.onBathroomsChanged,
    required this.roomBathroomType,
    required this.roomBathroomOptions,
    required this.onRoomBathroomTypeChanged,
    required this.studioSizeController,
    required this.floorController,
    required this.totalFloorsController,
    required this.plotAreaController,
    required this.parkingSpacesController,
    required this.hoaFeeController,
    required this.carpetAreaController,
    required this.terraceAreaController,
    required this.pgOccupancyController,
    required this.pgGender,
    required this.pgGenderOptions,
    required this.onPgGenderChanged,
    required this.pgMeals,
    required this.pgMealsOptions,
    required this.onPgMealsChanged,
    required this.pgAttachedBathroom,
    required this.onPgAttachedBathroomChanged,
  });

  bool get _isApartment => propertyType == 'apartment';
  bool get _isCondo => propertyType == 'condo';
  bool get _isTownhouse => propertyType == 'townhouse';
  bool get _isDuplex => propertyType == 'duplex';
  bool get _isPenthouse => propertyType == 'penthouse';
  bool get _isBungalow => propertyType == 'bungalow';
  bool get _isHouse => propertyType == 'house';
  bool get _isStudio => propertyType == 'studio';
  bool get _isRoom => propertyType == 'room';
  bool get _isPG => propertyType == 'pg' || propertyType == 'hostel';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    Widget compactField({
      required TextEditingController c,
      required String label,
      String? hint,
      TextInputType? type,
      String? Function(String?)? validator,
    }) {
      return TextFormField(
        controller: c,
        keyboardType: type,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
        style: TextStyle(fontSize: isPhone ? 12 : 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Furnishing (residential)
        DropdownButtonFormField<String>(
          value: furnishing,
          decoration: InputDecoration(
            labelText: 'Furnishing',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
          ),
          isExpanded: true,
          items: furnishingOptions
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) onFurnishingChanged(v);
          },
        ),
        const SizedBox(height: 12),

        // Apartment configuration or Bedrooms
        if (_isApartment)
          DropdownButtonFormField<String>(
            value: apartmentBhk,
            decoration: InputDecoration(
              labelText: 'Configuration',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            isExpanded: true,
            items: bhkOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (v) {
              if (v != null) onApartmentBhkChanged(v);
            },
          )
        else if (!_isStudio && !_isPG && !_isRoom)
          DropdownButtonFormField<int>(
            value: bedrooms,
            decoration: InputDecoration(
              labelText: 'Bedrooms',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            isExpanded: true,
            items: List.generate(6, (i) => i + 1)
                .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                .toList(),
            onChanged: (v) {
              if (v != null) onBedroomsChanged(v);
            },
          ),
        if (_isApartment) const SizedBox(height: 12),

        // Room: Bathroom type
        if (_isRoom)
          DropdownButtonFormField<String>(
            value: roomBathroomType,
            decoration: InputDecoration(
              labelText: 'Bathroom Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            isExpanded: true,
            items: roomBathroomOptions
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) {
              if (v != null) onRoomBathroomTypeChanged(v);
            },
          ),

        if (!_isRoom) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: bathrooms,
            decoration: InputDecoration(
              labelText: 'Bathrooms',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            isExpanded: true,
            items: List.generate(4, (i) => i + 1)
                .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                .toList(),
            onChanged: (v) {
              if (v != null) onBathroomsChanged(v);
            },
          ),
        ],

        const SizedBox(height: 12),
        // Type-specific details
        Text('Type-Specific Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        if (_isStudio) ...[
          compactField(
            c: studioSizeController,
            label: 'Studio Size (sq ft)*',
            type: TextInputType.number,
            validator: (v) => (v == null || v.isEmpty) ? 'Studio size is required' : null,
          ),
          const SizedBox(height: 12),
        ],
        if (_isPG) ...[
          compactField(
            c: pgOccupancyController,
            label: 'Occupancy per Room*',
            type: TextInputType.number,
            validator: (v) => (v == null || v.isEmpty) ? 'Occupancy is required' : null,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: pgGender,
                decoration: InputDecoration(
                  labelText: 'Gender Preference',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                isExpanded: true,
                items: pgGenderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onPgGenderChanged(v);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: pgMeals,
                decoration: InputDecoration(
                  labelText: 'Meal Preference',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                isExpanded: true,
                items: pgMealsOptions
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onPgMealsChanged(v);
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SwitchListTile(
            value: pgAttachedBathroom,
            onChanged: onPgAttachedBathroomChanged,
            title: const Text('Attached Bathroom'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
        ],

        if (_isApartment || _isCondo) ...[
          Row(children: [
            Expanded(
              child: compactField(
                c: floorController,
                label: 'Floor Number*',
                type: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Floor number is required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: compactField(
                c: totalFloorsController,
                label: 'Total Floors',
                type: TextInputType.number,
              ),
            ),
          ]),
          const SizedBox(height: 12),
        ],

        if (_isHouse || _isVilla) ...[
          Row(children: [
            Expanded(
              child: compactField(
                c: plotAreaController,
                label: 'Plot Area (sq ft)*',
                type: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Plot area is required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: compactField(
                c: parkingSpacesController,
                label: 'Parking Spaces',
                type: TextInputType.number,
              ),
            ),
          ]),
          const SizedBox(height: 12),
        ],

        if (_isCondo) ...[
          compactField(
            c: hoaFeeController,
            label: 'HOA Fee (monthly)',
            type: TextInputType.number,
          ),
          const SizedBox(height: 12),
        ],

        if (_isApartment || _isCondo || _isTownhouse || _isDuplex || _isPenthouse) ...[
          compactField(
            c: carpetAreaController,
            label: 'Carpet Area (sq ft)*',
            type: TextInputType.number,
            validator: (v) => (v == null || v.isEmpty) ? 'Carpet area is required' : null,
          ),
          const SizedBox(height: 12),
        ],

        if (_isBungalow) ...[
          Row(children: [
            Expanded(
              child: compactField(
                c: plotAreaController,
                label: 'Plot Area (sq ft)*',
                type: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Plot area is required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: compactField(
                c: parkingSpacesController,
                label: 'Parking Spaces',
                type: TextInputType.number,
              ),
            ),
          ]),
          const SizedBox(height: 12),
        ],

        if (_isPenthouse) ...[
          compactField(
            c: terraceAreaController,
            label: 'Terrace Area (sq ft)',
            type: TextInputType.number,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  bool get _isVilla => propertyType == 'villa';
}
