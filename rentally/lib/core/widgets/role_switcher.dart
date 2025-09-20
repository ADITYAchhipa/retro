import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../database/models/user_model.dart';
import '../providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as r;
import '../../app/app_state.dart' as app;

/// Role switcher widget for switching between seeker and owner roles
class RoleSwitcher extends StatefulWidget {
  final bool showLabels;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const RoleSwitcher({
    super.key,
    this.showLabels = true,
    this.width,
    this.margin,
  });

  @override
  State<RoleSwitcher> createState() => _RoleSwitcherState();
}

class _RoleSwitcherState extends State<RoleSwitcher> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _switchRole(UserProvider userProvider, UserRole newRole) async {
    if (_isSwitching || userProvider.currentUser?.role == newRole) return;

    setState(() => _isSwitching = true);
    _animationController.forward();

    try {
      final success = await userProvider.switchRole(newRole);
      if (success && mounted) {
        // Also sync Riverpod auth role so the rest of the app (e.g., shell/nav) updates consistently
        try {
          final container = r.ProviderScope.containerOf(context);
          final appRole = _mapToAppRole(newRole);
          container.read(app.authProvider.notifier).switchRole(appRole);
        } catch (_) {
          // no-op if container is not available; userProvider switch still applies
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${_getRoleDisplayName(newRole)} mode'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to switch role. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error switching role: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSwitching = false);
        _animationController.reverse();
      }
    }
  }

  // Map database model enum to app's Riverpod enum
  app.UserRole _mapToAppRole(UserRole role) {
    switch (role) {
      case UserRole.seeker:
        return app.UserRole.seeker;
      case UserRole.owner:
        return app.UserRole.owner;
      case UserRole.guest:
        // Default seekers for guest mode in app state
        return app.UserRole.seeker;
      default:
        return app.UserRole.seeker;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.seeker:
        return 'Seeker';
      case UserRole.owner:
        return 'Owner';
      case UserRole.guest:
        return 'Guest';
      default:
        return 'Seeker';
    }
  }

  // ignore: unused_element
  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.seeker:
        return Icons.search;
      case UserRole.owner:
        return Icons.business;
      case UserRole.guest:
        return Icons.person;
      default:
        return Icons.search;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentRole = userProvider.currentUser?.role ?? UserRole.guest;
        final isSeeker = currentRole == UserRole.seeker;
        final isOwner = currentRole == UserRole.owner;

        return Container(
          width: widget.width ?? double.infinity,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final perCell = w / 2;
              final double labelFont = perCell >= 160 ? 14 : 12;
              return Stack(
                children: [
              // Animated background slider
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: isOwner ? null : 4,
                    right: isOwner ? 4 : null,
                    top: 4,
                    bottom: 4,
                    width: math.max(w / 2 - 8, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Role buttons
              Row(
                children: [
                  // Seeker button
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSwitching ? null : () => _switchRole(userProvider, UserRole.seeker),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Seeker',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: labelFont,
                                  fontWeight: FontWeight.w600,
                                  color: isSeeker ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[600]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Owner button
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSwitching ? null : () => _switchRole(userProvider, UserRole.owner),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Owner',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: labelFont,
                                  fontWeight: FontWeight.w600,
                                  color: isOwner ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[600]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Loading overlay
              if (_isSwitching)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Compact role switcher for use in app bars or smaller spaces
class CompactRoleSwitcher extends StatelessWidget {
  const CompactRoleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentRole = userProvider.currentUser?.role ?? UserRole.guest;
        final theme = Theme.of(context);
        
        return PopupMenuButton<UserRole>(
          icon: Icon(
            _getRoleIcon(currentRole),
            color: theme.primaryColor,
          ),
          tooltip: 'Switch Role',
          onSelected: (UserRole role) async {
            if (role != currentRole) {
              final success = await userProvider.switchRole(role);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? 'Switched to ${_getRoleDisplayName(role)} mode'
                        : 'Failed to switch role'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<UserRole>(
              value: UserRole.seeker,
              child: Row(
                children: [
                  Icon(_getRoleIcon(UserRole.seeker), size: 18),
                  const SizedBox(width: 8),
                  const Text('Seeker Mode'),
                  if (currentRole == UserRole.seeker) ...[
                    const Spacer(),
                    Icon(Icons.check, size: 16, color: theme.primaryColor),
                  ],
                ],
              ),
            ),
            PopupMenuItem<UserRole>(
              value: UserRole.owner,
              child: Row(
                children: [
                  Icon(_getRoleIcon(UserRole.owner), size: 18),
                  const SizedBox(width: 8),
                  const Text('Owner Mode'),
                  if (currentRole == UserRole.owner) ...[
                    const Spacer(),
                    Icon(Icons.check, size: 16, color: theme.primaryColor),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.seeker:
        return 'Seeker';
      case UserRole.owner:
        return 'Owner';
      case UserRole.guest:
        return 'Guest';
      default:
        return 'Seeker';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.seeker:
        return Icons.search;
      case UserRole.owner:
        return Icons.business;
      case UserRole.guest:
        return Icons.person;
      default:
        return Icons.search;
    }
  }
}
