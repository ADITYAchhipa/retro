import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Split Payment Models
class SplitPaymentGroup {
  final String id;
  final String name;
  final String propertyTitle;
  final double totalAmount;
  final DateTime dueDate;
  final List<PaymentParticipant> participants;
  final PaymentStatus status;

  SplitPaymentGroup({
    required this.id,
    required this.name,
    required this.propertyTitle,
    required this.totalAmount,
    required this.dueDate,
    required this.participants,
    required this.status,
  });

  double get totalPaid => participants
      .where((p) => p.hasPaid)
      .fold(0.0, (sum, p) => sum + p.shareAmount);

  bool get isFullyPaid => totalPaid >= totalAmount;
}

class PaymentParticipant {
  final String id;
  final String name;
  final String email;
  final double shareAmount;
  final bool hasPaid;

  PaymentParticipant({
    required this.id,
    required this.name,
    required this.email,
    required this.shareAmount,
    required this.hasPaid,
  });
}

enum PaymentStatus { active, completed, pending }

// Split Payment Service
class SplitPaymentService extends StateNotifier<List<SplitPaymentGroup>> {
  SplitPaymentService() : super([]);

  void loadUserGroups() {
    state = [
      SplitPaymentGroup(
        id: '1',
        name: 'Downtown Apartment Split',
        propertyTitle: 'Modern Downtown Loft',
        totalAmount: 3000.0,
        dueDate: DateTime.now().add(const Duration(days: 15)),
        status: PaymentStatus.active,
        participants: [
          PaymentParticipant(
            id: '1',
            name: 'You',
            email: 'you@example.com',
            shareAmount: 1000.0,
            hasPaid: true,
          ),
          PaymentParticipant(
            id: '2',
            name: 'Sarah Johnson',
            email: 'sarah@example.com',
            shareAmount: 1000.0,
            hasPaid: false,
          ),
          PaymentParticipant(
            id: '3',
            name: 'Mike Chen',
            email: 'mike@example.com',
            shareAmount: 1000.0,
            hasPaid: false,
          ),
        ],
      ),
      SplitPaymentGroup(
        id: '2',
        name: 'Beach House Weekend',
        propertyTitle: 'Oceanfront Beach House',
        totalAmount: 1200.0,
        dueDate: DateTime.now().add(const Duration(days: 30)),
        status: PaymentStatus.completed,
        participants: [
          PaymentParticipant(
            id: '1',
            name: 'You',
            email: 'you@example.com',
            shareAmount: 600.0,
            hasPaid: true,
          ),
          PaymentParticipant(
            id: '4',
            name: 'Alex Smith',
            email: 'alex@example.com',
            shareAmount: 600.0,
            hasPaid: true,
          ),
        ],
      ),
    ];
  }

  void processPayment(String groupId, String participantId) {
    final groupIndex = state.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    final group = state[groupIndex];
    final participantIndex = group.participants.indexWhere((p) => p.id == participantId);
    if (participantIndex == -1) return;

    final updatedParticipant = PaymentParticipant(
      id: group.participants[participantIndex].id,
      name: group.participants[participantIndex].name,
      email: group.participants[participantIndex].email,
      shareAmount: group.participants[participantIndex].shareAmount,
      hasPaid: true,
    );

    final updatedParticipants = [...group.participants];
    updatedParticipants[participantIndex] = updatedParticipant;

    final updatedGroup = SplitPaymentGroup(
      id: group.id,
      name: group.name,
      propertyTitle: group.propertyTitle,
      totalAmount: group.totalAmount,
      dueDate: group.dueDate,
      participants: updatedParticipants,
      status: updatedParticipants.every((p) => p.hasPaid) 
          ? PaymentStatus.completed 
          : PaymentStatus.active,
    );

    final updatedState = [...state];
    updatedState[groupIndex] = updatedGroup;
    state = updatedState;
  }
}

// Provider
final splitPaymentServiceProvider = StateNotifierProvider<SplitPaymentService, List<SplitPaymentGroup>>(
  (ref) => SplitPaymentService(),
);

// Split Payment Screen
class SplitPaymentScreen extends ConsumerStatefulWidget {
  const SplitPaymentScreen({super.key});

  @override
  ConsumerState<SplitPaymentScreen> createState() => _SplitPaymentScreenState();
}

class _SplitPaymentScreenState extends ConsumerState<SplitPaymentScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(splitPaymentServiceProvider.notifier).loadUserGroups();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = ref.watch(splitPaymentServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Payments'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: groups.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) => _buildGroupCard(groups[index], theme),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Split'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 80,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No payment groups found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new split payment to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(SplitPaymentGroup group, ThemeData theme) {
    final progress = group.totalPaid / group.totalAmount;
    final daysUntilDue = group.dueDate.difference(DateTime.now()).inDays;
    final userParticipant = group.participants.firstWhere((p) => p.name == 'You');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.propertyTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(group.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(group.status).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _getStatusText(group.status),
                    style: TextStyle(
                      color: _getStatusColor(group.status),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '\$${group.totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Share',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '\$${userParticipant.shareAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        daysUntilDue > 0 ? '$daysUntilDue days' : 'Overdue',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: daysUntilDue > 0 ? null : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Progress',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% complete',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildParticipantAvatars(group.participants, theme),
                ),
                const SizedBox(width: 16),
                if (!userParticipant.hasPaid)
                  ElevatedButton(
                    onPressed: () => _showPaymentDialog(group, userParticipant),
                    child: const Text('Pay Now'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Paid',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantAvatars(List<PaymentParticipant> participants, ThemeData theme) {
    return Row(
      children: participants.take(4).map((participant) {
        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: participant.hasPaid ? Colors.green : theme.colorScheme.primary,
            child: participant.hasPaid
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    participant.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.active:
        return Colors.blue;
      case PaymentStatus.completed:
        return Colors.green;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.active:
        return 'Active';
      case PaymentStatus.completed:
        return 'Completed';
    }
  }

  void _showCreateDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create split payment feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showPaymentDialog(SplitPaymentGroup group, PaymentParticipant participant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pay Your Share',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              group.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount to Pay:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '\$${participant.shareAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildPaymentMethodTile(
                    icon: Icons.credit_card,
                    title: 'Credit Card',
                    subtitle: '•••• •••• •••• 1234',
                    onTap: () => _processPayment(group, participant, 'Credit Card'),
                  ),
                  _buildPaymentMethodTile(
                    icon: Icons.account_balance,
                    title: 'Bank Transfer',
                    subtitle: 'Chase Bank ••••5678',
                    onTap: () => _processPayment(group, participant, 'Bank Transfer'),
                  ),
                  _buildPaymentMethodTile(
                    icon: Icons.payment,
                    title: 'PayPal',
                    subtitle: 'your.email@example.com',
                    onTap: () => _processPayment(group, participant, 'PayPal'),
                  ),
                  _buildPaymentMethodTile(
                    icon: Icons.phone_android,
                    title: 'Apple Pay',
                    subtitle: 'Touch ID or Face ID',
                    onTap: () => _processPayment(group, participant, 'Apple Pay'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  void _processPayment(SplitPaymentGroup group, PaymentParticipant participant, String method) {
    Navigator.of(context).pop();
    ref.read(splitPaymentServiceProvider.notifier).processPayment(group.id, participant.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment processed via $method'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
