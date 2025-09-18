import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as pv;
import '../../widgets/responsive_layout.dart';
import '../../widgets/error_boundary.dart';
import '../../widgets/loading_states.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';
import '../../utils/snackbar_utils.dart';
import '../../core/widgets/role_switcher.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/listing_feed_provider.dart';
import '../../app/app_state.dart' show AppNotifiers;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/models/user_model.dart';
// Navigations now use GoRouter Routes; direct screen imports removed
// (no direct screen imports; navigation via GoRouter routes)
import '../../services/country_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../app/auth_router.dart';
import '../../core/providers/ui_visibility_provider.dart';

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
    final TextEditingController feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send Feedback'),
        content: TextField(
          controller: feedbackController,
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
              // TODO: Send feedback to backend
              SnackBarUtils.showSuccess(context, 'Feedback sent! Thank you.');
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showDataExportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool preparing = false;
        bool ready = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
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
            );
          },
        );
      },
    );
  }

  void _showAboutAppDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Rentally',
      applicationVersion: '1.0.0 (Build 1)',
      children: const [
        SizedBox(height: 8),
        Text('A modern rental platform for properties and vehicles.'),
        SizedBox(height: 8),
        Text('© 2025 Rentally. All rights reserved.'),
      ],
    );
  }

  void _showCurrencyDialog() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final current = _userSettings?.currency ?? 'USD';

    // Build unique currency list from CountryService
    final countries = CountryService.getAllCountries();
    final Map<String, Set<String>> currencyToCountries = {};
    for (final c in countries) {
      final code = (c['currency'] ?? '').toString();
      final name = (c['name'] ?? '').toString();
      if (code.isEmpty) continue;
      currencyToCountries.putIfAbsent(code, () => <String>{}).add(name);
    }
    final List<String> currencies = currencyToCountries.keys.toList()..sort();

    String query = '';

    Widget buildCurrencyContent(void Function(VoidCallback fn) setModalState, BuildContext popCtx, {bool expanded = false}) {
      final filtered = currencies.where((c) => c.toLowerCase().contains(query.toLowerCase())).toList();

      final list = ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final code = filtered[i];
          final countriesStr = (currencyToCountries[code] ?? const <String>{}).take(3).join(', ');
          final selected = code == current;
          return ListTile(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.10),
              child: Text(
                CurrencyFormatter.currencySymbolFor(code),
                style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(
              '$code — ${CurrencyFormatter.currencyNameFor(code)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Text(
              countriesStr.isEmpty ? '—' : countriesStr + ((currencyToCountries[code]?.length ?? 0) > 3 ? '…' : ''),
              style: const TextStyle(fontSize: 11),
            ),
            trailing: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.outline, width: 1.6),
                color: selected ? theme.colorScheme.primary : Colors.transparent,
              ),
              child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            onTap: () {
              Navigator.of(popCtx).pop();
              // Persist and apply globally
              _updateSetting('currency', code);
              CurrencyFormatter.setDefaultCurrency(code);
              SharedPreferences.getInstance().then((p) => p.setString('currencyCode', code));
              SnackBarUtils.showSuccess(context, 'Currency set to $code');
              // Refresh feeds that precomputed price labels (e.g., recently viewed)
              try {
                pv.Provider.of<ListingFeedProvider>(context, listen: false).refresh();
              } catch (_) {}
            },
          );
        },
      );

      return Column(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Select Currency', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(popCtx).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            autofocus: isPhone,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search currency code (e.g. USD)…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setModalState(() => query = v.trim()),
          ),
          const SizedBox(height: 12),
          expanded ? Expanded(child: list) : SizedBox(height: 360, child: list),
        ],
      );
    }

    if (isPhone) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModalState) => SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                ),
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.8,
                  child: buildCurrencyContent(setModalState, ctx, expanded: true),
                ),
              ),
            ),
          );
        },
      );
    } else {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Currency',
        barrierColor: Colors.black.withOpacity(0.45),
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (dialogContext, anim1, anim2) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (ctx, setModalState) => Container(
                  width: 560,
                  height: 560,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: buildCurrencyContent(setModalState, ctx, expanded: true),
                ),
              ),
            ),
          );
        },
      );
    }
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement logout functionality
              context.go('/auth');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        child: Theme(
          data: theme.copyWith(
            dividerTheme: DividerThemeData(
              color: Colors.grey.shade300,
              thickness: 0.6,
              space: 1,
            ),
          ),
          child: Scaffold(
            backgroundColor: isDark ? EnterpriseDarkTheme.primaryBackground : EnterpriseLightTheme.primaryBackground,
            appBar: _buildAppBar(theme),
            body: _buildBody(theme, isDark),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: _isSearching
          ? AnimatedContainer(
              height: 40,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface, // solid surface for better contrast
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.colorScheme.primary, width: 3.0),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Material(
                  type: MaterialType.transparency,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    cursorHeight: 18,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 14, height: 1.25),
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.transparent,
                      hintText: 'Search settings...',
                      contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  ),
                ),
              ),
            )
          : Text(AppLocalizations.of(context)!.settings),
      elevation: 0,
      backgroundColor: Colors.transparent,
      toolbarHeight: _isSearching ? 52 : kToolbarHeight,
      actions: [
        if (_isSearching)
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
              });
              _searchController.clear();
            },
          )
        else
          IconButton(
            tooltip: 'Search settings',
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _isSearching = true),
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
              color: Colors.green.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payments, color: Colors.green),
          ),
          title: const Text('Payout History'),
          subtitle: const Text('View withdrawals and status'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.payoutHistory);
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
              color: Colors.teal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.download_outlined, color: Colors.teal),
          ),
          title: const Text('Withdraw'),
          subtitle: const Text('Request a new payout'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.withdrawal);
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
              color: Colors.deepPurple.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.deepPurple),
          ),
          title: const Text('Transaction History'),
          subtitle: const Text('Payments and refunds'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.transactions);
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

  Widget _buildHeaderSection(ThemeData theme) {
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

        return Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(isPhone ? 10 : 14),
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
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/profile'),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Profile'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            minimumSize: const Size(0, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: theme.colorScheme.primary, width: 1.6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (role == UserRole.seeker)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final ok = await userProvider.switchRole(UserRole.owner);
                              if (mounted && ok) {
                                SnackBarUtils.showSuccess(context, 'Switched to Owner mode');
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
                            onPressed: () => context.go('/owner-dashboard'),
                            icon: const Icon(Icons.dashboard_outlined, size: 16),
                            label: const Text('Owner Dashboard'),
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
                      OutlinedButton.icon(
                        onPressed: () => context.push('/profile'),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          minimumSize: const Size(0, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(color: theme.colorScheme.primary, width: 1.6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      if (role == UserRole.seeker)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ok = await userProvider.switchRole(UserRole.owner);
                            if (mounted && ok) {
                              SnackBarUtils.showSuccess(context, 'Switched to Owner mode');
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
                          onPressed: () => context.go('/owner-dashboard'),
                          icon: const Icon(Icons.dashboard_outlined, size: 16),
                          label: const Text('Open Owner Dashboard'),
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
    final isPhone = media.size.width < 600;
    const bottomNavHeight = 76.0; // matches MainShell bottomNavigationBar height

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
            16 + bottomSafe + (isPhone ? bottomNavHeight : 0),
          ),
          child: _isLoading ? _buildLoadingState() : _buildContent(theme),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final themed = theme.copyWith(
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
      sections..add(_buildHeaderSection(theme))..add(const SizedBox(height: 20));
    }

    if (!_isSearching || showAny(['Profile', 'Payment Methods'])) {
      sections..add(_buildAccountSection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['Dark Mode', 'Language', 'Currency'])) {
      sections..add(_buildAppearanceSection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['Referral & Earn', 'Wallet & Rewards', 'Subscription Plans'])) {
      sections..add(_buildMonetizationSection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['All Notifications', 'Push Notifications', 'Email Notifications', 'SMS Notifications'])) {
      sections..add(_buildNotificationsSection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['Location Services', 'Analytics', 'Crash Reporting', 'Download My Data'])) {
      sections..add(_buildPrivacySection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['Change Password', 'Biometric Authentication', 'Two-Factor Authentication', 'Auto Logout'])) {
      sections..add(_buildSecuritySection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['Help Center', 'Contact Support', 'Send Feedback'])) {
      sections..add(_buildSupportSection(theme))..add(const SizedBox(height: 16));
    }
    if (!_isSearching || showAny(['App Version', 'Terms of Service', 'Privacy Policy', 'Logout'])) {
      sections..add(_buildAboutSection(theme))..add(const SizedBox(height: 80));
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
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_available, color: Colors.cyan),
          ),
          title: const Text('Calendar Sync'),
          subtitle: const Text('Google / Outlook / ICS'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.calendarSync);
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
              color: Colors.orange.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.group, color: Colors.orange),
          ),
          title: const Text('Agency Management'),
          subtitle: const Text('Co-owners and staff'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.agency);
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
      case UserRole.admin:
        return 'Admin';
      case UserRole.guest:
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
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.attach_money, color: Colors.amber),
          ),
          title: const Text('Currency'),
          subtitle: Builder(
            builder: (context) {
              final code = _userSettings?.currency ?? 'USD';
              final name = CurrencyFormatter.currencyNameFor(code);
              final sym = CurrencyFormatter.currencySymbolFor(code);
              return Text('$code — $name ($sym)');
            },
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showCurrencyDialog,
        ),
        // Removed 'Follow country currency' option by request
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
              color: Colors.teal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.help_center, color: Colors.teal),
          ),
          title: const Text('Help Center'),
          subtitle: const Text('FAQs and support articles'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.support);
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
        const Divider(height: 1),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.confirmation_number_outlined, color: Colors.deepOrange),
          ),
          title: const Text('Support Tickets'),
          subtitle: const Text('View and track'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.tickets);
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
              color: Colors.red.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.gavel_outlined, color: Colors.red),
          ),
          title: const Text('Dispute Resolution'),
          subtitle: const Text('Manage booking disputes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            ref.read(immersiveRouteOpenProvider.notifier).state = true;
            await context.push(Routes.disputes);
            if (mounted) {
              ref.read(immersiveRouteOpenProvider.notifier).state = false;
            }
          },
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
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isPhone ? 12 : 16),
            child: Row(
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

      final list = ListView.separated(
        padding: const EdgeInsets.only(bottom: 12),
        shrinkWrap: !expanded,
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final item = filtered[i];
          final code = item['code']!;
          final label = item['label']!;
          final selected = tempSelectedCode == code;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setModalState(() {
              tempSelectedCode = code;
              tempSelectedLabel = label;
            }),
            child: Container(
              decoration: BoxDecoration(
                color: selected ? theme.colorScheme.primary.withOpacity(0.06) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.4),
                  width: selected ? 1.6 : 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _colorForLang(code).withOpacity(0.12),
                    child: Text(
                      code.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _colorForLang(code),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(code, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.outline, width: 1.6),
                      color: selected ? theme.colorScheme.primary : Colors.transparent,
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      );

      final header = Row(
        children: [
          Icon(Icons.language, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('Select Language', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(popCtx).pop(),
          ),
        ],
      );

      final search = TextField(
        autofocus: false,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search languages',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (v) => setModalState(() => query = v),
      );

      final actions = Row(
        children: [
          TextButton(onPressed: () => Navigator.of(popCtx).pop(), child: const Text('Cancel')),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => onApply(popCtx),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Apply'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      );

      final content = Column(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 12),
          search,
          const SizedBox(height: 12),
          expanded ? Expanded(child: list) : Flexible(child: list),
          const SizedBox(height: 8),
          actions,
        ],
      );

      return content;
    }

    if (isPhone) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          debugPrint('[Settings] Showing bottom sheet language selector');
          return StatefulBuilder(
            builder: (ctx, setModalState) => SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.8,
                  child: buildSheetContent(setModalState, ctx, expanded: true),
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
        barrierColor: Colors.black.withOpacity(0.45),
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (dialogContext, anim1, anim2) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (ctx, setModalState) => Container(
                  width: 560,
                  height: 560,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
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
    return Column(
      children: [
        LoadingStates.propertyCardSkeleton(context),
        const SizedBox(height: 16),
        LoadingStates.propertyCardSkeleton(context),
        const SizedBox(height: 16),
        LoadingStates.propertyCardSkeleton(context),
        const SizedBox(height: 16),
        LoadingStates.propertyCardSkeleton(context),
      ],
    );
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
