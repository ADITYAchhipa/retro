import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as pv;
import '../../widgets/responsive_layout.dart';
import '../../widgets/error_boundary.dart';
import '../../core/widgets/loading_states.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../utils/snackbar_utils.dart';
import '../../core/widgets/role_switcher.dart';
import '../../core/providers/user_provider.dart';
import '../../app/app_state.dart' show AppNotifiers;
import '../../app/app_state.dart' as app;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/models/user_model.dart';
// Navigations now use GoRouter Routes; direct screen imports removed
// (no direct screen imports; navigation via GoRouter routes)
import '../../core/utils/currency_formatter.dart';
import '../../app/auth_router.dart';
import '../../core/providers/ui_visibility_provider.dart';
import '../../services/local_notifications_service.dart';

/// **ModularSettingsScreen**
/// 
/// Industrial-grade settings screen with comprehensive app configuration
/// 
/// **Features:**
/// - Responsive design for all screen sizes
/// - Error boundaries with crash protection
/// - Skeleton loading states with shimmer effects
/// - Pull-to-refresh functionality
/// - Theme and appearance settings
/// - Notification and privacy controls
/// - Account management and security
/// - Accessibility support with semantic labels
/// - Offline-ready with cached preferences
/// 
/// **Backend Integration Points:**
/// - Replace mock data with actual user preferences API
/// - Implement real notification settings sync
/// - Add privacy controls and data management
/// - Integrate security settings and 2FA
/// - Add app analytics and crash reporting controls

enum SettingsSection { account, preferences, notifications, privacy, security, about }

class ModularSettingsScreen extends ConsumerStatefulWidget {
  const ModularSettingsScreen({super.key});

  @override
  ConsumerState<ModularSettingsScreen> createState() => _ModularSettingsScreenState();
}

