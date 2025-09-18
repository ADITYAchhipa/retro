import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import 'package:go_router/go_router.dart';
import '../../app/auth_router.dart';

class EnhancedProfileScreen extends ConsumerStatefulWidget {
  const EnhancedProfileScreen({super.key});

  @override
  ConsumerState<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends ConsumerState<EnhancedProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  XFile? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    // Load current user profile data
    _nameController.text = 'John Doe';
    _emailController.text = 'john.doe@example.com';
    _phoneController.text = '+1 (555) 123-4567';
    _bioController.text = 'Experienced property owner and traveler. Love hosting guests from around the world!';
    _addressController.text = '123 Main St, San Francisco, CA';
    // Remove network image URL to avoid connection errors
    _currentImageUrl = null;
  }

  Future<void> _pickImage() async {
    final imageService = ref.read(imageServiceProvider);
    final image = await imageService.pickImageFromGallery();
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload new profile image if selected
      if (_selectedImage != null) {
        final imageService = ref.read(imageServiceProvider);
        final imageUrl = await imageService.uploadImage(_selectedImage!);
        if (imageUrl != null) {
          _currentImageUrl = imageUrl;
        }
      }

      // Simulate API call to save profile
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false;
          _selectedImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _selectedImage = null;
    });
    _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(t?.profile ?? 'Profile'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          if (_isEditing) ...[
            TextButton(
              onPressed: _cancelEdit,
              child: Text(t?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t?.save ?? 'Save'),
            ),
          ] else
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 16, right: 16, top: isPhone ? 12 : 16, bottom: isPhone ? 80 : 100),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
                // Profile Image Section
                Container(
                  margin: EdgeInsets.only(top: isPhone ? 12 : 20),
                  child: Center(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: isPhone ? 44 : 60,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            backgroundImage: _selectedImage != null
                                ? FileImage(File(_selectedImage!.path))
                                : _currentImageUrl != null
                                    ? NetworkImage(_currentImageUrl!) as ImageProvider
                                    : null,
                            child: _selectedImage == null && _currentImageUrl == null
                                ? Icon(
                                  Icons.person,
                                  size: isPhone ? 44 : 60,
                                  color: theme.colorScheme.onSurfaceVariant,
                                )
                                : null,
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: EdgeInsets.all(isPhone ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: isPhone ? 16 : 20,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: isPhone ? 16 : 32),

              // Profile Form
              _buildFormField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildFormField(
                controller: _emailController,
                label: t?.email ?? 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildFormField(
                controller: _phoneController,
                label: t?.phone ?? 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildFormField(
                controller: _bioController,
                label: 'Bio',
                icon: Icons.info_outline,
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Bio must be less than 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildFormField(
                controller: _addressController,
                label: t?.address ?? 'Address',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Profile Stats
              if (!_isEditing) ...[
                _buildStatsSection(theme),
                const SizedBox(height: 32),
              ],

              // Account Actions
              _buildAccountActions(context, theme, t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: !_isEditing,
        fillColor: _isEditing ? null : theme.colorScheme.surfaceVariant.withOpacity(0.3),
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Stats',
            style: (isPhone ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Properties',
                  '5',
                  Icons.home_outlined,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Reviews',
                  '23',
                  Icons.star_outline,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Rating',
                  '4.8',
                  Icons.thumb_up_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value, IconData icon) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Column(
      children: [
        Icon(
          icon,
          size: isPhone ? 18 : 24,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall)?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountActions(BuildContext context, ThemeData theme, AppLocalizations? t) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.security_outlined),
          title: Text(t?.changePassword ?? 'Change Password'),
          trailing: const Icon(Icons.chevron_right),
          dense: isPhone,
          visualDensity: VisualDensity.compact,
          onTap: () {
            final email = ref.read(authProvider).user?.email ?? '';
            context.push(
              Routes.resetPassword,
              extra: {
                'email': email,
                'successPath': Routes.profile,
              },
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notification Settings'),
          trailing: const Icon(Icons.chevron_right),
          dense: isPhone,
          visualDensity: VisualDensity.compact,
          onTap: () {
            // Navigate to notification settings
          },
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy Settings'),
          trailing: const Icon(Icons.chevron_right),
          dense: isPhone,
          visualDensity: VisualDensity.compact,
          onTap: () {
            // Navigate to privacy settings
          },
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: Colors.red[600]),
          title: Text(
            t?.logout ?? 'Logout',
            style: TextStyle(color: Colors.red[600]),
          ),
          dense: isPhone,
          visualDensity: VisualDensity.compact,
          onTap: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(t?.logout ?? 'Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(t?.cancel ?? 'Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(t?.logout ?? 'Logout'),
                  ),
                ],
              ),
            );

            if (shouldLogout == true && mounted) {
              await ref.read(authProvider.notifier).signOut();
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
