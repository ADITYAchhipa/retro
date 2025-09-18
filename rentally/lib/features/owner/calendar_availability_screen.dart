import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../utils/snackbar_utils.dart';
import 'package:go_router/go_router.dart';

enum AvailabilityStatus {
  available,
  booked,
  blocked,
  pending,
}

class CalendarAvailability {
  final DateTime date;
  final AvailabilityStatus status;
  final double? price;
  final String? bookingId;
  final String? guestName;
  final String? notes;

  const CalendarAvailability({
    required this.date,
    required this.status,
    this.price,
    this.bookingId,
    this.guestName,
    this.notes,
  });

  CalendarAvailability copyWith({
    DateTime? date,
    AvailabilityStatus? status,
    double? price,
    String? bookingId,
    String? guestName,
    String? notes,
  }) {
    return CalendarAvailability(
      date: date ?? this.date,
      status: status ?? this.status,
      price: price ?? this.price,
      bookingId: bookingId ?? this.bookingId,
      guestName: guestName ?? this.guestName,
      notes: notes ?? this.notes,
    );
  }
}

class CalendarService extends StateNotifier<Map<DateTime, CalendarAvailability>> {
  CalendarService() : super(_generateMockData());

  static Map<DateTime, CalendarAvailability> _generateMockData() {
    final Map<DateTime, CalendarAvailability> data = {};
    final now = DateTime.now();
    
    // Generate 6 months of data
    for (int i = 0; i < 180; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      AvailabilityStatus status;
      double? price;
      String? bookingId;
      String? guestName;
      
      // Mock some bookings and blocked dates
      if (i % 15 == 0) {
        status = AvailabilityStatus.booked;
        price = 150.0;
        bookingId = 'booking_$i';
        guestName = 'Guest ${i ~/ 15 + 1}';
      } else if (i % 20 == 0) {
        status = AvailabilityStatus.blocked;
      } else if (i % 25 == 0) {
        status = AvailabilityStatus.pending;
        price = 145.0;
        bookingId = 'pending_$i';
        guestName = 'Pending Guest';
      } else {
        status = AvailabilityStatus.available;
        price = 140.0 + (i % 10) * 5; // Varying prices
      }
      
      data[normalizedDate] = CalendarAvailability(
        date: normalizedDate,
        status: status,
        price: price,
        bookingId: bookingId,
        guestName: guestName,
      );
    }
    
    return data;
  }

  void updateAvailability(DateTime date, CalendarAvailability availability) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    state = {...state, normalizedDate: availability};
  }

  void blockDates(List<DateTime> dates) {
    final updatedState = Map<DateTime, CalendarAvailability>.from(state);
    for (final date in dates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final existing = state[normalizedDate];
      if (existing != null && existing.status == AvailabilityStatus.available) {
        updatedState[normalizedDate] = existing.copyWith(status: AvailabilityStatus.blocked);
      }
    }
    state = updatedState;
  }

  void unblockDates(List<DateTime> dates) {
    final updatedState = Map<DateTime, CalendarAvailability>.from(state);
    for (final date in dates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final existing = state[normalizedDate];
      if (existing != null && existing.status == AvailabilityStatus.blocked) {
        updatedState[normalizedDate] = existing.copyWith(status: AvailabilityStatus.available);
      }
    }
    state = updatedState;
  }

  void updatePricing(Map<DateTime, double> pricing) {
    final updatedState = Map<DateTime, CalendarAvailability>.from(state);
    pricing.forEach((date, price) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final existing = state[normalizedDate];
      if (existing != null) {
        updatedState[normalizedDate] = existing.copyWith(price: price);
      }
    });
    state = updatedState;
  }
}

final calendarServiceProvider = StateNotifierProvider<CalendarService, Map<DateTime, CalendarAvailability>>((ref) {
  return CalendarService();
});

class CalendarAvailabilityScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const CalendarAvailabilityScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
  });

  @override
  ConsumerState<CalendarAvailabilityScreen> createState() => _CalendarAvailabilityScreenState();
}

