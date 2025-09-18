import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as pv;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../utils/snackbar_utils.dart';
import '../../core/providers/user_provider.dart';
import '../../app/auth_router.dart';

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
    try {
      final up = pv.Provider.of<UserProvider>(context, listen: false);
      final u = up.currentUser;
      if (u != null) {
        _nameCtrl.text = (u.fullName.trim().isEmpty) ? 'User' : u.fullName;
        _emailCtrl.text = u.email;
        _phoneCtrl.text = u.phoneNumber ?? _phoneCtrl.text;
      } else {
        _nameCtrl.text = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'John Doe';
        _emailCtrl.text = _emailCtrl.text.isNotEmpty ? _emailCtrl.text : 'john.doe@example.com';
        _phoneCtrl.text = _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : '+1 (555) 123-4567';
      }
      if (_bioCtrl.text.isEmpty) {
        _bioCtrl.text = 'Passionate host and traveler. Love meeting people around the world!';
      }
    } catch (_) {
      _nameCtrl.text = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'John Doe';
      _emailCtrl.text = _emailCtrl.text.isNotEmpty ? _emailCtrl.text : 'john.doe@example.com';
      _phoneCtrl.text = _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : '+1 (555) 123-4567';
      if (_bioCtrl.text.isEmpty) {
        _bioCtrl.text = 'Passionate host and traveler. Love meeting people around the world!';
      }
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
      final up = pv.Provider.of<UserProvider>(context, listen: false);
      final fullName = _nameCtrl.text.trim();
      String firstName = fullName;
      String lastName = '';
      if (fullName.contains(' ')) {
        final parts = fullName.split(RegExp(r'\s+'));
        firstName = parts.first;
        lastName = parts.sublist(1).join(' ');
      }

      final ok = await up.updateProfile(
        firstName: firstName.isEmpty ? null : firstName,
        lastName: lastName.isEmpty ? null : lastName,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );

      if (!mounted) return;
      if (ok) {
        SnackBarUtils.showSuccess(context, 'Profile updated successfully');
      } else {
        SnackBarUtils.showError(context, 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsGrid(theme, isDark),
                      const SizedBox(height: 16),
                      _buildQuickActions(theme, isDark),
                      const SizedBox(height: 16),
                      _buildAboutCard(theme),
                      const SizedBox(height: 16),
                      _buildContactSocialCard(theme),
                      const SizedBox(height: 16),
                      _buildSecurityPrivacyCard(theme),
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

  SliverAppBar _buildHeader(ThemeData theme, bool isDark) {
    final cover = _coverImage;
    final avatar = _avatarImage;
    final isPhone = MediaQuery.of(context).size.width < 600;

    return SliverAppBar(
      expandedHeight: isPhone ? 180 : 220,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBack,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.85),
                    theme.colorScheme.primary.withOpacity(0.45),
                  ],
                ),
              ),
            ),
            if (cover != null)
              Positioned.fill(
                child: Image.file(File(cover.path), fit: BoxFit.cover),
              ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: isPhone ? 30 : 38,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: isPhone ? 28 : 35,
                          backgroundImage: avatar != null ? FileImage(File(avatar.path)) : null,
                          child: avatar == null
                              ? Icon(Icons.person, size: isPhone ? 28 : 36, color: Colors.white)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickAvatar,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(Icons.camera_alt, size: 16, color: theme.colorScheme.onPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _nameCtrl.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isPhone ? 16 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.verified_user, size: 16, color: Colors.white.withOpacity(0.9)),
                            const SizedBox(width: 6),
                            Text(
                              _emailCtrl.text,
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: isPhone ? 11 : 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _pickCover,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 10, vertical: isPhone ? 6 : 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.6)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wallpaper, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Cover', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
    );
  }

  Widget _buildStatsGrid(ThemeData theme, bool isDark) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    Widget tile(IconData icon, String label, String value, Color color) {
      return Container(
        padding: EdgeInsets.all(isPhone ? 10 : 14),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
          boxShadow: [
            if (!isDark)
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isPhone ? 8 : 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: isPhone ? 16 : 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: (isPhone ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(value, style: (isPhone ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        tile(Icons.home_work_outlined, 'Properties', '5', Colors.indigo),
        tile(Icons.rate_review_outlined, 'Reviews', '23', Colors.amber.shade700),
        tile(Icons.thumb_up_outlined, 'Rating', '4.8', Colors.green.shade700),
        tile(Icons.token_outlined, 'Tokens', '1,250', Colors.deepPurple),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    Widget action(IconData icon, String label, VoidCallback onTap, Color color) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isPhone ? 10 : 12, vertical: isPhone ? 10 : 12),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.2) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: isPhone ? 16 : 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: isPhone ? 12 : 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        action(Icons.edit_outlined, 'Edit', _openEditSheet, theme.colorScheme.primary),
        const SizedBox(width: 12),
        action(
          Icons.account_balance_wallet_outlined,
          'Wallet & Rewards',
          () => context.push(Routes.wallet),
          Colors.purple,
        ),
        const SizedBox(width: 12),
        action(
          Icons.share_outlined,
          'Referral & Earn',
          () => context.push(Routes.referrals),
          Colors.green.shade700,
        ),
      ],
    );
  }

  Widget _buildAboutCard(ThemeData theme) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About', style: (isPhone ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _infoRow(Icons.person_outline, _nameCtrl.text),
            const SizedBox(height: 8),
            _infoRow(Icons.email_outlined, _emailCtrl.text),
            const SizedBox(height: 8),
            _infoRow(Icons.phone_outlined, _phoneCtrl.text),
            const SizedBox(height: 8),
            _infoRow(Icons.info_outline, _bioCtrl.text, maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSocialCard(ThemeData theme) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    Widget chip(IconData icon, String label, Color color) {
      return Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: isPhone ? 10 : 12, vertical: isPhone ? 6 : 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: isPhone ? 14 : 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: isPhone ? 12 : 14)),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact & Social', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              children: [
                chip(Icons.link, 'Website', Colors.blue),
                chip(Icons.alternate_email, 'Twitter', Colors.lightBlue),
                chip(Icons.video_library_outlined, 'YouTube', Colors.redAccent),
                chip(Icons.camera_alt_outlined, 'Instagram', Colors.purple),
                chip(Icons.work_outline, 'LinkedIn', Colors.indigo),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityPrivacyCard(ThemeData theme) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
      child: Column(
        children: [
          // Two-Factor Authentication removed
          // Biometric Login removed
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text('Change Password', style: isPhone ? theme.textTheme.bodyMedium : null),
            trailing: const Icon(Icons.chevron_right),
            dense: isPhone,
            visualDensity: VisualDensity.compact,
            onTap: () {
              final email = _emailCtrl.text.trim();
              context.push(
                Routes.resetPassword,
                extra: {
                  'email': email,
                  'successPath': Routes.profile,
                },
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy Settings', style: isPhone ? theme.textTheme.bodyMedium : null),
            trailing: const Icon(Icons.chevron_right),
            dense: isPhone,
            visualDensity: VisualDensity.compact,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
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
                  Row(
                    children: [
                      const Icon(Icons.edit_outlined),
                      const SizedBox(width: 8),
                      Text('Edit Profile', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _bottomSheetField('Full Name', _nameCtrl, Icons.person_outline),
                  const SizedBox(height: 12),
                  _bottomSheetField('Email', _emailCtrl, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _bottomSheetField('Phone', _phoneCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _bottomSheetField('Bio', _bioCtrl, Icons.info_outline, maxLines: 3),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bottomSheetField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

}
