import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_wrapper.dart';
import '../features/onboarding/responsive_onboarding_screen.dart';
import '../features/country/enhanced_country_select_screen.dart';
import '../features/auth/fixed_modern_login_screen.dart';
import '../features/auth/fixed_modern_register_screen.dart';
import '../features/role/modern_role_select_screen.dart';
import '../features/home/original_home_screen.dart';
import '../features/search/advanced_search_screen.dart';
import '../features/profile/modern_profile_screen.dart';
import '../features/listing/modular_listing_detail_screen.dart';
import '../features/video_tour/modular_video_tour_screen.dart';
import '../features/owner/clean_owner_dashboard_screen.dart';
import '../features/owner/property_analytics_dashboard.dart';
import '../features/owner/modular_manage_listings_screen.dart';
import '../features/owner/modular_add_vehicle_listing_screen.dart';
import '../features/owner/modular_booking_requests_screen.dart';
import '../features/chat/clean_chat_list_screen.dart';
import '../features/chat/modular_chat_screen.dart';
import '../features/notifications/modular_notifications_screen.dart';
import '../features/owner/fixed_add_listing_screen.dart';
import '../features/booking/modular_booking_history_screen.dart';
import '../features/booking/modular_booking_detail_screen.dart';
import '../features/wishlist/modular_wishlist_screen.dart';
// import '../features/settings/responsive_settings_screen.dart'; // no longer used
import '../features/settings/modular_settings_screen.dart';
import '../features/auth/modern_forgot_password_screen.dart';
import '../features/auth/modular_otp_verification_screen.dart';
import '../features/auth/modular_reset_password_screen.dart';
import '../features/auth/password_changed_success_screen.dart';
import '../features/legal/modular_terms_screen.dart';
import '../features/legal/modular_privacy_screen.dart';
import '../features/reviews/modular_reviews_screen.dart';
import '../features/reviews/bidirectional_review_screen.dart';
import '../features/reviews/guest_profile_screen.dart';
import 'package:rentally/features/monetization/subscription_plans_screen.dart';
import '../features/recommendations/smart_recommendations_engine.dart';
import '../features/support/support_center_screen.dart';
import 'main_shell.dart';
import 'app_state.dart';
import '../features/kyc/kyc_verification_screen.dart';
import '../features/monetization/wallet_screen.dart';
import '../features/referral/referral_dashboard_screen.dart';
import '../features/payouts/payout_methods_screen.dart';
import '../features/payouts/payout_history_screen.dart';
import '../features/payouts/withdrawal_screen.dart';
import '../features/calendar/calendar_sync_screen.dart';
import '../features/owner/promote_listing_screen.dart';
import '../features/agency/agency_management_screen.dart';
import '../features/security/two_factor_setup_screen.dart';
import '../features/support/ticket_list_screen.dart';
import '../features/support/dispute_resolution_screen.dart';
import '../features/monetization/transaction_history_screen.dart';
import '../features/booking/modular_booking_screen.dart';
import '../features/booking/booking_confirmation_screen.dart';
import '../features/payment/payment_methods_screen.dart' as pay_methods;
import '../features/payment/payment_integration_screen.dart' show PaymentIntegrationScreen;
import '../features/widgets/property_gallery_widget.dart' show FullScreenGallery;
import '../features/video/video_tour_system.dart' show VideoTourSchedulingScreen;
import '../features/support/contact_support_screen.dart';

// Root navigator key to allow certain routes to appear above the ShellRoute
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// Reusable page transition: subtle fade + slight slide for smooth feel
CustomTransitionPage<T> _fadeSlidePage<T>({required Widget child}) {
  return CustomTransitionPage<T>(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(curve),
          child: child,
        ),
      );
    },
  );
}

