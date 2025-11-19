import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../config/dev_config.dart';

/// Shows current auth status in development mode
/// Helps debug authentication during hot reload
class DevAuthStatus extends ConsumerWidget {
  const DevAuthStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show in development mode
    if (!DevConfig.isDevelopmentMode) {
      return const SizedBox.shrink();
    }

    final authState = ref.watch(authProvider);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (authState.status) {
      case AuthStatus.authenticated:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Authenticated';
        break;
      case AuthStatus.unauthenticated:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Not Authenticated';
        break;
      case AuthStatus.loading:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Loading...';
        break;
      case AuthStatus.initial:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'Initial';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Auth: $statusText',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              if (authState.user != null)
                Text(
                  authState.user!.email,
                  style: TextStyle(
                    fontSize: 9,
                    color: statusColor.withValues(alpha: 0.8),
                  ),
                ),
              if (authState.error != null)
                Text(
                  'Error: ${authState.error}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.red,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Floating dev panel that shows auth info
class DevAuthPanel extends ConsumerWidget {
  const DevAuthPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!DevConfig.isDevelopmentMode) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 50,
      right: 10,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: const DevAuthStatus(),
      ),
    );
  }
}