class _ModularSettingsScreenState extends ConsumerState<ModularSettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  
  bool _isLoading = true;
  String? error;
  UserSettings? _userSettings;
  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();


  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  void _showFeedbackDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FeedbackSheet(theme: theme, isDark: isDark),
    );
  }

  void _showDataExportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool preparing = false;
        bool ready = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Row(
                    children: [
                      Icon(Icons.download_outlined),
                      SizedBox(width: 8),
                      Text('Export My Data', style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!preparing && !ready) ...[
                    const Text('Prepare a copy of your account data for download.'),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () {
                          setModalState(() => preparing = true);
                          Future.delayed(const Duration(milliseconds: 1500), () {
                            if (Navigator.of(context).mounted) {
                              setModalState(() {
                                preparing = false;
                                ready = true;
                              });
                            }
                          });
                        },
                        icon: const Icon(Icons.settings_backup_restore_outlined),
                        label: const Text('Prepare export'),
                      ),
                    ),
                  ] else if (preparing) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Preparing your data...'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else if (ready) ...[
                    const Text('Your export is ready.'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            SnackBarUtils.showSuccess(context, 'We\'ll email your data shortly.');
                          },
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Email me a copy'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            SnackBarUtils.showSuccess(context, 'Download started (mock).');
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }

  void _showAboutAppDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with App Icon & Name
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.home_work,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Rentally',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Version 1.0.0 (Build 1)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Text(
                        'A modern rental platform for properties and vehicles.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // What's New
                      _buildSectionTitle('What\'s New', Icons.new_releases, theme),
                      const SizedBox(height: 12),
                      _buildChangelogItem('✨', 'Modern UI with glass-morphism design', isDark),
                      _buildChangelogItem('🚀', 'Enhanced booking experience', isDark),
                      _buildChangelogItem('💳', 'Improved payment flow', isDark),
                      _buildChangelogItem('🔔', 'Smart notifications system', isDark),
                      _buildChangelogItem('🌙', 'Better dark mode support', isDark),
                      const SizedBox(height: 20),
                      
                      // License & Copyright
                      _buildSectionTitle('Legal', Icons.gavel, theme),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '© 2025 Rentally. All rights reserved.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This app uses open source libraries and follows industry best practices for security and privacy.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white60 : Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Close Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildChangelogItem(String emoji, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadUserSettings() async {
    setState(() {
      _isLoading = true;
      error = null;
    });

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString('currencyCode');
      // Read current theme from provider to reflect actual app theme
      final themeMode = ref.read(AppNotifiers.themeModeProvider);
      // Load persisted toggles
      final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      final pushNotifications = prefs.getBool('pushNotifications') ?? true;
      final emailNotifications = prefs.getBool('emailNotifications') ?? true;
      final smsNotifications = prefs.getBool('smsNotifications') ?? false;
      final locationServices = prefs.getBool('locationServices') ?? true;
      final analytics = prefs.getBool('analytics') ?? true;
      final crashReporting = prefs.getBool('crashReporting') ?? true;
      final biometricAuth = prefs.getBool('biometricAuth') ?? false;
      final twoFactorAuth = prefs.getBool('twoFactorAuth') ?? false;
      final dataSync = prefs.getBool('dataSync') ?? true;
      
      _userSettings = UserSettings(
        isDarkMode: themeMode == ThemeMode.dark,
        language: 'English',
        currency: savedCurrency ?? 'USD',
        notificationsEnabled: notificationsEnabled,
        pushNotifications: pushNotifications,
        emailNotifications: emailNotifications,
        smsNotifications: smsNotifications,
        locationServices: locationServices,
        analytics: analytics,
        crashReporting: crashReporting,
        biometricAuth: biometricAuth,
        twoFactorAuth: twoFactorAuth,
        dataSync: dataSync,
      );
      // Apply currency to global formatter
      CurrencyFormatter.setDefaultCurrency(_userSettings!.currency);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          error = e.toString();
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadUserSettings();
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update local settings
      setState(() {
        _userSettings = _userSettings!.copyWith(key, value);
      });
      
      // Apply side-effects for special keys
      if (key == 'isDarkMode' && value is bool) {
        // Update global theme immediately
        ref.read(AppNotifiers.themeModeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light;
        // Persist preference
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('themeMode', value ? 'dark' : 'light');
        } catch (_) {}
      } else {
        // Persist other simple boolean settings
        try {
          final prefs = await SharedPreferences.getInstance();
          if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is String) {
            await prefs.setString(key, value);
          }
        } catch (_) {}
      }

      // Biometric setup removed — no in-app biometric toggle handling

      if (key == 'twoFactorAuth' && value is bool) {
        if (mounted) SnackBarUtils.showInfo(context, value ? 'Two-factor authentication enabled' : 'Two-factor authentication disabled');
      }

      // Show success feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to update setting: $e');
      }
    }
  }

  void _showLogoutDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Logout',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.waving_hand_rounded,
              size: 60,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to logout?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You can always sign back in anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.waving_hand_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Goodbye! See you soon'),
                    ],
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ErrorBoundary(
      onError: (details) {
        debugPrint('Settings screen error: ${details.exception}');
      },
      child: ResponsiveLayout(
        maxWidth: 960,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
        child: Theme(
          data: theme.copyWith(
            dividerTheme: DividerThemeData(
              color: Colors.grey.shade200,
              thickness: 0.6,
              space: 1,
            ),
          ),
          child: Scaffold(
            backgroundColor: isDark ? EnterpriseDarkTheme.primaryBackground : Colors.white,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildModernHeader(theme, isDark),
                  Expanded(
                    child: _buildBody(theme, isDark),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: EnterpriseDarkTheme.primaryAccent.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        child: _isSearching
            ? _buildSearchBar(theme, isDark)
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.settings,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.search_rounded,
                      size: 22,
                      color: isDark ? Colors.white70 : theme.primaryColor,
                    ),
                    onPressed: () => setState(() => _isSearching = true),
                    tooltip: 'Search settings',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                    splashRadius: 18,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
            blurRadius: 12,
            offset: const Offset(-6, -6),
          ),
          BoxShadow(
            color: (isDark ? EnterpriseDarkTheme.primaryAccent : theme.colorScheme.primary)
                .withOpacity(isDark ? 0.2 : 0.15),
            blurRadius: 12,
            offset: const Offset(6, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.search_rounded, size: 20, color: theme.colorScheme.primary),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
              decoration: InputDecoration(
                hintText: 'Search settings...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500],
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: theme.colorScheme.primary),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                  });
                  _searchController.clear();
                },
                tooltip: 'Close search',
                padding: EdgeInsets.zero,
                iconSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentRemindersSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Rent Reminders',
      Icons.notifications_active_outlined,
      [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active_outlined, color: Colors.orange),
          ),
          title: const Text('Manage Rent Reminders'),
          subtitle: const Text('Pause, resume, reschedule or cancel'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.rentReminders);
            if (mounted) {
              ref.read(immersiveRouteOpenProvider.notifier).state = false;
            }
          },
        ),
        const Divider(height: 1),
        FutureBuilder<bool>(
          future: LocalNotificationsService.canScheduleExactAlarms(),
          builder: (context, snapshot) {
            final canExact = snapshot.data ?? true;
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (canExact ? Colors.green : Colors.red).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  canExact ? Icons.alarm_on : Icons.alarm_off,
                  color: canExact ? Colors.green : Colors.red,
                ),
              ),
              title: const Text('Exact Alarm Permission'),
              subtitle: Text(
                canExact
                    ? 'Exact alarms are enabled'
                    : 'Grant exact alarm permission for precise reminders',
              ),
              trailing: canExact
                  ? null
                  : FilledButton(
                      onPressed: () async {
                        await LocalNotificationsService.openExactAlarmSettings();
                      },
                      child: const Text('Open Settings'),
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonetizationSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Monetization',
      Icons.monetization_on_outlined,
      [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.people, color: Colors.green),
          ),
          title: const Text('Referral & Earn'),
          subtitle: const Text('Invite friends and earn'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.referrals);
            if (mounted) {
              ref.read(immersiveRouteOpenProvider.notifier).state = false;
            }
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.purple),
          ),
          title: const Text('Wallet & Rewards'),
          subtitle: const Text('Manage your earnings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.wallet);
            if (mounted) {
              ref.read(immersiveRouteOpenProvider.notifier).state = false;
            }
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_outlined, color: Colors.indigo),
          ),
          title: const Text('Payout Methods'),
          subtitle: const Text('Link bank, PayPal, Wise'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.payoutMethods);
            if (mounted) {
              ref.read(immersiveRouteOpenProvider.notifier).state = false;
            }
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star, color: Colors.blue),
          ),
          title: const Text('Subscription Plans'),
          subtitle: const Text('Upgrade for premium features'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.subscriptionPlans);
            if (mounted) {
              ref.read(immersiveRouteOpenProvider.notifier).state = false;
            }
          },
        ),
      ],
    );
  }

  Widget _buildHeaderSection(ThemeData theme, bool isDark) {
    return pv.Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        final role = currentUser?.role ?? UserRole.guest;
        final name = currentUser != null
            ? (currentUser.fullName.trim().isNotEmpty
                ? currentUser.fullName
                : currentUser.firstName)
            : 'User';
        final email = currentUser?.email ?? 'user@example.com';
        final isPhone = MediaQuery.sizeOf(context).width < 600;

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.all(isPhone ? 14 : 18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                blurRadius: 12,
                offset: const Offset(-6, -6),
              ),
              BoxShadow(
                color: (isDark ? EnterpriseDarkTheme.primaryAccent : theme.colorScheme.primary)
                    .withOpacity(isDark ? 0.15 : 0.08),
                blurRadius: 12,
                offset: const Offset(6, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isPhone)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          (name.isNotEmpty ? name[0] : 'U').toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Role: ${_getRoleDisplayName(role)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Flexible(
                        fit: FlexFit.loose,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 200,
                              child: RoleSwitcher(showLabels: true),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (isPhone)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            child: Text(
                              (name.isNotEmpty ? name[0] : 'U').toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(
                        width: double.infinity,
                        child: RoleSwitcher(showLabels: false, width: double.infinity),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Role: ${_getRoleDisplayName(role)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                if (isPhone)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (role == UserRole.seeker)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final ok = await userProvider.switchRole(UserRole.owner);
                              if (mounted && ok) {
                                try {
                                  final container = ProviderScope.containerOf(context);
                                  container.read(app.authProvider.notifier).switchRole(app.UserRole.owner);
                                } catch (_) {}
                                SnackBarUtils.showSuccess(context, 'Switched to Owner mode');
                                context.go('/owner-dashboard');
                              }
                            },
                            icon: const Icon(Icons.swap_horiz, size: 16),
                            label: const Text('Owner Mode'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              minimumSize: const Size(0, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide(color: theme.colorScheme.primary, width: 1.6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        )
                      else if (role == UserRole.owner)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final ok = await userProvider.switchRole(UserRole.seeker);
                              if (mounted && ok) {
                                try {
                                  final container = ProviderScope.containerOf(context);
                                  container.read(app.authProvider.notifier).switchRole(app.UserRole.seeker);
                                } catch (_) {}
                                SnackBarUtils.showSuccess(context, 'Switched to Seeker mode');
                                context.go('/home');
                              }
                            },
                            icon: const Icon(Icons.swap_horiz, size: 16),
                            label: const Text('Seeker Mode'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              minimumSize: const Size(0, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide(color: theme.colorScheme.primary, width: 1.6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (role == UserRole.seeker)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ok = await userProvider.switchRole(UserRole.owner);
                            if (mounted && ok) {
                              try {
                                final container = ProviderScope.containerOf(context);
                                container.read(app.authProvider.notifier).switchRole(app.UserRole.owner);
                              } catch (_) {}
                              SnackBarUtils.showSuccess(context, 'Switched to Owner mode');
                              context.go('/owner-dashboard');
                            }
                          },
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: const Text('Switch to Owner'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            minimumSize: const Size(0, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: theme.colorScheme.primary, width: 1.6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        )
                      else if (role == UserRole.owner)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ok = await userProvider.switchRole(UserRole.seeker);
                            if (mounted && ok) {
                              try {
                                final container = ProviderScope.containerOf(context);
                                container.read(app.authProvider.notifier).switchRole(app.UserRole.seeker);
                              } catch (_) {}
                              SnackBarUtils.showSuccess(context, 'Switched to Seeker mode');
                              context.go('/home');
                            }
                          },
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: const Text('Switch to Seeker'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            minimumSize: const Size(0, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: theme.colorScheme.primary, width: 1.6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (error != null) {
      return _buildErrorState(theme);
    }

    final media = MediaQuery.of(context);
    final bottomSafe = media.padding.bottom;
    // Note: The parent shell already reserves space for the bottom navigation
    // bar, so we only need to account for the device safe area here.

    return SafeArea(
      top: false,
      bottom: true,
      child: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + bottomSafe,
          ),
          child: _isLoading ? _buildLoadingState() : _buildContent(theme),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final themed = theme.copyWith(
      dividerTheme: theme.dividerTheme.copyWith(
        color: Colors.grey.shade300,
        thickness: 0.6,
        space: 1,
      ),
      listTileTheme: theme.listTileTheme.copyWith(
        dense: isPhone,
        minVerticalPadding: isPhone ? 6 : 10,
        contentPadding: EdgeInsets.symmetric(horizontal: isPhone ? 12 : 20, vertical: isPhone ? 6 : 10),
        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
          fontSize: isPhone ? 14 : 16,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        subtitleTextStyle: theme.textTheme.bodySmall?.copyWith(
          fontSize: isPhone ? 12 : 13,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.primary, width: 1.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPhone ? 12 : 14)),
          foregroundColor: theme.colorScheme.primary,
          textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: isPhone ? 8 : 10),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isPhone ? 12 : 14),
            side: BorderSide(color: theme.colorScheme.primary, width: 1.6),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: isPhone ? 8 : 10),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return theme.colorScheme.outline.withOpacity(0.3);
          }
          return states.contains(MaterialState.selected)
              ? theme.colorScheme.primary
              : theme.colorScheme.outline;
        }),
        trackOutlineWidth: MaterialStateProperty.resolveWith((states) => isPhone ? 1.4 : 1.6),
        trackColor: MaterialStateProperty.resolveWith((states) {
          return states.contains(MaterialState.selected)
              ? theme.colorScheme.primary.withOpacity(0.40)
              : theme.colorScheme.surfaceVariant.withOpacity(0.90);
        }),
        thumbColor: MaterialStateProperty.resolveWith((states) {
          return states.contains(MaterialState.selected)
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant;
        }),
      ),
    );

    // Section-level filtering based on query
    bool show(String label) => _matches(label);
    bool showAny(List<String> labels) => labels.any(show);

    final sections = <Widget>[];

    if (!_isSearching) {
      sections..add(_buildHeaderSection(theme, theme.brightness == Brightness.dark))..add(const SizedBox(height: 20));
    }

    if (!_isSearching || showAny(['Profile', 'Payment Methods'])) {
      sections..add(_buildAccountSection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['Dark Mode', 'Language'])) {
      sections..add(_buildAppearanceSection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['Referral & Earn', 'Wallet & Rewards', 'Payout Methods', 'Subscription Plans'])) {
      sections..add(_buildMonetizationSection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['Notifications', 'Email Notifications', 'Push Notifications', 'SMS Notifications'])) {
      sections..add(_buildNotificationsSection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['Rent Reminders', 'Manage Rent Reminders', 'Exact Alarm Permission'])) {
      sections..add(_buildRentRemindersSection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['Location Services', 'Analytics', 'Crash Reporting', 'Download My Data'])) {
      sections..add(_buildPrivacySection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['Change Password', 'Biometric Authentication', 'Two-Factor Authentication', 'Auto Logout'])) {
      sections..add(_buildSecuritySection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['Contact Support', 'Send Feedback'])) {
      sections..add(_buildSupportSection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['App Version', 'Terms of Service', 'Privacy Policy', 'Logout'])) {
      sections..add(_buildAboutSection(theme))..add(const SizedBox(height: 16));
    }

    return Theme(
      data: themed,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: sections),
    );
  }

  bool _matches(String label) {
    if (_searchQuery.isEmpty) return true;
    return label.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  Widget _buildAccountSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Account',
      Icons.person,
      [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.account_circle, color: theme.colorScheme.primary),
          ),
          title: const Text('Profile'),
          subtitle: const Text('Manage your profile information'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/profile'),
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payment, color: Colors.teal),
          ),
          title: const Text('Payment Methods'),
          subtitle: const Text('Manage cards and payment options'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.paymentMethods);
            if (mounted) {
              ref.read(immersiveRouteOpenProvider.notifier).state = false;
            }
          },
        ),
        
      ],
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
        return 'Guest';
    }
  }

  /// Returns an emoji flag or icon-like text for a given language code.
  /// This is a simple, lightweight mapping for visual cues in the language sheet.
  // _flagForLang removed (unused)

  /// Returns a representative color for a given language code to colorize the alias avatar
  Color _colorForLang(String code) {
    switch (code.toLowerCase()) {
      case 'sys':
        return Colors.blueGrey;
      case 'en':
        return Colors.indigo;
      case 'es':
        return Colors.redAccent;
      case 'fr':
        return Colors.blueAccent;
      case 'pt':
        return Colors.green;
      case 'ru':
        return Colors.deepPurple;
      case 'ar':
        return Colors.teal;
      case 'zh':
        return Colors.orange;
      case 'hi':
      case 'bn':
      case 'gu':
      case 'mr':
      case 'ta':
      case 'te':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAppearanceSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Appearance',
      Icons.palette,
      [
        SwitchListTile(
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dark_mode, color: Colors.indigo),
          ),
          title: const Text('Dark Mode'),
          subtitle: const Text('Use dark theme'),
          value: _userSettings?.isDarkMode ?? false,
          onChanged: (value) => _updateSetting('isDarkMode', value),
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.language, color: Colors.blue),
          ),
          title: const Text('Language'),
          subtitle: Text(_userSettings?.language ?? 'System'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showLanguageDialog,
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(ThemeData theme) {
    final allOn = _userSettings?.notificationsEnabled ?? true;
    return _buildSection(
      theme,
      'Notifications',
      Icons.notifications,
      [
        SwitchListTile(
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications, color: Colors.orange),
          ),
          title: const Text('All Notifications'),
          subtitle: const Text('Enable all notifications'),
          value: _userSettings?.notificationsEnabled ?? true,
          onChanged: (value) => _updateSetting('notificationsEnabled', value),
        ),
        const Divider(height: 1),
        SwitchListTile(
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.phone_android, color: Colors.teal),
          ),
          title: const Text('Push Notifications'),
          subtitle: const Text('Receive push notifications'),
          value: _userSettings?.pushNotifications ?? true,
          onChanged: allOn ? (value) => _updateSetting('pushNotifications', value) : null,
        ),
        const Divider(height: 1),
        SwitchListTile(
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.email, color: Colors.blue),
          ),
          title: const Text('Email Notifications'),
          subtitle: const Text('Receive email updates'),
          value: _userSettings?.emailNotifications ?? true,
          onChanged: allOn ? (value) => _updateSetting('emailNotifications', value) : null,
        ),
        const Divider(height: 1),
        SwitchListTile(
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sms, color: Colors.purple),
          ),
          title: const Text('SMS Notifications'),
          subtitle: const Text('Receive SMS updates'),
          value: _userSettings?.smsNotifications ?? false,
          onChanged: allOn ? (value) => _updateSetting('smsNotifications', value) : null,
        ),
      ],
    );
  }

  Widget _buildPrivacySection(ThemeData theme) {
    return _buildSection(
      theme,
      'Privacy & Data',
      Icons.privacy_tip,
      [
        SwitchListTile(
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on, color: Colors.green),
          ),
          title: const Text('Location Services'),
          subtitle: const Text('Allow location access'),
          value: _userSettings?.locationServices ?? true,
          onChanged: (value) => _updateSetting('locationServices', value),
        ),
        const Divider(height: 1),
        SwitchListTile(
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.analytics, color: Colors.indigo),
          ),
          title: const Text('Analytics'),
          subtitle: const Text('Help improve the app'),
          value: _userSettings?.analytics ?? true,
          onChanged: (value) => _updateSetting('analytics', value),
        ),
        const Divider(height: 1),
        SwitchListTile(
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bug_report, color: Colors.red),
          ),
          title: const Text('Crash Reporting'),
          subtitle: const Text('Send crash reports'),
          value: _userSettings?.crashReporting ?? true,
          onChanged: (value) => _updateSetting('crashReporting', value),
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.download, color: Colors.blueGrey),
          ),
          title: const Text('Download My Data'),
          subtitle: const Text('Export your personal data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showDataExportSheet,
        ),
      ],
    );
  }

  Widget _buildSecuritySection(ThemeData theme) {
    return _buildSection(
      theme,
      'Security',
      Icons.security,
      [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock, color: Colors.blueGrey),
          ),
          title: const Text('Change Password'),
          subtitle: const Text('Update your password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            String email = '';
            try {
              final userProvider = pv.Provider.of<UserProvider>(context, listen: false);
              email = userProvider.currentUser?.email ?? '';
            } catch (_) {
              email = '';
            }
            try {
              await context.push(
                Routes.resetPassword,
                extra: {
                  'email': email,
                  'successPath': Routes.settings,
                },
              );
            } finally {
              if (mounted) {
                ref.read(immersiveRouteOpenProvider.notifier).state = false;
              }
            }
          },
        ),
        const Divider(height: 1),
        SwitchListTile(
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user, color: Colors.cyan),
          ),
          title: const Text('Two-Factor Authentication'),
          subtitle: const Text('Add extra security layer'),
          value: _userSettings?.twoFactorAuth ?? false,
          onChanged: (value) => _updateSetting('twoFactorAuth', value),
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_moon_outlined, color: Colors.deepPurple),
          ),
          title: const Text('2FA Setup'),
          subtitle: const Text('Configure authenticator app'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.twoFactor);
            if (mounted) {
              ref.read(immersiveRouteOpenProvider.notifier).state = false;
            }
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Support',
      Icons.help,
      [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat, color: Colors.blue),
          ),
          title: const Text('Contact Support'),
          subtitle: const Text('Get help from our team'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.contactSupport);
            if (mounted) {
              ref.read(immersiveRouteOpenProvider.notifier).state = false;
            }
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.feedback, color: Colors.amber),
          ),
          title: const Text('Send Feedback'),
          subtitle: const Text('Share your thoughts'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showFeedbackDialog(),
        ),
      ],
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    return _buildSection(
      theme,
      'About',
      Icons.info,
      [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info, color: Colors.blueGrey),
          ),
          title: const Text('App Version'),
          subtitle: const Text('1.0.0 (Build 1)'),
          onTap: _showAboutAppDialog,
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description, color: Colors.blue),
          ),
          title: const Text('Terms of Service'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await context.push(Routes.terms);
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.privacy_tip, color: Colors.green),
          ),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await context.push(Routes.privacy);
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.logout, color: Colors.red[600]),
          ),
          title: Text(
            'Logout',
            style: TextStyle(color: Colors.red[600]),
          ),
          onTap: _showLogoutDialog,
        ),
      ],
    );
  }

  Widget _buildSection(ThemeData theme, String title, IconData icon, List<Widget> children) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            blurRadius: 10,
            offset: const Offset(-5, -5),
          ),
          BoxShadow(
            color: (isDark ? EnterpriseDarkTheme.primaryAccent : theme.colorScheme.primary)
                .withOpacity(isDark ? 0.12 : 0.06),
            blurRadius: 10,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(isPhone ? 16 : 20, isPhone ? 14 : 16, isPhone ? 16 : 20, isPhone ? 8 : 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: isPhone ? 20 : 22),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: isPhone ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    debugPrint('[Settings] Open language dialog. isPhone=$isPhone');
    final parentContext = context; // stable context for SnackBar

    final languages = [
      {'code': 'sys', 'label': 'System Default'},
      {'code': 'ar', 'label': 'Arabic'},
      {'code': 'bn', 'label': 'Bengali'},
      {'code': 'en', 'label': 'English'},
      {'code': 'es', 'label': 'Spanish'},
      {'code': 'fr', 'label': 'French'},
      {'code': 'gu', 'label': 'Gujarati'},
      {'code': 'hi', 'label': 'Hindi'},
      {'code': 'mr', 'label': 'Marathi'},
      {'code': 'pt', 'label': 'Portuguese'},
      {'code': 'ru', 'label': 'Russian'},
      {'code': 'ta', 'label': 'Tamil'},
      {'code': 'te', 'label': 'Telugu'},
      {'code': 'zh', 'label': 'Chinese'},
    ];

    final currentLocale = ref.read(AppNotifiers.localeProvider);
    String tempSelectedCode = currentLocale?.languageCode ?? 'sys';
    String tempSelectedLabel = languages.firstWhere(
      (m) => m['code'] == tempSelectedCode,
      orElse: () => languages.first,
    )['label']!;
    String query = '';

    Future<void> onApply(BuildContext popCtx) async {
      Navigator.of(popCtx).pop();
      // Persist human-readable label for local display
      final isSystem = tempSelectedCode == 'system' || tempSelectedCode == 'sys';
      _updateSetting('language', isSystem ? 'System' : tempSelectedLabel);
      // Update app locale immediately and persist
      try {
        final prefs = await SharedPreferences.getInstance();
        if (isSystem) {
          ref.read(AppNotifiers.localeProvider.notifier).state = null;
          await prefs.remove('localeCode');
        } else {
          ref.read(AppNotifiers.localeProvider.notifier).state = Locale(tempSelectedCode);
          await prefs.setString('localeCode', tempSelectedCode);
        }
      } catch (_) {}
      if (mounted) {
        SnackBarUtils.showSuccess(parentContext, 'Language changed to ${isSystem ? 'System' : tempSelectedLabel}');
      }
    }

    Widget buildSheetContent(void Function(VoidCallback fn) setModalState, BuildContext popCtx, {bool expanded = false}) {
      final filtered = languages.where((m) {
        final label = (m['label'] as String).toLowerCase();
        final code = (m['code'] as String).toLowerCase();
        final q = query.toLowerCase();
        return label.contains(q) || code.contains(q);
      }).toList();

      final isDark = theme.brightness == Brightness.dark;
      final list = ListView.separated(
        padding: const EdgeInsets.only(bottom: 12),
        shrinkWrap: !expanded,
        itemCount: filtered.length,
        separatorBuilder: (_, __) => SizedBox(height: isPhone ? 8 : 12),
        itemBuilder: (_, i) {
          final item = filtered[i];
          final code = item['code']!;
          final label = item['label']!;
          final selected = tempSelectedCode == code;
          final langColor = _colorForLang(code);
          return InkWell(
            borderRadius: BorderRadius.circular(isPhone ? 12 : 16),
            onTap: () => setModalState(() {
              tempSelectedCode = code;
              tempSelectedLabel = label;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.12),
                          theme.colorScheme.primary.withOpacity(0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : theme.colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(isPhone ? 12 : 16),
                border: Border.all(
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.3),
                  width: selected ? 2.0 : 1.0,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              padding: EdgeInsets.all(isPhone ? 10 : 14),
              child: Row(
                children: [
                  Container(
                    width: isPhone ? 36 : 48,
                    height: isPhone ? 36 : 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          langColor,
                          langColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(isPhone ? 10 : 12),
                      boxShadow: [
                        BoxShadow(
                          color: langColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        code == 'sys' ? '🌍' : code.substring(0, 2).toUpperCase(),
                        style: TextStyle(
                          fontSize: isPhone ? 14 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isPhone ? 12 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: isPhone ? 14 : 15,
                            fontWeight: FontWeight.bold,
                            color: selected ? theme.colorScheme.primary : null,
                          ),
                        ),
                        SizedBox(height: isPhone ? 2 : 4),
                        Text(
                          code.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: isPhone ? 10 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isPhone ? 20 : 28,
                    height: isPhone ? 20 : 28,
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withOpacity(0.8),
                              ],
                            )
                          : null,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.transparent : theme.colorScheme.outline,
                        width: 2,
                      ),
                      color: selected ? null : Colors.transparent,
                    ),
                    child: selected
                        ? Icon(Icons.check_rounded, size: isPhone ? 12 : 18, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      );

      final header = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.language_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Language',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Choose your preferred language',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(popCtx).pop(),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );

      final search = Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface.withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              blurRadius: 12,
              offset: const Offset(-6, -6),
            ),
            BoxShadow(
              color: (isDark ? EnterpriseDarkTheme.primaryAccent : theme.colorScheme.primary)
                  .withOpacity(isDark ? 0.2 : 0.15),
              blurRadius: 12,
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Icon(Icons.search_rounded, size: 20, color: theme.colorScheme.primary),
            ),
            Expanded(
              child: TextField(
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Search languages...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500],
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
                  isDense: true,
                ),
                onChanged: (v) => setModalState(() => query = v),
              ),
            ),
          ],
        ),
      );

      final actions = Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(popCtx).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
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
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => onApply(popCtx),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text('Apply Language'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

      final dirty = tempSelectedCode != (currentLocale?.languageCode ?? 'sys');

      final content = Column(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 18),
          search,
          const SizedBox(height: 16),
          expanded ? Expanded(child: list) : Flexible(child: list),
          if (dirty) ...[
            const SizedBox(height: 16),
            actions,
          ],
        ],
      );

      return content;
    }

    if (isPhone) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          debugPrint('[Settings] Showing bottom sheet language selector');
          return StatefulBuilder(
            builder: (ctx, setModalState) => Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(ctx).size.height * 0.8,
                    child: buildSheetContent(setModalState, ctx, expanded: true),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      debugPrint('[Settings] Showing desktop language selector (general dialog)');
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Language',
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (dialogContext, anim1, anim2) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (ctx, setModalState) => Container(
                  width: 600,
                  height: 680,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: buildSheetContent(setModalState, ctx, expanded: true),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildLoadingState() {
    return LoadingStates.listShimmer(context, itemCount: 4);
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load settings',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'An unexpected error occurred',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserSettings,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// **User Settings Data Model**

class UserSettings {
  final bool isDarkMode;
  final String language;
  final String currency;
  final bool notificationsEnabled;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool locationServices;
  final bool analytics;
  final bool crashReporting;
  final bool biometricAuth;
  final bool twoFactorAuth;
  final bool dataSync;

  UserSettings({
    required this.isDarkMode,
    required this.language,
    required this.currency,
    required this.notificationsEnabled,
    required this.pushNotifications,
    required this.emailNotifications,
    required this.smsNotifications,
    required this.locationServices,
    required this.analytics,
    required this.crashReporting,
    required this.biometricAuth,
    required this.twoFactorAuth,
    required this.dataSync,
  });

  UserSettings copyWith(String key, dynamic value) {
    switch (key) {
      case 'isDarkMode':
        return UserSettings(
          isDarkMode: value,
          language: language,
          currency: currency,
          notificationsEnabled: notificationsEnabled,
          pushNotifications: pushNotifications,
          emailNotifications: emailNotifications,
          smsNotifications: smsNotifications,
          locationServices: locationServices,
          analytics: analytics,
          crashReporting: crashReporting,
          biometricAuth: biometricAuth,
          twoFactorAuth: twoFactorAuth,
          dataSync: dataSync,
        );
      case 'language':
        return UserSettings(
          isDarkMode: isDarkMode,
          language: value,
          currency: currency,
          notificationsEnabled: notificationsEnabled,
          pushNotifications: pushNotifications,
          emailNotifications: emailNotifications,
          smsNotifications: smsNotifications,
          locationServices: locationServices,
          analytics: analytics,
          crashReporting: crashReporting,
          biometricAuth: biometricAuth,
          twoFactorAuth: twoFactorAuth,
          dataSync: dataSync,
        );
      case 'currency':
        return UserSettings(
          isDarkMode: isDarkMode,
          language: language,
          currency: value,
          notificationsEnabled: notificationsEnabled,
          pushNotifications: pushNotifications,
          emailNotifications: emailNotifications,
          smsNotifications: smsNotifications,
          locationServices: locationServices,
          analytics: analytics,
          crashReporting: crashReporting,
          biometricAuth: biometricAuth,
          twoFactorAuth: twoFactorAuth,
          dataSync: dataSync,
        );
      case 'notificationsEnabled':
        return UserSettings(
          isDarkMode: isDarkMode,
          language: language,
          currency: currency,
          notificationsEnabled: value,
          pushNotifications: pushNotifications,
          emailNotifications: emailNotifications,
          smsNotifications: smsNotifications,
          locationServices: locationServices,
          analytics: analytics,
          crashReporting: crashReporting,
          biometricAuth: biometricAuth,
          twoFactorAuth: twoFactorAuth,
          dataSync: dataSync,
        );
      case 'pushNotifications':
        return UserSettings(
          isDarkMode: isDarkMode,
          language: language,
          currency: currency,
          notificationsEnabled: notificationsEnabled,
          pushNotifications: value,
          emailNotifications: emailNotifications,
          smsNotifications: smsNotifications,
          locationServices: locationServices,
          analytics: analytics,
          crashReporting: crashReporting,
          biometricAuth: biometricAuth,
          twoFactorAuth: twoFactorAuth,
          dataSync: dataSync,
        );
      case 'emailNotifications':
        return UserSettings(
          isDarkMode: isDarkMode,
          language: language,
          currency: currency,
          notificationsEnabled: notificationsEnabled,
          pushNotifications: pushNotifications,
          emailNotifications: value,
          smsNotifications: smsNotifications,
          locationServices: locationServices,
          analytics: analytics,
          crashReporting: crashReporting,
          biometricAuth: biometricAuth,
          twoFactorAuth: twoFactorAuth,
          dataSync: dataSync,
        );
      case 'smsNotifications':
        return UserSettings(
          isDarkMode: isDarkMode,
          language: language,
          currency: currency,
          notificationsEnabled: notificationsEnabled,
          pushNotifications: pushNotifications,
          emailNotifications: emailNotifications,
          smsNotifications: value,
          locationServices: locationServices,
          analytics: analytics,
          crashReporting: crashReporting,
          biometricAuth: biometricAuth,
          twoFactorAuth: twoFactorAuth,
          dataSync: dataSync,
        );
      case 'locationServices':
        return UserSettings(
          isDarkMode: isDarkMode,
          language: language,
          currency: currency,
          notificationsEnabled: notificationsEnabled,
          pushNotifications: pushNotifications,
          emailNotifications: emailNotifications,
          smsNotifications: smsNotifications,
          locationServices: value,
          analytics: analytics,
          crashReporting: crashReporting,
          biometricAuth: biometricAuth,
          twoFactorAuth: twoFactorAuth,
          dataSync: dataSync,
        );
      case 'analytics':
        return UserSettings(
          isDarkMode: isDarkMode,
          language: language,
          currency: currency,
          notificationsEnabled: notificationsEnabled,
          pushNotifications: pushNotifications,
          emailNotifications: emailNotifications,
          smsNotifications: smsNotifications,
          locationServices: locationServices,
          analytics: value,
          crashReporting: crashReporting,
          biometricAuth: biometricAuth,
          twoFactorAuth: twoFactorAuth,
          dataSync: dataSync,
        );
      case 'crashReporting':
        return UserSettings(
          isDarkMode: isDarkMode,
          language: language,
          currency: currency,
          notificationsEnabled: notificationsEnabled,
          pushNotifications: pushNotifications,
          emailNotifications: emailNotifications,
          smsNotifications: smsNotifications,
          locationServices: locationServices,
          analytics: analytics,
          crashReporting: value,
          biometricAuth: biometricAuth,
          twoFactorAuth: twoFactorAuth,
          dataSync: dataSync,
        );
      case 'biometricAuth':
        return UserSettings(
          isDarkMode: isDarkMode,
          language: language,
          currency: currency,
          notificationsEnabled: notificationsEnabled,
          pushNotifications: pushNotifications,
          emailNotifications: emailNotifications,
          smsNotifications: smsNotifications,
          locationServices: locationServices,
          analytics: analytics,
          crashReporting: crashReporting,
          biometricAuth: value,
          twoFactorAuth: twoFactorAuth,
          dataSync: dataSync,
        );
      case 'twoFactorAuth':
        return UserSettings(
          isDarkMode: isDarkMode,
          language: language,
          currency: currency,
          notificationsEnabled: notificationsEnabled,
          pushNotifications: pushNotifications,
          emailNotifications: emailNotifications,
          smsNotifications: smsNotifications,
          locationServices: locationServices,
          analytics: analytics,
          crashReporting: crashReporting,
          biometricAuth: biometricAuth,
          twoFactorAuth: value,
          dataSync: dataSync,
        );
      case 'dataSync':
        return UserSettings(
          isDarkMode: isDarkMode,
          language: language,
          currency: currency,
          notificationsEnabled: notificationsEnabled,
          pushNotifications: pushNotifications,
          emailNotifications: emailNotifications,
          smsNotifications: smsNotifications,
          locationServices: locationServices,
          analytics: analytics,
          crashReporting: crashReporting,
          biometricAuth: biometricAuth,
          twoFactorAuth: twoFactorAuth,
          dataSync: value,
        );
      // Add other cases as needed
      default:
        return this;
    }
  }
}

class _FeedbackSheet extends StatefulWidget {
  final ThemeData theme;
  final bool isDark;

  const _FeedbackSheet({required this.theme, required this.isDark});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final TextEditingController _feedbackController = TextEditingController();
  String _selectedCategory = 'General';
  int _rating = 0;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isPhone = media.size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? widget.theme.colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: media.viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.theme.colorScheme.primary,
                          widget.theme.colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: widget.theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.feedback_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send Feedback',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Help us improve your experience',
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Rating
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isDark 
                      ? Colors.white.withOpacity(0.05) 
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isDark 
                        ? Colors.white.withOpacity(0.1) 
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 20,
                          color: widget.theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rate your experience',
                          style: widget.theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return InkWell(
                          onTap: () => setState(() => _rating = starIndex),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              _rating >= starIndex
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: isPhone ? 32 : 36,
                              color: _rating >= starIndex
                                  ? Colors.amber.shade600
                                  : Colors.grey.shade400,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Category selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isDark 
                      ? Colors.white.withOpacity(0.05) 
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isDark 
                        ? Colors.white.withOpacity(0.1) 
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.category_rounded,
                          size: 20,
                          color: widget.theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Category',
                          style: widget.theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['General', 'Bug', 'Feature', 'Other']
                          .map((category) => ChoiceChip(
                                label: Text(category),
                                selected: _selectedCategory == category,
                                showCheckmark: false,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedCategory = category);
                                  }
                                },
                                selectedColor: widget.theme.colorScheme.primary.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedCategory == category 
                                      ? FontWeight.bold 
                                      : FontWeight.w500,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Feedback text field
              TextField(
                controller: _feedbackController,
                maxLines: 5,
                maxLength: 500,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Your feedback',
                  hintText: 'Tell us what you think...',
                  hintStyle: TextStyle(
                    color: widget.isDark 
                        ? Colors.white.withOpacity(0.4) 
                        : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: widget.isDark 
                      ? Colors.white.withOpacity(0.05) 
                      : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: widget.isDark 
                          ? Colors.white.withOpacity(0.1) 
                          : Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: widget.isDark 
                          ? Colors.white.withOpacity(0.1) 
                          : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: widget.theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (_feedbackController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Please enter your feedback'),
                                ],
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          return;
                        }
                        
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Thank you for your feedback!'),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 20),
                      label: const Text(
                        'Submit Feedback',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
