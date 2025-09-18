import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/monetization/sponsored_listings_service.dart';
import '../../services/monetization_service.dart';
import '../../models/monetization_models.dart';
import '../../core/providers/ui_visibility_provider.dart';

class PromoteListingScreen extends ConsumerStatefulWidget {
  const PromoteListingScreen({super.key});

  @override
  ConsumerState<PromoteListingScreen> createState() => _PromoteListingScreenState();
}

class _PromoteListingScreenState extends ConsumerState<PromoteListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _listingIdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _bidCtrl = TextEditingController(text: '100');
  DateTimeRange? _range;

  @override
  void dispose() {
    _listingIdCtrl.dispose();
    _nameCtrl.dispose();
    _bidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promote Listing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _listingIdCtrl,
                decoration: const InputDecoration(labelText: 'Listing ID'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter listing id' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Campaign Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bidCtrl,
                decoration: const InputDecoration(labelText: 'Daily Budget (INR)'),
                keyboardType: TextInputType.number,
                validator: (v) => (double.tryParse(v ?? '') ?? 0) > 0 ? null : 'Enter valid amount',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDateRangePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 365)));
                        if (picked != null) setState(() => _range = picked);
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(_range == null ? 'Pick Dates' : '${_range!.start.toString().split(' ').first} → ${_range!.end.toString().split(' ').first}'),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Proceed to Checkout'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_range == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick a date range')));
      return;
    }

    final listingId = _listingIdCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final daily = double.tryParse(_bidCtrl.text.trim()) ?? 0.0;
    final days = _range!.end.difference(_range!.start).inDays + 1;
    final total = (daily * days).toDouble();

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid budget')));
      return;
    }

    // 1) Create sponsored campaign
    final okCampaign = await ref.read(sponsoredListingsProvider.notifier).createSponsoredCampaign(
          propertyId: listingId,
          campaignName: name,
          bidAmount: daily,
          startDate: _range!.start,
          endDate: _range!.end,
        );

    if (!okCampaign) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create campaign')));
      return;
    }

    // 2) Record transaction via monetization service (mock checkout)
    final item = MicrotransactionItem(
      id: 'sponsored_campaign_${DateTime.now().millisecondsSinceEpoch}',
      type: MicrotransactionType.featuredListing,
      name: 'Sponsored Campaign',
      description: 'Promote listing $listingId for $days days',
      price: total,
      currency: 'INR',
      icon: '📣',
      duration: Duration(days: days),
      isOneTime: true,
    );

    final okPayment = await ref.read(monetizationServiceProvider.notifier).purchaseMicrotransaction(item);

    if (!mounted) return;
    if (okPayment) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campaign created and payment recorded')));
      // Transactions is an immersive route rendered above the Shell
      ref.read(immersiveRouteOpenProvider.notifier).state = true;
      context.push('/transactions').whenComplete(() {
        ref.read(immersiveRouteOpenProvider.notifier).state = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed')));
    }
  }
}
