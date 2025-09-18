import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/responsive_layout.dart';
import '../../app/app_state.dart';
import '../../core/widgets/tab_back_handler.dart';

class ResponsiveOnboardingScreen extends ConsumerStatefulWidget {
  final int? initialPage;
  
  const ResponsiveOnboardingScreen({super.key, this.initialPage});

  @override
  ConsumerState<ResponsiveOnboardingScreen> createState() => _ResponsiveOnboardingScreenState();
}

class _ResponsiveOnboardingScreenState extends ConsumerState<ResponsiveOnboardingScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  final int _totalPages = 5;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _iconController;
  late AnimationController _floatController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _floatAnimation;
  
  // Fixed sizing like splash screen
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  bool get isDesktop => screenWidth >= 1024;
  bool get isTablet => screenWidth >= 768 && screenWidth < 1024;
  bool get isMobile => screenWidth < 768;
  
  // Fixed icon sizes like splash screen - reduced for enterprise mobile
  double get iconSize => 100.0;
  double get innerIconSize => 80.0;
  double get iconSizeValue => 40.0;
  double get horizontalPadding => isDesktop ? 32 : 16;
  double get cardMargin => 16.0;

  @override
  void initState() {
    super.initState();
    
    // Set initial page if provided
    if (widget.initialPage != null) {
      _currentPage = widget.initialPage!;
      _pageController = PageController(initialPage: _currentPage);
    } else {
      _pageController = PageController();
    }
    
    // Initialize animation controllers with ultra-smooth timing
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );
    
    // Initialize animations with buttery-smooth curves
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.95, curve: Curves.easeOutQuart),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.05, 1.0, curve: Curves.easeOutExpo),
    ));
    
    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
    ));
    
    _iconRotationAnimation = Tween<double>(
      begin: -0.08,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOutQuart),
    ));
    
    _floatAnimation = Tween<double>(
      begin: -4.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Start initial animations
    _startAnimations();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _iconController.dispose();
    _floatController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  void _startAnimations() {
    // Ultra-smooth staggered animation start
    _iconController.forward();
    
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _fadeController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _slideController.forward();
    });
    
    // Start floating animation with repeat
    _floatController.repeat(reverse: true);
  }
  
  void _resetAndStartAnimations() {
    _fadeController.reset();
    _slideController.reset();
    _iconController.reset();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _startAnimations();
      }
    });
  }

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      icon: Icons.home,
      title: 'Welcome to Rentally',
      subtitle: 'Your trusted rental marketplace',
      description: 'Secure rentals with verified properties and trusted hosts worldwide.',
      color: const Color(0xFF4F46E5),
      gradientColors: [
        const Color(0xFFFDFDFF),
        const Color(0xFFF8FAFF),
        const Color(0xFFF1F5F9),
        const Color(0xFFE2E8F0),
        const Color(0xFFF8FAFC),
      ],
    ),
    OnboardingSlideData(
      icon: Icons.home_work_outlined,
      title: 'Find Perfect Properties',
      subtitle: 'Find Rooms, Vehicles & More',
      description: 'Discover verified properties with detailed photos and instant booking.',
      color: const Color(0xFF7C3AED),
      gradientColors: [
        const Color(0xFFFEFDFF),
        const Color(0xFFFBF8FF),
        const Color(0xFFF3F0FF),
        const Color(0xFFE9E2FF),
        const Color(0xFFF8FAFC),
      ],
    ),
    OnboardingSlideData(
      icon: Icons.shield_outlined,
      title: 'Secure Payments',
      subtitle: 'Safe and protected transactions',
      description: 'Bank-level security protects every transaction with confidence.',
      color: const Color(0xFF059669),
      gradientColors: [
        const Color(0xFFFDFEFF),
        const Color(0xFFF0FDF4),
        const Color(0xFFDCFCE7),
        const Color(0xFFBBF7D0),
        const Color(0xFFF8FAFC),
      ],
    ),
    OnboardingSlideData(
      icon: Icons.monetization_on_outlined,
      title: 'Host Your Property',
      subtitle: 'Earn money from your space',
      description: 'List your property and start earning with verified bookings.',
      color: const Color(0xFFEA580C),
      gradientColors: [
        const Color(0xFFFFFEFD),
        const Color(0xFFFFF7ED),
        const Color(0xFFFFEDD5),
        const Color(0xFFFED7AA),
        const Color(0xFFF8FAFC),
      ],
    ),
    OnboardingSlideData(
      icon: Icons.celebration,
      title: 'Get Started',
      subtitle: 'Begin your rental journey',
      description: 'Join thousands of satisfied users finding their perfect rentals.',
      color: const Color(0xFF8B5CF6),
      gradientColors: [
        const Color(0xFFFFFDFF),
        const Color(0xFFFAF5FF),
        const Color(0xFFF3E8FF),
        const Color(0xFFE9D5FF),
        const Color(0xFFF8FAFC),
      ],
      isLastSlide: true,
    ),
  ];

  void _onPageChanged(int index) {
    if (mounted) {
      setState(() {
        _currentPage = index;
      });
      // Trigger animations for new slide
      _resetAndStartAnimations();
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1 && mounted) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0 && mounted) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    // Set onboarding complete state before navigation
    ref.read(onboardingCompleteProvider.notifier).state = true;
    
    // Navigate to country selection
    if (mounted) {
      context.go('/country');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TabBackHandler(
      pageController: _pageController,
      child: Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0A0F), // Deep enterprise black
                    Color(0xFF141428), // Professional dark slate
                    Color(0xFF1E1E3F), // Rich midnight blue
                    Color(0xFF2A2D5A), // Sophisticated navy
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                )
              : RadialGradient(
                  center: const Alignment(0.0, -0.4),
                  radius: 1.5,
                  colors: _slides[_currentPage].gradientColors,
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
        ),
        child: Stack(
          children: [
            // Main content
            SafeArea(
              child: ResponsiveLayout(
                maxWidth: 600,
                child: Column(
                  children: [
                    // Page content
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: _totalPages,
                        itemBuilder: (context, index) => _buildSlide(index, theme, isDark),
                      ),
                    ),
                    
                    // Page indicators
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: isDesktop ? 24 : 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _totalPages,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? _slides[_currentPage].color
                                  : _slides[_currentPage].color.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Navigation buttons
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: isDesktop ? 32 : 24,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back button (only show after first slide)
                          if (_currentPage > 0)
                            Container(
                              width: 92,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: isDark ? LinearGradient(
                                  colors: [
                                    const Color(0xFF21262D).withOpacity(0.9),
                                    const Color(0xFF30363D),
                                  ],
                                ) : null,
                                color: isDark ? null : Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: _slides[_currentPage].color.withOpacity(0.4),
                                  width: 1.5,
                                ),
                                boxShadow: const [],
                              ),
                              child: TextButton(
                                onPressed: _previousPage,
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chevron_left,
                                      color: _slides[_currentPage].color,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Back',
                                      style: TextStyle(
                                        color: _slides[_currentPage].color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 92),
                          
                          // Next/Get Started button - positioned right
                          Container(
                            width: _currentPage == _totalPages - 1 ? 155 : 110,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _slides[_currentPage].color,
                                  _slides[_currentPage].color.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [],
                            ),
                            child: TextButton(
                              onPressed: () {
                                if (_currentPage == _totalPages - 1) {
                                  _skipOnboarding();
                                } else {
                                  _nextPage();
                                }
                              },
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentPage == _totalPages - 1
                                        ? 'Get Started'
                                        : 'Next',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    _currentPage == _totalPages - 1
                                        ? Icons.check
                                        : Icons.chevron_right,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Skip button positioned absolutely
            if (_currentPage < _totalPages - 1)
              Positioned(
                top: 50,
                right: 20,
                child: SafeArea(
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      splashColor: _slides[_currentPage].color.withOpacity(0.2),
                      highlightColor: _slides[_currentPage].color.withOpacity(0.1),
                      onTap: () {
                        _skipOnboarding();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 20 : 16, 
                          vertical: isDesktop ? 8 : 6
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _slides[_currentPage].color.withOpacity(0.3),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: _slides[_currentPage].color,
                            fontWeight: FontWeight.w600,
                            fontSize: isDesktop ? 12 : 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildSlide(int index, ThemeData theme, bool isDark) {
    final slide = _slides[index];
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
            // Enhanced 3D Icon Container with Smooth Animations
            AnimatedBuilder(
              animation: Listenable.merge([_iconController, _floatController]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: Transform.scale(
                    scale: _iconScaleAnimation.value,
                    child: Transform.rotate(
                      angle: _iconRotationAnimation.value,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(-0.1)
                          ..rotateY(0.05),
                        child: Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.3, -0.3),
                              radius: 1.2,
                              colors: [
                                Colors.white,
                                Colors.grey.shade100,
                                Colors.grey.shade200,
                              ],
                              stops: const [0.0, 0.7, 1.0],
                            ),
                            boxShadow: [
                              // Deep outer shadow
                              BoxShadow(
                                color: slide.color.withOpacity(0.25),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                                spreadRadius: -5,
                              ),
                              // Medium shadow
                              BoxShadow(
                                color: slide.color.withOpacity(0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                                spreadRadius: -3,
                              ),
                              // Close shadow
                              BoxShadow(
                                color: slide.color.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                                spreadRadius: -1,
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-0.2, -0.2),
                                radius: 0.8,
                                colors: [
                                  slide.color.withOpacity(0.95),
                                  slide.color,
                                  slide.color.withOpacity(0.7),
                                  slide.color.withOpacity(0.9),
                                ],
                                stops: const [0.0, 0.3, 0.8, 1.0],
                              ),
                              boxShadow: [
                                // Inner depth
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(2, 3),
                                  spreadRadius: -4,
                                ),
                                // Inner highlight
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.6),
                                  blurRadius: 8,
                                  offset: const Offset(-2, -2),
                                  spreadRadius: -6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Transform(
                                transform: Matrix4.identity()
                                  ..translate(0.0, -1.0, 2.0),
                                child: Icon(
                                  slide.icon,
                                  size: iconSizeValue,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.6),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                    Shadow(
                                      color: slide.color.withOpacity(0.3),
                                      offset: const Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          
            SizedBox(height: isDesktop ? 80 : isTablet ? 65 : 55),
          
            // Title with white background container - Animated
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28, 
                        vertical: 12
                      ),
                      decoration: BoxDecoration(
                        gradient: isDark 
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFF1E1E3F).withOpacity(0.9),
                                  const Color(0xFF2A2D47).withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isDark ? null : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(35),
                        border: isDark 
                            ? Border.all(
                                color: const Color(0xFF4A6CF7).withOpacity(0.4),
                                width: 1.5,
                              )
                            : null,
                        boxShadow: isDark ? [
                          BoxShadow(
                            color: const Color(0xFF4A6CF7).withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: const Color(0xFF000000).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        slide.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark 
                              ? const Color(0xFFE8E8F0)
                              : slide.color,
                          fontSize: isDesktop ? 28 : isTablet ? 24 : 20,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Subtitle + Description combined into a single info card
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: _fadeController,
                    curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
                  )),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.12),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _slideController,
                      curve: const Interval(0.25, 1.0, curve: Curves.easeOutQuint),
                    )),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: isDark 
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFF1A1A2E).withOpacity(0.8),
                                  const Color(0xFF2A2D47).withOpacity(0.6),
                                  const Color(0xFF3E4A78).withOpacity(0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isDark ? null : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: isDark 
                            ? Border.all(
                                color: const Color(0xFF4A6CF7).withOpacity(0.3),
                                width: 1.5,
                              )
                            : Border.all(
                                color: slide.color.withOpacity(0.2),
                                width: 1.0,
                              ),
                        boxShadow: isDark ? [
                          BoxShadow(
                            color: const Color(0xFF4A6CF7).withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: const Color(0xFF000000).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ] : [
                          BoxShadow(
                            color: slide.color.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Subtitle as heading
                          Text(
                            slide.subtitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isDark ? const Color(0xFF9CA3F7) : slide.color,
                              fontWeight: FontWeight.w800,
                              fontSize: isDesktop ? 19 : isTablet ? 17 : 15,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Description below
                          Text(
                            slide.description,
                            style: TextStyle(
                              color: isDark ? const Color(0xFFB8BDF7) : Colors.grey[600],
                              // color: isDark ? const Color(0xFFE5E7EB) : Colors.grey[600], // neutral off-white in dark mode
                              fontSize: isDesktop ? 14 : 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Last slide action buttons
            if (slide.isLastSlide) ...[
              const SizedBox(height: 32),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.search,
                      label: 'Search',
                      color: const Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      icon: Icons.home_work,
                      label: 'Host',
                      color: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      icon: Icons.calendar_today,
                      label: 'Book',
                      color: const Color(0xFF059669),
                    ),
                  ],
                ),
              ),
            ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final buttonSize = isDesktop ? 64.0 : isTablet ? 56.0 : 48.0;
    final iconSize = isDesktop ? 28.0 : isTablet ? 24.0 : 20.0;
    final fontSize = isDesktop ? 14.0 : isTablet ? 13.0 : 12.0;
    
    return Column(
      children: [
        Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
          ),
          child: Icon(
            icon,
            color: color,
            size: iconSize,
          ),
        ),
        SizedBox(height: isDesktop ? 12 : 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class OnboardingSlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final List<Color> gradientColors;
  final bool isLastSlide;

  OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.gradientColors,
    this.isLastSlide = false,
  });
}
