import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../services/country_service.dart';
import '../../app/app_state.dart';
import '../../utils/snackbar_utils.dart';
import 'widgets/country_list_view.dart';
import 'widgets/continue_button.dart';
import 'widgets/background_pattern_painter.dart';
import 'widgets/country_selection_header.dart';
import 'widgets/country_search_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/currency_formatter.dart';

class EnhancedCountrySelectScreen extends ConsumerStatefulWidget {
  final String? nextPath;

  const EnhancedCountrySelectScreen({super.key, this.nextPath});

  @override
  ConsumerState<EnhancedCountrySelectScreen> createState() => _EnhancedCountrySelectScreenState();
}

/// Enhanced country selection screen with professional UI and animations
/// 
/// This screen allows users to search and select their country for personalized
/// rental experiences. Features include:
/// - Animated header with pulsing icon
/// - Real-time search functionality
/// - Smooth selection animations
/// - Professional background patterns
/// - Responsive design for desktop and mobile
class _EnhancedCountrySelectScreenState extends ConsumerState<EnhancedCountrySelectScreen> 
    with TickerProviderStateMixin {
  
  // State variables
  String? selectedCountry;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredCountries = [];
  bool _isLoading = false;
  bool _hasError = false;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text;
      setState(() {
        filteredCountries = CountryService.filterCountries(query);
      });
    });
    filteredCountries = CountryService.getAllCountries();
    _tryAutoDetectCountry();
    _initializeAnimations();
    _startAnimations();
  }

  Future<void> _tryAutoDetectCountry() async {
    try {
      final detectedCountry = await CountryService.detectCountryFromLocation();
      
      if (detectedCountry != null && mounted) {
        setState(() {
          selectedCountry = detectedCountry;
        });
        
        // Update country provider
        ref.read(countryProvider.notifier).state = detectedCountry;
        
        // Show detection success message
        if (mounted) {
          SnackBarUtils.showSuccess(
            context,
            'Detected your location: $detectedCountry',
          );
        }
      }
      // Silent fail if detection doesn't work - user can select manually
    } catch (e) {
      // Silent fail - location detection is optional
    }
  }

  /// Initialize all animation controllers and animations
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: AppConstants.animationEntry,
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: AppConstants.animationMedium,
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: AppConstants.animationPulse,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  /// Start entrance animations
  void _startAnimations() {
    _fadeController.forward();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Filters countries based on search query
  void _filterCountries(String query) {
    setState(() {
      filteredCountries = CountryService.filterCountries(query);
    });
  }

  /// Handles country selection
  void _selectCountry(String countryName) {
    setState(() {
      selectedCountry = countryName;
    });
  }

  /// Handles the continue button press with loading states and navigation
  Future<void> _handleContinue() async {
    if (selectedCountry == null || _isLoading) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      // Update country in provider
      ref.read(countryProvider.notifier).state = selectedCountry;
      
      // Save to backend if user is authenticated
      final authNotifier = ref.read(authProvider.notifier);
      try {
        await authNotifier.updateCountry(selectedCountry!);
      } catch (e) {
        // If API call fails (user not authenticated or network error), continue anyway
        // Country is still saved locally
        print('Failed to update country in backend: $e');
      }
      
      // Auto-select currency based on chosen country and persist globally (if enabled)
      try {
        final prefs = await SharedPreferences.getInstance();
        // Persist selected country so user doesn't have to choose again on next app launch
        await prefs.setString('selectedCountry', selectedCountry!);

        final follow = prefs.getBool('currencyFollowCountry') ?? true;
        if (follow) {
          final code = CountryService.getCurrencyForCountry(selectedCountry!);
          await prefs.setString('currencyCode', code);
          CurrencyFormatter.setDefaultCurrency(code);
        }
      } catch (_) {}
      
      if (!mounted) return;
      _showSuccessSnackBar();
      
      if (!mounted) return;
      final next = widget.nextPath;
      if (next != null && next.isNotEmpty) {
        context.go(next);
      } else {
        // Fallback: if we can pop back, do so; otherwise go to auth
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/auth');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
      
      if (!mounted) return;
      _showErrorSnackBar();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Shows success snackbar when country is selected
  void _showSuccessSnackBar() {
    SnackBarUtils.showSuccess(
      context,
      'Welcome to Rentaly in $selectedCountry!',
    );
  }

  /// Shows error snackbar when something goes wrong
  void _showErrorSnackBar() {
    SnackBarUtils.showError(
      context,
      'Something went wrong. Please try again.',
      actionLabel: 'Retry',
      onActionPressed: _handleContinue,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= AppConstants.desktopBreakpoint;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      body: _buildBody(isDesktop, theme),
    );
  }

  /// Builds the main body with background and content
  Widget _buildBody(bool isDesktop, ThemeData theme) {
    return Container(
      decoration: _buildBackgroundGradient(theme),
      child: Stack(
        children: [
          _buildBackgroundPattern(),
          _buildFloatingOrbs(theme),
          _buildMainContent(isDesktop, theme),
        ],
      ),
    );
  }

  /// Creates the background gradient decoration
  BoxDecoration _buildBackgroundGradient(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    if (isDark) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Deep navy
            Color(0xFF1E293B), // Rich slate
            Color(0xFF334155), // Medium slate
            Color(0xFF475569), // Lighter slate
            Color(0xFF1E293B), // Back to rich
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      );
    }

    // Light theme: bright white background
    return const BoxDecoration(
      color: Colors.white,
    );
  }

  /// Builds the background pattern
  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: BackgroundPatternPainter(),
      ),
    );
  }

  /// Builds floating orbs for visual depth
  Widget _buildFloatingOrbs(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Stack(
      children: [
        // Top-right energetic orb
        Positioned(
          top: -120,
          right: -120,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark ? [
                  const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  const Color(0xFF1D4ED8).withValues(alpha: 0.08),
                  const Color(0xFF1E40AF).withValues(alpha: 0.04),
                  Colors.transparent,
                ] : [
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),
        ),
        // Bottom-left trust orb
        Positioned(
          bottom: -180,
          left: -180,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark ? [
                  const Color(0xFF10B981).withValues(alpha: 0.12),
                  const Color(0xFF059669).withValues(alpha: 0.06),
                  const Color(0xFF047857).withValues(alpha: 0.03),
                  Colors.transparent,
                ] : [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.09),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),
        ),
        // Center accent orb for energy
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          right: -100,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark ? [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  const Color(0xFF7C3AED).withValues(alpha: 0.05),
                  Colors.transparent,
                ] : [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Additional trust indicator orb
        Positioned(
          top: MediaQuery.of(context).size.height * 0.6,
          left: -80,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark ? [
                  const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  const Color(0xFFD97706).withValues(alpha: 0.04),
                  Colors.transparent,
                ] : [
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.09),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the main content with animations
  Widget _buildMainContent(bool isDesktop, ThemeData theme) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildBackButton(isDesktop, theme),
                _buildScrollableContent(isDesktop, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds the back button
  Widget _buildBackButton(bool isDesktop, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.all(isDesktop ? AppConstants.spacingL : AppConstants.spacingM),
      child: Row(
        children: [
          Hero(
            tag: 'back_button',
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: AppConstants.backButtonSize,
                height: AppConstants.backButtonSize,
                decoration: BoxDecoration(
                  gradient: isDark ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF21262D).withValues(alpha: 0.8),
                      const Color(0xFF30363D).withValues(alpha: 0.9),
                    ],
                  ) : null,
                  color: isDark 
                      ? const Color(0xFF58A6FF).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  boxShadow: isDark ? [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.50),
                      blurRadius: 24,
                      offset: const Offset(0, -10),
                    ),
                    BoxShadow(
                      color: const Color(0xFF0969DA).withValues(alpha: 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, -20),
                    ),
                  ] : [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    if (!isDark)
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                        spreadRadius: 0,
                      ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                    width: 0.5,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  onTap: () {
                    // Reset onboarding state and use GoRouter with delay
                    ref.read(onboardingCompleteProvider.notifier).state = false;
                    
                    // Use Future.delayed to avoid navigator lock
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        context.go('/onboarding?page=0');
                      }
                    });
                  },
                  hoverColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                  splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    size: AppConstants.iconSizeSmall,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable content with scale animation
  Widget _buildScrollableContent(bool isDesktop, ThemeData theme) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? AppConstants.spacingXL : AppConstants.spacingL,
                    ),
                    child: Column(
                      children: [
                        CountrySelectionHeader(
                          pulseAnimation: _pulseAnimation,
                          isDesktop: isDesktop,
                        ),
                        CountrySearchField(
                          controller: _searchController,
                          onChanged: _filterCountries,
                          isDesktop: isDesktop,
                        ),
                        CountryListView(
                          countries: filteredCountries,
                          selectedCountry: selectedCountry,
                          isDesktop: isDesktop,
                          onCountrySelected: _selectCountry,
                        ),
                      ],
                    ),
                  ),
                ),
                // Fixed button at bottom
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? AppConstants.spacingXL : AppConstants.spacingL,
                    2.0, // Minimal top padding
                    isDesktop ? AppConstants.spacingXL : AppConstants.spacingL,
                    isDesktop ? 48.0 : 40.0, // Extra large bottom padding
                  ),
                  child: ContinueButton(
                    selectedCountry: selectedCountry,
                    isLoading: _isLoading,
                    hasError: _hasError,
                    isDesktop: isDesktop,
                    onPressed: _handleContinue,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

