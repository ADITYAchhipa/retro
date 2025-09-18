import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/monetization_service.dart';
import '../../models/monetization_models.dart';
import '../../utils/snackbar_utils.dart';

class MicrotransactionWidget extends ConsumerStatefulWidget {
  final MicrotransactionType type;
  final String? contextId; // For listing ID, message ID, etc.
  final VoidCallback? onSuccess;
  final bool showAsCard;

  const MicrotransactionWidget({
    super.key,
    required this.type,
    this.contextId,
    this.onSuccess,
    this.showAsCard = false,
  });

  @override
  ConsumerState<MicrotransactionWidget> createState() => _MicrotransactionWidgetState();
}

class _MicrotransactionWidgetState extends ConsumerState<MicrotransactionWidget> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final monetization = ref.watch(monetizationServiceProvider);
    final item = monetization.microtransactionItems
        .where((item) => item.type == widget.type)
        .firstOrNull;

    if (item == null) return const SizedBox.shrink();

    if (widget.showAsCard) {
      return _buildCard(item);
    } else {
      return _buildButton(item);
    }
  }

  Widget _buildCard(MicrotransactionItem item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              _getItemColor(item.type).withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getItemColor(item.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (item.duration != null)
                        Text(
                          'Valid for ${item.duration!.inDays} days',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _getItemColor(item.type),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _purchaseItem(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getItemColor(item.type),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Purchase ${item.icon}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(MicrotransactionItem item) {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : () => _purchaseItem(item),
      icon: _isProcessing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(item.icon),
      label: Text('${item.name} - ₹${item.price.toStringAsFixed(0)}'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _getItemColor(item.type),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Color _getItemColor(MicrotransactionType type) {
    switch (type) {
      case MicrotransactionType.highlightMessage:
        return Colors.orange;
      case MicrotransactionType.instantBooking:
        return Colors.green;
      case MicrotransactionType.priorityBadge:
        return Colors.purple;
      case MicrotransactionType.boostListing:
        return Colors.blue;
      case MicrotransactionType.verifiedBadge:
        return Colors.teal;
      case MicrotransactionType.featuredListing:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _purchaseItem(MicrotransactionItem item) async {
    // Show confirmation dialog
    final confirmed = await _showPurchaseConfirmation(item);
    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      final success = await ref
          .read(monetizationServiceProvider.notifier)
          .purchaseMicrotransaction(item);

      if (success && mounted) {
        _showSuccessMessage(item);
        widget.onSuccess?.call();
      } else if (mounted) {
        _showErrorMessage();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool> _showPurchaseConfirmation(MicrotransactionItem item) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${item.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Price:'),
                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (item.duration != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Duration:'),
                  Text('${item.duration!.inDays} days'),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getItemColor(item.type),
              foregroundColor: Colors.white,
            ),
            child: const Text('Purchase'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessMessage(MicrotransactionItem item) {
    SnackBarUtils.showSuccess(context, '${item.name} activated successfully!');
  }

  void _showErrorMessage() {
    SnackBarUtils.showError(context, 'Purchase failed. Please try again.');
  }
}

// Microtransaction Marketplace Screen
class MicrotransactionMarketplaceScreen extends ConsumerWidget {
  final bool isHost;

  const MicrotransactionMarketplaceScreen({
    super.key,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final monetization = ref.watch(monetizationServiceProvider);
    
    final items = monetization.microtransactionItems.where((item) {
      if (isHost) {
        return [
          MicrotransactionType.boostListing,
          MicrotransactionType.verifiedBadge,
          MicrotransactionType.featuredListing,
          MicrotransactionType.extraPhotos,
        ].contains(item.type);
      } else {
        return [
          MicrotransactionType.highlightMessage,
          MicrotransactionType.instantBooking,
          MicrotransactionType.priorityBadge,
          MicrotransactionType.premiumSupport,
        ].contains(item.type);
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isHost ? 'Host Boosters' : 'Premium Features'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isHost ? Icons.trending_up : Icons.star,
                  size: 48,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  isHost 
                      ? 'Boost Your Listings'
                      : 'Enhance Your Experience',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isHost
                      ? 'Get more visibility and bookings with premium features'
                      : 'Stand out and get priority access with premium add-ons',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Items Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return MicrotransactionWidget(
                  type: items[index].type,
                  showAsCard: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Quick Purchase Bottom Sheet
class QuickPurchaseBottomSheet extends ConsumerWidget {
  final List<MicrotransactionType> availableTypes;
  final String? contextId;
  final VoidCallback? onPurchaseSuccess;

  const QuickPurchaseBottomSheet({
    super.key,
    required this.availableTypes,
    this.contextId,
    this.onPurchaseSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monetization = ref.watch(monetizationServiceProvider);
    final items = monetization.microtransactionItems
        .where((item) => availableTypes.contains(item.type))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Quick Purchase',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          ...items.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: MicrotransactionWidget(
              type: item.type,
              contextId: contextId,
              onSuccess: () {
                Navigator.pop(context);
                onPurchaseSuccess?.call();
              },
            ),
          )),
          
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required List<MicrotransactionType> availableTypes,
    String? contextId,
    VoidCallback? onPurchaseSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickPurchaseBottomSheet(
        availableTypes: availableTypes,
        contextId: contextId,
        onPurchaseSuccess: onPurchaseSuccess,
      ),
    );
  }
}
