import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/loading_states.dart';
import '../../widgets/responsive_layout.dart';
import '../../models/listing.dart';
import '../../app/auth_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/tab_back_handler.dart';
import '../../app/app_state.dart';
// Removed direct payment router dependency; using unified booking payment screen route instead
import '../../services/booking_service.dart' as bs;
import '../../services/notification_service.dart';
import '../../services/referral_service.dart';
import '../../services/coupon_service.dart';
import '../../services/monetization_service.dart';
import '../../core/providers/ui_visibility_provider.dart';
import 'package:rentally/widgets/unified_card.dart';
import '../../services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/kyc/kyc_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Industrial-Grade Modular Booking Screen
/// 
/// Features:
/// - Multi-step booking flow with validation
/// - Calendar date selection with availability
/// - Guest count selection and validation
/// - Price calculation with dynamic pricing
/// - Payment method integration
/// - Error boundaries and crash prevention
/// - Skeleton loading states
/// - Responsive design for all devices
/// - Accessibility compliance (WCAG 2.1)
/// - Form validation and security
/// - Real-time availability checking
/// - Booking confirmation flow
class ModularBookingScreen extends ConsumerStatefulWidget {
  final String listingId;
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final int? initialAdults;
  final bool instantBooking; // true -> pay & confirm, false -> request approval

  const ModularBookingScreen({
    super.key,
    required this.listingId,
    this.initialCheckIn,
    this.initialCheckOut,
    this.initialAdults,
    this.instantBooking = true,
  });

  @override
  ConsumerState<ModularBookingScreen> createState() =>
      _ModularBookingScreenState();
}

