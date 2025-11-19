import 'package:flutter/material.dart';

class PayoutMethodsScreen extends StatelessWidget {
  const PayoutMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout Methods'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: EdgeInsets.all(isPhone ? 16 : 24),
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(isPhone ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                  theme.colorScheme.secondary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: isPhone ? 24 : 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Payout Methods',
                            style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Link your preferred accounts to receive payouts',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
          SizedBox(height: isPhone ? 20 : 28),
          
          // Payment Methods Grid
          Text(
            'Available Payout Methods',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildMethodCard(
            context,
            name: 'Bank Account',
            description: 'Direct bank transfer (NEFT/IMPS)',
            icon: Icons.account_balance,
            primaryColor: const Color(0xFF3B82F6),
            secondaryColor: const Color(0xFF06B6D4),
            isLinked: false,
            isPhone: isPhone,
          ),
          SizedBox(height: isPhone ? 12 : 16),
          
          _buildMethodCard(
            context,
            name: 'UPI',
            description: 'Instant payment via UPI ID',
            icon: Icons.qr_code_2,
            primaryColor: const Color(0xFF10B981),
            secondaryColor: const Color(0xFF059669),
            isLinked: false,
            isPhone: isPhone,
          ),
          SizedBox(height: isPhone ? 12 : 16),
          
          _buildMethodCard(
            context,
            name: 'PayPal',
            description: 'International payouts',
            icon: Icons.payment,
            primaryColor: const Color(0xFF8B5CF6),
            secondaryColor: const Color(0xFF6366F1),
            isLinked: false,
            isPhone: isPhone,
          ),
          SizedBox(height: isPhone ? 12 : 16),
          
          _buildMethodCard(
            context,
            name: 'Stripe',
            description: 'Fast & secure payouts',
            icon: Icons.credit_card,
            primaryColor: const Color(0xFFEC4899),
            secondaryColor: const Color(0xFFF59E0B),
            isLinked: false,
            isPhone: isPhone,
          ),
          SizedBox(height: isPhone ? 12 : 16),
          
          _buildMethodCard(
            context,
            name: 'Wise (TransferWise)',
            description: 'Low-cost international transfers',
            icon: Icons.swap_horiz,
            primaryColor: const Color(0xFF06B6D4),
            secondaryColor: const Color(0xFF3B82F6),
            isLinked: false,
            isPhone: isPhone,
          ),
          
          SizedBox(height: isPhone ? 24 : 32),
          
          // Help Section
          Container(
            padding: EdgeInsets.all(isPhone ? 14 : 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Link at least one payout method to receive your earnings. Processing time varies by method.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required String name,
    required String description,
    required IconData icon,
    required Color primaryColor,
    required Color secondaryColor,
    required bool isLinked,
    required bool isPhone,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.08),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: secondaryColor.withValues(alpha: 0.06),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Linking $name coming soon'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(isPhone ? 16 : 20),
              child: Row(
              children: [
                // Icon with gradient background
                Container(
                  width: isPhone ? 48 : 56,
                  height: isPhone ? 48 : 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.2),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isPhone ? 24 : 28,
                  ),
                ),
                SizedBox(width: isPhone ? 14 : 16),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: (isPhone ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLinked ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isLinked ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLinked ? Icons.check_circle : Icons.link_off,
                              size: 12,
                              color: isLinked ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isLinked ? 'Linked' : 'Not Linked',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isLinked ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: isPhone ? 14 : 16,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
