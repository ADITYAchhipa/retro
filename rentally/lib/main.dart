import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart' as provider;
import '../services/rent_reminder_service.dart';

// App configuration and routing
import 'app/auth_router.dart';
import 'app/app_state.dart';

// Theme configuration
import 'core/theme/enterprise_dark_theme.dart';
import 'core/theme/enterprise_light_theme.dart';
import 'core/theme/listing_card_theme.dart';

// State management providers
import 'core/providers/property_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/booking_provider.dart';
import '../core/providers/listing_feed_provider.dart';
import '../services/view_history_service.dart';
import '../core/providers/vehicle_provider.dart';

/// ========================================
/// 🚀 MAIN FUNCTION - APP INITIALIZATION
/// ========================================
/// 
/// Initializes the Flutter app with all necessary providers and services.
/// This function sets up the dependency injection and state management.
/// 
void main() async {
  // Ensure Flutter framework is initialized in the default zone
  WidgetsFlutterBinding.ensureInitialized();

  // Global top-level error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[TopLevel] Uncaught platform error: $error\n$stack');
    return true; // handled
  };

  // ========================================
  // 📦 PROVIDER INITIALIZATION
  // Initialize providers before app launch
  final propertyProvider = PropertyProvider();
  final vehicleProvider = VehicleProvider();
  final userProvider = UserProvider();
  final bookingProvider = BookingProvider();
  final viewHistoryService = ViewHistoryService();
  final listingFeedProvider = ListingFeedProvider(viewHistoryService: viewHistoryService);

  // Load initial data
  await Future.wait([
    propertyProvider.loadProperties(),
    vehicleProvider.loadVehicles(),
    userProvider.initialize(),
    bookingProvider.initialize(),
    listingFeedProvider.initialize(),
    viewHistoryService.initialize(),
  ]);

  // ========================================
  // 🚀 APP LAUNCH
  runApp(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider.value(value: propertyProvider),
        provider.ChangeNotifierProvider.value(value: userProvider),
        provider.ChangeNotifierProvider.value(value: bookingProvider),
        provider.ChangeNotifierProvider.value(value: vehicleProvider),
        provider.ChangeNotifierProvider.value(value: listingFeedProvider),
        provider.ChangeNotifierProvider.value(value: viewHistoryService),
      ],
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