class Routes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String country = '/country';
  static const String auth = '/auth';
  static const String register = '/register';
  static const String role = '/role';
  static const String home = '/home';
  static const String search = '/search';
  static const String listing = '/listing';
  static const String booking = '/booking';
  static const String ownerDashboard = '/owner-dashboard';
  static const String ownerAdd = '/owner/add';
  static const String ownerRequests = '/owner/requests';
  static const String settings = '/settings';
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String support = '/support';
  static const String bookingHistory = '/booking-history';
  static const String wishlist = '/wishlist';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String resetPassword = '/auth/reset-password';
  static const String passwordChanged = '/password-changed';
  static const String help = '/help';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String reviews = '/reviews';
  static const String recommendations = '/recommendations';
  static const String addListing = '/add-listing';
  static const String addVehicleListing = '/add-vehicle-listing';
  static const String manageListings = '/manage-listings';
  static const String subscriptionPlans = '/subscription-plans';
  static const String ownerAnalytics = '/owner/analytics';
  static const String kyc = '/kyc';
  static const String wallet = '/wallet';
  static const String paymentMethods = '/payment-methods';
  static const String paymentIntegration = '/payment-integration';
  static const String gallery = '/gallery';
  static const String videoTourSchedule = '/video-tour/schedule';
  static const String referrals = '/referrals';
  static const String trips = '/trips';
  static const String payoutMethods = '/payouts';
  static const String payoutHistory = '/payouts/history';
  static const String withdrawal = '/payouts/withdraw';
  static const String calendarSync = '/calendar-sync';
  static const String promoteListing = '/promote-listing';
  static const String agency = '/agency';
  static const String twoFactor = '/security/2fa';
  static const String tickets = '/support/tickets';
  static const String contactSupport = '/support/contact';
  static const String disputes = '/support/disputes';
  static const String transactions = '/transactions';
}


