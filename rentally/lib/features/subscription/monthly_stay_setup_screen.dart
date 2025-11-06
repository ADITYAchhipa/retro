import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../services/rent_reminder_service.dart';
import '../../services/local_notifications_service.dart';
import '../../services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/kyc/kyc_service.dart';
import '../../services/availability_service.dart';
// Note: No agreement creation in-app; agreements are handled offline between tenant and owner

class MonthlyStaySetupScreen extends ConsumerStatefulWidget {
  final String listingId;
  final DateTime? startDate;
  final double? monthlyAmount;
  final double? securityDeposit;
  final String currency;
  final bool requireSeekerId;

  const MonthlyStaySetupScreen({
    super.key,
    required this.listingId,
    this.startDate,
    this.monthlyAmount,
    this.securityDeposit,
    required this.currency,
    this.requireSeekerId = false,
  });

  @override
  ConsumerState<MonthlyStaySetupScreen> createState() => _MonthlyStaySetupScreenState();
}

class _MonthlyStaySetupScreenState extends ConsumerState<MonthlyStaySetupScreen> {
  DateTime? _startDate;
  bool _agreeConsent = false;
  bool _submitting = false;
  bool _uploadingSeekerId = false;
  String? _seekerIdImageUrl;
  final ImageService _imageService = ImageService();
  bool _autoIdChecked = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate ?? DateTime.now().add(const Duration(days: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoAttachSavedId());
  }

  Future<void> _useSavedId() async {
    try {
      setState(() => _uploadingSeekerId = true);
      final profile = await KycService.instance.getProfile();
      final path = profile.frontIdPath;
      if (path == null || path.isEmpty) {
        if (mounted) {
          setState(() => _uploadingSeekerId = false);
          _snack('No saved ID found. Complete KYC to store your ID.');
        }
        return;
      }
      final xfile = XFile(path);
      final url = await _imageService.uploadImage(xfile);
      if (!mounted) return;
      setState(() {
        _seekerIdImageUrl = url;
        _uploadingSeekerId = false;
      });
      if (url == null) {
        _snack('Failed to attach saved ID. Please try uploading again.');
      } else {
        _snack('Saved ID attached successfully');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingSeekerId = false);
      _snack('Failed to attach saved ID: $e');
    }
  }

