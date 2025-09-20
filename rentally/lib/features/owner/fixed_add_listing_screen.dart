// Modern Professional Add Listing Screen
// Redesigned with improved UI/UX and mobile-friendly font sizes

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../../models/listing_model.dart'; // Model will be created later
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../../services/listing_service.dart';
import '../../services/image_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../utils/snackbar_utils.dart';

class FixedAddListingScreen extends ConsumerStatefulWidget {
  const FixedAddListingScreen({super.key});

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
  final _pincodeController = TextEditingController();
  final _monthlyRentController = TextEditingController();
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
  bool _pgAttachedBathroom = true;
  String _pgGender = 'Any';
  String _pgMeals = 'No Meals';

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

  // Generic area & lease fields
  final _carpetAreaController = TextEditingController(); // apartment/condo/townhouse
  final _leaseTenureYearsController = TextEditingController(); // commercial
  final _lockInMonthsController = TextEditingController(); // commercial
  String _leaseType = 'Flexible/Negotiable';
  // Generic commercial area for new types
  final _commercialBuiltUpAreaController = TextEditingController();
  // Penthouse specific
  final _terraceAreaController = TextEditingController();

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

  // Lease type options (primarily for Commercial)
  final List<String> _leaseTypeOptions = [
    'Flexible/Negotiable', 'Short-term (<= 3 yrs)', 'Long-term (3+ yrs)'
  ];

  // PG/Hostel options
  final List<String> _pgGenderOptions = ['Any', 'Male', 'Female'];
  final List<String> _pgMealsOptions = ['No Meals', 'Breakfast', 'Breakfast + Dinner', 'All Meals'];
  
  // Categories
  final List<String> _categories = ['Residential', 'Commercial'];

  // Room options (Residential -> Room)
  final List<String> _roomBathroomOptions = ['Shared', 'Separate', 'Attached'];
  String _roomBathroomType = 'Attached';

