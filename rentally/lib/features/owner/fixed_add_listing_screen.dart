// Modern Professional Add Listing Screen
// Redesigned with improved UI/UX and mobile-friendly font sizes

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
// import '../../models/listing_model.dart'; // Model will be created later
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../../services/listing_service.dart';
import '../../services/image_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../utils/snackbar_utils.dart';
import 'forms/residential_details_form.dart';
import '../../app/app_state.dart';

class FixedAddListingScreen extends ConsumerStatefulWidget {
  final String? initialCategory;

  const FixedAddListingScreen({super.key, this.initialCategory});

  @override
  ConsumerState<FixedAddListingScreen> createState() => _FixedAddListingScreenState();
}

class _FixedAddListingScreenState extends ConsumerState<FixedAddListingScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _securityDepositController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _nearLandmarkController = TextEditingController();
  final _otherAmenitiesController = TextEditingController();
  final _houseRulesController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _discountPercentController = TextEditingController();
  final _noticePeriodDaysController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Type-specific detail controllers
  final _floorController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  final _plotAreaController = TextEditingController();
  final _parkingSpacesController = TextEditingController();
  final _hoaFeeController = TextEditingController();
  final _studioSizeController = TextEditingController();
  // PG/Hostel specific
  final _pgOccupancyController = TextEditingController();
  final _pgBedRentController = TextEditingController();
  bool _pgAttachedBathroom = true;
  String _pgGender = 'Any';
  String _pgMeals = 'No Meals';

  // Kitchen details
  final _kitchenPlatformController = TextEditingController();
  String _kitchenType = 'Modular';
  String _kitchenAccess = 'Full';
  bool _kitchenGasConnection = false;
  bool _kitchenChimney = false;
  bool _kitchenCabinets = false;
  bool _kitchenCommonKitchen = false;

  // Bathroom details
  bool _bathroomHasGeyser = true;
  String _bathroomStyle = 'Western';
  bool _bathroomHasExhaust = false;
  bool _pgHotWater = true;

  // Dynamic room module
  String _roomType = 'Single Room';
  final _roomSizeController = TextEditingController();
  final _roomSharingCountController = TextEditingController();
  bool _roomHasBed = true;
  bool _roomHasMattress = true;
  bool _roomHasWardrobe = true;
  bool _roomHasFan = true;
  bool _roomHasAC = false;
  bool _roomHasTable = false;
  bool _roomHasChair = false;
  bool _roomHasMirror = false;
  bool _roomHasMiniFridge = false;

  // Rules & restrictions
  bool _ruleVisitorsAllowed = true;
  bool _ruleOvernightGuestsAllowed = false;
  bool _ruleSmokingAllowed = false;
  bool _ruleDrinkingAllowed = false;
  bool _ruleCookingAllowed = true;
  bool _ruleOwnerStaysOnProperty = false;
  final _gateClosingTimeController = TextEditingController();

  // Availability
  final _availableFromController = TextEditingController();
  String _availabilityStatus = 'Vacant';
  bool _earlyMoveInAllowed = false;
  final _maxOccupancyController = TextEditingController();
  final _moveInRequirementsController = TextEditingController();

  // Commercial specific controllers/flags
  // Office
  final _officeCarpetAreaController = TextEditingController();
  final _officeCabinsController = TextEditingController();
  final _officeConferenceRoomsController = TextEditingController();
  bool _officePantry = false;
  // Shop
  final _shopCarpetAreaController = TextEditingController();
  final _shopFrontageController = TextEditingController();
  String _shopFootfall = 'Medium'; // Low, Medium, High
  bool _shopWashroom = false;
  // Warehouse
  final _warehouseBuiltUpAreaController = TextEditingController();
  final _warehouseCeilingHeightController = TextEditingController();
  final _warehouseLoadingBaysController = TextEditingController();
  final _warehousePowerController = TextEditingController(); // in kVA
  bool _warehouseTruckAccess = true;

  // Generic area fields
  final _carpetAreaController = TextEditingController(); // apartment/condo/townhouse
  // Generic commercial area for new types
  final _commercialBuiltUpAreaController = TextEditingController();
  // Penthouse specific
  final _terraceAreaController = TextEditingController();
  
  // New: Rental & Plot support
  String _rentalModeListing = 'both'; // both | rental | monthly
  String _plotUsageListing = 'any'; // any | agriculture | commercial | events | construction
  // Geo location (persisted in draft)
  double? _latitude;
  double? _longitude;
  // Monthly stay settings
  int _minStayMonthsMonthly = 0; // 0 = Any

  late TabController _tabController;
  String _selectedPropertyType = 'apartment';
  int _bedrooms = 1;
  int _bathrooms = 1;
  String _apartmentBhk = '1BHK';
  String _furnishing = 'Select';
  
  // BHK options for apartments
  final List<String> _bhkOptions = ['1BHK', '2BHK', '3BHK', '4BHK', '5BHK', '6BHK'];
  final List<String> _selectedAmenities = [];
  final List<String> _selectedNearbyFacilities = [];
  final List<String> _selectedChargesIncluded = [];
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  String _preferredTenant = 'Select';
  String _foodPreference = 'No Preference';
  bool _petsAllowed = false;
  bool _hidePhoneNumber = false;
  bool _agreeToTerms = false;
  bool _requireSeekerId = false;

  final List<String> _availableAmenities = [
    'Parking', 'Wi-Fi', 'Full Kitchen', 'TV', 'AC', '24/7 Water',
    'Lift/Elevator', 'Balcony', 'Garden'
  ];

  final List<String> _nearbyFacilities = [
    'School', 'Hospital', 'Market', 'Bus Stop', 'Metro Station', 'Park'
  ];

  final List<String> _chargesIncluded = [
    'Maintenance', 'Water', 'Electricity', 'Parking'
  ];

  final List<String> _furnishingOptions = [
    'Select', 'Fully Furnished', 'Semi Furnished', 'Unfurnished'
  ];

  final List<String> _tenantPreferences = [
    'Select', 'Family', 'Bachelor', 'Working Professional', 'Student'
  ];

  final List<String> _foodPreferences = [
    'No Preference', 'Vegetarian Only', 'Non-Vegetarian Only'
  ];

  // PG/Hostel options
  final List<String> _pgGenderOptions = ['Any', 'Male', 'Female'];
  final List<String> _pgMealsOptions = ['No Meals', 'Breakfast', 'Breakfast + Dinner', 'All Meals'];
  
  // Categories (now restricted to Residential-only for this screen)
  final List<String> _categories = ['Residential'];

  // Room options (Residential -> Room)
  final List<String> _roomBathroomOptions = ['Shared', 'Separate', 'Attached'];
  String _roomBathroomType = 'Attached';

  // Category selection and draft autosave
  String _selectedCategory = 'Residential';
  Timer? _draftDebounce;
  bool _suspendDraft = false;

  @override
  void didUpdateWidget(covariant FixedAddListingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newCategory = widget.initialCategory;
    if (newCategory != null &&
        newCategory != oldWidget.initialCategory &&
        _categories.contains(newCategory)) {
      setState(() {
        _selectedCategory = newCategory;
        final allowed = _getTypesForCategory();
        if (allowed.isNotEmpty) {
          _selectedPropertyType = allowed.first;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    final initial = widget.initialCategory;
    if (initial != null && _categories.contains(initial)) {
      _selectedCategory = initial;
      final allowed = _getTypesForCategory();
      if (allowed.isNotEmpty) {
        _selectedPropertyType = allowed.first;
      }
    }
    _attachDraftListeners();
    // Load any saved draft
    unawaited(_loadDraft());
  }

  Widget _buildBasicsStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final allowedTypes = _getTypesForCategory();
    final currentType = allowedTypes.contains(_selectedPropertyType)
        ? _selectedPropertyType
        : allowedTypes.first;
        
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyle(
              fontSize: isPhone ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Provide essential details about your property',
            style: TextStyle(
              fontSize: isPhone ? 12 : 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          
          // Title Field
          _buildModernTextField(
            controller: _titleController,
            label: 'Property Title',
            hint: 'e.g., Spacious 2BHK Apartment in Prime Location',
            prefixIcon: Icons.title_rounded,
            validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
          ),
          const SizedBox(height: 12),
          
          // Description Field
          _buildModernTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Describe key features, nearby amenities, and unique selling points',
            prefixIcon: Icons.description_outlined,
            maxLines: 4,
            validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
          ),
          const SizedBox(height: 12),
          
          // Property Type Dropdown
          _buildModernDropdown<String>(
            value: currentType,
            label: 'Property Type',
            prefixIcon: Icons.home_work_outlined,
            items: allowedTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  _formatPropertyType(type),
                  style: TextStyle(
                    fontSize: isPhone ? 13 : 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() {
              _selectedPropertyType = value!;
              final allowed = _getAvailableAmenities();
              _selectedAmenities.removeWhere((a) => !allowed.contains(a));
              _scheduleDraftSave();
            }),
          ),
          
          const SizedBox(height: 24),
          
          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(
                    'Back',
                    style: TextStyle(fontSize: isPhone ? 11 : 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isPhone ? 12 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 19),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  label: Text(
                    'Continue',
                    style: TextStyle(fontSize: isPhone ? 12 : 13),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: isPhone ? 13 : 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Helper method to build modern text fields
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helperText,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool showRequiredMarker = true,
  }) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.of(context).size.width < 600;
    final isRequired = validator != null && showRequiredMarker;
    
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: isPhone ? 11 : 12),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: isPhone ? 14 : 16) : null,
        hintStyle: TextStyle(
          fontSize: isPhone ? 11 : 12,
          color: theme.hintColor.withValues(alpha: 0.9),
        ),
        labelStyle: TextStyle(fontSize: isPhone ? 13 : 15),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: prefixIcon != null ? 12 : 16,
          vertical: maxLines > 1 ? 12 : 14,
        ),
      ),
    );
  }
  
  // Helper method to build compact text fields
  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helperText,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool showRequiredMarker = true,
  }) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.of(context).size.width < 600;
    final isRequired = validator != null && showRequiredMarker;
    
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: isPhone ? 10 : 11),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: isPhone ? 14 : 16) : null,
        labelStyle: TextStyle(fontSize: isPhone ? 12 : 13),
        hintStyle: TextStyle(fontSize: isPhone ? 11 : 12, color: theme.hintColor.withValues(alpha: 0.9)),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: prefixIcon != null ? 12 : 14,
          vertical: maxLines > 1 ? 12 : 12,
        ),
      ),
    );
  }

  // Helper method to build modern dropdowns
  Widget _buildModernDropdown<T>({
    required T value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    IconData? prefixIcon,
  }) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.of(context).size.width < 600;
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      style: TextStyle(fontSize: isPhone ? 12 : 13, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: isPhone ? 13 : 15),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: isPhone ? 14 : 16) : null,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: prefixIcon != null ? 12 : 16,
          vertical: 14,
        ),
      ),
    );
  }

  // Helper method to build compact dropdowns
  Widget _buildCompactDropdown<T>({
    required T value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    IconData? prefixIcon,
  }) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.of(context).size.width < 600;
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      style: TextStyle(fontSize: isPhone ? 12 : 13, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: isPhone ? 12 : 13),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: isPhone ? 14 : 16) : null,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: prefixIcon != null ? 12 : 14,
          vertical: 12,
        ),
      ),
    );
  }

  // Format property type strings like "apartment" -> "Apartment", "penthouse_suite" -> "Penthouse Suite"
  String _formatPropertyType(String type) {
    final formatted = type.replaceAll('_', ' ');
    return formatted
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Returns base amenities plus type-specific extras without duplicates
  List<String> _getAvailableAmenities() {
    final Map<String, List<String>> extrasByType = {
      'apartment': ['Lift/Elevator', 'Security', 'Power Backup'],
      'condo': ['Gym', 'Clubhouse', 'Swimming Pool'],
      'house': ['Private Garden', 'Backyard', 'Storage Shed'],
      'villa': ['Private Pool', 'Servant Room', 'Garden'],
      'studio': ['Pantry', 'Work Desk'],
      'townhouse': ['Garage', 'Community Pool'],
      'duplex': ['Internal Staircase', 'Balcony', 'Power Backup'],
      'penthouse': ['Private Terrace', 'Lift/Elevator', 'Power Backup'],
      'bungalow': ['Large Garden', 'Private Parking', 'Servant Room'],
      'room': ['Wardrobe', 'Geyser', 'Attached Bathroom'],
      'pg': ['CCTV', 'Warden', 'Laundry', 'RO Water', 'Common Kitchen'],
      'hostel': ['CCTV', 'Warden', 'Laundry', 'Mess', 'Study Room'],
    };
    final extras = extrasByType[_selectedPropertyType] ?? const <String>[];
    final set = <String>{..._availableAmenities, ...extras};
    return set.toList()..sort();
  }

  // Filter property types by selected category
  List<String> _getTypesForCategory() {
    // This screen is residential-only: always return residential/room/PG types.
    return [
      'apartment',        // Apartment / Flat
      'house',            // Independent House
      'villa',            // Villa
      'studio',           // Studio Apartment
      'townhouse',
      'condo',
      'room',             // Single / Shared Room, Room in Shared Apartment
      'pg',               // PG / Co-living
      'hostel',           // Hostel
      'duplex',
      'penthouse',
      'bungalow',
    ];
  }

  // Attach text field listeners for draft autosave
  void _attachDraftListeners() {
    final ctrls = <TextEditingController>[
      _titleController,
      _descriptionController,
      _monthlyRentController,
      _discountPercentController,
      _securityDepositController,
      _addressController,
      _cityController,
      _stateController,
      _zipCodeController,
      _nearLandmarkController,
      _otherAmenitiesController,
      _houseRulesController,
      _pincodeController,
      _contactPersonController,
      _phoneController,
      _alternatePhoneController,
      _emailController,
      _studioSizeController,
      _floorController,
      _totalFloorsController,
      _plotAreaController,
      _parkingSpacesController,
      _hoaFeeController,
      _pgOccupancyController,
       _pgBedRentController,
      _kitchenPlatformController,
      _roomSizeController,
      _roomSharingCountController,
      _gateClosingTimeController,
      _availableFromController,
      _maxOccupancyController,
      _moveInRequirementsController,
      // Commercial controllers
      _officeCarpetAreaController,
      _officeCabinsController,
      _officeConferenceRoomsController,
      _shopCarpetAreaController,
      _shopFrontageController,
      _warehouseBuiltUpAreaController,
      _warehouseCeilingHeightController,
      _warehouseLoadingBaysController,
      _warehousePowerController,
      _carpetAreaController,
      _terraceAreaController,
      _commercialBuiltUpAreaController,
      _noticePeriodDaysController,
    ];
    for (final c in ctrls) {
      c.addListener(_scheduleDraftSave);
    }
  }

  // Debounced save
  void _scheduleDraftSave() {
    if (_suspendDraft) return;
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 400), _persistDraft);
  }

  Future<void> _persistDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'category': _selectedCategory,
        'type': _selectedPropertyType,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'monthlyRent': _monthlyRentController.text,
        'discountPercent': _discountPercentController.text,
        'securityDeposit': _securityDepositController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zipCode': _zipCodeController.text,
        'nearLandmark': _nearLandmarkController.text,
        'houseRules': _houseRulesController.text,
        'furnishing': _furnishing,
        'bedrooms': _bedrooms,
        'bathrooms': _bathrooms,
        'apartmentBhk': _apartmentBhk,
        'amenities': _selectedAmenities,
        'nearby': _selectedNearbyFacilities,
        'charges': _selectedChargesIncluded,
        'pg': {
          'occupancy': _pgOccupancyController.text,
          'gender': _pgGender,
          'meals': _pgMeals,
          'attached': _pgAttachedBathroom,
          'bedRent': _pgBedRentController.text,
        },
        'studioSize': _studioSizeController.text,
        'floor': _floorController.text,
        'totalFloors': _totalFloorsController.text,
        'plotArea': _plotAreaController.text,
        'parkingSpaces': _parkingSpacesController.text,
        'hoaFee': _hoaFeeController.text,
        'contact': {
          'person': _contactPersonController.text,
          'phone': _phoneController.text,
          'altPhone': _alternatePhoneController.text,
          'email': _emailController.text,
        },
        'prefs': {
          'tenant': _preferredTenant,
          'food': _foodPreference,
          'petsAllowed': _petsAllowed,
          'hidePhone': _hidePhoneNumber,
          'agree': _agreeToTerms,
        },
        'rentalMode': _rentalModeListing,
        'requireSeekerId': _requireSeekerId,
        'monthly': {
          'minStayMonths': _minStayMonthsMonthly,
          'noticeDays': _noticePeriodDaysController.text,
        },
        'plot': {
          'usage': _plotUsageListing,
        },
        'area': {
          'carpet': _carpetAreaController.text,
          'terrace': _terraceAreaController.text,
        },
        'room': {
          'bathroomType': _roomBathroomType,
        },
        'kitchen': {
          'type': _kitchenType,
          'access': _kitchenAccess,
          'platform': _kitchenPlatformController.text,
          'gas': _kitchenGasConnection,
          'chimney': _kitchenChimney,
          'cabinets': _kitchenCabinets,
          'commonKitchen': _kitchenCommonKitchen,
        },
        'bathroomExtra': {
          'style': _bathroomStyle,
          'hasGeyser': _bathroomHasGeyser,
          'hasExhaust': _bathroomHasExhaust,
          'pgHotWater': _pgHotWater,
        },
        'roomModule': {
          'roomType': _roomType,
          'roomSize': _roomSizeController.text,
          'sharingCount': _roomSharingCountController.text,
          'hasBed': _roomHasBed,
          'hasMattress': _roomHasMattress,
          'hasWardrobe': _roomHasWardrobe,
          'hasFan': _roomHasFan,
          'hasAC': _roomHasAC,
          'hasTable': _roomHasTable,
          'hasChair': _roomHasChair,
          'hasMirror': _roomHasMirror,
          'hasMiniFridge': _roomHasMiniFridge,
        },
        'rulesExt': {
          'visitorsAllowed': _ruleVisitorsAllowed,
          'overnightGuestsAllowed': _ruleOvernightGuestsAllowed,
          'smokingAllowed': _ruleSmokingAllowed,
          'drinkingAllowed': _ruleDrinkingAllowed,
          'cookingAllowed': _ruleCookingAllowed,
          'ownerStaysOnProperty': _ruleOwnerStaysOnProperty,
          'gateClosingTime': _gateClosingTimeController.text,
        },
        'availability': {
          'availableFrom': _availableFromController.text,
          'status': _availabilityStatus,
          'earlyMoveIn': _earlyMoveInAllowed,
          'maxOccupancy': _maxOccupancyController.text,
          'requirements': _moveInRequirementsController.text,
        },
        'commercial': {
          'office': {
            'carpetArea': _officeCarpetAreaController.text,
            'cabins': _officeCabinsController.text,
            'conferenceRooms': _officeConferenceRoomsController.text,
            'pantry': _officePantry,
          },
          'shop': {
            'carpetArea': _shopCarpetAreaController.text,
            'frontage': _shopFrontageController.text,
            'footfall': _shopFootfall,
            'washroom': _shopWashroom,
          },
          'warehouse': {
            'builtUpArea': _warehouseBuiltUpAreaController.text,
            'ceilingHeight': _warehouseCeilingHeightController.text,
            'loadingBays': _warehouseLoadingBaysController.text,
            'power': _warehousePowerController.text,
            'truckAccess': _warehouseTruckAccess,
          },
          'generic': {
            'builtUpArea': _commercialBuiltUpAreaController.text,
          },
        },
      
      };
      await prefs.setString('listing_draft_v1', jsonEncode(data));
    } catch (_) {}
  }

  // Location helpers
  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) SnackBarUtils.showWarning(context, 'Location services are disabled');
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) SnackBarUtils.showWarning(context, 'Location permission denied');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) SnackBarUtils.showWarning(context, 'Permission permanently denied. Enable in settings.');
      return false;
    }
    return true;
  }

  Future<void> _useCurrentLocation() async {
    try {
      final ok = await _ensureLocationPermission();
      if (!ok) return;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      _scheduleDraftSave();
      if (mounted) SnackBarUtils.showSuccess(context, 'Location updated');
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Failed to get location: $e');
    }
  }

  void _openMapPicker() {
    final theme = Theme.of(context);
    LatLng selected = LatLng(_latitude ?? 28.6139, _longitude ?? 77.2090); // Default: New Delhi
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Pick Location'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
                body: GoogleMap(
                  initialCameraPosition: CameraPosition(target: selected, zoom: 14.5),
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  zoomControlsEnabled: true,
                  markers: {
                    Marker(markerId: const MarkerId('sel'), position: selected),
                  },
                  onTap: (pos) {
                    setModalState(() {
                      selected = pos;
                    });
                  },
                ),
                bottomNavigationBar: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _latitude = selected.latitude;
                          _longitude = selected.longitude;
                        });
                        _scheduleDraftSave();
                        Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Use this location'),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('listing_draft_v1');
      if (raw == null || raw.isEmpty) return;

      Map<String, dynamic> map;
      try {
        map = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        // Fallback: legacy Map.toString() format
        final legacy = _parseMap(raw);
        map = _legacyToJsonMap(legacy);
      }

      if (!mounted) return;
      setState(() {
        final hasInitialCategory = widget.initialCategory != null;
        if (!hasInitialCategory) {
          final savedCategory = _asString(map['category']);
          // This screen is now residential-only: ignore any non-residential
          // categories from older drafts and always keep Residential.
          if (savedCategory == 'Residential') {
            _selectedCategory = 'Residential';
          }
          final allowed = _getTypesForCategory();
          final savedType = _asString(map['type']) ?? _selectedPropertyType;
          _selectedPropertyType =
              allowed.contains(savedType) && allowed.isNotEmpty
                  ? savedType
                  : (allowed.isNotEmpty ? allowed.first : _selectedPropertyType);
        }

        _titleController.text = _asString(map['title']) ?? '';
        _descriptionController.text = _asString(map['description']) ?? '';
        _monthlyRentController.text = _asString(map['monthlyRent']) ?? '';
        _discountPercentController.text = _asString(map['discountPercent']) ?? '';
        _securityDepositController.text = _asString(map['securityDeposit']) ?? '';
        _addressController.text = _asString(map['address']) ?? '';
        _cityController.text = _asString(map['city']) ?? '';
        _stateController.text = _asString(map['state']) ?? '';
        _zipCodeController.text = _asString(map['zipCode']) ?? '';
        _nearLandmarkController.text = _asString(map['nearLandmark']) ?? '';
        _houseRulesController.text = _asString(map['houseRules']) ?? '';
        _furnishing = _asString(map['furnishing']) ?? _furnishing;
        _bedrooms = _asInt(map['bedrooms']) ?? _bedrooms;
        _bathrooms = _asInt(map['bathrooms']) ?? _bathrooms;

        _selectedAmenities
          ..clear()
          ..addAll(_asStringList(map['amenities']));
        _selectedNearbyFacilities
          ..clear()
          ..addAll(_asStringList(map['nearby']));
        _selectedChargesIncluded
          ..clear()
          ..addAll(_asStringList(map['charges']));

        final pg = _asMap(map['pg']);
        _pgOccupancyController.text = _asString(pg['occupancy']) ?? '';
        _pgGender = _asString(pg['gender']) ?? _pgGender;
        _pgMeals = _asString(pg['meals']) ?? _pgMeals;
        _pgAttachedBathroom = _asBool(pg['attached']);
        _pgBedRentController.text = _asString(pg['bedRent']) ?? '';

        _studioSizeController.text = _asString(map['studioSize']) ?? '';
        _floorController.text = _asString(map['floor']) ?? '';
        _totalFloorsController.text = _asString(map['totalFloors']) ?? '';
        _plotAreaController.text = _asString(map['plotArea']) ?? '';
        _parkingSpacesController.text = _asString(map['parkingSpaces']) ?? '';
        _hoaFeeController.text = _asString(map['hoaFee']) ?? '';

        final contact = _asMap(map['contact']);
        _contactPersonController.text = _asString(contact['person']) ?? '';
        _phoneController.text = _asString(contact['phone']) ?? '';
        _alternatePhoneController.text = _asString(contact['altPhone']) ?? '';
        _emailController.text = _asString(contact['email']) ?? '';

        final prefsMap = _asMap(map['prefs']);
        _preferredTenant = _asString(prefsMap['tenant']) ?? _preferredTenant;
        _foodPreference = _asString(prefsMap['food']) ?? _foodPreference;
        _petsAllowed = _asBool(prefsMap['petsAllowed']);
        _hidePhoneNumber = _asBool(prefsMap['hidePhone']);
        _agreeToTerms = _asBool(prefsMap['agree']);

        // Restore rental mode selection
        _rentalModeListing = _asString(map['rentalMode']) ?? _rentalModeListing;
        _requireSeekerId = _asBool(map['requireSeekerId']);

        final monthly = _asMap(map['monthly']);
        _minStayMonthsMonthly = _asInt(monthly['minStayMonths']) ?? _minStayMonthsMonthly;
        _noticePeriodDaysController.text = _asString(monthly['noticeDays']) ?? _noticePeriodDaysController.text;

        final plot = _asMap(map['plot']);
        _plotUsageListing = _asString(plot['usage']) ?? _plotUsageListing;

        final area = _asMap(map['area']);
        _carpetAreaController.text = _asString(area['carpet']) ?? '';
        _terraceAreaController.text = _asString(area['terrace']) ?? '';

        final room = _asMap(map['room']);
        _roomBathroomType = _asString(room['bathroomType']) ?? _roomBathroomType;

        final kitchen = _asMap(map['kitchen']);
        _kitchenType = _asString(kitchen['type']) ?? _kitchenType;
        _kitchenAccess = _asString(kitchen['access']) ?? _kitchenAccess;
        _kitchenPlatformController.text = _asString(kitchen['platform']) ?? '';
        _kitchenGasConnection = _asBool(kitchen['gas']);
        _kitchenChimney = _asBool(kitchen['chimney']);
        _kitchenCabinets = _asBool(kitchen['cabinets']);
        _kitchenCommonKitchen = _asBool(kitchen['commonKitchen']);

        final bathExtra = _asMap(map['bathroomExtra']);
        _bathroomStyle = _asString(bathExtra['style']) ?? _bathroomStyle;
        _bathroomHasGeyser = _asBool(bathExtra['hasGeyser']);
        _bathroomHasExhaust = _asBool(bathExtra['hasExhaust']);
        _pgHotWater = _asBool(bathExtra['pgHotWater']);

        final roomModule = _asMap(map['roomModule']);
        _roomType = _asString(roomModule['roomType']) ?? _roomType;
        _roomSizeController.text = _asString(roomModule['roomSize']) ?? '';
        _roomSharingCountController.text = _asString(roomModule['sharingCount']) ?? '';
        _roomHasBed = _asBool(roomModule['hasBed']);
        _roomHasMattress = _asBool(roomModule['hasMattress']);
        _roomHasWardrobe = _asBool(roomModule['hasWardrobe']);
        _roomHasFan = _asBool(roomModule['hasFan']);
        _roomHasAC = _asBool(roomModule['hasAC']);
        _roomHasTable = _asBool(roomModule['hasTable']);
        _roomHasChair = _asBool(roomModule['hasChair']);
        _roomHasMirror = _asBool(roomModule['hasMirror']);
        _roomHasMiniFridge = _asBool(roomModule['hasMiniFridge']);

        final rulesExt = _asMap(map['rulesExt']);
        _ruleVisitorsAllowed = _asBool(rulesExt['visitorsAllowed']);
        _ruleOvernightGuestsAllowed = _asBool(rulesExt['overnightGuestsAllowed']);
        _ruleSmokingAllowed = _asBool(rulesExt['smokingAllowed']);
        _ruleDrinkingAllowed = _asBool(rulesExt['drinkingAllowed']);
        _ruleCookingAllowed = _asBool(rulesExt['cookingAllowed']);
        _ruleOwnerStaysOnProperty = _asBool(rulesExt['ownerStaysOnProperty']);
        _gateClosingTimeController.text = _asString(rulesExt['gateClosingTime']) ?? '';

        final availability = _asMap(map['availability']);
        _availableFromController.text = _asString(availability['availableFrom']) ?? '';
        _availabilityStatus = _asString(availability['status']) ?? _availabilityStatus;
        _earlyMoveInAllowed = _asBool(availability['earlyMoveIn']);
        _maxOccupancyController.text = _asString(availability['maxOccupancy']) ?? '';
        _moveInRequirementsController.text = _asString(availability['requirements']) ?? '';

        final commercial = _asMap(map['commercial']);
        final office = _asMap(commercial['office']);
        _officeCarpetAreaController.text = _asString(office['carpetArea']) ?? '';
        _officeCabinsController.text = _asString(office['cabins']) ?? '';
        _officeConferenceRoomsController.text = _asString(office['conferenceRooms']) ?? '';
        _officePantry = _asBool(office['pantry']);
        final shop = _asMap(commercial['shop']);
        _shopCarpetAreaController.text = _asString(shop['carpetArea']) ?? '';
        _shopFrontageController.text = _asString(shop['frontage']) ?? '';
        _shopFootfall = _asString(shop['footfall']) ?? _shopFootfall;
        _shopWashroom = _asBool(shop['washroom']);
        final warehouse = _asMap(commercial['warehouse']);
        _warehouseBuiltUpAreaController.text = _asString(warehouse['builtUpArea']) ?? '';
        _warehouseCeilingHeightController.text = _asString(warehouse['ceilingHeight']) ?? '';
        _warehouseLoadingBaysController.text = _asString(warehouse['loadingBays']) ?? '';
        _warehousePowerController.text = _asString(warehouse['power']) ?? '';
        _warehouseTruckAccess = _asBool(warehouse['truckAccess']);
        final generic = _asMap(commercial['generic']);
        _commercialBuiltUpAreaController.text = _asString(generic['builtUpArea']) ?? '';
        // Geo (lat/lng)
        final geo = _asMap(map['geo']);
        final latRaw = geo['lat'];
        final lngRaw = geo['lng'];
        if (latRaw is num) {
          _latitude = latRaw.toDouble();
        } else if (latRaw is String) {
          _latitude = double.tryParse(latRaw);
        }
        if (lngRaw is num) {
          _longitude = lngRaw.toDouble();
        } else if (lngRaw is String) {
          _longitude = double.tryParse(lngRaw);
        }
      });
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('listing_draft_v1');
    } catch (_) {}
  }

  Future<void> _handleClearDraft() async {
    _suspendDraft = true;
    try {
      // Reset form fields
      setState(() {
        _selectedCategory = 'Residential';
        _selectedPropertyType = _getTypesForCategory().first;
        _rentalModeListing = 'both';
        _minStayMonthsMonthly = 0;
        _titleController.clear();
        _descriptionController.clear();
        _monthlyRentController.clear();
        _securityDepositController.clear();
        _noticePeriodDaysController.clear();
        _addressController.clear();
        _cityController.clear();
        _stateController.clear();
        _zipCodeController.clear();
        _nearLandmarkController.clear();
        _houseRulesController.clear();
        _pincodeController.clear();
        _contactPersonController.clear();
        _phoneController.clear();
        _alternatePhoneController.clear();
        _emailController.clear();
        _carpetAreaController.clear();
        _terraceAreaController.clear();
        _roomBathroomType = 'Attached';
        _pgAttachedBathroom = true;
        _pgGender = 'Any';
        _pgMeals = 'No Meals';
        _furnishing = 'Select';
        _bedrooms = 1;
        _bathrooms = 1;
        _preferredTenant = 'Select';
        _foodPreference = 'No Preference';
        _petsAllowed = false;
        _hidePhoneNumber = false;
        _agreeToTerms = false;
        _requireSeekerId = false;
        _selectedAmenities.clear();
        _selectedNearbyFacilities.clear();
        _selectedChargesIncluded.clear();
        _selectedImages.clear();
        _kitchenPlatformController.clear();
        _kitchenType = 'Modular';
        _kitchenAccess = 'Full';
        _kitchenGasConnection = false;
        _kitchenChimney = false;
        _kitchenCabinets = false;
        _kitchenCommonKitchen = false;
        _bathroomHasGeyser = true;
        _bathroomStyle = 'Western';
        _bathroomHasExhaust = false;
        _pgHotWater = true;
        _roomType = 'Single Room';
        _roomSizeController.clear();
        _roomSharingCountController.clear();
        _roomHasBed = true;
        _roomHasMattress = true;
        _roomHasWardrobe = true;
        _roomHasFan = true;
        _roomHasAC = false;
        _roomHasTable = false;
        _roomHasChair = false;
        _roomHasMirror = false;
        _roomHasMiniFridge = false;
        _ruleVisitorsAllowed = true;
        _ruleOvernightGuestsAllowed = false;
        _ruleSmokingAllowed = false;
        _ruleDrinkingAllowed = false;
        _ruleCookingAllowed = true;
        _ruleOwnerStaysOnProperty = false;
        _gateClosingTimeController.clear();
        _availableFromController.clear();
        _availabilityStatus = 'Vacant';
        _earlyMoveInAllowed = false;
        _maxOccupancyController.clear();
        _moveInRequirementsController.clear();
      });
      await _clearDraft();
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Draft cleared');
    } finally {
      _suspendDraft = false;
    }
  }

  // Tiny helper to parse Map.toString(); for production, use JSON serialization
  Map<String, String> _parseMap(String raw) {
    final out = <String, String>{};
    final trimmed = raw.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) return out;
    final inner = trimmed.substring(1, trimmed.length - 1);
    for (final part in inner.split(',')) {
      final idx = part.indexOf(':');
      if (idx <= 0) continue;
      final k = part.substring(0, idx).trim();
      final v = part.substring(idx + 1).trim();
      out[k.replaceAll("'", '')] = v.replaceAll("'", '');
    }
    return out;
  }

  // Helpers for robust JSON/legacy decoding
  String? _asString(dynamic v) => v?.toString();
  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is double) return v.toInt();
    return null;
  }
  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) {
      final s = v.toLowerCase().trim();
      if (s == 'true') return true;
      if (s == 'false') return false;
    }
    if (v is num) return v != 0;
    return false;
  }
  List<String> _asStringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    if (v is String) {
      // legacy serialized list like "[a, b, c]"
      final inner = v.replaceAll('[', '').replaceAll(']', '');
      return inner
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }
  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) {
      return v.map((key, value) => MapEntry(key.toString(), value));
    }
    if (v is String) {
      return _parseMap(v);
    }
    return <String, dynamic>{};
  }
  Map<String, dynamic> _legacyToJsonMap(Map<String, String> m) {
    return {
      'category': m['category'],
      'type': m['type'],
      'title': m['title'],
      'description': m['description'],
      'monthlyRent': m['monthlyRent'],
      'securityDeposit': m['securityDeposit'],
      'address': m['address'],
      'city': m['city'],
      'state': m['state'],
      'zipCode': m['zipCode'],
      'nearLandmark': m['nearLandmark'],
      'furnishing': m['furnishing'],
      'bedrooms': m['bedrooms'],
      'bathrooms': m['bathrooms'],
      'amenities': m['amenities'],
      'nearby': m['nearby'],
      'charges': m['charges'],
      'pg': m['pg'] ?? '{}',
      'contact': m['contact'] ?? '{}',
      'prefs': m['prefs'] ?? '{}',
    };
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _securityDepositController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _nearLandmarkController.dispose();
    _otherAmenitiesController.dispose();
    _houseRulesController.dispose();
    _pincodeController.dispose();
    _monthlyRentController.dispose();
    _kitchenPlatformController.dispose();
    _roomSizeController.dispose();
    _roomSharingCountController.dispose();
    _gateClosingTimeController.dispose();
    _availableFromController.dispose();
    _maxOccupancyController.dispose();
    _moveInRequirementsController.dispose();
    _noticePeriodDaysController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _discountPercentController.dispose();
    _carpetAreaController.dispose();
    _terraceAreaController.dispose();
    _commercialBuiltUpAreaController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.length > 10) {
        if (mounted) {
          SnackBarUtils.showWarning(context, 'You can select maximum 10 images');
        }
        return;
      }

      setState(() {
        _selectedImages = images;
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to pick images: $e');
      }
    }
  }

  // Video and document upload are not supported in this screen; only photos are used.


  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      SnackBarUtils.showWarning(context, 'Please select at least one image');
      return;
    }

    // Require owner role and KYC verification before creating a listing
    final auth = ref.read(authProvider);
    final user = auth.user;
    if (user == null || user.role != UserRole.owner) {
      SnackBarUtils.showWarning(context, 'Only owners can create listings. Please switch to Owner role.');
      if (mounted) context.go('/role');
      return;
    }
    if (!user.isKycVerified) {
      SnackBarUtils.showWarning(context, 'Please complete owner verification (KYC) before listing.');
      if (mounted) context.push('/kyc');
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Upload images
      final imageService = ref.read(imageServiceProvider);
      List<String> imageUrls = [];
      
      for (XFile image in _selectedImages) {
        String? imageUrl = await imageService.uploadImage(image);
        if (imageUrl != null) {
          imageUrls.add(imageUrl);
        }
      }

      // Create amenities map
      Map<String, dynamic> amenitiesMap = {};
      for (String amenity in _selectedAmenities) {
        amenitiesMap[amenity.toLowerCase().replaceAll(' ', '_')] = true;
      }

      // Rental & deposits
      amenitiesMap['rental_mode'] = _rentalModeListing;
      int? secDep = int.tryParse(_securityDepositController.text.trim());
      if ((secDep == null || secDep <= 0) && _rentalModeListing == 'monthly') {
        final mr = int.tryParse(_monthlyRentController.text.trim());
        if (mr != null && mr > 0) secDep = mr; // default to 1-month deposit
      }
      if (secDep != null) amenitiesMap['security_deposit'] = secDep;

      // Add type-specific details into metadata
      if (_selectedPropertyType == 'studio') {
        final size = int.tryParse(_studioSizeController.text.trim());
        if (size != null) amenitiesMap['studio_size_sqft'] = size;
      }
      if (_selectedPropertyType == 'apartment' || _selectedPropertyType == 'condo') {
        final floor = int.tryParse(_floorController.text.trim());
        final totalFloors = int.tryParse(_totalFloorsController.text.trim());
        if (floor != null) amenitiesMap['floor'] = floor;
        if (totalFloors != null) amenitiesMap['total_floors'] = totalFloors;
      }
      if (_selectedPropertyType == 'condo') {
        final hoa = double.tryParse(_hoaFeeController.text.trim());
        if (hoa != null) amenitiesMap['hoa_fee'] = hoa;
      }
      if (_selectedPropertyType == 'house' || _selectedPropertyType == 'villa') {
        final plot = int.tryParse(_plotAreaController.text.trim());
        final parking = int.tryParse(_parkingSpacesController.text.trim());
        if (plot != null) amenitiesMap['plot_area_sqft'] = plot;
        if (parking != null) amenitiesMap['parking_spaces'] = parking;
      }
      if (_selectedPropertyType == 'apartment' || _selectedPropertyType == 'condo' || _selectedPropertyType == 'townhouse' || _selectedPropertyType == 'duplex' || _selectedPropertyType == 'penthouse') {
        final carpet = int.tryParse(_carpetAreaController.text.trim());
        if (carpet != null) amenitiesMap['carpet_area_sqft'] = carpet;
      }
      if (_selectedPropertyType == 'penthouse') {
        final terr = int.tryParse(_terraceAreaController.text.trim());
        if (terr != null) amenitiesMap['penthouse_terrace_area_sqft'] = terr;
      }
      if (_selectedPropertyType == 'bungalow') {
        final plot = int.tryParse(_plotAreaController.text.trim());
        final parking = int.tryParse(_parkingSpacesController.text.trim());
        if (plot != null) amenitiesMap['plot_area_sqft'] = plot;
        if (parking != null) amenitiesMap['parking_spaces'] = parking;
      }
      if (_selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel') {
        final occ = int.tryParse(_pgOccupancyController.text.trim());
        if (occ != null) amenitiesMap['pg_occupancy'] = occ;
        amenitiesMap['pg_gender'] = _pgGender.toLowerCase();
        amenitiesMap['pg_meals'] = _pgMeals.toLowerCase().replaceAll(' + ', '_').replaceAll(' ', '_');
        amenitiesMap['attached_bathroom'] = _pgAttachedBathroom;
      }
      if (_selectedPropertyType == 'room') {
        amenitiesMap['room_bathroom_type'] = _roomBathroomType.toLowerCase();
      }
      // Kitchen mapping
      if (_selectedPropertyType == 'apartment' ||
          _selectedPropertyType == 'house' ||
          _selectedPropertyType == 'villa' ||
          _selectedPropertyType == 'condo' ||
          _selectedPropertyType == 'townhouse' ||
          _selectedPropertyType == 'duplex' ||
          _selectedPropertyType == 'penthouse' ||
          _selectedPropertyType == 'studio') {
        amenitiesMap['kitchen_type'] = _kitchenType.toLowerCase();
        final platform = _kitchenPlatformController.text.trim();
        if (platform.isNotEmpty) amenitiesMap['kitchen_platform'] = platform;
        amenitiesMap['kitchen_gas_connection'] = _kitchenGasConnection;
        amenitiesMap['kitchen_chimney'] = _kitchenChimney;
        amenitiesMap['kitchen_cabinets'] = _kitchenCabinets;
      } else {
        amenitiesMap['kitchen_access'] = _kitchenAccess.toLowerCase().replaceAll(' ', '_');
        amenitiesMap['common_kitchen_available'] = _kitchenCommonKitchen;
      }

      // Bathroom extras
      if (!(_selectedPropertyType == 'room' || _selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel')) {
        amenitiesMap['bathroom_style'] = _bathroomStyle.toLowerCase();
        amenitiesMap['bathroom_geyser'] = _bathroomHasGeyser;
        amenitiesMap['bathroom_exhaust'] = _bathroomHasExhaust;
      } else {
        final sharing = int.tryParse(_roomSharingCountController.text.trim());
        if (sharing != null) amenitiesMap['bathroom_sharing_count'] = sharing;
        amenitiesMap['pg_hot_water'] = _pgHotWater;
      }

      // Room module mapping
      if (_selectedPropertyType == 'room' || _selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel' || _selectedPropertyType == 'studio') {
        amenitiesMap['room_type'] = _roomType.toLowerCase().replaceAll(' ', '_');
        final size = int.tryParse(_roomSizeController.text.trim());
        if (size != null) amenitiesMap['room_size_sqft'] = size;
        amenitiesMap['room_has_bed'] = _roomHasBed;
        amenitiesMap['room_has_mattress'] = _roomHasMattress;
        amenitiesMap['room_has_wardrobe'] = _roomHasWardrobe;
        amenitiesMap['room_has_fan'] = _roomHasFan;
        amenitiesMap['room_has_ac'] = _roomHasAC;
        amenitiesMap['room_has_table'] = _roomHasTable;
        amenitiesMap['room_has_chair'] = _roomHasChair;
        amenitiesMap['room_has_mirror'] = _roomHasMirror;
        amenitiesMap['room_has_mini_fridge'] = _roomHasMiniFridge;
      }
      if (_selectedCategory == 'Residential') {
        final rules = _houseRulesController.text.trim();
        if (rules.isNotEmpty) {
          amenitiesMap['house_rules'] = rules;
        }
        if (_selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel') {
          final bedRent = int.tryParse(_pgBedRentController.text.trim());
          if (bedRent != null) {
            amenitiesMap['pg_bed_rent'] = bedRent;
          }
        }
      }
      // Extended rules & availability
      amenitiesMap['visitors_allowed'] = _ruleVisitorsAllowed;
      amenitiesMap['overnight_guests_allowed'] = _ruleOvernightGuestsAllowed;
      amenitiesMap['smoking_allowed'] = _ruleSmokingAllowed;
      amenitiesMap['drinking_allowed'] = _ruleDrinkingAllowed;
      amenitiesMap['cooking_allowed'] = _ruleCookingAllowed;
      amenitiesMap['owner_stays_on_property'] = _ruleOwnerStaysOnProperty;
      final gateTime = _gateClosingTimeController.text.trim();
      if (gateTime.isNotEmpty) amenitiesMap['gate_closing_time'] = gateTime;

      final availableFrom = _availableFromController.text.trim();
      if (availableFrom.isNotEmpty) amenitiesMap['available_from'] = availableFrom;
      amenitiesMap['availability_status'] = _availabilityStatus.toLowerCase();
      amenitiesMap['early_move_in'] = _earlyMoveInAllowed;
      final maxOcc = int.tryParse(_maxOccupancyController.text.trim());
      if (maxOcc != null) amenitiesMap['max_occupancy'] = maxOcc;
      final req = _moveInRequirementsController.text.trim();
      if (req.isNotEmpty) amenitiesMap['move_in_requirements'] = req;
      // Monthly/Rental mode meta
      if (_rentalModeListing == 'monthly') {
        amenitiesMap['rental_unit'] = 'monthly';
        amenitiesMap['monthly_min_stay_months'] = _minStayMonthsMonthly;
        final nd = int.tryParse(_noticePeriodDaysController.text.trim());
        if (nd != null) amenitiesMap['monthly_notice_period_days'] = nd;
      } else if (_rentalModeListing == 'rental') {
        amenitiesMap['rental_unit'] = 'day';
      } else {
        // both
        amenitiesMap['rental_unit'] = 'both';
      }

      // Create listing
      final String? rentalUnit = _rentalModeListing == 'monthly'
          ? 'month'
          : _rentalModeListing == 'rental'
              ? 'day'
              : null; // 'both' -> normal daily flow
      final listing = Listing(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_monthlyRentController.text),
        type: _selectedPropertyType,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        zipCode: _zipCodeController.text,
        images: imageUrls,
        ownerId: 'current_user_id',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        amenities: amenitiesMap,
        requireSeekerId: _requireSeekerId,
        rentalUnit: rentalUnit,
        securityDeposit: secDep?.toDouble(),
        monthlyMinStayMonths: _rentalModeListing == 'monthly' ? _minStayMonthsMonthly : null,
        monthlyNoticePeriodDays: _rentalModeListing == 'monthly' ? int.tryParse(_noticePeriodDaysController.text.trim()) : null,
        discountPercent: () {
          final d = double.tryParse(_discountPercentController.text.trim());
          if (d == null) return null;
          final clamped = d.clamp(0, 90).toDouble();
          return clamped;
        }(),
      );

      await ref.read(listingProvider.notifier).addListing(listing);
      await _clearDraft();
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Listing created successfully!');
      context.pop();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to create listing: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isPhone = size.width < 600;
    // final isTablet = size.width >= 600 && size.width < 1200; // Reserved for future use

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isPhone ? 56 : 64),
        child: AppBar(
          title: Text(
            'Create Listing',
            style: TextStyle(
              fontSize: isPhone ? 16 : 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Clear All',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.refresh, size: 18, color: Colors.white),
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Clear Form?', style: TextStyle(fontSize: isPhone ? 14 : 16)),
                      content: Text('This will remove all entered data.', 
                        style: TextStyle(fontSize: isPhone ? 12 : 13)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false), 
                          child: Text('Cancel', style: TextStyle(fontSize: isPhone ? 11 : 12))
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true), 
                          child: Text('Clear', style: TextStyle(fontSize: isPhone ? 11 : 12, color: Colors.red))
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    await _handleClearDraft();
                  }
                },
              ),
            ),
          ],
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.85),
                  theme.colorScheme.secondary.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Ultra-minimal Progress Bar
          Container(
            height: 1,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            ),
            child: LinearProgressIndicator(
              value: (_tabController.index + 1) / 6,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
              minHeight: 1,
            ),
          ),
          // Modern Tab Navigation
          Container(
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                // Ultra-compact Step indicator  
                Container(
                  padding: EdgeInsets.zero,
                  child: const SizedBox.shrink(),
                ),
                // Tab bar with modern design
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorWeight: 2.5,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    labelStyle: TextStyle(
                      fontSize: isPhone ? 8 : 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: isPhone ? 8 : 9,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                    labelPadding: EdgeInsets.symmetric(
                      horizontal: isPhone ? 6 : 8,
                    ),
                    tabs: [
                      Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home_outlined, size: isPhone ? 14 : 16),
                            SizedBox(height: isPhone ? 2 : 3),
                            const Text('Basics'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: isPhone ? 14 : 16),
                            SizedBox(height: isPhone ? 2 : 3),
                            const Text('Property Details'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_outline, size: isPhone ? 14 : 16),
                            SizedBox(height: isPhone ? 2 : 3),
                            const Text('Amenities'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payments_outlined, size: isPhone ? 14 : 16),
                            SizedBox(height: isPhone ? 2 : 3),
                            const Text('Pricing'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera_outlined, size: isPhone ? 14 : 16),
                            SizedBox(height: isPhone ? 2 : 3),
                            const Text('Media'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.contact_phone_outlined, size: isPhone ? 14 : 16),
                            SizedBox(height: isPhone ? 2 : 3),
                            const Text('Contact'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Form Content
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              child: ResponsiveLayout(
                maxWidth: 800,
                child: Theme(
                  data: theme.copyWith(
                    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: TabBarView(
                      controller: _tabController,
                      dragStartBehavior: DragStartBehavior.down,
                      physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
                      children: [
                        _buildBasicsStep(),
                        _buildDetailsStep(),
                        _buildAmenitiesStep(),
                        _buildPricingStep(),
                        _buildPhotosStep(),
                        _buildContactStep(),
                      ],
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

  Widget _buildDetailsStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final showFurnishing = _selectedPropertyType != 'studio';
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Details',
            style: TextStyle(
              fontSize: isPhone ? 16 : 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          if (_selectedCategory == 'Residential') ...[
            ResidentialDetailsForm(
              propertyType: _selectedPropertyType,
              furnishing: _furnishing,
              furnishingOptions: _furnishingOptions,
              onFurnishingChanged: (v) { setState(() { _furnishing = v; }); _scheduleDraftSave(); },
              apartmentBhk: _apartmentBhk,
              bhkOptions: _bhkOptions,
              onApartmentBhkChanged: (v) { setState(() { _apartmentBhk = v; }); _scheduleDraftSave(); },
              bedrooms: _bedrooms,
              onBedroomsChanged: (v) { setState(() { _bedrooms = v; }); _scheduleDraftSave(); },
              bathrooms: _bathrooms,
              onBathroomsChanged: (v) { setState(() { _bathrooms = v; }); _scheduleDraftSave(); },
              roomBathroomType: _roomBathroomType,
              roomBathroomOptions: _roomBathroomOptions,
              onRoomBathroomTypeChanged: (v) { setState(() { _roomBathroomType = v; }); _scheduleDraftSave(); },
              studioSizeController: _studioSizeController,
              floorController: _floorController,
              totalFloorsController: _totalFloorsController,
              plotAreaController: _plotAreaController,
              parkingSpacesController: _parkingSpacesController,
              hoaFeeController: _hoaFeeController,
              carpetAreaController: _carpetAreaController,
              terraceAreaController: _terraceAreaController,
              pgOccupancyController: _pgOccupancyController,
              pgGender: _pgGender,
              pgGenderOptions: _pgGenderOptions,
              onPgGenderChanged: (v) { setState(() { _pgGender = v; }); _scheduleDraftSave(); },
              pgMeals: _pgMeals,
              pgMealsOptions: _pgMealsOptions,
              onPgMealsChanged: (v) { setState(() { _pgMeals = v; }); _scheduleDraftSave(); },
              pgAttachedBathroom: _pgAttachedBathroom,
              onPgAttachedBathroomChanged: (v) { setState(() { _pgAttachedBathroom = v; }); _scheduleDraftSave(); },
            ),
            const SizedBox(height: 12),
            if (_selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel') ...[
              Text(
                'PG Occupancy Quick Select',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: const [1, 2, 3, 4, 5, 6].map((occ) {
                  return Builder(builder: (context) {
                    final theme = Theme.of(context);
                    final isSelected = _pgOccupancyController.text.trim() == occ.toString();
                    return ChoiceChip(
                      label: Text('$occ per room'),
                      selected: isSelected,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      selectedColor: theme.colorScheme.secondary.withValues(alpha: 0.9),
                      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                      shape: const StadiumBorder(),
                      onSelected: (_) {
                        setState(() {
                          _pgOccupancyController.text = occ.toString();
                        });
                        _scheduleDraftSave();
                      },
                    );
                  });
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ],
          LayoutBuilder(builder: (context, cons) {
            final isXS = cons.maxWidth < 360;
            if (isXS) {
              return Column(
                children: [
                  if (showFurnishing)
                    _buildCompactDropdown<String>(
                      value: _furnishing,
                      label: 'Furnishing',
                      items: _furnishingOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(
                            option,
                            style: TextStyle(fontSize: isPhone ? 12 : 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _furnishing = value!),
                    ),
                  if (_selectedPropertyType == 'apartment') ...[
                    const SizedBox(height: 12),
                    _buildCompactDropdown<String>(
                      value: _apartmentBhk,
                      label: 'Configuration',
                      items: _bhkOptions.map((bhk) {
                        return DropdownMenuItem(
                          value: bhk,
                          child: Text(
                            bhk,
                            style: TextStyle(fontSize: isPhone ? 12 : 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() {
                        _apartmentBhk = value!;
                        _scheduleDraftSave();
                      }),
                    ),
                  ] else if (_selectedPropertyType != 'studio' && _selectedPropertyType != 'pg' && _selectedPropertyType != 'hostel' && _selectedPropertyType != 'room') ...[
                    const SizedBox(height: 12),
                    _buildCompactDropdown<int>(
                      value: _bedrooms,
                      label: 'Bedrooms',
                      items: List.generate(6, (index) => index + 1).map((number) {
                        return DropdownMenuItem(
                          value: number,
                          child: Text(
                            '$number',
                            style: TextStyle(fontSize: isPhone ? 12 : 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _bedrooms = value!),
                    ),
                  ],
                  if (_selectedPropertyType == 'room')
                    _buildCompactDropdown<String>(
                      value: _roomBathroomType,
                      label: 'Bathroom Type',
                      items: _roomBathroomOptions.map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t,
                          style: TextStyle(fontSize: isPhone ? 12: 13),
                        ),
                      )).toList(),
                      onChanged: (v) => setState(() { _roomBathroomType = v ?? _roomBathroomType; _scheduleDraftSave(); }),
                    ),
                ],
              );
            }
            return Row(
              children: [
                if (showFurnishing)
                  Expanded(
                    child: _buildCompactDropdown<String>(
                      value: _furnishing,
                      label: 'Furnishing',
                      items: _furnishingOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(
                            option,
                            style: TextStyle(fontSize: isPhone ? 12 : 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _furnishing = value!),
                    ),
                  ),
                if (showFurnishing) const SizedBox(width: 16),
                if (_selectedPropertyType == 'apartment')
                  Expanded(
                    child: _buildCompactDropdown<String>(
                      value: _apartmentBhk,
                      label: 'Configuration',
                      items: _bhkOptions.map((bhk) {
                        return DropdownMenuItem(
                          value: bhk,
                          child: Text(
                            bhk,
                            style: TextStyle(fontSize: isPhone ? 12 : 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() {
                        _apartmentBhk = value!;
                        _scheduleDraftSave();
                      }),
                    ),
                  )
                else if (_selectedPropertyType != 'studio' && _selectedPropertyType != 'pg' && _selectedPropertyType != 'hostel' && _selectedPropertyType != 'room')
                  Expanded(
                    child: _buildCompactDropdown<int>(
                      value: _bedrooms,
                      label: 'Bedrooms',
                      items: List.generate(6, (index) => index + 1).map((number) {
                        return DropdownMenuItem(
                          value: number,
                          child: Text(
                            '$number',
                            style: TextStyle(fontSize: isPhone ? 12 : 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _bedrooms = value!),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            );
          }),
          const SizedBox(height: 16),

          // Kitchen Details
          Text(
            'Kitchen Details',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_selectedPropertyType == 'apartment' ||
              _selectedPropertyType == 'house' ||
              _selectedPropertyType == 'villa' ||
              _selectedPropertyType == 'condo' ||
              _selectedPropertyType == 'townhouse' ||
              _selectedPropertyType == 'duplex' ||
              _selectedPropertyType == 'penthouse' ||
              _selectedPropertyType == 'studio') ...[
            DropdownButtonFormField<String>(
              initialValue: _kitchenType,
              decoration: InputDecoration(
                labelText: 'Kitchen Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Modular', child: Text('Modular')),
                DropdownMenuItem(value: 'Open', child: Text('Open')),
                DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                DropdownMenuItem(value: 'Kitchenette', child: Text('Kitchenette')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _kitchenType = v);
                _scheduleDraftSave();
              },
            ),
            const SizedBox(height: 12),
            _buildCompactTextField(
              controller: _kitchenPlatformController,
              label: 'Kitchen Platform / Counter Type',
              hint: 'e.g., Granite platform',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: const Text('Gas Connection'),
                  selected: _kitchenGasConnection,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _kitchenGasConnection
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  onSelected: (v) {
                    setState(() => _kitchenGasConnection = v);
                    _scheduleDraftSave();
                  },
                ),
                FilterChip(
                  label: const Text('Chimney'),
                  selected: _kitchenChimney,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _kitchenChimney
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  onSelected: (v) {
                    setState(() => _kitchenChimney = v);
                    _scheduleDraftSave();
                  },
                ),
                FilterChip(
                  label: const Text('Cabinets'),
                  selected: _kitchenCabinets,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _kitchenCabinets
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  onSelected: (v) {
                    setState(() => _kitchenCabinets = v);
                    _scheduleDraftSave();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else ...[
            DropdownButtonFormField<String>(
              initialValue: _kitchenAccess,
              decoration: InputDecoration(
                labelText: 'Kitchen Access',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Full', child: Text('Full')),
                DropdownMenuItem(value: 'Limited', child: Text('Limited')),
                DropdownMenuItem(value: 'No Access', child: Text('No Access')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _kitchenAccess = v);
                _scheduleDraftSave();
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _kitchenCommonKitchen,
              onChanged: (v) {
                setState(() => _kitchenCommonKitchen = v);
                _scheduleDraftSave();
              },
              title: const Text('Common Kitchen Available'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
          ],

          // Bathroom Details
          Text(
            'Bathroom Details',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (!(_selectedPropertyType == 'room' || _selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel')) ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _bathroomStyle,
                    decoration: InputDecoration(
                      labelText: 'Bathroom Style',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Western', child: Text('Western')),
                      DropdownMenuItem(value: 'Indian', child: Text('Indian')),
                      DropdownMenuItem(value: 'Both', child: Text('Both')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _bathroomStyle = v);
                      _scheduleDraftSave();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SwitchListTile(
                    value: _bathroomHasGeyser,
                    onChanged: (v) {
                      setState(() => _bathroomHasGeyser = v);
                      _scheduleDraftSave();
                    },
                    title: const Text('Geyser'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _bathroomHasExhaust,
              onChanged: (v) {
                setState(() => _bathroomHasExhaust = v);
                _scheduleDraftSave();
              },
              title: const Text('Exhaust Fan'),
              contentPadding: EdgeInsets.zero,
            ),
          ] else ...[
            _buildCompactTextField(
              controller: _roomSharingCountController,
              label: 'Number of people sharing bathroom (if shared)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _pgHotWater,
              onChanged: (v) {
                setState(() => _pgHotWater = v);
                _scheduleDraftSave();
              },
              title: const Text('Hot Water Available'),
              contentPadding: EdgeInsets.zero,
            ),
          ],

          const SizedBox(height: 16),
          if (_selectedPropertyType == 'room' || _selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel' || _selectedPropertyType == 'studio') ...[
            Text(
              'Room Module',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _roomType,
              decoration: InputDecoration(
                labelText: 'Room Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Single Room', child: Text('Single Room')),
                DropdownMenuItem(value: 'Single Room (Attached Bathroom)', child: Text('Single Room (Attached Bathroom)')),
                DropdownMenuItem(value: 'Single Room (Shared Bathroom)', child: Text('Single Room (Shared Bathroom)')),
                DropdownMenuItem(value: 'Double Sharing', child: Text('Double Sharing')),
                DropdownMenuItem(value: 'Triple Sharing', child: Text('Triple Sharing')),
                DropdownMenuItem(value: '4+ Sharing', child: Text('4+ Sharing')),
                DropdownMenuItem(value: 'Dormitory Bed', child: Text('Dormitory Bed')),
                DropdownMenuItem(value: 'Studio Room', child: Text('Studio Room')),
                DropdownMenuItem(value: 'Private Room in Shared Apartment', child: Text('Private Room in Shared Apartment')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _roomType = v);
                _scheduleDraftSave();
              },
            ),
            const SizedBox(height: 8),
            _buildCompactTextField(
              controller: _roomSizeController,
              label: 'Room Size (sq ft)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: const Text('Bed'),
                  selected: _roomHasBed,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _roomHasBed
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  onSelected: (v) {
                    setState(() => _roomHasBed = v);
                    _scheduleDraftSave();
                  },
                ),
                FilterChip(
                  label: const Text('Mattress'),
                  selected: _roomHasMattress,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _roomHasMattress
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  onSelected: (v) {
                    setState(() => _roomHasMattress = v);
                    _scheduleDraftSave();
                  },
                ),
                FilterChip(
                  label: const Text('Wardrobe'),
                  selected: _roomHasWardrobe,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _roomHasWardrobe
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  onSelected: (v) {
                    setState(() => _roomHasWardrobe = v);
                    _scheduleDraftSave();
                  },
                ),
                FilterChip(
                  label: const Text('Fan'),
                  selected: _roomHasFan,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _roomHasFan
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  onSelected: (v) {
                    setState(() => _roomHasFan = v);
                    _scheduleDraftSave();
                  },
                ),
                FilterChip(
                  label: const Text('AC'),
                  selected: _roomHasAC,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _roomHasAC
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  onSelected: (v) {
                    setState(() => _roomHasAC = v);
                    _scheduleDraftSave();
                  },
                ),
                FilterChip(
                  label: const Text('Table'),
                  selected: _roomHasTable,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _roomHasTable
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  onSelected: (v) {
                    setState(() => _roomHasTable = v);
                    _scheduleDraftSave();
                  },
                ),
                FilterChip(
                  label: const Text('Chair'),
                  selected: _roomHasChair,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _roomHasChair
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  onSelected: (v) {
                    setState(() => _roomHasChair = v);
                    _scheduleDraftSave();
                  },
                ),
                FilterChip(
                  label: const Text('Mirror'),
                  selected: _roomHasMirror,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _roomHasMirror
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  onSelected: (v) {
                    setState(() => _roomHasMirror = v);
                    _scheduleDraftSave();
                  },
                ),
                FilterChip(
                  label: const Text('Mini Fridge'),
                  selected: _roomHasMiniFridge,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _roomHasMiniFridge
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  onSelected: (v) {
                    setState(() => _roomHasMiniFridge = v);
                    _scheduleDraftSave();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 12),

            // Rules & Restrictions (for PG/Hostel/Shared)
            Text(
              'Rules & Restrictions',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _ruleVisitorsAllowed,
              onChanged: (v) {
                setState(() => _ruleVisitorsAllowed = v);
                _scheduleDraftSave();
              },
              title: const Text('Visitors allowed'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _ruleOvernightGuestsAllowed,
              onChanged: (v) {
                setState(() => _ruleOvernightGuestsAllowed = v);
                _scheduleDraftSave();
              },
              title: const Text('Overnight guests allowed'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _ruleSmokingAllowed,
              onChanged: (v) {
                setState(() => _ruleSmokingAllowed = v);
                _scheduleDraftSave();
              },
              title: const Text('Smoking allowed'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _ruleDrinkingAllowed,
              onChanged: (v) {
                setState(() => _ruleDrinkingAllowed = v);
                _scheduleDraftSave();
              },
              title: const Text('Drinking allowed'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _ruleCookingAllowed,
              onChanged: (v) {
                setState(() => _ruleCookingAllowed = v);
                _scheduleDraftSave();
              },
              title: const Text('Cooking allowed'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _ruleOwnerStaysOnProperty,
              onChanged: (v) {
                setState(() => _ruleOwnerStaysOnProperty = v);
                _scheduleDraftSave();
              },
              title: const Text('Owner stays on property'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            _buildCompactTextField(
              controller: _gateClosingTimeController,
              label: 'Gate closing time (optional)',
              hint: 'e.g., 11:00 PM',
            ),
          ],

          const SizedBox(height: 12),
          // Type-specific details (moved into ResidentialDetailsForm)
/*
          Text('Type-Specific Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_selectedPropertyType == 'studio') ...[
            _buildCompactTextField(
              controller: _studioSizeController,
              label: 'Studio Size (sq ft)*',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_selectedPropertyType == 'studio' && (value?.isEmpty ?? true)) {
                  return 'Studio size is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],
          if (_selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel') ...[
            _buildCompactTextField(
              controller: _pgOccupancyController,
              label: 'Occupancy per Room*',
              keyboardType: TextInputType.number,
              validator: (value) {
                if ((_selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel') && (value?.isEmpty ?? true)) {
                  return 'Occupancy is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCompactDropdown<String>(
                    value: _pgGender,
                    label: 'Gender Preference',
                    items: _pgGenderOptions.map((g) => DropdownMenuItem(
                      value: g,
                      child: Text(
                        g,
                        style: TextStyle(fontSize: isPhone ? 12 : 13),
                      ),
                    )).toList(),
                    onChanged: (v) => setState(() { _pgGender = v ?? _pgGender; _scheduleDraftSave(); }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactDropdown<String>(
                    value: _pgMeals,
                    label: 'Meal Preference',
                    items: _pgMealsOptions.map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(
                        m,
                        style: TextStyle(fontSize: isPhone ? 12 : 13),
                      ),
                    )).toList(),
                    onChanged: (v) => setState(() { _pgMeals = v ?? _pgMeals; _scheduleDraftSave(); }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _pgAttachedBathroom,
              onChanged: (v) => setState(() => _pgAttachedBathroom = v),
              title: const Text('Attached Bathroom'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
          ],
          if (_selectedPropertyType == 'apartment' || _selectedPropertyType == 'condo') ...[
            Row(
              children: [
                Expanded(
                  child: _buildCompactTextField(
                    controller: _floorController,
                    label: 'Floor Number*',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if ((_selectedPropertyType == 'apartment' || _selectedPropertyType == 'condo') && (value?.isEmpty ?? true)) {
                        return 'Floor number is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactTextField(
                    controller: _totalFloorsController,
                    label: 'Total Floors',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_selectedPropertyType == 'house' || _selectedPropertyType == 'villa') ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _plotAreaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Plot Area (sq ft)*',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) {
                      if ((_selectedPropertyType == 'house' || _selectedPropertyType == 'villa') && (value?.isEmpty ?? true)) {
                        return 'Plot area is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _parkingSpacesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Parking Spaces',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_selectedPropertyType == 'condo') ...[
            _buildCompactTextField(
              controller: _hoaFeeController,
              label: 'HOA Fee (monthly)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
          ],
          // Residential: Area for apartment/condo/townhouse
          if (_selectedPropertyType == 'apartment' || _selectedPropertyType == 'condo' || _selectedPropertyType == 'townhouse' || _selectedPropertyType == 'duplex' || _selectedPropertyType == 'penthouse') ...[
            _buildCompactTextField(
              controller: _carpetAreaController,
              label: 'Carpet Area (sq ft)*',
              keyboardType: TextInputType.number,
              validator: (value) {
                if ((_selectedPropertyType == 'apartment' || _selectedPropertyType == 'condo' || _selectedPropertyType == 'townhouse' || _selectedPropertyType == 'duplex' || _selectedPropertyType == 'penthouse') && (value?.isEmpty ?? true)) {
                  return 'Carpet area is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],
          if (_selectedPropertyType == 'bungalow') ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _plotAreaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Plot Area (sq ft)*',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) {
                      if ((_selectedPropertyType == 'bungalow') && (value?.isEmpty ?? true)) {
                        return 'Plot area is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _parkingSpacesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Parking Spaces',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
*/
          // Commercial: generic extra fields removed; this screen is residential-only now
          Text('Location Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildCompactTextField(
            controller: _addressController,
            label: 'Address',
            validator: (value) => value?.isEmpty ?? true ? 'Address is required' : null,
          ),
          const SizedBox(height: 12),
          _buildCompactTextField(
            controller: _nearLandmarkController,
            label: 'Near Landmark',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, cons) {
            final isXS = cons.maxWidth < 360;
            if (isXS) {
              return Column(children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select State',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  isExpanded: true,
                  selectedItemBuilder: (context) => const [
                    Align(alignment: Alignment.centerLeft, child: Text('Select state', overflow: TextOverflow.ellipsis)),
                  ],
                  items: const [
                    DropdownMenuItem(value: 'Select state', child: Text('Select state')),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'City/District',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  isExpanded: true,
                  selectedItemBuilder: (context) => const [
                    Align(alignment: Alignment.centerLeft, child: Text('Select city', overflow: TextOverflow.ellipsis)),
                  ],
                  items: const [
                    DropdownMenuItem(value: 'Select city', child: Text('Select city')),
                  ],
                  onChanged: (value) {},
                ),
              ]);
            }
            return Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  isExpanded: true,
                  selectedItemBuilder: (context) => const [
                    Align(alignment: Alignment.centerLeft, child: Text('Select state', overflow: TextOverflow.ellipsis)),
                  ],
                  items: const [
                    DropdownMenuItem(value: 'Select state', child: Text('Select state')),
                  ],
                  onChanged: (value) {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCompactTextField(
                  controller: _cityController,
                  label: 'City Name',
                  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                ),
              ),
            ]);
          }),
          const SizedBox(height: 12),
          _buildCompactTextField(
            controller: _pincodeController,
            label: 'Pincode',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          if (_latitude != null && _longitude != null) ...[
            Text('Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Use current location'),
              ),
              FilledButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Icons.pin_drop_outlined),
                label: const Text('Pick on map'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SafeArea(
            top: false,
            child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => _tabController.animateTo(0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 18),
                      SizedBox(width: 8),
                      Text('Back', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next: Amenities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAmenitiesStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final amenities = _getAvailableAmenities();
    final bottomPad = (isPhone ? 56.0 : 72.0) + MediaQuery.of(context).padding.bottom + 12.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 2, 16, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities & Features',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 1),
          Text(
            'Select all amenities that apply to your property. This helps tenants find what they\'re looking for.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 15),
          Text('Property Amenities', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amenities.map((amenity) {
              final isSelected = _selectedAmenities.contains(amenity);
              return FilterChip(
                label: Text(amenity),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.8)
                        : theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAmenities.add(amenity);
                    } else {
                      _selectedAmenities.remove(amenity);
                    }
                  });
                  _scheduleDraftSave();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 15),
          Text('Nearby Facilities', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _nearbyFacilities.map((facility) {
              final isSelected = _selectedNearbyFacilities.contains(facility);
              return FilterChip(
                label: Text(facility),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.8)
                        : theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedNearbyFacilities.add(facility);
                    } else {
                      _selectedNearbyFacilities.remove(facility);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 15),
          Text('Other Amenities', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          _buildCompactTextField(
            controller: _otherAmenitiesController,
            label: 'Additional Features (optional)',
            hint: 'Any other amenities or special features...',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Text('Tenant Preferences', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, cons) {
            final isXS = cons.maxWidth < 360;
            if (isXS) {
              return Column(children: [
                DropdownButtonFormField<String>(
                  initialValue: _preferredTenant,
                  decoration: InputDecoration(
                    labelText: 'Preferred Tenants*',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  isExpanded: true,
                  selectedItemBuilder: (context) => _tenantPreferences
                      .map((p) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(p, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  items: _tenantPreferences.map((pref) {
                    return DropdownMenuItem(value: pref, child: Text(pref));
                  }).toList(),
                  onChanged: (value) => setState(() => _preferredTenant = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _foodPreference,
                  decoration: InputDecoration(
                    labelText: 'Food Preference',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  isExpanded: true,
                  selectedItemBuilder: (context) => _foodPreferences
                      .map((p) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(p, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  items: _foodPreferences.map((pref) {
                    return DropdownMenuItem(value: pref, child: Text(pref));
                  }).toList(),
                  onChanged: (value) => setState(() => _foodPreference = value!),
                ),
              ]);
            }
            return Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _preferredTenant,
                  decoration: InputDecoration(
                    labelText: 'Preferred Tenants*',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  isExpanded: true,
                  items: _tenantPreferences.map((pref) {
                    return DropdownMenuItem(value: pref, child: Text(pref));
                  }).toList(),
                  onChanged: (value) => setState(() => _preferredTenant = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _foodPreference,
                  decoration: InputDecoration(
                    labelText: 'Food Preference',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  isExpanded: true,
                  items: _foodPreferences.map((pref) {
                    return DropdownMenuItem(value: pref, child: Text(pref));
                  }).toList(),
                  onChanged: (value) => setState(() => _foodPreference = value!),
                ),
              ),
            ]);
          }),
          const SizedBox(height: 15),
          SwitchListTile(
            title: const Text('Pets Allowed'),
            subtitle: const Text('Allow tenants to keep pets in the property'),
            value: _petsAllowed,
            onChanged: (value) => setState(() => _petsAllowed = value),
          ),
          SwitchListTile(
            title: const Text('Require government ID to book'),
            subtitle: const Text('Seeker must upload a government ID photo during booking'),
            value: _requireSeekerId,
            onChanged: (value) {
              setState(() => _requireSeekerId = value);
              _scheduleDraftSave();
            },
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => _tabController.animateTo(1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 8),
                      Text('Back', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(3),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next: Pricing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
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

  Widget _buildPricingStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final isPG = _selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel';
    final bottomPad = (isPhone ? 56.0 : 72.0) + MediaQuery.of(context).padding.bottom + 12.0;
    final rentLabel = isPG
        ? 'Base Rent (per room)*'
        : 'Monthly Rent*';
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 2, 16, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing & Availability',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _monthlyRentController,
                label: rentLabel,
                prefixIcon: Icons.currency_rupee,
                hint: 'e.g., 25000',
                helperText: 'Amount billed monthly',
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Price is required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCompactTextField(
                controller: _securityDepositController,
                label: 'Security Deposit (₹, optional)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }
                  final n = int.tryParse(value.trim());
                  if (n == null || n < 0) return 'Enter a valid amount';
                  return null;
                },
                showRequiredMarker: false,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _buildCompactTextField(
            controller: _discountPercentController,
            label: 'Discount (%) (optional)',
            hint: '0-90',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final d = double.tryParse(value.trim());
              if (d == null) return 'Enter a valid number';
              if (d < 0 || d > 90) return 'Enter 0-90';
              return null;
            },
            showRequiredMarker: false,
          ),
          if (isPG) ...[
            const SizedBox(height: 12),
            _buildCompactTextField(
              controller: _pgBedRentController,
              label: 'Rent per Bed (₹, optional)',
              hint: 'e.g., 8000',
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 15),
          Text('Charges Included in Rent', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _chargesIncluded.map((charge) {
              final isSelected = _selectedChargesIncluded.contains(charge);
              return FilterChip(
                label: Text(charge),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.8)
                        : theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedChargesIncluded.add(charge);
                    } else {
                      _selectedChargesIncluded.remove(charge);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 15),
          _buildCompactTextField(
            controller: _houseRulesController,
            label: 'House Rules (optional)',
            hint: 'e.g., No loud music after 10 PM; no smoking inside the flat',
            maxLines: 3,
          ),
          const SizedBox(height: 15),
          Text('Rent Type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              {'key': 'both', 'label': 'Both (per day & per month)'},
              {'key': 'rental', 'label': 'Per Day'},
              {'key': 'monthly', 'label': 'Per Month'},
            ].map((m) {
              final String k = m['key']!;
              final bool sel = _rentalModeListing == k;
              return ChoiceChip(
                showCheckmark: false,
                selected: sel,
                label: Text(m['label']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : theme.colorScheme.onSurface)),
                selectedColor: theme.colorScheme.secondary.withValues(alpha: 0.9),
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                shape: const StadiumBorder(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onSelected: (_) { setState(() { _rentalModeListing = k; }); _scheduleDraftSave(); },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          if (_rentalModeListing == 'monthly') ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _minStayMonthsMonthly,
              decoration: InputDecoration(
                labelText: 'Minimum Stay (months)',
                helperText: 'Set to Any if you do not enforce a minimum',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              isExpanded: true,
              items: <int>[0, 1, 2, 3, 6, 9, 12]
                  .map((m) => DropdownMenuItem(value: m, child: Text(m == 0 ? 'Any' : '$m months')))
                  .toList(),
              onChanged: (v) => setState(() { _minStayMonthsMonthly = v ?? 0; _scheduleDraftSave(); }),
            ),
            const SizedBox(height: 10),
            _buildCompactTextField(
              controller: _noticePeriodDaysController,
              label: 'Notice Period (days) for Cancellation',
              hint: 'e.g., 30',
              helperText: 'Max 90 days',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_rentalModeListing == 'monthly') {
                  if (value != null && value.isNotEmpty) {
                    final n = int.tryParse(value.trim());
                    if (n == null || n < 0) return 'Enter a valid number of days';
                    if (n > 90) return 'Maximum allowed is 90 days';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: const [7, 15, 30, 45, 60, 90].map((d) {
                return Builder(builder: (context) {
                  final theme = Theme.of(context);
                  final isSelected = _noticePeriodDaysController.text.trim() == d.toString();
                  return ChoiceChip(
                    label: Text('$d days'),
                    selected: isSelected,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: theme.colorScheme.secondary.withValues(alpha: 0.9),
                    backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                    onSelected: (_) {
                      setState(() {
                        _noticePeriodDaysController.text = d.toString();
                      });
                      _scheduleDraftSave();
                    },
                  );
                });
              }).toList(),
            ),
          ],
          const SizedBox(height: 15),
          Text('Availability', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildCompactTextField(
            controller: _availableFromController,
            label: 'Available From (date)',
            hint: 'e.g., 01-12-2025',
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _availabilityStatus,
            decoration: InputDecoration(
              labelText: 'Current Status',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'Vacant', child: Text('Vacant')),
              DropdownMenuItem(value: 'Occupied', child: Text('Occupied')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _availabilityStatus = v);
              _scheduleDraftSave();
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _earlyMoveInAllowed,
            onChanged: (v) {
              setState(() => _earlyMoveInAllowed = v);
              _scheduleDraftSave();
            },
            title: const Text('Early move-in allowed'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          _buildCompactTextField(
            controller: _maxOccupancyController,
            label: 'Maximum Occupancy (people)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: const [1, 2, 3, 4, 5, 6].map((n) {
              return Builder(builder: (context) {
                final theme = Theme.of(context);
                final isSelected = _maxOccupancyController.text.trim() == n.toString();
                return ChoiceChip(
                  label: Text('$n pax'),
                  selected: isSelected,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: theme.colorScheme.secondary.withValues(alpha: 0.9),
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                  onSelected: (_) {
                    setState(() {
                      _maxOccupancyController.text = n.toString();
                    });
                    _scheduleDraftSave();
                  },
                );
              });
            }).toList(),
          ),
          const SizedBox(height: 8),
          _buildCompactTextField(
            controller: _moveInRequirementsController,
            label: 'Move-in Requirements (optional)',
            hint: 'e.g., ID proof, salary slips, agreement signing',
            maxLines: 3,
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => _tabController.animateTo(2),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 8),
                      Text('Back', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(4),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next: Photos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
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

  Widget _buildPhotosStep() {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 600;
    final crossAxisCount = isPhone ? 2 : 3;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isPhone ? 4 : 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Media',
            style: TextStyle(
              fontSize: isPhone ? 16 : 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Add photos to showcase your property',
            style: TextStyle(
              fontSize: isPhone ? 12 : 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          
          // Modern Photo Upload Card
          Container(
            padding: EdgeInsets.all(isPhone ? 12 : 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    size: isPhone ? 32 : 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Upload Property Photos',
                  style: TextStyle(
                    fontSize: isPhone ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'JPEG, PNG • Max 5MB per image',
                  style: TextStyle(
                    fontSize: isPhone ? 11 : 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: Text(
                    'Choose Photos',
                    style: TextStyle(fontSize: isPhone ? 14 : 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: isPhone ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 12),
                const Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    Text(
                      'Upload at least 3 photos. First photo will be used as the cover image.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: Colors.grey),
                    Text(
                      'Tip: Include photos of all rooms, kitchen, bathroom and no clutter.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Show selected images
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Selected Photos (${_selectedImages.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                final isCover = index == 0;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImages[index].path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    if (isCover)
                      Positioned(
                        left: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'COVER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (!isCover)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              final imgToMakeCover = _selectedImages.removeAt(index);
                              _selectedImages.insert(0, imgToMakeCover);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Make cover',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: isCover ? 4 : 46,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: theme.colorScheme.onPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => _tabController.animateTo(2),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 8),
                      Text('Back', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(4),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next: Contact Info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
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

  Widget _buildContactStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final bottomPad = (isPhone ? 56.0 : 72.0) + MediaQuery.of(context).padding.bottom + 12.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildCompactTextField(
                  controller: _contactPersonController,
                  label: 'Contact Person Name*',
                  validator: (value) => value?.isEmpty ?? true ? 'Contact name is required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCompactTextField(
                  controller: _phoneController,
                  label: 'Phone Number*',
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty ?? true ? 'Phone number is required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _alternatePhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Alternate Phone (Optional)',
                    hintText: 'Alternate contact number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address*',
                    hintText: 'Your email address',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Email is required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Preferred Contact Method*',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 16,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(value: true, onChanged: (value) {}),
                  Flexible(
                    child: Text(
                      'Phone Call',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(value: false, onChanged: (value) {}),
                  Flexible(
                    child: Text(
                      'WhatsApp',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(value: false, onChanged: (value) {}),
                  Flexible(
                    child: Text(
                      'Email',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(value: false, onChanged: (value) {}),
                  Flexible(
                    child: Text(
                      'SMS',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          SwitchListTile(
            title: Text(
              'Hide Phone Number',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            subtitle: Text(
              'Inquiries will be forwarded to your email if you hide your phone number',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            value: _hidePhoneNumber,
            onChanged: (value) => setState(() => _hidePhoneNumber = value),
          ),
          const SizedBox(height: 15),
          CheckboxListTile(
            title: RichText(
              text: TextSpan(
                text: 'I agree to the ',
                style: TextStyle(color: theme.colorScheme.onSurface),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: '*'),
                ],
              ),
            ),
            value: _agreeToTerms,
            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => _tabController.animateTo(3),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 8),
                      Text('Back', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.upload, size: 20),
                            SizedBox(width: 8),
                            Text('Submit Listing', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
}