// Router provider that depends on auth state
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final onboardingComplete = ref.watch(onboardingCompleteProvider);
  final selectedCountry = ref.watch(countryProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    redirect: (context, state) {
      final currentPath = state.uri.path;
      
      // Public routes that don't require authentication
      final publicRoutes = [
        Routes.splash,
        Routes.onboarding,
        Routes.country,
        Routes.auth,
        Routes.register,
        Routes.role,
        Routes.forgotPassword,
        Routes.otpVerification,
        Routes.resetPassword,
        Routes.passwordChanged,
      ];
      
      final isPublicRoute = publicRoutes.contains(currentPath);
      
      // Handle authenticated users - immediate redirect without splash
      if (authState.status == AuthStatus.authenticated) {
        if (isPublicRoute) {
          // Allow certain public routes even when authenticated
          if (currentPath == Routes.resetPassword || currentPath == Routes.passwordChanged) {
            return null;
          }
          final userRole = authState.user?.role ?? UserRole.seeker;
          if (userRole == UserRole.owner) {
            return Routes.ownerDashboard;
          } else {
            // Admins are routed to home; web admin panel is the source of truth
            return Routes.home;
          }
        }
        return null;
      }
      
      // Handle loading state - stay on current route to prevent splash flicker
      if (authState.status == AuthStatus.loading) {
        return null;
      }
      
      // Handle unauthenticated users
      if (authState.status == AuthStatus.unauthenticated || authState.status == AuthStatus.initial) {
        if (isPublicRoute) {
          // Onboarding flow
          if (!onboardingComplete && currentPath != Routes.splash && currentPath != Routes.onboarding) {
            final query = state.uri.query;
            return query.isNotEmpty ? '${Routes.onboarding}?$query' : Routes.onboarding;
          }
          
          // Country selection flow
          if (onboardingComplete && selectedCountry == null && currentPath != Routes.country) {
            return Routes.country;
          }
          
          // Auth flow
          if (onboardingComplete && selectedCountry != null && 
              currentPath != Routes.auth && currentPath != Routes.register && currentPath != Routes.role &&
              currentPath != Routes.forgotPassword && currentPath != Routes.otpVerification &&
              currentPath != Routes.resetPassword && currentPath != Routes.passwordChanged) {
            return Routes.auth;
          }
          
          return null;
        }
        
        return Routes.auth;
      }
      
      return null;
    },
    routes: <RouteBase>[
      // Public routes
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) => _fadeSlidePage(child: const AuthWrapper()),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) => _fadeSlidePage(child: const ResponsiveOnboardingScreen()),
      ),
      GoRoute(
        path: Routes.country,
        pageBuilder: (context, state) => _fadeSlidePage(child: const EnhancedCountrySelectScreen()),
      ),
      GoRoute(
        path: Routes.auth,
        pageBuilder: (context, state) => _fadeSlidePage(child: const FixedModernLoginScreen()),
      ),
      GoRoute(
        path: Routes.register,
        pageBuilder: (context, state) => _fadeSlidePage(child: const FixedModernRegisterScreen()),
      ),
      
      GoRoute(
        path: Routes.role,
        pageBuilder: (context, state) => _fadeSlidePage(child: const ModernRoleSelectScreen()),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        pageBuilder: (context, state) => _fadeSlidePage(child: const ModernForgotPasswordScreen()),
      ),
      GoRoute(
        path: Routes.otpVerification,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final phoneNumber = extra['phoneNumber'] ?? state.uri.queryParameters['phone'] ?? '';
          final verificationId = extra['verificationId'] ?? state.uri.queryParameters['verificationId'] ?? '';
          final isPasswordReset = extra['isPasswordReset'] ?? false;
          return _fadeSlidePage(child: ModularOtpVerificationScreen(
            phoneNumber: phoneNumber,
            verificationId: verificationId,
            isPasswordReset: isPasswordReset,
          ));
        },
      ),
      GoRoute(
        path: Routes.resetPassword,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final email = extra['email'] ?? '';
          final successPath = extra['successPath'] as String? ?? Routes.passwordChanged;
          return _fadeSlidePage(child: ModularResetPasswordScreen(email: email, successPath: successPath));
        },
      ),
      GoRoute(
        path: Routes.passwordChanged,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const PasswordChangedSuccessScreen()),
      ),
      GoRoute(
        path: '/help',
        pageBuilder: (context, state) => _fadeSlidePage(child: const SupportCenterScreen()),
      ),
      GoRoute(
        path: Routes.terms,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const ModularTermsScreen()),
      ),
      GoRoute(
        path: Routes.privacy,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const ModularPrivacyScreen()),
      ),

      // Immersive routes rendered above the Shell (no bottom nav)
      GoRoute(
        path: Routes.profile,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const ModernProfileScreen()),
      ),
      GoRoute(
        path: Routes.recommendations,
        name: 'recommendations',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const SmartRecommendationsScreen()),
      ),
      GoRoute(
        path: Routes.ownerAnalytics,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final propertyId = state.uri.queryParameters['propertyId'];
          return _fadeSlidePage(child: PropertyAnalyticsDashboard(propertyId: propertyId));
        },
      ),
      GoRoute(
        path: Routes.addListing,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const FixedAddListingScreen()),
      ),
      GoRoute(
        path: Routes.addVehicleListing,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const ModularAddVehicleListingScreen()),
      ),
      GoRoute(
        path: Routes.kyc,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const KYCVerificationScreen()),
      ),
      GoRoute(
        path: Routes.promoteListing,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const PromoteListingScreen()),
      ),

      // Full-page Listing Detail outside the Shell (separate page, no bottom bar)
      GoRoute(
        path: '${Routes.listing}/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return _fadeSlidePage(
            child: ModularListingDetailScreen(listingId: state.pathParameters['id'] ?? '0'),
          );
        },
      ),

      // Other immersive routes rendered above the Shell
      GoRoute(
        path: '/book/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extras = (state.extra as Map<String, dynamic>?) ?? const {};
          DateTime? parseDt(dynamic v) {
            if (v is DateTime) return v;
            if (v is String && v.isNotEmpty) {
              try { return DateTime.parse(v); } catch (_) { return null; }
            }
            return null;
          }
          final checkIn = parseDt(extras['checkIn']);
          final checkOut = parseDt(extras['checkOut']);
          final guests = (extras['guests'] is int) ? extras['guests'] as int : null;
          final instant = (extras['instant'] is bool) ? extras['instant'] as bool : true;
          return _fadeSlidePage(
            child: ModularBookingScreen(
              listingId: state.pathParameters['id'] ?? '',
              initialCheckIn: checkIn,
              initialCheckOut: checkOut,
              initialAdults: guests,
              instantBooking: instant,
            ),
          );
        },
      ),
      GoRoute(
        path: '/video-tour/:propertyId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final propertyId = state.pathParameters['propertyId'] ?? '';
          return _fadeSlidePage(child: ModularVideoTourScreen(propertyId: propertyId));
        },
      ),
      GoRoute(
        path: '/guest-profile/:guestId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final guestId = state.pathParameters['guestId'] ?? '';
          final extras = (state.extra as Map<String, dynamic>?) ?? const {};
          final guestName = extras['guestName'] ?? state.uri.queryParameters['name'] ?? '';
          final guestAvatar = extras['guestAvatar'] ?? state.uri.queryParameters['avatar'];
          return _fadeSlidePage(
            child: GuestProfileScreen(
              guestId: guestId,
              guestName: guestName,
              guestAvatar: guestAvatar,
            ),
          );
        },
      ),
      GoRoute(
        path: '${Routes.reviews}/:listingId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final propertyId = state.pathParameters['listingId'] ?? '';
          return _fadeSlidePage(child: ModularReviewsScreen(propertyId: propertyId));
        },
      ),
      // Calendar Sync and Agency Management as immersive (root navigator)
      GoRoute(
        path: Routes.calendarSync,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const CalendarSyncScreen()),
      ),
      GoRoute(
        path: Routes.agency,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const AgencyManagementScreen()),
      ),
      // Settings & Monetization flows (immersive, outside Shell)
      GoRoute(
        path: Routes.paymentMethods,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const pay_methods.PaymentMethodsScreen()),
      ),
      GoRoute(
        path: '${Routes.videoTourSchedule}/:propertyId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extras = (state.extra as Map<String, dynamic>?) ?? const {};
          final propertyId = state.pathParameters['propertyId'] ?? '';
          final propertyTitle = extras['propertyTitle'] ?? state.uri.queryParameters['title'] ?? '';
          final hostId = extras['hostId'] ?? state.uri.queryParameters['hostId'] ?? '';
          final hostName = extras['hostName'] ?? state.uri.queryParameters['hostName'] ?? '';
          return _fadeSlidePage(
            child: VideoTourSchedulingScreen(
              propertyId: propertyId,
              propertyTitle: propertyTitle,
              hostId: hostId,
              hostName: hostName,
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.gallery,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extras = (state.extra as Map<String, dynamic>?) ?? const {};
          final images = (extras['images'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList();
          final initialIndex = (extras['initialIndex'] as int?) ?? 0;
          final heroTag = (extras['heroTag'] as String?) ?? 'gallery';
          return _fadeSlidePage(
            child: FullScreenGallery(
              images: images,
              initialIndex: initialIndex,
              heroTag: heroTag,
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.paymentIntegration,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = (state.extra as Map<String, dynamic>?) ?? const {};
          final bookingId = extra['bookingId'] ?? state.uri.queryParameters['bookingId'];
          final amountParam = extra['amount'] ?? state.uri.queryParameters['amount'];
          final propertyTitle = extra['propertyTitle'] ?? state.uri.queryParameters['propertyTitle'];
          final double? amount = amountParam is double
              ? amountParam
              : amountParam is String
                  ? double.tryParse(amountParam)
                  : null;
          return _fadeSlidePage(
            child: PaymentIntegrationScreen(
              bookingId: bookingId,
              amount: amount,
              propertyTitle: propertyTitle,
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.referrals,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const ReferralDashboardScreen()),
      ),
      GoRoute(
        path: Routes.wallet,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const WalletScreen()),
      ),
      GoRoute(
        path: Routes.payoutMethods,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const PayoutMethodsScreen()),
      ),
      GoRoute(
        path: Routes.payoutHistory,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const PayoutHistoryScreen()),
      ),
      GoRoute(
        path: Routes.withdrawal,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const WithdrawalScreen()),
      ),
      GoRoute(
        path: Routes.transactions,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const TransactionHistoryScreen()),
      ),
      GoRoute(
        path: Routes.subscriptionPlans,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const SubscriptionPlansScreen()),
      ),
      // Security
      GoRoute(
        path: Routes.twoFactor,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const TwoFactorSetupScreen()),
      ),
      // Support center and tools
      GoRoute(
        path: Routes.support,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const SupportCenterScreen()),
      ),
      GoRoute(
        path: Routes.contactSupport,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const ContactSupportScreen()),
      ),
      GoRoute(
        path: Routes.tickets,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(child: const TicketListScreen()),
      ),
      GoRoute(
        path: Routes.disputes,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final bookingId = (state.extra as Map?)?['bookingId'] as String?;
          return _fadeSlidePage(child: DisputeResolutionScreen(bookingId: bookingId));
        },
      ),
      
      // Protected routes with shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(state: state, child: child),
        routes: [
          // Seeker routes
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) => _fadeSlidePage(child: const OriginalHomeScreen()),
          ),
          GoRoute(
            path: Routes.search,
            pageBuilder: (context, state) {
              final type = state.uri.queryParameters['type'];
              final category = state.uri.queryParameters['category'];
              return _fadeSlidePage(child: AdvancedSearchScreen(initialType: type, initialCategory: category));
            },
          ),
          // Legacy '/booking' now routes to booking history (screen removed)
          GoRoute(
            path: Routes.booking,
            pageBuilder: (context, state) => _fadeSlidePage(child: const ModularBookingHistoryScreen()),
          ),
          
          // Owner routes
          GoRoute(
            path: Routes.ownerDashboard,
            pageBuilder: (context, state) => _fadeSlidePage(child: const CleanOwnerDashboardScreen()),
          ),
          
          GoRoute(
            path: Routes.ownerAdd,
            pageBuilder: (context, state) => _fadeSlidePage(child: const FixedAddListingScreen()),
          ),
          GoRoute(
            path: Routes.ownerRequests,
            pageBuilder: (context, state) => _fadeSlidePage(child: const ModularBookingRequestsScreen()),
          ),
          
          // Common routes
          GoRoute(
            path: Routes.settings,
            pageBuilder: (context, state) => _fadeSlidePage(child: const ModularSettingsScreen()),
          ),
          GoRoute(
            path: Routes.chat,
            pageBuilder: (context, state) => _fadeSlidePage(child: const CleanChatListScreen()),
          ),
          GoRoute(
            path: '/chat/:chatId',
            pageBuilder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final chatData = state.extra as Map<String, dynamic>? ?? {};
              return _fadeSlidePage(child: ModularChatScreen(chatId: chatId, chatData: chatData));
            },
          ),
          GoRoute(
            path: Routes.notifications,
            pageBuilder: (context, state) => _fadeSlidePage(child: const ModularNotificationsScreen()),
          ),
          
          GoRoute(
            path: Routes.bookingHistory,
            pageBuilder: (context, state) => _fadeSlidePage(child: const ModularBookingHistoryScreen()),
          ),
          GoRoute(
            path: '${Routes.bookingHistory}/:id',
            pageBuilder: (context, state) => _fadeSlidePage(child: ModularBookingDetailScreen(bookingId: state.pathParameters['id'] ?? '')),
          ),
          GoRoute(
            path: Routes.wishlist,
            pageBuilder: (context, state) => _fadeSlidePage(child: const ModularWishlistScreen()),
          ),
          
          GoRoute(
            path: Routes.manageListings,
            pageBuilder: (context, state) => _fadeSlidePage(child: const ModularManageListingsScreen()),
          ),
          GoRoute(
            path: Routes.trips,
            pageBuilder: (context, state) => _fadeSlidePage(child: const ModularBookingHistoryScreen()),
          ),
          
          GoRoute(
            path: '/booking-confirmation/:id',
            pageBuilder: (context, state) => _fadeSlidePage(child: BookingConfirmationScreen(bookingId: state.pathParameters['id'] ?? '')),
          ),
          GoRoute(
            path: '/bidirectional-review/:bookingId',
            pageBuilder: (context, state) {
              final extras = (state.extra as Map<String, dynamic>?) ?? const {};
              return _fadeSlidePage(
                child: BidirectionalReviewScreen(
                  bookingId: state.pathParameters['bookingId'] ?? '',
                  guestId: extras['guestId'] ?? '',
                  guestName: extras['guestName'] ?? '',
                  listingId: extras['listingId'] ?? '',
                  listingTitle: extras['listingTitle'] ?? '',
                ),
              );
            },
          ),
          // Admin in-app route removed (use web admin panel instead)
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
