import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';
import 'package:go_router/go_router.dart';

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Center'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(theme, 'Get Help', Icons.help_outline, isPhone),
          const SizedBox(height: 12),
          _supportTile(
            context,
            color: Colors.teal,
            icon: Icons.help_center,
            title: 'Help Center',
            subtitle: 'FAQs and articles',
            onTap: () => SnackBarUtils.showInfo(context, 'Help Center coming soon'),
          ),
          const Divider(height: 1),
          _supportTile(
            context,
            color: Colors.blue,
            icon: Icons.chat_bubble_outline,
            title: 'Contact Support',
            subtitle: 'Chat with our team',
            onTap: () => context.push('/chat/support', extra: {'isSupport': true, 'title': 'Support'}),
          ),
          const Divider(height: 1),
          _supportTile(
            context,
            color: Colors.amber,
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Share your thoughts',
            onTap: () => _showFeedbackDialog(context),
          ),

          const SizedBox(height: 24),
          _sectionHeader(theme, 'Guides', Icons.menu_book_outlined, isPhone),
          const SizedBox(height: 12),
          _guideTile(
            context,
            color: Colors.indigo,
            icon: Icons.settings_suggest_outlined,
            title: 'Using Settings',
            subtitle: 'Personalize your experience',
          ),
          const Divider(height: 1),
          _guideTile(
            context,
            color: Colors.green,
            icon: Icons.security_outlined,
            title: 'Account & Security',
            subtitle: 'Keep your account safe',
          ),
          const Divider(height: 1),
          _guideTile(
            context,
            color: Colors.purple,
            icon: Icons.monetization_on_outlined,
            title: 'Payments & Rewards',
            subtitle: 'Manage payment and wallet',
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title, IconData icon, bool isPhone) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: isPhone ? 20 : 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: isPhone ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _supportTile(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _guideTile(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => SnackBarUtils.showInfo(context, 'Guide coming soon'),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Tell us what you think...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              SnackBarUtils.showSuccess(context, 'Feedback sent! Thank you.');
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
