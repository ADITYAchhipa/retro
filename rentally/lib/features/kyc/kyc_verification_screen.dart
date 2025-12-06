import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../core/widgets/tab_back_handler.dart';
import '../../app/app_state.dart';
import '../../services/kyc/kyc_service.dart';

/// KYC (Know Your Customer) verification screen for identity verification
class KYCVerificationScreen extends ConsumerStatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  ConsumerState<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends ConsumerState<KYCVerificationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  int _furthestStep = 0; // highest index user has reached
  bool _isLoading = false;
  
  // Document verification - store both XFile and bytes for cross-platform

  Uint8List? _frontIdBytes;
  Uint8List? _backIdBytes;
  Uint8List? _selfieBytes;
  Uint8List? _profileIdBytes;
  String _selectedDocumentType = 'passport';
  
  // Personal information
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await KycService.instance.getProfile();

      String? profileIdPath;
      try {
        final prefs = await SharedPreferences.getInstance();
        profileIdPath = prefs.getString('user_id_document_path');
      } catch (_) {}

      if (!mounted) return;
      
      // For non-web platforms, load bytes from file paths
      if (!kIsWeb) {
        if (profile.frontIdPath != null) {
          final file = File(profile.frontIdPath!);
          if (await file.exists()) {
            _frontIdBytes = await file.readAsBytes();
          }
        }
        if (profile.backIdPath != null) {
          final file = File(profile.backIdPath!);
          if (await file.exists()) {
            _backIdBytes = await file.readAsBytes();
          }
        }
        if (profile.selfiePath != null) {
          final file = File(profile.selfiePath!);
          if (await file.exists()) {
            _selfieBytes = await file.readAsBytes();
          }
        }
        if (profileIdPath != null) {
          final file = File(profileIdPath);
          if (await file.exists()) {
            _profileIdBytes = await file.readAsBytes();
          }
        }
      }
      
      if (!mounted) return;
      setState(() {
        _selectedDocumentType = profile.documentType;
        _firstNameController.text = profile.firstName ?? _firstNameController.text;
        _lastNameController.text = profile.lastName ?? _lastNameController.text;
        _dobController.text = profile.dob ?? _dobController.text;
        _addressController.text = profile.address ?? _addressController.text;
        _cityController.text = profile.city ?? _cityController.text;
        _postalCodeController.text = profile.postalCode ?? _postalCodeController.text;
        _countryController.text = profile.country ?? _countryController.text;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TabBackHandler(
      pageController: _pageController,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          toolbarHeight: 60,
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: const Text('Identity Verification'),
        ),
        body: SafeArea(
          top: false,
          bottom: true,
          child: Column(
            children: [
              _buildProgressIndicator(theme),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() {
                    _currentStep = index;
                    if (_furthestStep < index) _furthestStep = index;
                  }),
                  children: [
                    _buildWelcomeStep(theme),
                    _buildPersonalInfoStep(theme),
                    _buildDocumentSelectionStep(theme),
                    _buildDocumentUploadStep(theme),
                    _buildSelfieStep(theme),
                    _buildReviewStep(theme),
                    _buildSubmissionStep(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Let Scaffold handle safe insets for the bottom action bar
        bottomNavigationBar: SafeArea(top: false, child: _buildNavigationButtons(theme)),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    // Modern chip-based horizontal step header
    final labels = ['Welcome', 'Info', 'Document', 'Photos', 'Selfie', 'Review', 'Submit'];
    final icons = <IconData>[
      Icons.info_outline,
      Icons.person_outline,
      Icons.credit_card,
      Icons.document_scanner_outlined,
      Icons.camera_alt_outlined,
      Icons.fact_check_outlined,
      Icons.check_circle_outline,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (i) {
            final bool isActive = i == _currentStep;
            final bool isCompleted = i < _currentStep;
            final bool canTap = i <= _furthestStep;
            final Color bg = isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : (isCompleted
                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5));
            final Color fg = (isActive || isCompleted)
                ? theme.colorScheme.primary
                : (theme.textTheme.bodySmall?.color ?? Colors.black87);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: canTap
                    ? () {
                        if (_pageController.hasClients) {
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icons[i], size: 14, color: fg.withValues(alpha: canTap ? 1 : 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        labels[i],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: fg.withValues(alpha: canTap ? 1 : 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Verify Your Identity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'To ensure the safety and security of our platform, we need to verify your identity. This process typically takes 2-3 minutes.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildFeatureList(theme),
        ],
      ),
    );
  }

  Widget _buildFeatureList(ThemeData theme) {
    final features = [
      'Bank-level security encryption',
      'Quick 3-minute verification',
      'Trusted by millions worldwide',
      'GDPR compliant data handling',
    ];

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                feature,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPersonalInfoStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please enter your personal details as they appear on your ID document.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'First Name',
                              hintText: 'As on your ID',
                              helperText: 'Enter your legal first name',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.person_outline),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            ),
                            validator: (value) => value?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Last Name',
                              hintText: 'As on your ID',
                              helperText: 'Enter your legal last name',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.person_outline),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            ),
                            validator: (value) => value?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dobController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        hintText: 'DD/MM/YYYY',
                        helperText: 'You must be at least 18 years old',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      readOnly: true,
                      onTap: _selectDateOfBirth,
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Street Address',
                        hintText: 'House number, street, apt/suite',
                        helperText: 'As on your ID document',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.home_outlined),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'City',
                              hintText: 'City / Town',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.location_city_outlined),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            ),
                            validator: (value) => value?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _postalCodeController,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: 'Postal Code',
                              hintText: 'ZIP / Postal code',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.local_post_office_outlined),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            ),
                            validator: (value) => value?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        labelText: 'Country',
                        helperText: 'Tap to select your country',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.public),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      readOnly: true,
                      onTap: _selectCountry,
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSelectionStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Document Type',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose the type of government-issued ID you want to use for verification.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDocumentOption(
                    theme,
                    'passport',
                    'Passport',
                    'International travel document',
                    Icons.book,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentOption(
                    theme,
                    'drivers_license',
                    'Driver\'s License',
                    'Government-issued driving permit',
                    Icons.credit_card,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentOption(
                    theme,
                    'national_id',
                    'National ID Card',
                    'Government-issued identity card',
                    Icons.badge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentOption(ThemeData theme, String value, String title, String subtitle, IconData icon) {
    final isSelected = _selectedDocumentType == value;
    
    return InkWell(
      onTap: () async {
        setState(() => _selectedDocumentType = value);
        await KycService.instance.saveDocumentType(value);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Document Photos',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload clear photos of both sides of your ${_getDocumentName()}. Ensure all text is readable.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: theme.colorScheme.tertiary.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 12, color: theme.colorScheme.tertiary),
                      const SizedBox(width: 6),
                      Text('Photo tips', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.tertiary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('• Good lighting, no glare', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
                  Text('• Entire document in frame', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
                  Text('• Text and photo clearly visible', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDocumentUploadCard(
                    theme,
                    'Front Side',
                    'Upload a photo of the front of your ${_getDocumentName()}',
                    _frontIdBytes,
                    () => _pickImage(ImageSource.gallery, 'front'),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedDocumentType != 'passport')
                    _buildDocumentUploadCard(
                      theme,
                      'Back Side',
                      'Upload a photo of the back of your ${_getDocumentName()}',
                      _backIdBytes,
                      () => _pickImage(ImageSource.gallery, 'back'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadCard(ThemeData theme, String title, String subtitle, Uint8List? imageBytes, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 96,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(10),
          color: imageBytes != null ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
        ),
        child: imageBytes != null
          ? Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    imageBytes,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$title Uploaded',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to retake photo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildSelfieStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Take a Selfie',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Take a clear selfie to verify your identity matches your document.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: theme.colorScheme.tertiary.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 12, color: theme.colorScheme.tertiary),
                      const SizedBox(width: 6),
                      Text('Selfie tips', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.tertiary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('• Face centered, well-lit background', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
                  Text('• No hats, sunglasses, or filters', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
                  Text('• Keep a neutral expression', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: _selfieBytes != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipOval(
                            child: Image.memory(
                              _selfieBytes!,
                              width: 128,
                              height: 128,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Selfie captured successfully',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _pickImage(ImageSource.camera, 'selfie'),
                            child: const Text('Retake Selfie'),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 48,
                              color: theme.colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera, 'selfie'),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Selfie'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please review all information before submitting for verification.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildReviewSection(
                    theme,
                    'Personal Information',
                    [
                      'Name: ${_firstNameController.text} ${_lastNameController.text}',
                      'Date of Birth: ${_dobController.text}',
                      'Address: ${_addressController.text}',
                      'City: ${_cityController.text}',
                      'Country: ${_countryController.text}',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildReviewSection(
                    theme,
                    'Document Type',
                    [_getDocumentName()],
                  ),
                  const SizedBox(height: 12),
                  _buildReviewSection(
                    theme,
                    'Uploaded Documents',
                    [
                      'Front ID: ${_frontIdBytes != null ? "✓ Uploaded" : "✗ Missing"}',
                      if (_selectedDocumentType != 'passport')
                        'Back ID: ${_backIdBytes != null ? "✓ Uploaded" : "✗ Missing"}',
                      'Selfie: ${_selfieBytes != null ? "✓ Uploaded" : "✗ Missing"}',
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(ThemeData theme, String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                item,
                style: theme.textTheme.bodyMedium,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'Submitting for Verification...',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Please wait while we process your documents',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ] else ...[
            Icon(
              Icons.check_circle,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Verification Submitted!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your documents have been submitted for review. We\'ll notify you within 24-48 hours once verification is complete.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Continue to App'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timeline, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'Step ${_currentStep + 1} of 7',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previousStep,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              if (_currentStep > 0 && _currentStep < 6) const SizedBox(width: 12),
              if (_currentStep < 6)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canProceed() ? _nextStep : null,
                    icon: Icon(_currentStep == 5 ? Icons.check : Icons.arrow_forward),
                    label: Text(_currentStep == 5 ? 'Submit' : 'Continue'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return true;
      case 1:
        return _formKey.currentState?.validate() ?? false;
      case 2:
        return _selectedDocumentType.isNotEmpty;
      case 3:
        return _frontIdBytes != null && 
               (_selectedDocumentType == 'passport' || _backIdBytes != null);
      case 4:
        return _selfieBytes != null;
      case 5:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep == 5) {
      _submitVerification();
    } else {
      // Persist personal info when leaving step 1
      if (_currentStep == 1 && (_formKey.currentState?.validate() ?? false)) {
        KycService.instance.savePersonalInfo(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          dob: _dobController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _countryController.text.trim(),
        );
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      // Read bytes for cross-platform display
      final bytes = await image.readAsBytes();
      
      setState(() {
        switch (type) {
          case 'front':
            _frontIdXFile = image;
            _frontIdBytes = bytes;
            break;
          case 'back':
            _backIdXFile = image;
            _backIdBytes = bytes;
            break;
          case 'selfie':
            _selfieXFile = image;
            _selfieBytes = bytes;
            break;
        }
      });
      
      // Persist data for submission
      try {
        if (type == 'front') {
          // Save bytes for web compatibility
          await KycService.instance.saveFrontIdBytes(bytes);
          // Also save path for mobile platforms
          if (!kIsWeb) {
            await KycService.instance.saveDocumentPaths(frontIdPath: image.path);
          }
        } else if (type == 'back') {
          await KycService.instance.saveBackIdBytes(bytes);
          if (!kIsWeb) {
            await KycService.instance.saveDocumentPaths(backIdPath: image.path);
          }
        } else if (type == 'selfie') {
          await KycService.instance.saveSelfieBytes(bytes);
          if (!kIsWeb) {
            await KycService.instance.saveSelfiePath(image.path);
          }
        }
      } catch (_) {}
    }
  }

  void _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)),
    );
    if (picked != null) {
      if (!mounted) return;
      _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  void _selectCountry() {
    const options = [
      'United States',
      'United Kingdom',
      'Canada',
      'India',
      'Australia',
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
            itemBuilder: (context, index) {
              final country = options[index];
              return ListTile(
                title: Text(country),
                trailing: _countryController.text == country
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _countryController.text = country;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        );
      },
    );
  }

  String _getDocumentName() {
    switch (_selectedDocumentType) {
      case 'passport':
        return 'Passport';
      case 'drivers_license':
        return 'Driver\'s License';
      case 'national_id':
        return 'National ID Card';
      default:
        return 'Document';
    }
  }

  Future<void> _submitVerification() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Submit to backend API
      final result = await KycService.instance.submitToBackend();
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        // Update user's kycStatus to 'pending' in auth state for instant UI update
        try {
          final auth = ref.read(authProvider);
          final current = auth.user;
          if (current != null) {
            await ref.read(authProvider.notifier).updateProfile(
              current.copyWith(kycStatus: 'pending'),
            );
          }
        } catch (_) {}

        setState(() => _isLoading = false);
        if (_pageController.hasClients) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else {
        // Show error message
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to submit KYC. Please try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