  Future<void> _tryAutoAttachSavedId() async {
    if (_autoIdChecked) return;
    _autoIdChecked = true;
    if (!widget.requireSeekerId) return;
    if (_seekerIdImageUrl != null && _seekerIdImageUrl!.isNotEmpty) return;
    try {
      final profile = await KycService.instance.getProfile();
      final path = profile.frontIdPath;
      if (path == null || path.isEmpty) return;
      setState(() => _uploadingSeekerId = true);
      final url = await _imageService.uploadImage(XFile(path));
      if (!mounted) return;
      setState(() {
        _seekerIdImageUrl = url;
        _uploadingSeekerId = false;
      });
      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved ID attached.'),
            action: SnackBarAction(
              label: 'Change',
              onPressed: () => setState(() => _seekerIdImageUrl = null),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _uploadingSeekerId = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double monthly = ((widget.monthlyAmount ?? 0).toDouble()).clamp(0.0, double.infinity).toDouble();
    final double deposit = ((widget.securityDeposit ?? monthly).toDouble()).clamp(0.0, double.infinity).toDouble();
    final double dueNow = monthly + deposit;

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Stay Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Listing: ${widget.listingId}'),
            const SizedBox(height: 12),
            const SizedBox(height: 4),
            Text('Select Start Date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(_startDate == null ? 'Choose date' : _fmt(_startDate!)),
              onPressed: _pickStartDate,
            ),
            const SizedBox(height: 16),
            Text('Pricing & Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Monthly rent', CurrencyFormatter.formatPrice(monthly, currency: widget.currency)),
                    const Divider(),
                    _row('Security deposit (one-time)', CurrencyFormatter.formatPrice(deposit, currency: widget.currency)),
                    const Divider(),
                    _row('Due now', CurrencyFormatter.formatPrice(dueNow, currency: widget.currency), isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.requireSeekerId) ...[
              Text('Identity Verification', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_seekerIdImageUrl == null)
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _uploadingSeekerId ? null : () => _pickAndUploadId(camera: false),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Upload ID'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _uploadingSeekerId ? null : () => _pickAndUploadId(camera: true),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Use Camera'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _uploadingSeekerId ? null : _useSavedId,
                      icon: const Icon(Icons.badge_outlined),
                      label: const Text('Use saved ID'),
                    ),
                    if (_uploadingSeekerId) ...[
                      const SizedBox(width: 12),
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    ]
                  ],
                )
              else
                Row(
                  children: [
                    const Icon(Icons.verified_user, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text('ID uploaded', style: Theme.of(context).textTheme.bodyMedium)),
                    TextButton.icon(
                      onPressed: _uploadingSeekerId ? null : () => setState(() => _seekerIdImageUrl = null),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(
                'Host requires a government-issued ID. Your ID will be kept confidential.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rental agreements are handled offline directly between tenant and owner. No digital agreement is created in-app.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _agreeConsent,
              onChanged: (v) => setState(() => _agreeConsent = v ?? false),
              title: const Text('I agree to the Terms & House Rules'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : () => _continue(monthly),
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward),
                label: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isTotal = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: isTotal ? const TextStyle(fontWeight: FontWeight.w600) : null,
          ),
        ),
        Text(
          value,
          style: isTotal ? TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary) : null,
        ),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} (Billing day: ${d.day})';

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      // Prevent selecting start dates in fully blocked months
      final avail = ref.read(availabilityProvider);
      final a = avail.byListingId[widget.listingId];
      final monthKey = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}';
      if (a != null && a.blockedMonths.contains(monthKey)) {
        _snack('Selected month is not available. Please choose another month.');
        return;
      }
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickAndUploadId({required bool camera}) async {
    try {
      setState(() => _uploadingSeekerId = true);
      final img = camera
          ? await _imageService.pickImageFromCamera()
          : await _imageService.pickImageFromGallery();
      if (img == null) {
        setState(() => _uploadingSeekerId = false);
        return;
      }
      final url = await _imageService.uploadImage(img);
      if (!mounted) return;
      setState(() {
        _seekerIdImageUrl = url;
        _uploadingSeekerId = false;
      });
      if (url == null) {
        _snack('Failed to upload ID image');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingSeekerId = false);
      _snack('Failed to upload ID image: $e');
    }
  }

  Future<void> _continue(double monthly) async {
    if (_startDate == null) {
      _snack('Please select a start date');
      return;
    }
    if (widget.requireSeekerId && (_seekerIdImageUrl == null || _seekerIdImageUrl!.isEmpty)) {
      _snack('Please upload your ID to continue');
      return;
    }
    if (!_agreeConsent) {
      _snack('Please agree to terms and house rules');
      return;
    }
    setState(() => _submitting = true);
    try {
      // Schedule monthly rent reminder based on selected start date
      await RentReminderService.scheduleForMonthlyStay(
        listingId: widget.listingId,
        startDate: _startDate!,
        monthlyAmount: monthly,
        currency: widget.currency,
      );

      // Also schedule OS-level local notifications (12 months ahead)
      final nextMonth = DateTime(_startDate!.year, _startDate!.month + 1, 1);
      final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
      final billingDay = _startDate!.day;
      final day = billingDay > lastDay ? lastDay : billingDay;
      final firstDue = DateTime(nextMonth.year, nextMonth.month, day, 10);
      await LocalNotificationsService.instance.scheduleMonthlySeries(
        listingId: widget.listingId,
        firstDueLocal: firstDue,
        count: 12,
        title: 'Rent due today',
        body: 'Your rent for listing ${widget.listingId} is due today. Please pay ${CurrencyFormatter.formatPrice(monthly, currency: widget.currency)}.',
      );

      // Simulate setup processing, then navigate to Recurring Payment Setup
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _snack('Monthly subscription created. Rent reminders scheduled. Proceeding to payment setup...');
      context.push(
        '/recurring/setup/${widget.listingId}',
        extra: {
          'monthlyAmount': monthly,
          'currency': widget.currency,
        },
      );
    } catch (e) {
      _snack('Failed to continue: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