  // Category selection and draft autosave
  String _selectedCategory = 'Residential';
  Timer? _draftDebounce;
  bool _suspendDraft = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
              color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                  onPressed: () => _tabController.animateTo(0),
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
                      color: theme.colorScheme.outline.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 19),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(2),
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
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.of(context).size.width < 600;
    
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: isPhone ? 11 : 12),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: isPhone ? 12 : 13,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
        labelStyle: TextStyle(fontSize: isPhone ? 13 : 15),
        prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, size: 20, color: theme.colorScheme.primary.withOpacity(0.7))
          : null,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.8)),
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
      value: value,
      items: items,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: isPhone ? 11 : 12,
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: isPhone ? 13 : 14),
        prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, size: 20, color: theme.colorScheme.primary.withOpacity(0.7))
          : null,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.8)),
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
  
  // Helper method to format property types
  String _formatPropertyType(String type) {
    final formatted = type.replaceAll('_', ' ');
    return formatted.split(' ').map((word) => 
      word.substring(0, 1).toUpperCase() + word.substring(1)
    ).join(' ');
  }
  
  // Helper method to build compact dropdowns with small font sizes
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
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      style: TextStyle(
        fontSize: isPhone ? 12 : 13,
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: isPhone ? 12 : 13),
        prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, size: 18, color: theme.colorScheme.primary.withOpacity(0.7))
          : null,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.8)),
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
  
  // Helper method to build compact text fields
  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.of(context).size.width < 600;
    
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: isPhone ? 10 : 11),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: isPhone ? 9 : 10,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
        labelStyle: TextStyle(fontSize: isPhone ? 10 : 11),
        prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, size: 18, color: theme.colorScheme.primary.withOpacity(0.7))
          : null,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.8)),
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
      'office': ['Reception', 'Meeting Rooms', 'Cafeteria'],
      'shop': ['Shutter', 'Display Window', 'Near Main Road'],
      'warehouse': ['Dock', 'Security Cabin', 'CCTV'],
      'coworking': ['Hot Desk', 'Meeting Rooms', 'High-Speed Internet'],
      'showroom': ['Display Area', 'Storage', 'Prime Location'],
      'clinic': ['Waiting Area', 'Reception', 'Washroom'],
      'restaurant': ['Exhaust', 'Kitchen Setup', 'Fire Safety'],
      'industrial': ['Power Backup', 'Crane', 'Truck Access'],
    };
    final extras = extrasByType[_selectedPropertyType] ?? const <String>[];
    final set = <String>{..._availableAmenities, ...extras};
    return set.toList()..sort();
  }

  // Filter property types by selected category
  List<String> _getTypesForCategory() {
    switch (_selectedCategory) {
      case 'PG/Hostel':
        return ['pg', 'hostel'];
      case 'Commercial':
        return ['office', 'shop', 'warehouse', 'coworking', 'showroom', 'clinic', 'restaurant', 'industrial'];
      case 'Residential':
      default:
        return ['apartment', 'house', 'villa', 'studio', 'townhouse', 'condo', 'room', 'duplex', 'penthouse', 'bungalow'];
    }
  }

  // Attach text field listeners for draft autosave
  void _attachDraftListeners() {
    final ctrls = <TextEditingController>[
      _titleController,
      _descriptionController,
      _monthlyRentController,
      _securityDepositController,
      _addressController,
      _cityController,
      _stateController,
      _zipCodeController,
      _nearLandmarkController,
      _otherAmenitiesController,
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
      _leaseTenureYearsController,
      _lockInMonthsController,
      _commercialBuiltUpAreaController,
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
        'securityDeposit': _securityDepositController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zipCode': _zipCodeController.text,
        'nearLandmark': _nearLandmarkController.text,
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
        'lease': {
          'type': _leaseType,
          'tenureYears': _leaseTenureYearsController.text,
          'lockInMonths': _lockInMonthsController.text,
        },
        'area': {
          'carpet': _carpetAreaController.text,
          'terrace': _terraceAreaController.text,
        },
        'room': {
          'bathroomType': _roomBathroomType,
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
        _selectedCategory = _asString(map['category']) ?? _selectedCategory;
        final allowed = _getTypesForCategory();
        final savedType = _asString(map['type']) ?? _selectedPropertyType;
        _selectedPropertyType = allowed.contains(savedType) ? savedType : allowed.first;

        _titleController.text = _asString(map['title']) ?? '';
        _descriptionController.text = _asString(map['description']) ?? '';
        _monthlyRentController.text = _asString(map['monthlyRent']) ?? '';
        _securityDepositController.text = _asString(map['securityDeposit']) ?? '';
        _addressController.text = _asString(map['address']) ?? '';
        _cityController.text = _asString(map['city']) ?? '';
        _stateController.text = _asString(map['state']) ?? '';
        _zipCodeController.text = _asString(map['zipCode']) ?? '';
        _nearLandmarkController.text = _asString(map['nearLandmark']) ?? '';
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

        final lease = _asMap(map['lease']);
        _leaseType = _asString(lease['type']) ?? _leaseType;
        _leaseTenureYearsController.text = _asString(lease['tenureYears']) ?? '';
        _lockInMonthsController.text = _asString(lease['lockInMonths']) ?? '';

        final area = _asMap(map['area']);
        _carpetAreaController.text = _asString(area['carpet']) ?? '';
        _terraceAreaController.text = _asString(area['terrace']) ?? '';

        final room = _asMap(map['room']);
        _roomBathroomType = _asString(room['bathroomType']) ?? _roomBathroomType;

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
        _titleController.clear();
        _descriptionController.clear();
        _monthlyRentController.clear();
        _securityDepositController.clear();
        _addressController.clear();
        _cityController.clear();
        _stateController.clear();
        _zipCodeController.clear();
        _nearLandmarkController.clear();
        _pincodeController.clear();
        _contactPersonController.clear();
        _phoneController.clear();
        _alternatePhoneController.clear();
        _emailController.clear();
        _studioSizeController.clear();
        _floorController.clear();
        _totalFloorsController.clear();
        _plotAreaController.clear();
        _parkingSpacesController.clear();
        _hoaFeeController.clear();
        _pgOccupancyController.clear();
        _carpetAreaController.clear();
        _terraceAreaController.clear();
        _leaseType = 'Flexible/Negotiable';
        _leaseTenureYearsController.clear();
        _lockInMonthsController.clear();
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
        _selectedAmenities.clear();
        _selectedNearbyFacilities.clear();
        _selectedChargesIncluded.clear();
        _selectedImages.clear();
        _commercialBuiltUpAreaController.clear();
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
      'studioSize': m['studioSize'],
      'floor': m['floor'],
      'totalFloors': m['totalFloors'],
      'plotArea': m['plotArea'],
      'parkingSpaces': m['parkingSpaces'],
      'hoaFee': m['hoaFee'],
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
    _pincodeController.dispose();
    _monthlyRentController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    // Dispose type-specific controllers
    _floorController.dispose();
    _totalFloorsController.dispose();
    _plotAreaController.dispose();
    _parkingSpacesController.dispose();
    _hoaFeeController.dispose();
    _studioSizeController.dispose();
    _pgOccupancyController.dispose();
    // Dispose commercial controllers
    _officeCarpetAreaController.dispose();
    _officeCabinsController.dispose();
    _officeConferenceRoomsController.dispose();
    _shopCarpetAreaController.dispose();
    _shopFrontageController.dispose();
    _warehouseBuiltUpAreaController.dispose();
    _warehouseCeilingHeightController.dispose();
    _warehouseLoadingBaysController.dispose();
    _warehousePowerController.dispose();
    // Dispose generic lease/area
    _carpetAreaController.dispose();
    _leaseTenureYearsController.dispose();
    _lockInMonthsController.dispose();
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

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      
      if (video != null && mounted) {
        SnackBarUtils.showSuccess(context, 'Video selected successfully!');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Error picking video: $e');
      }
    }
  }


  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      SnackBarUtils.showWarning(context, 'Please select at least one image');
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
      if (_selectedPropertyType == 'office') {
        final area = int.tryParse(_officeCarpetAreaController.text.trim());
        final cabins = int.tryParse(_officeCabinsController.text.trim());
        final conf = int.tryParse(_officeConferenceRoomsController.text.trim());
        if (area != null) amenitiesMap['office_carpet_area_sqft'] = area;
        if (cabins != null) amenitiesMap['office_cabins'] = cabins;
        if (conf != null) amenitiesMap['office_conference_rooms'] = conf;
        amenitiesMap['office_pantry'] = _officePantry;
      }
      if (_selectedPropertyType == 'shop') {
        final area = int.tryParse(_shopCarpetAreaController.text.trim());
        final frontage = int.tryParse(_shopFrontageController.text.trim());
        if (area != null) amenitiesMap['shop_carpet_area_sqft'] = area;
        if (frontage != null) amenitiesMap['shop_frontage_ft'] = frontage;
        amenitiesMap['shop_footfall'] = _shopFootfall.toLowerCase();
        amenitiesMap['shop_washroom'] = _shopWashroom;
      }
      if (_selectedPropertyType == 'warehouse') {
        final area = int.tryParse(_warehouseBuiltUpAreaController.text.trim());
        final height = int.tryParse(_warehouseCeilingHeightController.text.trim());
        final bays = int.tryParse(_warehouseLoadingBaysController.text.trim());
        final power = int.tryParse(_warehousePowerController.text.trim());
        if (area != null) amenitiesMap['wh_builtup_area_sqft'] = area;
        if (height != null) amenitiesMap['wh_ceiling_height_ft'] = height;
        if (bays != null) amenitiesMap['wh_loading_bays'] = bays;
        if (power != null) amenitiesMap['wh_power_kva'] = power;
        amenitiesMap['wh_truck_access'] = _warehouseTruckAccess;
      }
      if (_selectedCategory == 'Commercial') {
        amenitiesMap['lease_type'] = _leaseType.toLowerCase();
        final tenure = int.tryParse(_leaseTenureYearsController.text.trim());
        final lockIn = int.tryParse(_lockInMonthsController.text.trim());
        if (tenure != null) amenitiesMap['lease_tenure_years'] = tenure;
        if (lockIn != null) amenitiesMap['lease_lockin_months'] = lockIn;
        if (_selectedPropertyType != 'office' && _selectedPropertyType != 'shop' && _selectedPropertyType != 'warehouse') {
          final built = int.tryParse(_commercialBuiltUpAreaController.text.trim());
          if (built != null) amenitiesMap['commercial_builtup_area_sqft'] = built;
        }
      }

      // Create listing
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
                    color: Colors.white.withOpacity(0.15),
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
                  theme.colorScheme.primary.withOpacity(0.85),
                  theme.colorScheme.secondary.withOpacity(0.9),
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
              color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
            ),
            child: LinearProgressIndicator(
              value: (_tabController.index + 1) / 6,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary.withOpacity(0.8),
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
                  padding: EdgeInsets.symmetric(
                    vertical: isPhone ? 2 : 3,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_tabController.index + 1}/6',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab bar with modern design
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.1),
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
                    unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.category_outlined, size: isPhone ? 14 : 12),
                            SizedBox(width: isPhone ? 2 : 3),
                            const Text('Category'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home_outlined, size: isPhone ? 10 : 12),
                            SizedBox(width: isPhone ? 2 : 3),
                            const Text('Basics'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: isPhone ? 10 : 12),
                            SizedBox(width: isPhone ? 2 : 3),
                            const Text('Details'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_outline, size: isPhone ? 10 : 12),
                            SizedBox(width: isPhone ? 2 : 3),
                            const Text('Amenities'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera_outlined, size: isPhone ? 10 : 12),
                            SizedBox(width: isPhone ? 2 : 3),
                            const Text('Media'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.contact_phone_outlined, size: isPhone ? 10 : 12),
                            SizedBox(width: isPhone ? 2 : 3),
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
              color: theme.colorScheme.background,
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
                        _buildCategoryStep(),
                        _buildBasicsStep(),
                        _buildDetailsStep(),
                        _buildAmenitiesStep(),
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

  Widget _buildCategoryStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Select the category that best describes your property',
                    style: TextStyle(
                      fontSize: isPhone ? 11 : 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Property Category',
            style: TextStyle(
              fontSize: isPhone ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          
          // Modern Category Cards
          ..._categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    final allowed = _getTypesForCategory();
                    if (!allowed.contains(_selectedPropertyType)) {
                      _selectedPropertyType = allowed.first;
                    }
                    _scheduleDraftSave();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                      ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                      : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ] : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceVariant).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          category == 'Residential' 
                            ? Icons.home_rounded
                            : Icons.business_rounded,
                          size: 22,
                          color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: isPhone ? 15 : 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              category == 'Residential'
                                ? 'Homes, Apartments, PG, Hostels'
                                : 'Offices, Shops, Warehouses, etc.',
                              style: TextStyle(
                                fontSize: isPhone ? 10 : 11,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Modern Navigation Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: isPhone ? 14 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: isPhone ? 15 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
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
    final isCommercial = _selectedCategory == 'Commercial';
    final showFurnishing = !isCommercial || _selectedPropertyType == 'office';
    
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
                  ] else if (!isCommercial && _selectedPropertyType != 'studio' && _selectedPropertyType != 'pg' && _selectedPropertyType != 'hostel' && _selectedPropertyType != 'room') ...[
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
                else if (!isCommercial && _selectedPropertyType != 'studio' && _selectedPropertyType != 'pg' && _selectedPropertyType != 'hostel' && _selectedPropertyType != 'room')
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
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, cons) {
            final isXS = cons.maxWidth < 360;
            if (isCommercial) {
              return const SizedBox.shrink();
            }
            if (_selectedPropertyType == 'room') {
              if (isXS) {
                return DropdownButtonFormField<String>(
                  value: _roomBathroomType,
                  decoration: InputDecoration(
                    labelText: 'Bathroom Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  isExpanded: true,
                  items: _roomBathroomOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() { _roomBathroomType = v ?? _roomBathroomType; _scheduleDraftSave(); }),
                );
              }
              return Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _roomBathroomType,
                    decoration: InputDecoration(
                      labelText: 'Bathroom Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    isExpanded: true,
                    items: _roomBathroomOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() { _roomBathroomType = v ?? _roomBathroomType; _scheduleDraftSave(); }),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()),
              ]);
            }
            if (isXS) {
              return DropdownButtonFormField<int>(
                value: _bathrooms,
                decoration: InputDecoration(
                  labelText: 'Bathrooms',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                isExpanded: true,
                items: List.generate(4, (index) => index + 1).map((number) {
                  return DropdownMenuItem(value: number, child: Text('$number'));
                }).toList(),
                onChanged: (value) => setState(() => _bathrooms = value!),
              );
            }
            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _bathrooms,
                    decoration: InputDecoration(
                      labelText: 'Bathrooms',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    isExpanded: true,
                    items: List.generate(4, (index) => index + 1).map((number) {
                      return DropdownMenuItem(value: number, child: Text('$number'));
                    }).toList(),
                    onChanged: (value) => setState(() => _bathrooms = value!),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()),
              ],
            );
          }),
          const SizedBox(height: 12),
          // Type-specific details
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
          if (_selectedPropertyType == 'penthouse') ...[
            _buildCompactTextField(
              controller: _leaseTenureYearsController,
              label: 'Lease Tenure (years)',
              keyboardType: TextInputType.number,
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
          // Commercial: Generic built-up area for new types (coworking, showroom, clinic, restaurant, industrial)
          if (_selectedCategory == 'Commercial' && _selectedPropertyType != 'office' && _selectedPropertyType != 'shop' && _selectedPropertyType != 'warehouse') ...[
            _buildCompactTextField(
              controller: _commercialBuiltUpAreaController,
              label: 'Built-up Area (sq ft)*',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_selectedCategory == 'Commercial' && _selectedPropertyType != 'office' && _selectedPropertyType != 'shop' && _selectedPropertyType != 'warehouse' && (value?.isEmpty ?? true)) {
                  return 'Built-up area is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],
          // Commercial: Lease options (applies to all commercial types)
          if (_selectedCategory == 'Commercial') ...[
            DropdownButtonFormField<String>(
              value: _leaseType,
              decoration: InputDecoration(
                labelText: 'Lease Option',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              isExpanded: true,
              items: _leaseTypeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() { _leaseType = v ?? _leaseType; _scheduleDraftSave(); }),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _buildCompactTextField(
                  controller: _leaseTenureYearsController,
                  label: 'Lease Tenure (years)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCompactTextField(
                  controller: _lockInMonthsController,
                  label: 'Lock-in (months)',
                  keyboardType: TextInputType.number,
                ),
              ),
            ]),
            const SizedBox(height: 12),
          ],
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
          SafeArea(
            top: false,
            child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
    final isPG = _selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel';
    final isCommercial = _selectedCategory == 'Commercial';
    final isRoom = _selectedPropertyType == 'room';
    final rentLabel = isPG
        ? 'Monthly Rent (per bed)*'
        : isRoom
            ? 'Monthly Rent (per room)*'
            : isCommercial
                ? 'Monthly Rent (Commercial)*'
                : 'Monthly Rent*';
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
          Text('Rental Terms', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          LayoutBuilder(builder: (context, cons) {
            final isXS = cons.maxWidth < 360;
            if (isXS) {
              return Column(children: [
                _buildCompactTextField(
                  controller: _monthlyRentController,
                  label: rentLabel,
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Price is required' : null,
                ),
                const SizedBox(height: 12),
                _buildCompactTextField(
                  controller: _securityDepositController,
                  label: 'Security Deposit (₹)',
                  keyboardType: TextInputType.number,
                ),
              ]);
            }
            return Row(children: [
              Expanded(
                child: _buildCompactTextField(
                  controller: _monthlyRentController,
                  label: rentLabel,
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Price is required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCompactTextField(
                  controller: _securityDepositController,
                  label: 'Security Deposit (₹)',
                  keyboardType: TextInputType.number,
                ),
              ),
            ]);
          }),
          if (!isCommercial) ...[
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
          ],
          const SizedBox(height: 15),
          _buildCompactTextField(
            controller: _otherAmenitiesController,
            label: 'Additional Features (optional)',
            hint: 'Any other amenities or special features...',
            maxLines: 3,
          ),
          if (!isCommercial) ...[
            const SizedBox(height: 15),
            Text('Tenant Preferences', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, cons) {
              final isXS = cons.maxWidth < 360;
              if (isXS) {
                return Column(children: [
                  DropdownButtonFormField<String>(
                    value: _preferredTenant,
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
                    value: _foodPreference,
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
                    value: _preferredTenant,
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
                    value: _foodPreference,
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
          ],
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
              color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.2),
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
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                    Positioned(
                      top: 4,
                      right: 4,
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
          const Text(
            'Upload Video Tour (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Video Upload Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Column(
              children: [
                const Icon(Icons.videocam, size: 36, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                  'Drag & drop video here',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'or click to browse (MP4, max 50MB)',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _pickVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('+ Select Video'),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Tip: Add a short video tour (max 2 minutes) to increase tenant interest by 80%.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
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
              border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
