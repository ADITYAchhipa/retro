import 'package:flutter/material.dart';

class CommercialDetailsForm extends StatelessWidget {
  final String propertyType; // office | shop | warehouse | coworking | showroom | clinic | restaurant | industrial

  // Office
  final TextEditingController officeCarpetAreaController;
  final TextEditingController officeCabinsController;
  final TextEditingController officeConferenceRoomsController;
  final bool officePantry;
  final ValueChanged<bool> onOfficePantryChanged;

  // Shop
  final TextEditingController shopCarpetAreaController;
  final TextEditingController shopFrontageController;
  final String shopFootfall; // Low, Medium, High
  final ValueChanged<String> onShopFootfallChanged;
  final bool shopWashroom;
  final ValueChanged<bool> onShopWashroomChanged;

  // Warehouse
  final TextEditingController warehouseBuiltUpAreaController;
  final TextEditingController warehouseCeilingHeightController;
  final TextEditingController warehouseLoadingBaysController;
  final TextEditingController warehousePowerController;
  final bool warehouseTruckAccess;
  final ValueChanged<bool> onWarehouseTruckAccessChanged;

  // Generic commercial types
  final TextEditingController commercialBuiltUpAreaController;

  const CommercialDetailsForm({
    super.key,
    required this.propertyType,
    // Office
    required this.officeCarpetAreaController,
    required this.officeCabinsController,
    required this.officeConferenceRoomsController,
    required this.officePantry,
    required this.onOfficePantryChanged,
    // Shop
    required this.shopCarpetAreaController,
    required this.shopFrontageController,
    required this.shopFootfall,
    required this.onShopFootfallChanged,
    required this.shopWashroom,
    required this.onShopWashroomChanged,
    // Warehouse
    required this.warehouseBuiltUpAreaController,
    required this.warehouseCeilingHeightController,
    required this.warehouseLoadingBaysController,
    required this.warehousePowerController,
    required this.warehouseTruckAccess,
    required this.onWarehouseTruckAccessChanged,
    // Generic
    required this.commercialBuiltUpAreaController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    Widget buildText({
      required TextEditingController c,
      required String label,
      TextInputType? type,
      String? hint,
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

    if (propertyType == 'office') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Office Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          buildText(c: officeCarpetAreaController, label: 'Carpet Area (sq ft)*', type: TextInputType.number, validator: (v) => (v==null||v.isEmpty) ? 'Required' : null),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: buildText(c: officeCabinsController, label: 'Cabins', type: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: buildText(c: officeConferenceRoomsController, label: 'Conference Rooms', type: TextInputType.number)),
          ]),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: officePantry,
            onChanged: onOfficePantryChanged,
            title: const Text('Pantry Available'),
          ),
        ],
      );
    }

    if (propertyType == 'shop') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shop Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: buildText(c: shopCarpetAreaController, label: 'Carpet Area (sq ft)*', type: TextInputType.number, validator: (v) => (v==null||v.isEmpty) ? 'Required' : null)),
            const SizedBox(width: 16),
            Expanded(child: buildText(c: shopFrontageController, label: 'Frontage (ft)', type: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: shopFootfall,
            decoration: InputDecoration(
              labelText: 'Footfall',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            items: const ['Low','Medium','High']
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
            onChanged: (v) { if (v!=null) onShopFootfallChanged(v); },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: shopWashroom,
            onChanged: onShopWashroomChanged,
            title: const Text('Washroom Available'),
          ),
        ],
      );
    }

    if (propertyType == 'warehouse') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Warehouse Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          buildText(c: warehouseBuiltUpAreaController, label: 'Built-up Area (sq ft)*', type: TextInputType.number, validator: (v) => (v==null||v.isEmpty) ? 'Required' : null),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: buildText(c: warehouseCeilingHeightController, label: 'Ceiling Height (ft)', type: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: buildText(c: warehouseLoadingBaysController, label: 'Loading Bays', type: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          buildText(c: warehousePowerController, label: 'Power (kVA)', type: TextInputType.number),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: warehouseTruckAccess,
            onChanged: onWarehouseTruckAccessChanged,
            title: const Text('Truck Access'),
          ),
        ],
      );
    }

    // Generic commercial types
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Commercial Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        buildText(
          c: commercialBuiltUpAreaController,
          label: 'Built-up Area (sq ft)*',
          type: TextInputType.number,
          validator: (v) => (v==null||v.isEmpty) ? 'Built-up area is required' : null,
        ),
      ],
    );
  }
}
