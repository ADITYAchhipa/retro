import 'package:flutter/material.dart';

class PlotDetailsForm extends StatelessWidget {
  final TextEditingController plotAreaController;
  final String plotUsage;
  final ValueChanged<String> onPlotUsageChanged;

  const PlotDetailsForm({
    super.key,
    required this.plotAreaController,
    required this.plotUsage,
    required this.onPlotUsageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    const usageOptions = ['any', 'agriculture', 'commercial', 'events', 'construction'];

    String toLabel(String value) {
      switch (value) {
        case 'agriculture':
          return 'Agriculture';
        case 'commercial':
          return 'Commercial';
        case 'events':
          return 'Events';
        case 'construction':
          return 'Construction';
        default:
          return 'Any';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plot Details',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: plotAreaController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Plot Area (sq ft)*',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Plot area is required';
            }
            return null;
          },
          style: TextStyle(fontSize: isPhone ? 12 : 13),
        ),
        const SizedBox(height: 12),
        Text(
          'Plot Usage',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: usageOptions.map((u) {
            final sel = plotUsage == u;
            return ChoiceChip(
              showCheckmark: false,
              selected: sel,
              label: Text(
                toLabel(u),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              selectedColor: theme.colorScheme.primary,
              shape: const StadiumBorder(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onPlotUsageChanged(u),
            );
          }).toList(),
        ),
      ],
    );
  }
}