class _ModularBookingScreenState extends ConsumerState<ModularBookingScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Booking State
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;
  int _adults = 1;
  int _children = 0;
  int _infants = 0;
  String _specialRequests = '';
  
  // UI State
  bool _isLoading = true;
  // bool _isProcessing = false;
  String? _error;
  Listing? _listing;
  // Helper: treat anything not explicitly 'Vehicle' as property for monthly flow
  bool get _isVehicle => (_listing?.category.toLowerCase() ?? 'property') == 'vehicle';
  bool get _isHourlyVehicle => _isVehicle && ((_listing?.rentalUnit?.toLowerCase() ?? 'day') == 'hour');
  
  
  // Add-ons (dynamically loaded based on listing category)
  Map<String, _AddOn> _addOns = {};
  
  // Property-specific add-ons
  Map<String, _AddOn> get _propertyAddOns => {
    'cleaning': _AddOn('cleaning', 'Professional Cleaning', 'Deep cleaning before check-in', 35.0, category: 'property'),
    'breakfast': _AddOn('breakfast', 'Breakfast Package', 'Daily breakfast for all guests', 12.0, category: 'property'),
    'extra_bed': _AddOn('extra_bed', 'Extra Bed', 'One additional bed setup', 18.0, category: 'property'),
    'early_checkin': _AddOn('early_checkin', 'Early Check-in', 'Check in from 10 AM (subject to availability)', 25.0, category: 'property'),
    'late_checkout': _AddOn('late_checkout', 'Late Check-out', 'Check out until 2 PM (subject to availability)', 25.0, category: 'property'),
    'parking': _AddOn('parking', 'Parking Space', 'Dedicated parking spot', 15.0, category: 'property'),
  };
  
  // Vehicle-specific add-ons
  Map<String, _AddOn> get _vehicleAddOns => {
    'gps': _AddOn('gps', 'GPS Navigation', 'Built-in GPS navigation system', 8.0, category: 'vehicle', perDay: true),
    'child_seat': _AddOn('child_seat', 'Child Safety Seat', 'Child car seat (specify age)', 5.0, category: 'vehicle', perDay: true),
    'additional_driver': _AddOn('additional_driver', 'Additional Driver', 'Add one more authorized driver', 15.0, category: 'vehicle', perDay: false),
    'fuel_full': _AddOn('fuel_full', 'Full Tank Fuel', 'Start with full tank (prepaid)', 60.0, category: 'vehicle', perDay: false),
    'roadside_assist': _AddOn('roadside_assist', '24/7 Roadside Assistance', 'Emergency support anytime', 12.0, category: 'vehicle', perDay: true),
    'wifi_hotspot': _AddOn('wifi_hotspot', 'WiFi Hotspot', 'Mobile internet in vehicle', 6.0, category: 'vehicle', perDay: true),
  };
  String _couponCode = '';
  double _couponDiscount = 0.0;
  String? _appliedCouponCode;
  bool _autoIdChecked = false;

  // Payment (selection UI removed, payment handled in BookingPaymentScreen)
  bool _agreeToTerms = false;
  bool _acceptedHouseRules = false;

  // Price Calculation
  double _basePrice = 0;
  double _serviceFee = 0;
  double _taxes = 0;
  double _totalPrice = 0;
  int _nights = 0;
  int _months = 0;
  int _hours = 0;
  double _addOnsTotal = 0;
  // Referral credits
  final TextEditingController _referralCtrl = TextEditingController();
  double _referralDiscount = 0.0; // 1 token = 1 currency unit for now
  int _referralTokensApplied = 0;

  // Seeker ID upload (conditional)
  bool _uploadingSeekerId = false;
  String? _seekerIdImageUrl;
  
  // Security deposit (for properties)
  double _securityDeposit = 0;
  
  // Vehicle condition checklist (for vehicles)
  final Map<String, bool> _vehicleConditions = {
    'exterior_front': false,
    'exterior_back': false,
    'exterior_left': false,
    'exterior_right': false,
    'interior_front': false,
    'interior_back': false,
    'dashboard': false,
    'fuel_level': false,
  };
  final Map<String, String> _vehicleConditionPhotos = {};
  bool _uploadingVehiclePhotos = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadListingData();
    _initializeAddOns();
    // Seed initial state from route params
    _checkInDate = widget.initialCheckIn;
    _checkOutDate = widget.initialCheckOut;
    if (widget.initialAdults != null && widget.initialAdults! > 0) {
      _adults = widget.initialAdults!;
    }
    _calculateSecurityDeposit();
    _recalculatePrice();
    // Hide Shell chrome while booking flow is open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(immersiveRouteOpenProvider.notifier).state = true;
      }
    });
  }

  Future<void> _showIdChangeOptions() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Replace from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadId(camera: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a new photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadId(camera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Use saved ID'),
                onTap: () async {
                  Navigator.pop(context);
                  await _useSavedId();
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove attached ID'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _seekerIdImageUrl = null);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _tryAutoAttachSavedId() async {
    if (_autoIdChecked) return;
    _autoIdChecked = true;
    if (!_requiresIdUpload()) return;
    if (_seekerIdImageUrl != null && _seekerIdImageUrl!.isNotEmpty) return;
    try {
      final profile = await KycService.instance.getProfile();
      String? path = profile.frontIdPath;

      // Fallback to ID uploaded in Profile → Edit Profile (stored locally)
      if (path == null || path.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final profileIdPath = prefs.getString('user_id_document_path');
          if (profileIdPath != null && profileIdPath.isNotEmpty) {
            path = profileIdPath;
          }
        } catch (_) {}
      }

      if (path == null || path.isEmpty) return;
      setState(() => _uploadingSeekerId = true);
      final imageService = ref.read(imageServiceProvider);
      final url = await imageService.uploadImage(XFile(path));
      if (!mounted) return;
      setState(() {
        _seekerIdImageUrl = url;
        _uploadingSeekerId = false;
      });
      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved ID attached.'),
            action: SnackBarAction(
              label: 'Change',
              onPressed: () {
                setState(() => _seekerIdImageUrl = null);
              },
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _uploadingSeekerId = false);
    }
  }

  Widget _buildReferralCreditsSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final available = ref.watch(referralServiceProvider).totalTokens;
    final rentBase = _isHourlyVehicle
        ? (_basePrice * _hours)
        : (_isVehicle ? (_basePrice * _nights) : (_basePrice * _months));
    final beforeReferral = rentBase + _addOnsTotal + _serviceFee + _taxes - _couponDiscount;
    final maxApplicable = beforeReferral.floor();
    final capByTotal = (beforeReferral * 0.10).floor(); // 10% of total payable amount
    int maxUsable = available;
    if (capByTotal < maxUsable) maxUsable = capByTotal;
    if (maxApplicable >= 0 && maxApplicable < maxUsable) maxUsable = maxApplicable;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.3),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade50,
                  Colors.amber.shade50.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade400,
                        Colors.amber.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.referralCredits ?? 'Referral Credits',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)?.availableTokens(available) ?? 'Available: $available tokens',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input field with Max button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: TextField(
                    controller: _referralCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.tokensToApply ?? 'Tokens to apply',
                      hintText: 'Enter amount',
                      filled: true,
                      fillColor: isDark 
                          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                          : Colors.grey.shade50,
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade300,
                              Colors.amber.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.loyalty_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              _referralCtrl.text = maxUsable.toString();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Text(
                              AppLocalizations.of(context)?.max ?? 'Max',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.amber.shade600,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      final v = int.tryParse(_referralCtrl.text.trim()) ?? 0;
                      final toApply = v.clamp(0, maxUsable);
                      setState(() {
                        _referralTokensApplied = toApply;
                        _referralDiscount = toApply.toDouble();
                        _recalculatePrice();
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final v = int.tryParse(_referralCtrl.text.trim()) ?? 0;
                      final toApply = v.clamp(0, maxUsable);
                      setState(() {
                        _referralTokensApplied = toApply;
                        _referralDiscount = toApply.toDouble();
                        _recalculatePrice();
                      });
                      if (toApply > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)?.appliedTokens(toApply) ?? 'Applied: $toApply tokens',
                            ),
                            backgroundColor: Colors.amber.shade800,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(AppLocalizations.of(context)?.apply ?? 'Apply Credits'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                // Applied Credits Card
                if (_referralDiscount > 0) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade50,
                          Colors.green.shade50.withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.green.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Credits Applied!',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppLocalizations.of(context)?.appliedTokens(_referralTokensApplied) ?? '$_referralTokensApplied tokens',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _referralTokensApplied = 0;
                              _referralDiscount = 0.0;
                              _referralCtrl.clear();
                              _recalculatePrice();
                            });
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Info Section
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Credit Details',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• ${AppLocalizations.of(context)?.tokenUnitEquation(CurrencyFormatter.defaultCurrency) ?? '1 token = 1 ${CurrencyFormatter.defaultCurrency} unit'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '• Max usable: $maxUsable tokens (10% cap)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPriceBreakdownSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final isPhone = media.size.width < 600;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: media.viewInsets.bottom + 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 720,
                maxHeight: isPhone ? media.size.height * 0.75 : media.size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)?.priceBreakdown ?? 'Price Summary',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPriceSummary(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  Future<void> _loadListingData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      
      if (mounted) {
        setState(() {
          _listing = _createMockListing();
          // Set base price per unit: per day for vehicles, per month for properties
          final isVehicle = (_listing!.category.toLowerCase() == 'vehicle');
          if (isVehicle) {
            // If hourly unit is specified, treat price as per-hour; otherwise per-day
            _basePrice = _listing!.price;
          } else {
            _basePrice = (_listing!.price * 30);
          }
          _isLoading = false;
        });
        // Prefill coupon from Wallet deep-link if present
        final prefill = ref.read(selectedCouponCodeProvider);
        if (prefill != null && prefill.isNotEmpty) {
          setState(() {
            _couponCode = prefill;
          });
          _applyCoupon();
          ref.read(selectedCouponCodeProvider.notifier).state = null;
        }
        // Attempt to auto-attach saved ID if required
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tryAutoAttachSavedId();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load booking details: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Listing _createMockListing() {
    return Listing(
      id: widget.listingId,
      title: 'Luxury Penthouse with City Views',
      location: 'Downtown Manhattan, New York',
      price: 350.0,
      images: [
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400',
      ],
      rating: 4.9,
      reviews: 247,
      amenities: ['WiFi', 'Kitchen', 'Parking'],
      hostName: 'Alexandra Chen',
      hostImage: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=200',
      description: 'Beautiful luxury penthouse',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TabBackHandler(
      pageController: _pageController,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            // If we have previous pages, TabBackHandler will handle stepping back.
            final current = _pageController.hasClients
                ? (_pageController.page?.round() ?? _pageController.initialPage)
                : 0;
            if (current > 0) {
              return;
            }
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              context.go(Routes.home);
            }
        },
        child: Scaffold(
          backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
          appBar: _buildAppBar(),
          body: ResponsiveLayout(
            child: _isLoading ? _buildLoadingState() : _buildContent(),
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(AppLocalizations.of(context)?.bookYourStay ?? 'Book Your Stay'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          final router = GoRouter.of(context);
          if (router.canPop()) {
            router.pop();
          } else {
            context.go(Routes.home);
          }
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    // Use a standardized shimmer list for a modern loading experience
    return LoadingStates.listShimmer(context, itemCount: 3);
  }

  Widget _buildContent() {
    if (_error != null) {
      return _buildErrorState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: Builder(
              builder: (context) {
                final steps = _stepsWidgets();
                return PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: steps,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _stepsWidgets() {
    final steps = <Widget>[
      _buildDetailsStep(),
      _buildAddOnsStep(),
    ];
    if (_requiresIdUpload()) {
      steps.add(_buildIdVerificationStep());
    }
    // Add vehicle condition checklist for vehicles only
    if (_isVehicle) {
      steps.add(_buildVehicleConditionStep());
    }
    steps.addAll([
      _buildPaymentStep(),
      _buildReviewStep(),
    ]);
    return steps;
  }

  bool _requiresIdUpload() {
    // Only for vehicle bookings in this screen; monthly property flows use different screens
    if (_isVehicle) {
      final needsId = _listing?.requireSeekerId == true;
      final hasAttached = _seekerIdImageUrl != null && _seekerIdImageUrl!.isNotEmpty;
      return needsId && !hasAttached;
    }
    // For short-stay property, do not require ID here
    return false;
  }

  int _idStepIndex() => _requiresIdUpload() ? 2 : -1;
  
  int _paymentStepIndex() {
    int index = 2; // After details and add-ons
    if (_requiresIdUpload()) index++;
    if (_isVehicle) index++; // After vehicle condition
    return index;
  }
  int _reviewStepIndex() => _paymentStepIndex() + 1;
  int _lastStepIndex() => _reviewStepIndex();
  int _stepsCount() {
    int count = 4; // Details, Add-ons, Payment, Review
    if (_requiresIdUpload()) count++;
    if (_isVehicle) count++; // Vehicle condition checklist
    return count;
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.bookingError ?? 'Booking Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadListingData,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (int i = 0; i < _stepsCount(); i++) ...[
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _currentStep
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < _stepsCount() - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      color: isDark ? theme.colorScheme.surface : Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildListingCard(),
            const SizedBox(height: 8),
            
            // Dates Section
            _buildSectionCard(
              icon: Icons.calendar_month_rounded,
              title: AppLocalizations.of(context)?.selectDates ?? 'Select Dates',
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateTile(
                      label: AppLocalizations.of(context)?.checkIn ?? 'Check-in',
                      value: _checkInDate == null ? (AppLocalizations.of(context)?.select ?? 'Select') : _formatDate(_checkInDate!),
                      onTap: _pickDateRange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateTile(
                      label: AppLocalizations.of(context)?.checkOut ?? 'Check-out',
                      value: _checkOutDate == null ? (AppLocalizations.of(context)?.select ?? 'Select') : _formatDate(_checkOutDate!),
                      onTap: _pickDateRange,
                    ),
                  ),
                ],
              ),
            ),
            if (_isHourlyVehicle) ...[
              const SizedBox(height: 12),
              _buildSectionCard(
                icon: Icons.access_time_rounded,
                title: 'Select Time',
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTimeTile(
                        label: AppLocalizations.of(context)?.checkInTime ?? 'Check-in time',
                        value: _checkInTime == null ? (AppLocalizations.of(context)?.select ?? 'Select') : _formatTime(_checkInTime!),
                        onTap: _pickCheckInTime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeTile(
                        label: AppLocalizations.of(context)?.checkOutTime ?? 'Check-out time',
                        value: _checkOutTime == null ? (AppLocalizations.of(context)?.select ?? 'Select') : _formatTime(_checkOutTime!),
                        onTap: _pickCheckOutTime,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          const SizedBox(height: 16),
          
          // Guests Section
          _buildSectionCard(
            icon: Icons.people_alt_rounded,
            title: AppLocalizations.of(context)?.guestsLabel ?? 'Guests',
            child: _buildGuestCounters(),
          ),
          const SizedBox(height: 16),
          
          // Special Requests Section
          _buildSectionCard(
            icon: Icons.note_alt_rounded,
            title: AppLocalizations.of(context)?.specialRequestsOptional ?? 'Special Requests',
            child: TextField(
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Add any special requests or notes for the host...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
              ),
              onChanged: (v) => _specialRequests = v.trim(),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSectionCard({required IconData icon, required String title, required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildIdVerificationStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? theme.colorScheme.surface : Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identity Verification',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This host requires a photo of your government-issued ID to proceed with booking.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            UnifiedCard(
              title: 'Upload your ID',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_seekerIdImageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _seekerIdImageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _uploadingSeekerId ? null : () => _pickAndUploadId(camera: false),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Replace'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _uploadingSeekerId ? null : () => setState(() => _seekerIdImageUrl = null),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                        ),
                      ],
                    ),
                  ] else ...[
                    if (_uploadingSeekerId)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (!_uploadingSeekerId)
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _pickAndUploadId(camera: false),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Choose from gallery'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _pickAndUploadId(camera: true),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Take photo'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _uploadingSeekerId ? null : _useSavedId,
                            icon: const Icon(Icons.badge_outlined),
                            label: const Text('Use saved ID'),
                          ),
                        ],
                      ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Note: Your ID is securely stored and only shared with the host for verification.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildPriceSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard() {
    if (_listing == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Image background
            CachedNetworkImage(
              imageUrl: _listing!.images.first,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: double.infinity,
                height: 160,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
            // Gradient overlay
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            // Content
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              top: 50, // Reserve space for price badge at top
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 0), // Full width at bottom
                    child: Text(
                      _listing!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 15, color: Colors.white.withValues(alpha: 0.95)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _listing!.location,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.98),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            shadows: const [
                              Shadow(
                                color: Colors.black38,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${_listing!.rating}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Price badge
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  CurrencyFormatter.formatPricePerUnit(
                    _basePrice,
                    _isHourlyVehicle ? 'hour' : (_isVehicle ? 'day' : 'month'),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCalendar() {
    // Calendar removed as per requirement; keep method for backward compatibility
    return const SizedBox.shrink();
  }

  // ignore: unused_element
  Widget _buildDateSummary() {
    return UnifiedCard(
      title: AppLocalizations.of(context)?.selectedDates ?? 'Selected Dates',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.checkIn ?? 'Check-in',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _checkInDate == null ? (AppLocalizations.of(context)?.select ?? 'Select') : _formatDate(_checkInDate!),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.checkOut ?? 'Check-out',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _checkOutDate == null ? (AppLocalizations.of(context)?.select ?? 'Select') : _formatDate(_checkOutDate!),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isHourlyVehicle
              ? '$_hours ${AppLocalizations.of(context)?.hours ?? 'hours'}'
              : (_isVehicle
                  ? '$_nights ${AppLocalizations.of(context)?.days ?? 'days'}'
                  : '$_months ${AppLocalizations.of(context)?.months ?? 'months'}'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCounters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGuestCounter(
          AppLocalizations.of(context)?.adults ?? 'Adults',
          AppLocalizations.of(context)?.ages13OrAbove ?? 'Ages 13 or above',
          _adults,
          (value) {
          setState(() => _adults = value);
          _recalculatePrice();
        },
          min: 1,
        ),
        _buildGuestCounter(
          AppLocalizations.of(context)?.children ?? 'Children',
          AppLocalizations.of(context)?.ages2To12 ?? 'Ages 2-12',
          _children,
          (value) {
          setState(() => _children = value);
          _recalculatePrice();
        }),
        _buildGuestCounter(
          AppLocalizations.of(context)?.infants ?? 'Infants',
          AppLocalizations.of(context)?.under2 ?? 'Under 2',
          _infants,
          (value) {
          setState(() => _infants = value);
        }),
      ],
    );
  }

  Widget _buildGuestCounter(String title, String subtitle, int count, Function(int) onChanged, {int min = 0}) {
    return UnifiedCard(
      dense: true,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: count > min ? () => onChanged(count - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: count < 10 ? () => onChanged(count + 1) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    return UnifiedCard(
      title: AppLocalizations.of(context)?.priceBreakdown ?? 'Price Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildPriceRow(
            _isHourlyVehicle
              ? '${CurrencyFormatter.formatPricePerUnit(_basePrice, 'hour')} x $_hours ${AppLocalizations.of(context)?.hours ?? 'hours'}'
              : (_isVehicle
                  ? '${CurrencyFormatter.formatPricePerUnit(_basePrice, 'day')} x $_nights ${AppLocalizations.of(context)?.days ?? 'days'}'
                  : '${CurrencyFormatter.formatPricePerUnit(_basePrice, 'month')} x $_months ${AppLocalizations.of(context)?.months ?? 'months'}'),
            _isHourlyVehicle ? (_basePrice * _hours) : (_isVehicle ? (_basePrice * _nights) : (_basePrice * _months)),
          ),
          _buildPriceRow(AppLocalizations.of(context)?.serviceFee ?? 'Service fee', _serviceFee),
          _buildPriceRow(AppLocalizations.of(context)?.taxes ?? 'Taxes', _taxes),
          if (_couponDiscount > 0)
            _buildPriceRow(AppLocalizations.of(context)?.couponCode ?? 'Coupon', -_couponDiscount),
          if (_referralDiscount > 0) _buildPriceRow(AppLocalizations.of(context)?.referralCredits ?? 'Referral credits', -_referralDiscount),
          const Divider(),
          _buildPriceRow(AppLocalizations.of(context)?.total ?? 'Total', _totalPrice, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: isTotal
                  ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            CurrencyFormatter.formatPrice(amount),
            textAlign: TextAlign.right,
            style: isTotal
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAddOnsStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isVehicle ? Icons.directions_car_rounded : Icons.home_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.addonsPreferences ?? 'Add-ons & Preferences',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'Enhance your ${_isVehicle ? "rental" : "stay"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._addOns.values.map((a) {
            final totalCost = a.calculateCost(_nights, _hours, _isHourlyVehicle);
            final priceText = a.category == 'vehicle' && a.perDay
                ? '${CurrencyFormatter.formatPrice(a.price)}/day'
                : CurrencyFormatter.formatPrice(totalCost);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      a.selected = !a.selected;
                      _recalculatePrice();
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: a.selected
                          ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08)
                          : (isDark ? theme.colorScheme.surface : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: a.selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.3),
                        width: a.selected ? 2 : 1,
                      ),
                      boxShadow: a.selected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                            ],
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: a.selected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: a.selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: a.selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _addonTitle(a.key, a.title),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: a.selected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _addonSubtitle(a.key, a.subtitle),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              priceText,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: a.selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            if (a.perDay && totalCost != a.price)
                              Text(
                                'Total: ${CurrencyFormatter.formatPrice(totalCost)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          _buildAvailableCoupons(),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.couponCode ?? 'Coupon code',
                hintText: AppLocalizations.of(context)?.enterCouponOptional ?? 'Enter code here',
                filled: true,
                fillColor: isDark 
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : Colors.grey.shade50,
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade400,
                        Colors.deepOrange.shade500,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: _applyCoupon,
                  tooltip: 'Apply',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (v) => _couponCode = v.trim(),
              onSubmitted: (_) => _applyCoupon(),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
          const SizedBox(height: 12),
          if (_appliedCouponCode != null && _appliedCouponCode!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade50,
                    Colors.green.shade50.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.green.shade300,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Coupon Applied!',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Code: ${_appliedCouponCode!}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _appliedCouponCode = null;
                        _couponCode = '';
                        _couponDiscount = 0.0;
                        _recalculatePrice();
                      });
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_listing?.requireSeekerId == true && _seekerIdImageUrl != null && _seekerIdImageUrl!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ID attached and will be shared with host',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.green[800]),
                    ),
                  ),
                  TextButton(
                    onPressed: _showIdChangeOptions,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _applyCoupon,
              icon: const Icon(Icons.check),
              label: Text(AppLocalizations.of(context)?.apply ?? 'Apply'),
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceSummary(),
        ],
      ),
    );
  }

  Widget _buildVehicleConditionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Condition Checklist',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Document the vehicle condition before pickup. This protects both you and the owner.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._vehicleConditions.entries.map((entry) {
            return CheckboxListTile(
              value: entry.value,
              onChanged: (val) {
                setState(() {
                  _vehicleConditions[entry.key] = val ?? false;
                });
              },
              title: Text(_getConditionLabel(entry.key)),
              subtitle: Text(_getConditionDescription(entry.key)),
              secondary: _uploadingVehiclePhotos
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: Icon(
                        _vehicleConditionPhotos.containsKey(entry.key)
                            ? Icons.check_circle
                            : Icons.camera_alt_outlined,
                        color: _vehicleConditionPhotos.containsKey(entry.key)
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: _uploadingVehiclePhotos
                          ? null
                          : () => _captureConditionPhoto(entry.key),
                    ),
            );
          }),
          const SizedBox(height: 20),
          Text(
            '${_vehicleConditions.values.where((v) => v).length}/${_vehicleConditions.length} checks completed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern header with subtle background
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                  theme.colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.payment_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.paymentBilling ?? 'Payment & Billing',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Review and confirm your booking',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Security Deposit Notice for Properties
          if (!_isVehicle && _securityDeposit > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: isDark ? 0.15 : 0.1),
                    Colors.blue.withValues(alpha: isDark ? 0.08 : 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Color(0xFF1976D2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security Deposit Required',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatPrice(_securityDeposit),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This refundable deposit will be held and returned within 7 days after checkout, subject to property inspection.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (!widget.instantBooking) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: isDark ? 0.12 : 0.08),
                    Colors.blue.withValues(alpha: isDark ? 0.06 : 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Color(0xFF1976D2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.info_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.hostApprovalNote ?? 'This listing requires host approval. You will not be charged now. We will notify you when the host approves your request.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.blue.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Payment method selection moved to BookingPaymentScreen
          // Inline card entry removed; we collect payment on BookingPaymentScreen
          _buildReferralCreditsSection(),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _agreeToTerms
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _agreeToTerms
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: _agreeToTerms
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)?.agreeTerms ?? 'I agree to the Terms & Cancellation Policies',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                InkWell(
                  onTap: () => setState(() => _acceptedHouseRules = !_acceptedHouseRules),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _acceptedHouseRules
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _acceptedHouseRules
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: _acceptedHouseRules
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I agree to the house rules (no smoking, no pets)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Violations may lead to penalties or cancellation per host policy',
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
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceSummary(),
        ],
      ),
    );
  }

  

  Widget _buildBottomBar() {
    if (_isLoading || _error != null) return const SizedBox.shrink();

    final isPhone = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.2),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Price breakdown row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatPrice(_totalPrice),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _showPriceBreakdownSheet,
                    icon: Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      'View Breakdown',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Action buttons row
              Row(
                children: [
                  // Back button (when not on first step)
                  if (_currentStep > 0) ...[
                OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.3 : 0.5),
                      width: 1.5,
                    ),
                    backgroundColor: isDark 
                        ? theme.colorScheme.surface 
                        : Colors.grey.shade50,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Primary CTA
              Expanded(
                flex: _currentStep > 0 ? 1 : 1,
                child: FilledButton(
                  onPressed: _canProceed() ? (_currentStep == _lastStepIndex() ? _confirmBooking : _nextStep) : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    backgroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getButtonText(),
                        style: TextStyle(
                          fontSize: isPhone ? 15 : 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: Colors.white,
                        ),
                      ),
                      if (_currentStep < _lastStepIndex()) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                      ],
                    ],
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

  void _recalculatePrice() {
    if (_checkInDate != null && _checkOutDate != null) {
      _nights = _checkOutDate!.difference(_checkInDate!).inDays;
      if (_isHourlyVehicle) {
        // Compute hours using date + time
        final start = DateTime(
          _checkInDate!.year, _checkInDate!.month, _checkInDate!.day,
          (_checkInTime?.hour ?? 9), (_checkInTime?.minute ?? 0),
        );
        final end = DateTime(
          _checkOutDate!.year, _checkOutDate!.month, _checkOutDate!.day,
          (_checkOutTime?.hour ?? 17), (_checkOutTime?.minute ?? 0),
        );
        _hours = end.isAfter(start) ? end.difference(start).inHours : 0;
      } else {
        _hours = 0;
      }
    } else {
      _nights = 0;
      _hours = 0;
    }
    // Months: ceil of days/30 for properties
    _months = _nights == 0 ? 0 : ((_nights + 29) ~/ 30);
    // Calculate add-ons total with category-specific pricing
    _addOnsTotal = _addOns.values
        .where((a) => a.selected)
        .fold(0.0, (sum, addon) => sum + addon.calculateCost(_nights, _hours, _isHourlyVehicle));
    final subtotal = _isHourlyVehicle
        ? (_basePrice * _hours)
        : (_isVehicle ? (_basePrice * _nights) : (_basePrice * _months));
    _serviceFee = subtotal * 0.10; // 10% service fee
    _taxes = subtotal * 0.08; // 8% taxes
    final discount = _couponDiscount;
    // Total before referral credits
    double beforeReferral = subtotal + _addOnsTotal + _serviceFee + _taxes - discount;
    // Clamp referral discount to available, max payable, and 10% of total payable
    final availableTokens = ref.read(referralServiceProvider).totalTokens;
    final maxApplicable = beforeReferral.floor();
    final capByTotal = (beforeReferral * 0.10).floor();
    int allowed = availableTokens;
    if (maxApplicable >= 0 && maxApplicable < allowed) allowed = maxApplicable;
    if (capByTotal < allowed) allowed = capByTotal;
    if (_referralDiscount > allowed) {
      _referralDiscount = allowed.toDouble();
      _referralTokensApplied = _referralDiscount.toInt();
    }
    _totalPrice = beforeReferral - _referralDiscount;
  }


  bool _canProceed() {
    // 0: Details
    if (_currentStep == 0) {
      // For short-stay bookings in this screen, require check-in and check-out dates
      final hasDates = _checkInDate != null && _checkOutDate != null;
      return _adults > 0 && hasDates;
    }
    // 1: Add-ons
    if (_currentStep == 1) {
      return true;
    }
    // Optional ID step (when required by listing)
    if (_requiresIdUpload() && _currentStep == _idStepIndex()) {
      return _seekerIdImageUrl != null && _seekerIdImageUrl!.isNotEmpty;
    }
    // Payment step (index depends on whether ID step exists)
    if (_currentStep == _paymentStepIndex()) {
      if (!widget.instantBooking) {
        // For request-based, require agreement to terms and house rules
        return _agreeToTerms && _acceptedHouseRules;
      }
      // For instant booking, we collect actual payment in BookingPaymentScreen,
      // so only require agreement to terms and house rules here.
      return _agreeToTerms && _acceptedHouseRules;
    }
    // Review step
    if (_currentStep == _reviewStepIndex()) {
      return true;
    }
    return false;
  }

  String _getButtonText() {
    final t = AppLocalizations.of(context);
    if (_currentStep == 0) {
      return t?.continueToAddOns ?? 'Continue to Add-ons';
    }
    if (_currentStep == 1) {
      // If ID step is required, go to ID; otherwise go to Payment
      return _requiresIdUpload()
          ? 'Continue to Verification'
          : (t?.continueToPayment ?? 'Continue to Payment');
    }
    if (_requiresIdUpload() && _currentStep == _idStepIndex()) {
      return t?.continueToPayment ?? 'Continue to Payment';
    }
    if (_currentStep == _paymentStepIndex()) {
      return widget.instantBooking
          ? (t?.reviewAndConfirm ?? 'Review & Confirm')
          : (t?.reviewRequest ?? 'Review Request');
    }
    if (_currentStep == _reviewStepIndex()) {
      return widget.instantBooking
          ? (t?.payAndConfirm ?? 'Pay & Confirm')
          : (t?.submitRequest ?? 'Submit Request');
    }
    return t?.continueAction ?? 'Continue';
  }

  void _nextStep() {
    if (_currentStep < _lastStepIndex()) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _confirmBooking();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _confirmBooking() async {
    final auth = ref.read(authProvider);
    // Capture notifiers upfront to avoid using `ref` after awaits
    final bookingNotifier = ref.read(bs.bookingProvider.notifier);
    final notificationNotifier = ref.read(notificationProvider.notifier);
    final referralNotifier = ref.read(referralServiceProvider.notifier);
    final monetizationNotifier = ref.read(monetizationServiceProvider.notifier);
    final t = AppLocalizations.of(context);
    // KYC verification removed - users can book without KYC

    final now = DateTime.now();
    final checkIn = _checkInDate ?? now.add(const Duration(days: 1));
    final checkOut = _checkOutDate ?? checkIn.add(const Duration(days: 1));
    final bookingId = 'bk_${DateTime.now().millisecondsSinceEpoch}';
    final userId = auth.user?.id ?? 'user_demo';

    if (!widget.instantBooking) {
      // Request-based booking: create pending record and notify
      final pending = bs.Booking(
        id: bookingId,
        listingId: widget.listingId,
        userId: userId,
        ownerId: 'owner_demo',
        checkIn: checkIn,
        checkOut: checkOut,
        totalPrice: _totalPrice,
        status: bs.BookingStatus.pending,
        specialRequests: _specialRequests.isEmpty ? null : _specialRequests,
        createdAt: now,
        updatedAt: now,
        paymentInfo: const bs.PaymentInfo(method: 'Request', isPaid: false),
        seekerIdImage: _requiresIdUpload() ? _seekerIdImageUrl : null,
      );
      await bookingNotifier.createBooking(pending);
      if (!mounted) return;
      await notificationNotifier.addNotification(
        AppNotification(
          id: 'notif_$bookingId',
          title: t?.bookingRequestSentTitle ?? 'Booking Request Sent',
          body: t?.bookingRequestSentBody ?? "Your request has been sent to the host. We will notify you when it's approved.",
          type: 'booking',
          timestamp: DateTime.now(),
          data: {'bookingId': bookingId, 'status': 'pending'},
        ),
      );
      if (!mounted) return;
      context.go('/booking/requested/$bookingId');
      return;
    }

    // Instant booking: route to unified BookingPaymentScreen and await result
    try {
      final currency = CurrencyFormatter.defaultCurrency;
      final payResult = await context.push('/book/${widget.listingId}/payment', extra: {
        'amount': _totalPrice,
        'currency': currency,
      });

      if (!mounted) return;

      if (payResult is Map && (payResult['success'] == true)) {
        final String? txnId = payResult['transactionId'] as String?;
        final String method = (payResult['method'] as String?) ?? 'card';
        final confirmed = bs.Booking(
          id: bookingId,
          listingId: widget.listingId,
          userId: userId,
          ownerId: 'owner_demo',
          checkIn: checkIn,
          checkOut: checkOut,
          totalPrice: _totalPrice,
          status: bs.BookingStatus.confirmed,
          specialRequests: _specialRequests.isNotEmpty ? _specialRequests : null,
          createdAt: now,
          updatedAt: now,
          paymentInfo: bs.PaymentInfo(
            method: method,
            transactionId: txnId,
            isPaid: method != 'cash' && method != 'bankTransfer',
            paidAt: (method != 'cash' && method != 'bankTransfer') ? DateTime.now() : null,
          ),
          seekerIdImage: _requiresIdUpload() ? _seekerIdImageUrl : null,
        );
        await bookingNotifier.createBooking(confirmed);
        // Deduct referral tokens applied (only for successful instant booking)
        if (_referralTokensApplied > 0) {
          await referralNotifier.redeemTokens(
            _referralTokensApplied,
            'Booking discount #$bookingId',
          );
        }
        // Record commission transaction for the platform (stub)
        // Use host gross (pre service fee/taxes, excluding platform-funded coupons and referral credits) as base
        final hostGross = (((_isHourlyVehicle
          ? (_basePrice * _hours)
          : (_isVehicle ? (_basePrice * _nights) : (_basePrice * _months)))) + _addOnsTotal).clamp(0.0, double.infinity);
        await monetizationNotifier.collectCommission(
          hostGross,
          bookingId: bookingId,
          ownerId: 'owner_demo',
        );
        // Notify user of confirmed booking
        await notificationNotifier.addNotification(
          AppNotification(
            id: 'notif_$bookingId',
            title: t?.bookingConfirmedNotificationTitle ?? 'Booking Confirmed',
            body: t?.bookingConfirmedNotificationBody ?? 'Your booking is confirmed! Tap to view details.',
            type: 'booking',
            timestamp: DateTime.now(),
            data: {'bookingId': bookingId, 'status': 'confirmed'},
          ),
        );
        if (!mounted) return;
        // Standard booking confirmation
        context.go('/booking/confirmed/$bookingId');
      } else {
        // Payment failed or cancelled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t?.paymentFailed ?? 'Payment failed or cancelled')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t?.paymentErrorWithReason(e.toString()) ?? 'Payment error: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final res = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _checkInDate != null && _checkOutDate != null
          ? DateTimeRange(start: _checkInDate!, end: _checkOutDate!)
          : null,
    );
    if (res != null) {
      setState(() {
        _checkInDate = res.start;
        _checkOutDate = res.end;
        // If hourly vehicle and times are not set yet, provide sensible defaults
        if (_isHourlyVehicle) {
          _checkInTime ??= const TimeOfDay(hour: 9, minute: 0);
          _checkOutTime ??= const TimeOfDay(hour: 17, minute: 0);
        }
        _recalculatePrice();
      });
    }
  }

  // Time selection helpers (for hourly vehicle bookings)
  Widget _buildTimeTile({required String label, required String value, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $suffix';
  }

  Future<void> _pickCheckInTime() async {
    final res = await showTimePicker(context: context, initialTime: _checkInTime ?? const TimeOfDay(hour: 9, minute: 0));
    if (res != null) {
      setState(() {
        _checkInTime = res;
        _recalculatePrice();
      });
    }
  }

  Future<void> _pickCheckOutTime() async {
    final res = await showTimePicker(context: context, initialTime: _checkOutTime ?? const TimeOfDay(hour: 17, minute: 0));
    if (res != null) {
      setState(() {
        _checkOutTime = res;
        _recalculatePrice();
      });
    }
  }

  Future<void> _pickAndUploadId({required bool camera}) async {
    try {
      setState(() => _uploadingSeekerId = true);
      final imageService = ref.read(imageServiceProvider);
      final img = camera
          ? await imageService.pickImageFromCamera()
          : await imageService.pickImageFromGallery();
      if (img == null) {
        setState(() => _uploadingSeekerId = false);
        return;
      }
      final url = await imageService.uploadImage(img);
      if (!mounted) return;
      setState(() {
        _seekerIdImageUrl = url;
        _uploadingSeekerId = false;
      });
      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload ID image')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingSeekerId = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload ID image: $e')),
      );
    }
  }

  Future<void> _useSavedId() async {
    try {
      setState(() => _uploadingSeekerId = true);
      final profile = await KycService.instance.getProfile();
      String? path = profile.frontIdPath;

      // If KYC has no saved front ID yet, fall back to the ID uploaded in Profile → Edit Profile
      if (path == null || path.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final profileIdPath = prefs.getString('user_id_document_path');
          if (profileIdPath != null && profileIdPath.isNotEmpty) {
            path = profileIdPath;
          }
        } catch (_) {}
      }

      if (path == null || path.isEmpty) {
        if (mounted) {
          setState(() => _uploadingSeekerId = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No uploaded ID found.\nPlease open your Profile → Edit Profile → ID Verification section to upload your ID first, then return here and tap "Use saved ID".',
              ),
            ),
          );
        }
        return;
      }
      final imageService = ref.read(imageServiceProvider);
      final xfile = XFile(path);
      final url = await imageService.uploadImage(xfile);
      if (!mounted) return;
      setState(() {
        _seekerIdImageUrl = url;
        _uploadingSeekerId = false;
      });
      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to attach saved ID. Please try uploading again.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your uploaded ID has been attached successfully.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingSeekerId = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to attach saved ID: $e')),
      );
    }
  }

  Widget _buildDateTile({required String label, required String value, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  Widget _buildReviewStep() {
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t?.reviewAndConfirm ?? 'Review & Confirm',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildListingCard(),
          const SizedBox(height: 16),
          Text('${t?.guestsLabel ?? 'Guests'}: '
              '$_adults ${t?.adults ?? 'adults'}, '
              '$_children ${t?.children ?? 'children'}, '
              '$_infants ${t?.infants ?? 'infants'}'),
          Text('${t?.datesLabel ?? 'Dates'}: '
              '${_checkInDate != null ? _formatDate(_checkInDate!) : '—'} → '
              '${_checkOutDate != null ? _formatDate(_checkOutDate!) : '—'}'),
          if (_specialRequests.isNotEmpty) Text('${t?.requestsLabel ?? 'Requests'}: $_specialRequests'),
          const SizedBox(height: 12),
          if (_addOns.values.any((a) => a.selected)) ...[
            Text('${t?.addonsLabel ?? 'Add-ons'}:', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._addOns.values.where((a) => a.selected).map((a) => Text('• ${_addonTitle(a.key, a.title)} (${CurrencyFormatter.formatPrice(a.price)})')),
            const SizedBox(height: 12),
          ],
          _buildPriceSummary(),
        ],
      ),
    );
  }

  String _addonTitle(String key, String fallback) {
    final t = AppLocalizations.of(context);
    switch (key) {
      case 'airport_pickup':
        return t?.addonAirportPickup ?? fallback;
      case 'breakfast':
        return t?.addonBreakfast ?? fallback;
      case 'extra_bed':
        return t?.addonExtraBed ?? fallback;
      default:
        return fallback;
    }
  }

  String _addonSubtitle(String key, String fallback) {
    final t = AppLocalizations.of(context);
    switch (key) {
      case 'airport_pickup':
        return t?.addonAirportPickupSubtitle ?? fallback;
      case 'breakfast':
        return t?.addonBreakfastSubtitle ?? fallback;
      case 'extra_bed':
        return t?.addonExtraBedSubtitle ?? fallback;
      default:
        return fallback;
    }
  }

  Widget _buildAvailableCoupons() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final availableCoupons = ref.read(couponServiceProvider.notifier).getAvailableCoupons();
    
    if (availableCoupons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_offer_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Available Coupons',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...availableCoupons.asMap().entries.map((entry) {
          final i = entry.key;
          final coupon = entry.value;
          final isApplied = _appliedCouponCode == coupon.code;
          final daysLeft = coupon.validUntil?.difference(DateTime.now()).inDays;
          final isLast = i == availableCoupons.length - 1;

          return Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isApplied ? null : () {
                  setState(() {
                    _couponCode = coupon.code;
                  });
                  _applyCoupon();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: isApplied
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                              theme.colorScheme.primary.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isApplied
                        ? null
                        : (isDark ? theme.colorScheme.surface : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isApplied
                          ? theme.colorScheme.primary.withValues(alpha: 0.5)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.2)),
                      width: isApplied ? 2 : 1,
                    ),
                    boxShadow: isApplied
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                          ],
                  ),
                  child: Row(
                    children: [
                      // Coupon Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isApplied
                                ? [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withValues(alpha: 0.8),
                                  ]
                                : [
                                    Colors.orange,
                                    Colors.deepOrange,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (isApplied
                                      ? theme.colorScheme.primary
                                      : Colors.orange)
                                  .withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isApplied ? Icons.check_circle_rounded : Icons.sell_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Coupon Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isApplied
                                        ? theme.colorScheme.primary
                                        : Colors.deepOrange,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    coupon.code,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    coupon.isPercentage
                                        ? '${coupon.amount.toInt()}% OFF'
                                        : '${CurrencyFormatter.formatPrice(coupon.amount)} OFF',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isApplied
                                          ? theme.colorScheme.primary
                                          : Colors.deepOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              coupon.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (coupon.description != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                coupon.description!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (daysLeft != null && daysLeft <= 7) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: daysLeft <= 3 ? Colors.red : Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expires in $daysLeft ${daysLeft == 1 ? "day" : "days"}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: daysLeft <= 3 ? Colors.red : Colors.amber[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Apply/Applied Badge
                      if (isApplied)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'APPLIED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _applyCoupon() {
    setState(() {
      final code = _couponCode.trim().toUpperCase();
      // Enforce one coupon per booking. Clear existing to change.
      if ((_appliedCouponCode != null && _appliedCouponCode!.isNotEmpty) && code != _appliedCouponCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only one coupon can be applied. Clear current coupon to apply another.')),
        );
        return;
      }
      if (code.isEmpty) {
        _couponDiscount = 0.0;
        _appliedCouponCode = null;
        _recalculatePrice();
        return;
      }

      final svc = ref.read(couponServiceProvider.notifier);
      final coupon = svc.getByCode(code);

      if (coupon == null) {
        _couponDiscount = 0.0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.invalidCoupon ?? 'Invalid coupon')),
        );
        _recalculatePrice();
        return;
      }

      final rentBase = _isHourlyVehicle
          ? (_basePrice * _hours)
          : (_isVehicle ? (_basePrice * _nights) : (_basePrice * _months));
      final grossBeforeTokens = rentBase + _addOnsTotal + _serviceFee + _taxes;
      final base = coupon.applyOnBase ? rentBase : grossBeforeTokens;

      if ((coupon.minSpend ?? 0) > 0 && base < (coupon.minSpend ?? 0)) {
        _couponDiscount = 0.0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.invalidCoupon ?? 'Coupon not applicable: minimum spend not met')),
        );
        _recalculatePrice();
        return;
      }

      double discount;
      if (coupon.isPercentage) {
        discount = (base * (coupon.amount / 100)).clamp(0, base);
      } else {
        discount = coupon.amount.clamp(0, base);
      }

      _couponDiscount = discount;
      _appliedCouponCode = code;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.couponApplied10 ?? 'Coupon applied')),
      );
      _recalculatePrice();
    });
  }

  void _initializeAddOns() {
    // Load appropriate add-ons based on listing category
    if (_isVehicle) {
      _addOns = Map.from(_vehicleAddOns);
    } else {
      _addOns = Map.from(_propertyAddOns);
    }
  }
  
  void _calculateSecurityDeposit() {
    if (!_isVehicle && _listing != null) {
      // For properties: calculate as percentage of total rent or fixed amount
      // Example: 1 month's rent or minimum $500
      final monthlyRent = _basePrice > 0 ? _basePrice : (_listing!.price);
      _securityDeposit = monthlyRent.clamp(500.0, double.infinity);
    } else {
      _securityDeposit = 0; // No deposit for vehicles in this example
    }
  }
  
  String _getConditionLabel(String key) {
    switch (key) {
      case 'exterior_front':
        return 'Exterior - Front';
      case 'exterior_back':
        return 'Exterior - Back';
      case 'exterior_left':
        return 'Exterior - Left Side';
      case 'exterior_right':
        return 'Exterior - Right Side';
      case 'interior_front':
        return 'Interior - Front Seats';
      case 'interior_back':
        return 'Interior - Back Seats';
      case 'dashboard':
        return 'Dashboard & Controls';
      case 'fuel_level':
        return 'Fuel Level';
      default:
        return key;
    }
  }
  
  String _getConditionDescription(String key) {
    switch (key) {
      case 'exterior_front':
        return 'Check for scratches, dents on hood, bumper, windshield';
      case 'exterior_back':
        return 'Check rear bumper, tail lights, trunk';
      case 'exterior_left':
        return 'Check doors, mirrors, windows on left side';
      case 'exterior_right':
        return 'Check doors, mirrors, windows on right side';
      case 'interior_front':
        return 'Check seats, seatbelts, floor mats';
      case 'interior_back':
        return 'Check rear seats, floor condition';
      case 'dashboard':
        return 'Check all controls, indicators, AC/heating';
      case 'fuel_level':
        return 'Note the current fuel level';
      default:
        return '';
    }
  }
  
  Future<void> _captureConditionPhoto(String conditionKey) async {
    setState(() => _uploadingVehiclePhotos = true);
    try {
      final imageService = ref.read(imageServiceProvider);
      final image = await imageService.pickImageFromCamera();
      
      if (image != null) {
        // Store the image path temporarily
        // In production, you would upload this to cloud storage
        setState(() {
          _vehicleConditionPhotos[conditionKey] = image.path;
          _vehicleConditions[conditionKey] = true; // Auto-check when photo is added
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${_getConditionLabel(conditionKey)} documented'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingVehiclePhotos = false);
      }
    }
  }

  @override
  void dispose() {
    // Clear immersive route flag on exit
    ref.read(immersiveRouteOpenProvider.notifier).state = false;
    _referralCtrl.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Helper types
}

class _AddOn {
  final String key;
  final String title;
  final String subtitle;
  final double price; // base price
  final String category; // 'property' or 'vehicle'
  final bool perDay; // for vehicles: true = per day, false = one-time
  bool selected = false;
  
  _AddOn(
    this.key,
    this.title,
    this.subtitle,
    this.price, {
    this.category = 'property',
    this.perDay = false,
  });
  
  // Calculate total cost based on rental duration
  double calculateCost(int days, int hours, bool isHourlyVehicle) {
    if (category == 'vehicle' && perDay) {
      // Per-day vehicle add-on
      if (isHourlyVehicle) {
        // For hourly rentals, charge per day (rounded up)
        final rentedDays = (hours / 24).ceil();
        return price * rentedDays;
      } else {
        // For daily rentals
        return price * days;
      }
    }
    // Property add-ons or one-time vehicle add-ons
    return price;
  }
}