import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/neo/neo.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';

class ModernProfileScreen extends ConsumerStatefulWidget {
  const ModernProfileScreen({super.key});

  @override
  ConsumerState<ModernProfileScreen> createState() => _ModernProfileScreenState();
}

class _ModernProfileScreenState extends ConsumerState<ModernProfileScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  XFile? _avatarImage;
  XFile? _coverImage;

  bool _busy = false;

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFromUser();
  }

  void _loadFromUser() {
    // Load user profile data - currently using placeholder data
    _nameCtrl.text = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'John Doe';
    _emailCtrl.text = _emailCtrl.text.isNotEmpty ? _emailCtrl.text : 'john.doe@example.com';
    _phoneCtrl.text = _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : '+1 (555) 123-4567';
    if (_bioCtrl.text.isEmpty) {
      _bioCtrl.text = 'Passionate host and traveler. Love meeting people around the world!';
    }
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
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        blurRadius: 10,
        offset: const Offset(-5, -5),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: (isDark
            ? EnterpriseDarkTheme.primaryAccent
            : EnterpriseLightTheme.primaryAccent)
            .withOpacity(isDark ? 0.18 : 0.12),
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

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.background : Colors.white,
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
            color: theme.colorScheme.primary.withOpacity(0.1),
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
        backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderColor: (verified ? color : Colors.grey).withOpacity(isDark ? 0.28 : 0.35),
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
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
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
                        colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
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
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
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
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: achievementColor.withOpacity(0.1),
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
                      achievementColor.withOpacity(0.15),
                      achievementColor.withOpacity(0.05),
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
                              color: achievementColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: achievementColor.withOpacity(0.3),
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
                            ? theme.colorScheme.surface.withOpacity(0.5)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
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

    return SliverAppBar(
      expandedHeight: isPhone ? 200 : 240,
      pinned: true,
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
          tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: _handleBack,
        style: IconButton.styleFrom(
          backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      actions: [
        IconButton(
            tooltip: 'Edit Profile',
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: _openEditSheet,
          style: IconButton.styleFrom(
            backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
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
                    theme.colorScheme.primary.withOpacity(0.8),
                    theme.colorScheme.secondary.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            if (cover != null)
              Positioned.fill(
                child: Image.file(File(cover.path), fit: BoxFit.cover),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
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
                        ? Colors.white.withOpacity(0.10)
                        : Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Colors.white.withOpacity(0.95),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cover',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
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
                  // Avatar with camera button
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
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
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                            backgroundImage: avatar != null ? FileImage(File(avatar.path)) : null,
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
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _pickAvatar,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: isPhone ? 28 : 32,
                              height: isPhone ? 28 : 32,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(shape: BoxShape.circle),
                              child: Container(
                                width: isPhone ? 26 : 30,
                                height: isPhone ? 26 : 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.primary,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: isPhone ? 14 : 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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
                                      color: Colors.black.withOpacity(0.3),
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
                            color: Colors.white.withOpacity(0.95),
                            fontSize: isPhone ? 12 : 13,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
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
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
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
                          color.withOpacity(0.2),
                          color.withOpacity(0.1),
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
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
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
          _infoRow(Icons.info_outline_rounded, _bioCtrl.text, maxLines: 3),
        ],
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
                    color: (iconColor ?? theme.colorScheme.primary).withOpacity(0.12),
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
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
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
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
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
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: SingleChildScrollView(
                primary: false,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text('Edit Profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                          ),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]),
                    const SizedBox(height: 12),
                    Text(
                      'Basic information',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _bottomSheetField('Full Name', _nameCtrl, Icons.person_outline),
                    const SizedBox(height: 12),
                    _bottomSheetField('Email', _emailCtrl, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _bottomSheetField('Phone', _phoneCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _bottomSheetField('Bio', _bioCtrl, Icons.info_outline, maxLines: 3),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () async {
                                    Navigator.pop(context);
                                    await _saveProfile();
                                  },
                            icon: _busy
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.check_circle_outline),
                            label: Text(_busy ? 'Saving...' : 'Save Changes'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
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
      },
    );
  }

  Widget _bottomSheetField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPhone = MediaQuery.of(context).size.width < 600;
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: isPhone ? 13 : 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter $label',
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          fontSize: isPhone ? 12 : 13,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        hintStyle: theme.textTheme.bodySmall?.copyWith(
          fontSize: isPhone ? 12 : 13,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(icon, size: 18, color: theme.colorScheme.primary),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

}