/// ========================================
/// 🎨 MAIN APP WIDGET - ROOT APPLICATION
/// ========================================
/// 
/// The root widget that configures the entire application including:
/// - Theme management (light/dark mode)
/// - Routing and navigation
/// - Internationalization
/// - Material Design setup
/// 
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  Timer? _rentReminderTimer;
  @override
  void initState() {
    super.initState();
    _loadInitialLocale();
    _startRentReminderPolling();
  }

  Future<void> _loadInitialLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('localeCode');
      if (code != null && code.isNotEmpty) {
        ref.read(AppNotifiers.localeProvider.notifier).state = Locale(code);
      }
      // Load saved theme mode
      final savedTheme = prefs.getString('themeMode');
      if (savedTheme == 'dark') {
        ref.read(AppNotifiers.themeModeProvider.notifier).state = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        ref.read(AppNotifiers.themeModeProvider.notifier).state = ThemeMode.light;
      } else if (savedTheme == 'system') {
        ref.read(AppNotifiers.themeModeProvider.notifier).state = ThemeMode.system;
      } else {
        // Default to light theme
        ref.read(AppNotifiers.themeModeProvider.notifier).state = ThemeMode.light;
      }
    } catch (_) {
      // ignore errors, default locale will be used
    } finally {}
  }

  void _startRentReminderPolling() {
    // Fire once at startup, then hourly while app is in foreground.
    RentReminderService.checkAndFireDue(ref);
    _rentReminderTimer?.cancel();
    _rentReminderTimer = Timer.periodic(const Duration(hours: 1), (_) {
      RentReminderService.checkAndFireDue(ref);
    });
  }

  @override
  void dispose() {
    _rentReminderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch theme mode changes for dynamic theme switching
    final themeMode = ref.watch(AppNotifiers.themeModeProvider);
    final locale = ref.watch(AppNotifiers.localeProvider);
    // Watch router for navigation management
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Rentally',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: EnterpriseLightTheme.primaryAccent,
          secondary: EnterpriseLightTheme.secondaryAccent,
          surface: EnterpriseLightTheme.cardBackground,
          background: EnterpriseLightTheme.primaryBackground,
          onPrimary: EnterpriseLightTheme.onPrimaryAccent,
          onSecondary: EnterpriseLightTheme.primaryText,
          onSurface: EnterpriseLightTheme.primaryText,
          onBackground: EnterpriseLightTheme.primaryText,
          outline: EnterpriseLightTheme.primaryBorder,
        ),
        scaffoldBackgroundColor: EnterpriseLightTheme.primaryBackground,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: EnterpriseLightTheme.primaryBackground,
          foregroundColor: EnterpriseLightTheme.primaryText,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: EnterpriseLightTheme.cardBackground,
          shadowColor: EnterpriseLightTheme.cardShadow.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: EnterpriseLightTheme.primaryBorder, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: EnterpriseLightTheme.primaryAccent,
            foregroundColor: EnterpriseLightTheme.onPrimaryAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: EnterpriseLightTheme.primaryAccent.withOpacity(0.3),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: EnterpriseLightTheme.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: EnterpriseLightTheme.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: EnterpriseLightTheme.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: EnterpriseLightTheme.inputFocusBorder, width: 2),
          ),
        ),
        textTheme: const TextTheme().apply(
          bodyColor: EnterpriseLightTheme.primaryText,
          displayColor: EnterpriseLightTheme.primaryText,
        ),
        extensions: <ThemeExtension<dynamic>>[
          ListingCardTheme.defaults(dark: false),
        ],
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: EnterpriseDarkTheme.primaryAccent,
          secondary: EnterpriseDarkTheme.secondaryAccent,
          surface: EnterpriseDarkTheme.secondaryBackground,
          background: EnterpriseDarkTheme.primaryBackground,
          onPrimary: EnterpriseDarkTheme.onPrimaryAccent,
          onSecondary: EnterpriseDarkTheme.primaryText,
          onSurface: EnterpriseDarkTheme.primaryText,
          onBackground: EnterpriseDarkTheme.primaryText,
          outline: EnterpriseDarkTheme.primaryBorder,
        ),
        scaffoldBackgroundColor: EnterpriseDarkTheme.primaryBackground,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: EnterpriseDarkTheme.primaryBackground,
          foregroundColor: EnterpriseDarkTheme.primaryText,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: EnterpriseDarkTheme.surfaceBackground,
          shadowColor: EnterpriseDarkTheme.primaryShadow.withOpacity(0.18),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: EnterpriseDarkTheme.primaryBorder, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: EnterpriseDarkTheme.primaryAccent,
            foregroundColor: EnterpriseDarkTheme.onPrimaryAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 1,
            shadowColor: EnterpriseDarkTheme.primaryAccent.withOpacity(0.18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: EnterpriseDarkTheme.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: EnterpriseDarkTheme.primaryBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: EnterpriseDarkTheme.primaryBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: EnterpriseDarkTheme.primaryAccent, width: 2),
          ),
        ),
        textTheme: const TextTheme().apply(
          bodyColor: EnterpriseDarkTheme.primaryText,
          displayColor: EnterpriseDarkTheme.primaryText,
        ),
        extensions: <ThemeExtension<dynamic>>[
          ListingCardTheme.defaults(dark: true),
        ],
      ),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('hi'),
        Locale('bn'),
        Locale('mr'),
        Locale('te'),
        Locale('ta'),
        Locale('gu'),
        Locale('zh'),
        Locale('ar'),
        Locale('pt'),
        Locale('ru'),
      ],
      routerConfig: router,
    );
  }
}
