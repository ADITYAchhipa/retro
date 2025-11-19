import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../core/config/dev_config.dart';

/// Development Login Helper Widget
/// Shows quick login buttons during development
/// Only visible in development mode
class DevLoginHelper extends ConsumerWidget {
  const DevLoginHelper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show in development mode
    if (!DevConfig.isDevelopmentMode) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        border: Border.all(color: Colors.amber),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.developer_mode, size: 20, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'DEV MODE - Quick Login',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickLoginButton(
                label: 'Test User',
                email: 'user@test.com',
                password: 'user123',
                icon: Icons.person,
              ),
              _QuickLoginButton(
                label: 'Owner',
                email: 'owner@test.com',
                password: 'owner123',
                icon: Icons.business,
              ),
              _QuickLoginButton(
                label: 'Demo',
                email: 'demo@rentally.com',
                password: 'demo123',
                icon: Icons.dashboard,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These buttons auto-login for faster testing (hot reload friendly)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickLoginButton extends ConsumerWidget {
  final String label;
  final String email;
  final String password;
  final IconData icon;

  const _QuickLoginButton({
    required this.label,
    required this.email,
    required this.password,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return ElevatedButton.icon(
      onPressed: isLoading
          ? null
          : () async {
              try {
                await ref.read(authProvider.notifier).signIn(email, password);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Logged in as $label'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Login failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.shade100,
        foregroundColor: Colors.amber.shade900,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

/// Quick logout button for development
class DevLogoutButton extends ConsumerWidget {
  const DevLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!DevConfig.isDevelopmentMode) {
      return const SizedBox.shrink();
    }

    final authState = ref.watch(authProvider);
    
    if (authState.status != AuthStatus.authenticated) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.small(
      onPressed: () async {
        await ref.read(authProvider.notifier).signOut();
      },
      backgroundColor: Colors.red,
      child: const Icon(Icons.logout, size: 16),
    );
  }
}
