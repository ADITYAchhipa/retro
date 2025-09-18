import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  bool _isLoading = false;
  
  // Document verification
  File? _frontIdImage;
  File? _backIdImage;
  File? _selfieImage;
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
        if (profile.frontIdPath != null) _frontIdImage = File(profile.frontIdPath!);
        if (profile.backIdPath != null) _backIdImage = File(profile.backIdPath!);
        if (profile.selfiePath != null) _selfieImage = File(profile.selfiePath!);
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
          title: const Text('Identity Verification'),
          backgroundColor: Colors.transparent,
          elevation: 0,
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
                  onPageChanged: (index) => setState(() => _currentStep = index),
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(7, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 6 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted 
                  ? theme.colorScheme.primary
                  : isActive 
                    ? theme.colorScheme.primary.withOpacity(0.5)
                    : theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomeStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Verify Your Identity',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'To ensure the safety and security of our platform, we need to verify your identity. This process typically takes 2-3 minutes.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 20,
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
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please enter your personal details as they appear on your ID document.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dobController,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: _selectDateOfBirth,
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Street Address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal Code',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.arrow_drop_down),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Document Type',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the type of government-issued ID you want to use for verification.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
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
                  const SizedBox(height: 16),
                  _buildDocumentOption(
                    theme,
                    'drivers_license',
                    'Driver\'s License',
                    'Government-issued driving permit',
                    Icons.credit_card,
                  ),
                  const SizedBox(height: 16),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Document Photos',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take clear photos of both sides of your ${_getDocumentName()}. Ensure all text is readable.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDocumentUploadCard(
                    theme,
                    'Front Side',
                    'Take a photo of the front of your ${_getDocumentName()}',
                    _frontIdImage,
                    () => _pickImage(ImageSource.camera, 'front'),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedDocumentType != 'passport')
                    _buildDocumentUploadCard(
                      theme,
                      'Back Side',
                      'Take a photo of the back of your ${_getDocumentName()}',
                      _backIdImage,
                      () => _pickImage(ImageSource.camera, 'back'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadCard(ThemeData theme, String title, String subtitle, File? image, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 132,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
          color: image != null ? theme.colorScheme.primary.withOpacity(0.1) : null,
        ),
        child: image != null
          ? Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
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
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$title Uploaded',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to retake photo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Take a Selfie',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a clear selfie to verify your identity matches your document.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: _selfieImage != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: Image.file(
                          _selfieImage!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
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
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => _pickImage(ImageSource.camera, 'selfie'),
                        child: const Text('Retake Selfie'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 3,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera, 'selfie'),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Selfie'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Information',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review all information before submitting for verification.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
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
                  const SizedBox(height: 16),
                  _buildReviewSection(
                    theme,
                    'Document Type',
                    [_getDocumentName()],
                  ),
                  const SizedBox(height: 16),
                  _buildReviewSection(
                    theme,
                    'Uploaded Documents',
                    [
                      'Front ID: ${_frontIdImage != null ? "✓ Uploaded" : "✗ Missing"}',
                      if (_selectedDocumentType != 'passport')
                        'Back ID: ${_backIdImage != null ? "✓ Uploaded" : "✗ Missing"}',
                      'Selfie: ${_selfieImage != null ? "✓ Uploaded" : "✗ Missing"}',
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Submitting for Verification...',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we process your documents',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ] else ...[
            Icon(
              Icons.check_circle,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Verification Submitted!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your documents have been submitted for review. We\'ll notify you within 24-48 hours once verification is complete.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue to App'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0 && _currentStep < 6)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0 && _currentStep < 6) const SizedBox(width: 16),
          if (_currentStep < 6)
            Expanded(
              child: ElevatedButton(
                onPressed: _canProceed() ? _nextStep : null,
                child: Text(_currentStep == 5 ? 'Submit' : 'Continue'),
              ),
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
        return _frontIdImage != null && 
               (_selectedDocumentType == 'passport' || _backIdImage != null);
      case 4:
        return _selfieImage != null;
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
      setState(() {
        switch (type) {
          case 'front':
            _frontIdImage = File(image.path);
            break;
          case 'back':
            _backIdImage = File(image.path);
            break;
          case 'selfie':
            _selfieImage = File(image.path);
            break;
        }
      });
      // Persist paths
      try {
        if (type == 'front') {
          await KycService.instance.saveDocumentPaths(frontIdPath: image.path);
        } else if (type == 'back') {
          await KycService.instance.saveDocumentPaths(backIdPath: image.path);
        } else if (type == 'selfie') {
          await KycService.instance.saveSelfiePath(image.path);
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
      _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  void _selectCountry() {
    // In a real app, this would show a country picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Country'),
        content: const Text('Country picker would be implemented here'),
        actions: [
          TextButton(
            onPressed: () {
              _countryController.text = 'United States';
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
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
    setState(() => _isLoading = true);
    
    // Simulate API submission
    await Future.delayed(const Duration(seconds: 3));
    try {
      await KycService.instance.submit();
    } catch (_) {}
    
    // Mark user as KYC-verified in auth state
    try {
      final auth = ref.read(authProvider);
      final current = auth.user;
      if (current != null) {
        await ref.read(authProvider.notifier).updateProfile(
          current.copyWith(isKycVerified: true),
        );
      }
    } catch (_) {}

    setState(() => _isLoading = false);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
