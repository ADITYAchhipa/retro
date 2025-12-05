import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as pv;
import 'app_state.dart' hide UserRole;
import 'auth_router.dart';
import '../core/providers/user_provider.dart';
import '../core/database/models/user_model.dart';
import '../core/providers/ui_visibility_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  final GoRouterState state;

  const MainShell({super.key, required this.child, required this.state});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _modeSynced = false;
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    // Use Shell's state for current path (compatible with current go_router version)
    final String location = widget.state.uri.path;
    
    // Add RepaintBoundary for performance optimization
    return RepaintBoundary(
      child: _buildShellContent(context, authState, location),
    );
  }
  
  Widget _buildShellContent(BuildContext context, AuthState authState, String location) {
    return pv.Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Prefer role from auth state if available (ensures correct navbar after login),
        // fallback to persisted userProvider role.
        final bool isOwnerAuth = authState.user != null && authState.user!.role.name == 'owner';
        final desiredRole = isOwnerAuth ? UserRole.owner : UserRole.seeker;

        // Reset sync flag when not authenticated
        if (authState.status != AuthStatus.authenticated && _modeSynced) {
          _modeSynced = false;
        }

        // One-time sync after login so initial mode matches auth role,
        // but allow user to switch modes later via Settings RoleSwitcher.
        if (authState.status == AuthStatus.authenticated && !_modeSynced) {
          scheduleMicrotask(() {
            if ((userProvider.currentUser?.role ?? UserRole.guest) != desiredRole) {
              userProvider.switchRole(desiredRole);
            }
            if (mounted) setState(() => _modeSynced = true);
          });
        }

        final currentRole = (userProvider.currentUser?.role ?? desiredRole);
        debugPrint('[MainShell] Building with role: ${currentRole.name}, location: $location');
        
        final items = currentRole == UserRole.owner
        ? const [
            _NavItem('Dashboard', Icons.dashboard_outlined, '/owner-dashboard'),
            _NavItem('Manage', Icons.home_work_outlined, '/manage-listings'),
            _NavItem('Add', Icons.add_box_outlined, '/owner/add'),
            _NavItem('Requests', Icons.inbox_outlined, '/owner/requests'),
            _NavItem('Settings', Icons.settings_outlined, '/settings'),
          ]
        : const [
            _NavItem('Home', Icons.home_outlined, '/home'),
            _NavItem('Search', Icons.search, '/search'),
            _NavItem('Wishlist', Icons.favorite_outline, '/wishlist'),
            _NavItem('History', Icons.history_rounded, '/booking-history'),
            _NavItem('Settings', Icons.settings_outlined, '/settings'),
          ];

        int currentIndex = _indexForLocation(currentRole, location);
        final bool immersiveOpen = ref.watch(immersiveRouteOpenProvider);
        // Only show the bottom bar on the main tab root routes for the active role
        final Set<String> seekerTabs = {
          '/home', '/search', '/wishlist', '/booking-history', '/settings',
        };
        final Set<String> ownerTabs = {
          '/owner-dashboard', '/manage-listings', '/owner/add', '/owner/requests', '/settings',
        };
        final bool onPrimaryTab = (currentRole == UserRole.owner)
            ? ownerTabs.contains(location)
            : seekerTabs.contains(location);
        // Allow immersive overlays (filters, full-screen dialogs) to hide bottom bar
        // even on primary tabs, as long as they reset immersiveRouteOpenProvider
        // when closed.
        final bool effectiveImmersive = immersiveOpen;
        final bool hideBottomBar = effectiveImmersive || !onPrimaryTab;

        // Debug: log route and visibility (debug builds only)
        assert(() {
          // ignore: avoid_print
          print('[MainShell] path=$location, role=${currentRole.name}, onPrimaryTab=$onPrimaryTab, hideBottomBar=$hideBottomBar, child=${widget.child.runtimeType}');
          return true;
        }());
        final bool showChatFab = !hideBottomBar && (
          (currentRole == UserRole.seeker && location.startsWith('/home')) ||
          (currentRole == UserRole.owner && location.startsWith('/owner-dashboard'))
        );

        final isPhone = MediaQuery.sizeOf(context).width < 600;
        return Scaffold(
          extendBody: true,
          appBar: null,
          body: widget.child,
          floatingActionButton: showChatFab
              ? FloatingActionButton(
                  heroTag: null,
                  tooltip: 'Chat',
                  onPressed: () => context.push('/chat'),
                  child: const Icon(Icons.chat_bubble_outline, size: 28),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: hideBottomBar
              ? null
              : MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Container(
                      height: isPhone ? 56 : 72,
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Expanded(
                            child: _NavBarItem(
                              item: item,
                              isSelected: currentIndex == index,
                              onTap: () {
                                if (currentRole == UserRole.owner && item.path == '/owner/add') {
                                  _showAddListingDialog(context);
                                } else {
                                  context.go(item.path);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  int _indexForLocation(UserRole role, String location) {
    if (role == UserRole.owner) {
      if (location.startsWith('/manage-listings')) return 1;
      if (location.startsWith('/owner/add')) return 2;
      if (location.startsWith('/owner/requests')) return 3;
      if (location.startsWith('/settings')) return 4;
      if (location.startsWith('/owner-dashboard')) return 0;
      // default dashboard
      return 0;
    } else {
      if (location.startsWith('/search') || location.startsWith('/listing')) return 1;
      if (location.startsWith('/wishlist')) return 2;
      if (location.startsWith('/booking-history')) return 3;
      if (location.startsWith('/settings')) return 4;
      // default home
      return 0;
    }
  }

  void _showAddListingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add New Listing',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ) ??
                              const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'What would you like to list?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Residential Property Option
                  _buildListingOption(
                    context,
                    'Residential Property',
                    'List homes, apartments, rooms, PGs and hostels',
                    Icons.home,
                    Colors.blue,
                    () {
                      Navigator.pop(context);
                      context.push(Routes.addResidentialListing);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Commercial Property Option
                  _buildListingOption(
                    context,
                    'Commercial Property',
                    'List offices, shops, warehouses and more',
                    Icons.business,
                    Colors.deepPurple,
                    () {
                      Navigator.pop(context);
                      context.push(Routes.addCommercialListing);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Venue Option
                  _buildListingOption(
                    context,
                    'Venue',
                    'List resorts, event halls, and event gardens',
                    Icons.event_available,
                    Colors.orange,
                    () {
                      Navigator.pop(context);
                      context.push(Routes.addVenueListing);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Vehicle Option
                  _buildListingOption(
                    context,
                    'Vehicle',
                    'List cars, bikes, scooters, and other vehicles',
                    Icons.directions_car,
                    Colors.green,
                    () {
                      Navigator.pop(context);
                      context.push('/add-vehicle-listing');
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListingOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem(this.label, this.icon, this.path);
}

class _NavBarItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: _isHovered 
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.item.icon,
                  size: _isHovered ? 21 : 19,
                  color: widget.isSelected
                      ? theme.colorScheme.primary
                      : _isHovered
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      fontSize: 9.0,
                      height: 1.0,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: widget.isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
