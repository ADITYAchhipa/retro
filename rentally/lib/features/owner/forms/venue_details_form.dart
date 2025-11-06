import 'package:flutter/material.dart';

class VenueDetailsForm extends StatelessWidget {
  final String propertyType; // resort | event_hall | event_garden
  // Common
  final TextEditingController seatedCapacityController;
  final TextEditingController parkingCapacityController;
  final bool powerBackup;
  final ValueChanged<bool> onPowerBackupChanged;
  final bool inHouseCatering;
  final ValueChanged<bool> onInHouseCateringChanged;
  final bool outsideCateringAllowed;
  final ValueChanged<bool> onOutsideCateringAllowedChanged;
  final bool alcoholAllowed;
  final ValueChanged<bool> onAlcoholAllowedChanged;
  // Resort specific
  final TextEditingController roomCountController;
  // Event Hall specific
  final TextEditingController hallAreaController;
  final bool hallAC;
  final ValueChanged<bool> onHallACChanged;
  final bool stageIncluded;
  final ValueChanged<bool> onStageIncludedChanged;
  final bool bridalRoom;
  final ValueChanged<bool> onBridalRoomChanged;
  // Event Garden specific
  final TextEditingController gardenAreaController;
  final bool openAirAllowed;
  final ValueChanged<bool> onOpenAirAllowedChanged;

  const VenueDetailsForm({
    super.key,
    required this.propertyType,
    required this.seatedCapacityController,
    required this.parkingCapacityController,
    required this.powerBackup,
    required this.onPowerBackupChanged,
    required this.inHouseCatering,
    required this.onInHouseCateringChanged,
    required this.outsideCateringAllowed,
    required this.onOutsideCateringAllowedChanged,
    required this.alcoholAllowed,
    required this.onAlcoholAllowedChanged,
    required this.roomCountController,
    required this.hallAreaController,
    required this.hallAC,
    required this.onHallACChanged,
    required this.stageIncluded,
    required this.onStageIncludedChanged,
    required this.bridalRoom,
    required this.onBridalRoomChanged,
    required this.gardenAreaController,
    required this.openAirAllowed,
    required this.onOpenAirAllowedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    Widget field(TextEditingController c, String label, {TextInputType? type, bool req = false}) {
      return TextFormField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
        style: TextStyle(fontSize: isPhone ? 12 : 13),
        validator: req ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Venue Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: field(seatedCapacityController, 'Seated Capacity', type: TextInputType.number, req: true)),
          const SizedBox(width: 16),
          Expanded(child: field(parkingCapacityController, 'Parking Capacity', type: TextInputType.number)),
        ]),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: powerBackup,
          onChanged: onPowerBackupChanged,
          title: const Text('Power Backup'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: inHouseCatering,
          onChanged: onInHouseCateringChanged,
          title: const Text('In-house Catering'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: outsideCateringAllowed,
          onChanged: onOutsideCateringAllowedChanged,
          title: const Text('Outside Catering Allowed'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: alcoholAllowed,
          onChanged: onAlcoholAllowedChanged,
          title: const Text('Alcohol Allowed'),
        ),
        const SizedBox(height: 12),
        if (propertyType == 'resort') ...[
          field(roomCountController, 'Number of Rooms', type: TextInputType.number),
          const SizedBox(height: 12),
        ],
        if (propertyType == 'event_hall') ...[
          field(hallAreaController, 'Hall Area (sq ft)', type: TextInputType.number),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: hallAC,
            onChanged: onHallACChanged,
            title: const Text('AC Available'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: stageIncluded,
            onChanged: onStageIncludedChanged,
            title: const Text('Stage Included'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: bridalRoom,
            onChanged: onBridalRoomChanged,
            title: const Text('Bridal/Green Room'),
          ),
          const SizedBox(height: 12),
        ],
        if (propertyType == 'event_garden') ...[
          field(gardenAreaController, 'Garden Area (sq ft)', type: TextInputType.number),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: openAirAllowed,
            onChanged: onOpenAirAllowedChanged,
            title: const Text('Open Air Allowed'),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
