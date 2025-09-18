import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/snackbar_utils.dart';

/// GDPR Compliance screen for data privacy management
class GDPRComplianceScreen extends ConsumerStatefulWidget {
  const GDPRComplianceScreen({super.key});

  @override
  ConsumerState<GDPRComplianceScreen> createState() => _GDPRComplianceScreenState();
}

class _GDPRComplianceScreenState extends ConsumerState<GDPRComplianceScreen> {
  bool _isLoading = false;
  final Map<String, bool> _consents = {
    'essential': true, // Always required
    'analytics': false,
    'marketing': false,
    'personalization': false,
    'thirdParty': false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data Protection'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            _buildDataProcessingSection(theme),
            const SizedBox(height: 24),
            _buildConsentManagement(theme),
            const SizedBox(height: 24),
            _buildDataRights(theme),
            const SizedBox(height: 24),
            _buildDataExportSection(theme),
            const SizedBox(height: 24),
            _buildDataDeletionSection(theme),
            const SizedBox(height: 32),
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Your Privacy Matters',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We are committed to protecting your personal data and respecting your privacy rights under GDPR and other applicable data protection laws.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataProcessingSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Processing Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDataProcessingItem(
              theme,
              'Personal Information',
              'Name, email, phone number for account management',
              Icons.person,
            ),
            _buildDataProcessingItem(
              theme,
              'Location Data',
              'Used for property search and recommendations',
              Icons.location_on,
            ),
            _buildDataProcessingItem(
              theme,
              'Usage Analytics',
              'App usage patterns to improve user experience',
              Icons.analytics,
            ),
            _buildDataProcessingItem(
              theme,
              'Communication Data',
              'Messages and booking communications',
              Icons.message,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataProcessingItem(ThemeData theme, String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentManagement(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consent Management',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildConsentItem(
              'Essential Cookies',
              'Required for basic app functionality',
              'essential',
              true, // Always required
            ),
            _buildConsentItem(
              'Analytics',
              'Help us improve the app experience',
              'analytics',
              false,
            ),
            _buildConsentItem(
              'Marketing',
              'Personalized offers and recommendations',
              'marketing',
              false,
            ),
            _buildConsentItem(
              'Personalization',
              'Customize content based on your preferences',
              'personalization',
              false,
            ),
            _buildConsentItem(
              'Third-party Services',
              'Integration with external services',
              'thirdParty',
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentItem(String title, String description, String key, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isRequired) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Required',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _consents[key] ?? false,
            onChanged: isRequired ? null : (value) {
              setState(() {
                _consents[key] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataRights(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Data Rights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDataRightItem(
              theme,
              'Right to Access',
              'Request a copy of your personal data',
              Icons.visibility,
              () => _showDataAccessDialog(),
            ),
            _buildDataRightItem(
              theme,
              'Right to Rectification',
              'Correct inaccurate personal data',
              Icons.edit,
              () => context.push('/profile/edit'),
            ),
            _buildDataRightItem(
              theme,
              'Right to Erasure',
              'Request deletion of your personal data',
              Icons.delete_forever,
              () => _showDataDeletionDialog(),
            ),
            _buildDataRightItem(
              theme,
              'Right to Portability',
              'Export your data in a structured format',
              Icons.download,
              () => _exportUserData(),
            ),
            _buildDataRightItem(
              theme,
              'Right to Object',
              'Object to processing of your personal data',
              Icons.block,
              () => _showObjectionDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRightItem(ThemeData theme, String title, String description, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataExportSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Export',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Download all your personal data in a machine-readable format.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _exportUserData,
              icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
              label: Text(_isLoading ? 'Preparing Export...' : 'Export My Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataDeletionSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Deletion',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Permanently delete your account and all associated data. This action cannot be undone.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showDataDeletionDialog,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete My Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveConsentPreferences,
            child: const Text('Save Preferences'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.push('/legal/privacy-policy'),
          child: const Text('View Privacy Policy'),
        ),
      ],
    );
  }

  void _saveConsentPreferences() async {
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      SnackBarUtils.showSuccess(context, 'Consent preferences saved successfully');
    }
  }

  void _exportUserData() async {
    setState(() => _isLoading = true);
    
    // Simulate data export preparation
    await Future.delayed(const Duration(seconds: 3));
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Ready'),
          content: const Text('Your data export has been prepared and will be sent to your registered email address within 24 hours.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showDataAccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Access Request'),
        content: const Text('We will provide you with a comprehensive report of all personal data we have about you within 30 days. This will be sent to your registered email address.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              SnackBarUtils.showSuccess(context, 'Data access request submitted');
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  void _showDataDeletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to account deletion flow
              context.push('/account/delete');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showObjectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Object to Data Processing'),
        content: const Text('You can object to certain types of data processing. Please specify which processing activities you object to and we will review your request.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              SnackBarUtils.showInfo(context, 'Objection request submitted for review');
            },
            child: const Text('Submit Objection'),
          ),
        ],
      ),
    );
  }
}
