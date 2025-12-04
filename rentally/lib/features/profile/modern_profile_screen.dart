import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/neo/neo.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';
import '../../app/app_state.dart';
import '../../services/country_service.dart';
import '../../services/user_preferences_service.dart';
import '../../core/utils/currency_formatter.dart';

class ModernProfileScreen extends ConsumerStatefulWidget {
  const ModernProfileScreen({super.key});

  @override
  ConsumerState<ModernProfileScreen> createState() => _ModernProfileScreenState();
}

class _ModernProfileScreenState extends ConsumerState<ModernProfileScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  XFile? _avatarImage;
  XFile? _coverImage;
  XFile? _idImage;

  bool _busy = false;
  bool _isAvatarCameraHovered = false;

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFromUser();
    _loadIdDocument();
    _initCountryAndCurrency();
  }

  void _loadFromUser() {
    // Load user profile data from authenticated user
    final authState = ref.read(authProvider);
    final user = authState.user;
    
    if (user != null) {
      _nameCtrl.text = user.name;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phone ?? '';
    } else {
      // Fallback to empty values if no user is authenticated
      _nameCtrl.text = '';
      _emailCtrl.text = '';
      _phoneCtrl.text = '';
    }
    
    // Bio is not stored in backend yet, keep default
    if (_bioCtrl.text.isEmpty) {
      _bioCtrl.text = 'Passionate host and traveler. Love meeting people around the world!';
    }
  }

  Future<void> _initCountryAndCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var country = prefs.getString('selectedCountry');
      final followCountry = prefs.getBool('currencyFollowCountry') ?? true;

      if (country == null) {
        final detectedCountry = await CountryService.detectCountryFromLocation();
        if (detectedCountry != null) {
          country = detectedCountry;
          await prefs.setString('selectedCountry', detectedCountry);
        }
      }

      if (country != null) {
        ref.read(countryProvider.notifier).state = country;

        if (followCountry) {
          var currencyCode = prefs.getString('currencyCode');
          currencyCode ??= CountryService.getCurrencyForCountry(country);
          await prefs.setString('currencyCode', currencyCode);
          CurrencyFormatter.setDefaultCurrency(currencyCode);
          try {
            await ref.read(userPreferencesProvider.notifier).updateCurrency(currencyCode);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // Home screen style neumorphic shadows
  List<BoxShadow> _homeStyleShadows(ThemeData theme, bool isDark) {
    return [
      BoxShadow(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        blurRadius: 10,
        offset: const Offset(-5, -5),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: (isDark
            ? EnterpriseDarkTheme.primaryAccent
            : EnterpriseLightTheme.primaryAccent)
            .withValues(alpha: isDark ? 0.18 : 0.12),
        blurRadius: 10,
        offset: const Offset(5, 5),
        spreadRadius: 0,
      ),
    ];
  }

  Future<void> _pickAvatar() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _avatarImage = img);
  }

  Future<void> _pickCover() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _coverImage = img);
  }

  Future<void> _pickIdDocument() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _idImage = img);
      await _saveIdDocument(img.path);
    }
  }

  Future<void> _loadIdDocument() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idPath = prefs.getString('user_id_document_path');
      if (idPath != null && File(idPath).existsSync()) {
        setState(() => _idImage = XFile(idPath));
      }
    } catch (_) {}
  }

  Future<void> _saveIdDocument(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id_document_path', path);
    } catch (_) {}
  }

  Future<void> _deleteIdDocument() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id_document_path');
      setState(() => _idImage = null);
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    setState(() => _busy = true);
    try {
      // Simulate save delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Watch auth state so the screen rebuilds when authentication/user changes
    ref.watch(authProvider);

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 400));
            _loadFromUser();
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(theme, isDark),
              // Edge-to-edge badges only
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildVerificationBadges(theme, isDark),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Rest of content with standard horizontal padding
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickActions(theme, isDark),
                      const SizedBox(height: 20),
                      _buildSectionHeader(theme, 'Personal Information', Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildAboutCard(theme, isDark),
                      const SizedBox(height: 20),
                      _buildSectionHeader(theme, 'Achievements', Icons.emoji_events_outlined),
                      const SizedBox(height: 8),
                      _buildAchievements(theme, isDark),
                      const SizedBox(height: 16),
                      _buildSectionHeader(theme, 'Security & Privacy', Icons.security_outlined),
                      const SizedBox(height: 12),
                      _buildSecurityPrivacyCard(theme, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/home');
    }
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationBadges(ThemeData theme, bool isDark) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    
    Widget badge(String label, IconData icon, Color color, {bool verified = true}) {
      return NeoGlass(
        margin: EdgeInsets.only(right: isPhone ? 6 : 8),
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 8 : 10,
          vertical: isPhone ? 6 : 8,
        ),
        borderRadius: BorderRadius.circular(16),
        blur: isDark ? 10 : 0,
        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderColor: (verified ? color : Colors.grey).withValues(alpha: isDark ? 0.28 : 0.35),
        borderWidth: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              verified ? icon : Icons.pending_outlined,
              size: isPhone ? 14 : 15,
              color: verified ? color : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isPhone ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: verified ? color : Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          badge('Email Verified', Icons.mark_email_read_rounded, Colors.green.shade600),
          badge('Phone Verified', Icons.phone_enabled_rounded, Colors.blue.shade600),
          badge('ID Verified', Icons.badge_rounded, Colors.purple.shade600),
          badge('Premium Member', Icons.workspace_premium_rounded, Colors.amber.shade700),
        ],
      ),
    );
  }

  Widget _buildAchievements(ThemeData theme, bool isDark) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    
    Widget achievementTile(String title, String description, IconData icon, Color color, VoidCallback onTap) {
      return Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: _homeStyleShadows(theme, isDark),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(isPhone ? 14 : 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isPhone ? 14 : 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: isPhone ? 12 : 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        achievementTile(
          'Superhost',
          'Earned for exceptional hosting',
          Icons.military_tech_rounded,
          Colors.amber.shade700,
          () => _showAchievementDetails('Superhost', 'You\'ve been recognized as a Superhost for maintaining excellent ratings and providing outstanding service to your guests.'),
        ),
        achievementTile(
          'Early Adopter',
          'One of the first 1000 users',
          Icons.rocket_launch_rounded,
          Colors.blue.shade600,
          () => _showAchievementDetails('Early Adopter', 'Thank you for being one of our first 1000 users! Your early support helped shape Rentaly into what it is today.'),
        ),
        achievementTile(
          'Top Reviewer',
          '50+ helpful reviews written',
          Icons.rate_review_rounded,
          Colors.green.shade600,
          () => _showAchievementDetails('Top Reviewer', 'You\'ve written over 50 helpful reviews, helping other users make informed decisions. Your contributions are invaluable!'),
        ),
      ],
    );
  }

  void _showAchievementDetails(String title, String description) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Color achievementColor;
    IconData achievementIcon;
    String achievementEmoji;
    
    switch (title) {
      case 'Superhost':
        achievementColor = Colors.amber.shade700;
        achievementIcon = Icons.military_tech_rounded;
        achievementEmoji = '🏆';
        break;
      case 'Early Adopter':
        achievementColor = Colors.blue.shade600;
        achievementIcon = Icons.rocket_launch_rounded;
        achievementEmoji = '🚀';
        break;
      case 'Top Reviewer':
        achievementColor = Colors.green.shade600;
        achievementIcon = Icons.rate_review_rounded;
        achievementEmoji = '⭐';
        break;
      default:
        achievementColor = theme.colorScheme.primary;
        achievementIcon = Icons.emoji_events_rounded;
        achievementEmoji = '🎉';
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: achievementColor.withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      achievementColor.withValues(alpha: 0.15),
                      achievementColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: achievementColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: achievementColor.withValues(alpha: 0.3),
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              achievementIcon,
                              size: 48,
                              color: achievementColor,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      achievementEmoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: achievementColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surface.withValues(alpha: 0.5)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Share feature coming soon!'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: achievementColor),
                            ),
                            icon: Icon(Icons.share_rounded, color: achievementColor, size: 18),
                            label: Text(
                              'Share',
                              style: TextStyle(color: achievementColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: achievementColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Got it'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildHeader(ThemeData theme, bool isDark) {
    final cover = _coverImage;
    final avatar = _avatarImage;
    final isPhone = MediaQuery.of(context).size.width < 600;
    final selectedCountry = ref.watch(countryProvider);
    final countryFlag = selectedCountry != null
        ? CountryService.getFlagEmojiForCountry(selectedCountry)
        : null;

    return SliverAppBar(
      expandedHeight: isPhone ? 200 : 240,
      pinned: true,
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Colors.white,
        ),
        onPressed: _handleBack,
        style: IconButton.styleFrom(
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.18),
        ),
      ),
      actions: [
        IconButton(
            tooltip: 'Edit Profile',
          icon: const Icon(
            Icons.edit_outlined,
            size: 20,
            color: Colors.white,
          ),
          onPressed: _openEditSheet,
          style: IconButton.styleFrom(
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.18),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover photo background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                    theme.colorScheme.secondary.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            if (cover != null)
              Positioned.fill(
                child: kIsWeb
                    ? Image.network(
                        cover.path,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      )
                    : Image.file(
                        File(cover.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
            // Cover change button - repositioned to bottom right
            Positioned(
              bottom: 20,
              right: 16,
              child: GestureDetector(
                onTap: _pickCover,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cover',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Profile avatar and info
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar (non-editable from main profile header)
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: isPhone ? 36 : 42,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: isPhone ? 34 : 40,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                            backgroundImage: avatar != null
                                ? (kIsWeb
                                    ? NetworkImage(avatar.path)
                                    : FileImage(File(avatar.path)) as ImageProvider)
                                : null,
                            child: avatar == null
                                ? Icon(
                                    Icons.person_rounded,
                                    size: isPhone ? 32 : 38,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Name and email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _nameCtrl.text,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isPhone ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.verified,
                              size: 18,
                              color: Colors.blue[300],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _emailCtrl.text,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: isPhone ? 12 : 13,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        if (selectedCountry != null && selectedCountry.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (countryFlag != null)
                                Text(
                                  countryFlag,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isPhone ? 12 : 14,
                                  ),
                                ),
                              if (countryFlag != null) const SizedBox(width: 6),
                              Text(
                                selectedCountry,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: isPhone ? 12 : 13,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    
    Widget tile({
      required IconData icon,
      required String label,
      required String subtitle,
      required VoidCallback onTap,
      required Color color,
    }) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(isPhone ? 10 : 12),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: _homeStyleShadows(theme, isDark),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isPhone ? 8 : 9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: isPhone ? 20 : 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: isPhone ? 13 : 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: isPhone ? 11 : 12,
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

    return Row(
      children: [
        tile(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Wallet',
          subtitle: 'Manage rewards',
          onTap: () => context.push('/wallet'),
          color: Colors.purple.shade600,
        ),
        const SizedBox(width: 12),
        tile(
          icon: Icons.card_giftcard_rounded,
          label: 'Referrals',
          subtitle: 'Invite & earn',
          onTap: () => context.push('/referrals'),
          color: Colors.green.shade600,
        ),
      ],
    );
  }

  Widget _buildAboutCard(ThemeData theme, bool isDark) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isPhone ? 14 : 18),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: _homeStyleShadows(theme, isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.person_outline_rounded, _nameCtrl.text),
          const SizedBox(height: 12),
          _infoRow(Icons.email_outlined, _emailCtrl.text),
          const SizedBox(height: 12),
          _infoRow(Icons.phone_outlined, _phoneCtrl.text),
          const SizedBox(height: 12),
          _buildCountryRow(theme, isDark),
          const SizedBox(height: 12),
          _infoRow(Icons.info_outline_rounded, _bioCtrl.text, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildCountryRow(ThemeData theme, bool isDark) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    // Prioritize country from user object (database), fallback to provider state
    final selectedCountry = user?.country ?? ref.watch(countryProvider);
    final displayName = selectedCountry ?? 'Select country';
    final flag = selectedCountry != null
        ? CountryService.getFlagEmojiForCountry(selectedCountry)
        : '🌍';
    final isPhone = MediaQuery.of(context).size.width < 600;
    return InkWell(
      onTap: () => context.push('/country?next=/profile'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isPhone ? 4 : 6),
        child: Row(
          children: [
            Text(
              flag,
              style: TextStyle(fontSize: isPhone ? 18 : 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: isPhone ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium,
              ),
            ),
            Icon(
              Icons.edit_location_alt_outlined,
              size: isPhone ? 18 : 20,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSecurityPrivacyCard(ThemeData theme, bool isDark) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    
    Widget settingTile({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
      Color? iconColor,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isPhone ? 14 : 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: isPhone ? 14 : 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: _homeStyleShadows(theme, isDark),
      ),
      child: Column(
        children: [
          settingTile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            iconColor: Colors.orange.shade600,
            onTap: () {
              final email = _emailCtrl.text.trim();
              context.push(
                '/auth/reset-password',
                extra: {
                  'email': email,
                  'successPath': '/profile',
                },
              );
            },
          ),
          Divider(
            height: 1,
            indent: isPhone ? 14 : 16,
            endIndent: isPhone ? 14 : 16,
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
          ),
          settingTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Settings',
            iconColor: Colors.blue.shade600,
            onTap: () => context.push('/privacy'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {int maxLines = 1}) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.of(context).size.width < 600;
    return Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: isPhone ? 18 : null),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: isPhone ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  void _openEditSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit Profile',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 420),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Primary animation with smooth spring-like curve
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        
        // Secondary bounce for scale
        final scaleAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack, // Overshoot effect
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.96,
              end: 1.0,
            ).animate(scaleAnimation),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        final screenHeight = MediaQuery.of(context).size.height;
        final contentAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
        );

        return Align(
          alignment: Alignment.center,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.85,
                  maxWidth: 480,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141414) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(contentAnimation),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildEnterpriseHeader(theme, isDark),
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                const SizedBox(height: 32),
                                _buildEnterpriseAvatar(theme, isDark),
                                const SizedBox(height: 32),
                                _buildEnterpriseFields(theme, isDark),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                        _buildEnterpriseFooter(theme, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnterpriseHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Edit Profile',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterpriseAvatar(ThemeData theme, bool isDark) {
    final avatar = _avatarImage;
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(3), // Space for the border
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(3), // White/Dark gap between border and image
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF141414) : Colors.white,
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                backgroundImage: avatar != null
                    ? (kIsWeb ? NetworkImage(avatar.path) : FileImage(File(avatar.path)) as ImageProvider)
                    : null,
                child: avatar == null
                    ? Icon(
                        Icons.person,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) {
                setState(() => _isAvatarCameraHovered = true);
              },
              onExit: (_) {
                setState(() => _isAvatarCameraHovered = false);
              },
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() => _isAvatarCameraHovered = true);
                },
                onTapUp: (_) {
                  setState(() => _isAvatarCameraHovered = false);
                },
                onTapCancel: () {
                  setState(() => _isAvatarCameraHovered = false);
                },
                onTap: _pickAvatar,
                child: AnimatedScale(
                  scale: _isAvatarCameraHovered ? 1.25 : 1.0,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isAvatarCameraHovered ? Colors.white : theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF141414) : Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: _isAvatarCameraHovered ? 0.3 : 0.1),
                          blurRadius: _isAvatarCameraHovered ? 10 : 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: _isAvatarCameraHovered ? theme.colorScheme.primary : Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterpriseFields(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EnterpriseTextField(
          label: 'Full Name',
          controller: _nameCtrl,
          isDark: isDark,
          theme: theme,
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        _EnterpriseTextField(
          label: 'Email',
          controller: _emailCtrl,
          isDark: isDark,
          theme: theme,
          keyboardType: TextInputType.emailAddress,
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 20),
        _EnterpriseTextField(
          label: 'Phone',
          controller: _phoneCtrl,
          isDark: isDark,
          theme: theme,
          keyboardType: TextInputType.phone,
          icon: Icons.phone_outlined,
        ),
        const SizedBox(height: 20),
        _EnterpriseTextField(
          label: 'Bio',
          controller: _bioCtrl,
          isDark: isDark,
          theme: theme,
          maxLines: 3,
          icon: Icons.edit_note_rounded,
          hintText: 'Tell others about yourself, your interests, and what makes you unique',
        ),
        const SizedBox(height: 24),
        _buildIdVerificationSection(theme, isDark),
      ],
    );
  }

  Widget _buildEnterpriseFooter(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _saveProfile();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdVerificationSection(ThemeData theme, bool isDark) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    final Widget idCard = _idImage == null
        ? _buildIdUploadCard(theme, isDark)
        : _buildIdPreviewCard(theme, isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.badge_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('ID Verification', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Upload your government ID for property/vehicle bookings',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.center,
          child: isPhone
              ? idCard
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: idCard,
                ),
        ),
      ],
    );
  }

  Widget _buildIdUploadCard(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _pickIdDocument,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isDark ? EnterpriseDarkTheme.inputBackground : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.22) : theme.colorScheme.outline, width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? EnterpriseDarkTheme.primaryAccent.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_photo_alternate_outlined, color: isDark ? EnterpriseDarkTheme.primaryAccent : theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(height: 12),
            Text('Upload ID Document', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Driver License, Passport, or Government ID', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildIdPreviewCard(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? EnterpriseDarkTheme.inputBackground : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? EnterpriseDarkTheme.primaryAccent.withValues(alpha: 0.3) : theme.colorScheme.primary.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.file(File(_idImage!.path), height: 120, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.verified, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(child: Text('ID Uploaded', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600))),
                TextButton.icon(
                  onPressed: _pickIdDocument,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Replace'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: _deleteIdDocument,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: theme.colorScheme.error,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _EnterpriseTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final ThemeData theme;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData icon;
  final String? hintText;

  const _EnterpriseTextField({
    required this.label,
    required this.controller,
    required this.isDark,
    required this.theme,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText ?? 'Enter your ${label.toLowerCase()}',
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 12,
        ),
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontSize: 12,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark 
                ? EnterpriseDarkTheme.primaryAccent.withValues(alpha: 0.1)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDark 
                ? EnterpriseDarkTheme.primaryAccent
                : theme.colorScheme.primary,
            size: 16,
          ),
        ),
        filled: true,
        fillColor: isDark ? EnterpriseDarkTheme.inputBackground : theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.22) : theme.colorScheme.outline,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.22) : theme.colorScheme.outline,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? EnterpriseDarkTheme.primaryAccent : theme.colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