class _CalendarAvailabilityScreenState extends ConsumerState<CalendarAvailabilityScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Set<DateTime> _selectedDates = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final availability = ref.watch(calendarServiceProvider);
    final theme = Theme.of(context);
    // final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Availability'),
            Text(
              widget.propertyTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          if (_isSelectionMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedDates.clear();
                });
              },
              child: const Text('Cancel'),
            )
          else
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.block),
                      SizedBox(width: 8),
                      Text('Block Dates'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pricing',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.attach_money),
                      SizedBox(width: 8),
                      Text('Update Pricing'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'bulk',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.edit_calendar),
                      SizedBox(width: 8),
                      Text('Bulk Edit'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'block':
                    _startSelectionMode();
                    break;
                  case 'pricing':
                    _showPricingDialog();
                    break;
                  case 'bulk':
                    _showBulkEditDialog();
                    break;
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Legend
          _buildLegend(theme),
          
          // Calendar
          Expanded(
            child: TableCalendar<CalendarAvailability>(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: (day) {
                final normalizedDay = DateTime(day.year, day.month, day.day);
                final dayAvailability = availability[normalizedDay];
                return dayAvailability != null ? [dayAvailability] : [];
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red[400]),
                holidayTextStyle: TextStyle(color: Colors.red[400]),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (_isSelectionMode) {
                  setState(() {
                    if (_selectedDates.contains(selectedDay)) {
                      _selectedDates.remove(selectedDay);
                    } else {
                      _selectedDates.add(selectedDay);
                    }
                  });
                } else {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _showDayDetails(selectedDay, availability);
                }
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildCalendarDay(day, availability[DateTime(day.year, day.month, day.day)], theme);
                },
                selectedBuilder: (context, day, focusedDay) {
                  return _buildCalendarDay(day, availability[DateTime(day.year, day.month, day.day)], theme, isSelected: true);
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildCalendarDay(day, availability[DateTime(day.year, day.month, day.day)], theme, isToday: true);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode ? _buildSelectionActions(theme) : null,
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Available', Colors.green, theme),
          _buildLegendItem('Booked', Colors.blue, theme),
          _buildLegendItem('Blocked', Colors.red, theme),
          _buildLegendItem('Pending', Colors.orange, theme),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCalendarDay(DateTime day, CalendarAvailability? availability, ThemeData theme, {bool isSelected = false, bool isToday = false}) {
    Color backgroundColor = Colors.transparent;
    Color textColor = theme.colorScheme.onSurface;
    
    if (availability != null) {
      switch (availability.status) {
        case AvailabilityStatus.available:
          backgroundColor = Colors.green.withOpacity(0.3);
          break;
        case AvailabilityStatus.booked:
          backgroundColor = Colors.blue.withOpacity(0.3);
          textColor = Colors.white;
          break;
        case AvailabilityStatus.blocked:
          backgroundColor = Colors.red.withOpacity(0.3);
          textColor = Colors.white;
          break;
        case AvailabilityStatus.pending:
          backgroundColor = Colors.orange.withOpacity(0.3);
          break;
      }
    }

    if (_selectedDates.contains(day)) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.7);
      textColor = theme.colorScheme.onPrimary;
    } else if (isSelected) {
      backgroundColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else if (isToday) {
      backgroundColor = theme.colorScheme.secondary.withOpacity(0.3);
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (availability?.price != null)
            Text(
              '\$${availability!.price!.toInt()}',
              style: TextStyle(
                color: textColor,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '${_selectedDates.length} dates selected',
            style: theme.textTheme.bodyMedium,
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: _selectedDates.isEmpty ? null : () => _blockSelectedDates(),
            child: const Text('Block'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _selectedDates.isEmpty ? null : () => _unblockSelectedDates(),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _startSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedDates.clear();
    });
  }

  void _blockSelectedDates() {
    ref.read(calendarServiceProvider.notifier).blockDates(_selectedDates.toList());
    setState(() {
      _isSelectionMode = false;
      _selectedDates.clear();
    });
    SnackBarUtils.showWarning(context, 'Selected dates have been blocked');
  }

  void _unblockSelectedDates() {
    ref.read(calendarServiceProvider.notifier).unblockDates(_selectedDates.toList());
    setState(() {
      _isSelectionMode = false;
      _selectedDates.clear();
    });
    SnackBarUtils.showSuccess(context, 'Selected dates have been unblocked');
  }

  void _showDayDetails(DateTime day, Map<DateTime, CalendarAvailability> availability) {
    final dayAvailability = availability[DateTime(day.year, day.month, day.day)];
    if (dayAvailability == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DayDetailsBottomSheet(
        day: day,
        availability: dayAvailability,
        onUpdate: (updatedAvailability) {
          ref.read(calendarServiceProvider.notifier).updateAvailability(day, updatedAvailability);
        },
      ),
    );
  }

  void _showPricingDialog() {
    showDialog(
      context: context,
      builder: (context) => PricingDialog(
        onPricingUpdate: (pricing) {
          ref.read(calendarServiceProvider.notifier).updatePricing(pricing);
        },
      ),
    );
  }

  void _showBulkEditDialog() {
    showDialog(
      context: context,
      builder: (context) => BulkEditDialog(
        onBulkUpdate: (startDate, endDate, status, price) {
          // Implement bulk update logic
        },
      ),
    );
  }
}

class DayDetailsBottomSheet extends StatefulWidget {
  final DateTime day;
  final CalendarAvailability availability;
  final Function(CalendarAvailability) onUpdate;

  const DayDetailsBottomSheet({
    super.key,
    required this.day,
    required this.availability,
    required this.onUpdate,
  });

  @override
  State<DayDetailsBottomSheet> createState() => _DayDetailsBottomSheetState();
}

class _DayDetailsBottomSheetState extends State<DayDetailsBottomSheet> {
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  late AvailabilityStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.availability.price?.toString() ?? '');
    _notesController = TextEditingController(text: widget.availability.notes ?? '');
    _selectedStatus = widget.availability.status;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit ${widget.day.day}/${widget.day.month}/${widget.day.year}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Status Selection
          Text(
            'Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AvailabilityStatus.values.map((status) {
              return ChoiceChip(
                label: Text(_getStatusLabel(status)),
                selected: _selectedStatus == status,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Price
          if (_selectedStatus == AvailabilityStatus.available) ...[
            Text(
              'Price per night',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          Text(
            'Notes (Optional)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any notes about this date...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(AvailabilityStatus status) {
    switch (status) {
      case AvailabilityStatus.available:
        return 'Available';
      case AvailabilityStatus.booked:
        return 'Booked';
      case AvailabilityStatus.blocked:
        return 'Blocked';
      case AvailabilityStatus.pending:
        return 'Pending';
    }
  }

  void _saveChanges() {
    final price = double.tryParse(_priceController.text);
    final notes = _notesController.text.trim();

    final updatedAvailability = widget.availability.copyWith(
      status: _selectedStatus,
      price: price,
      notes: notes.isEmpty ? null : notes,
    );

    widget.onUpdate(updatedAvailability);
    context.pop();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class PricingDialog extends StatefulWidget {
  final Function(Map<DateTime, double>) onPricingUpdate;

  const PricingDialog({
    super.key,
    required this.onPricingUpdate,
  });

  @override
  State<PricingDialog> createState() => _PricingDialogState();
}

class _PricingDialogState extends State<PricingDialog> {
  final _priceController = TextEditingController();
  DateTimeRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Update Pricing'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date Range Selector
          OutlinedButton(
            onPressed: _selectDateRange,
            child: Text(
              _selectedRange != null
                  ? '${_selectedRange!.start.day}/${_selectedRange!.start.month} - ${_selectedRange!.end.day}/${_selectedRange!.end.month}'
                  : 'Select Date Range',
            ),
          ),
          const SizedBox(height: 16),

          // Price Input
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Price per night',
              prefixText: '\$',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSave() ? _savePricing : null,
          child: const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (range != null) {
      setState(() {
        _selectedRange = range;
      });
    }
  }

  bool _canSave() {
    return _selectedRange != null && _priceController.text.isNotEmpty;
  }

  void _savePricing() {
    final price = double.tryParse(_priceController.text);
    if (price == null || _selectedRange == null) return;

    final pricing = <DateTime, double>{};
    DateTime current = _selectedRange!.start;

    while (current.isBefore(_selectedRange!.end) || current.isAtSameMomentAs(_selectedRange!.end)) {
      pricing[DateTime(current.year, current.month, current.day)] = price;
      current = current.add(const Duration(days: 1));
    }

    widget.onPricingUpdate(pricing);
    context.pop();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
}

class BulkEditDialog extends StatefulWidget {
  final Function(DateTime, DateTime, AvailabilityStatus, double?) onBulkUpdate;

  const BulkEditDialog({
    super.key,
    required this.onBulkUpdate,
  });

  @override
  State<BulkEditDialog> createState() => _BulkEditDialogState();
}

class _BulkEditDialogState extends State<BulkEditDialog> {
  DateTimeRange? _selectedRange;
  AvailabilityStatus _selectedStatus = AvailabilityStatus.available;
  final _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Edit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: _selectDateRange,
            child: Text(
              _selectedRange != null
                  ? '${_selectedRange!.start.day}/${_selectedRange!.start.month} - ${_selectedRange!.end.day}/${_selectedRange!.end.month}'
                  : 'Select Date Range',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AvailabilityStatus>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: AvailabilityStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(_getStatusLabel(status)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedStatus = value;
                });
              }
            },
          ),
          if (_selectedStatus == AvailabilityStatus.available) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price per night',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedRange != null ? _saveBulkEdit : null,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (range != null) {
      setState(() {
        _selectedRange = range;
      });
    }
  }

  String _getStatusLabel(AvailabilityStatus status) {
    switch (status) {
      case AvailabilityStatus.available:
        return 'Available';
      case AvailabilityStatus.booked:
        return 'Booked';
      case AvailabilityStatus.blocked:
        return 'Blocked';
      case AvailabilityStatus.pending:
        return 'Pending';
    }
  }

  void _saveBulkEdit() {
    if (_selectedRange == null) return;

    final price = double.tryParse(_priceController.text);
    widget.onBulkUpdate(_selectedRange!.start, _selectedRange!.end, _selectedStatus, price);
    context.pop();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
}
