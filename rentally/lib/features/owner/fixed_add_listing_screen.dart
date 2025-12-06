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

import 'forms/modern_form_controls.dart';
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
    final isDark = theme.brightness == Brightness.dark;
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
          // Section Card: Basic Info
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade100,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                            theme.colorScheme.secondary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.edit_note_rounded, size: 20, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Basic Information', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text('Title and description', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Title Field
                ModernTextFormField(
                  controller: _titleController,
                  label: 'Property Title',
                  hint: 'e.g., Spacious 2BHK Apartment...',
                  prefixIcon: Icons.title_rounded,
                  validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                
                // Description Field
                ModernTextFormField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Describe features, amenities...',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Section Card: Property Type
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade100,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                            theme.colorScheme.secondary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.home_work_rounded, size: 20, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Property Type', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text('Select the type of property', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Property Type Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: allowedTypes.asMap().entries.map((entry) {
                      final type = entry.value;
                      final isSelected = type == currentType;
                      final typeIcons = {
                        'apartment': Icons.apartment_rounded,
                        'house': Icons.home_rounded,
                        'villa': Icons.villa_rounded,
                        'studio': Icons.weekend_rounded,
                        'townhouse': Icons.holiday_village_rounded,
                        'condo': Icons.domain_rounded,
                        'room': Icons.single_bed_rounded,
                        'pg': Icons.groups_rounded,
                        'hostel': Icons.hotel_rounded,
                        'duplex': Icons.stairs_rounded,
                        'penthouse': Icons.roofing_rounded,
                        'bungalow': Icons.cottage_rounded,
                      };
                      
                      return Padding(
                        padding: EdgeInsets.only(right: entry.key < allowedTypes.length - 1 ? 10 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedPropertyType = type;
                            final allowed = _getAvailableAmenities();
                            _selectedAmenities.removeWhere((a) => !allowed.contains(a));
                            _scheduleDraftSave();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary])
                                  : null,
                              color: isSelected ? null : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(typeIcons[type] ?? Icons.home_rounded, size: 18, color: isSelected ? Colors.white : Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  _formatPropertyType(type),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text('Cancel', style: TextStyle(fontSize: isPhone ? 12 : 13)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isPhone ? 14 : 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(1),
                    label: Text('Continue', style: TextStyle(fontSize: isPhone ? 13 : 14, fontWeight: FontWeight.w600)),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isPhone ? 14 : 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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

  // Helper: Modern step navigation buttons
  Widget _buildStepNavigation({
    required int backStep,
    required int nextStep,
    required String nextLabel,
    bool isLast = false,
    VoidCallback? onNext,
  }) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    
    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _tabController.animateTo(backStep),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text('Back', style: TextStyle(fontSize: isPhone ? 12 : 13)),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: isPhone ? 14 : 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLast 
                      ? [Colors.green.shade600, Colors.green.shade400]
                      : [theme.colorScheme.primary, theme.colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isLast ? Colors.green : theme.colorScheme.primary).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onNext ?? () => _tabController.animateTo(nextStep),
                label: Text(nextLabel, style: TextStyle(fontSize: isPhone ? 13 : 14, fontWeight: FontWeight.w600)),
                icon: Icon(isLast ? Icons.check_rounded : Icons.arrow_forward_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isPhone ? 14 : 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
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
          // Modern Animated Step Progress
          Container(
            padding: EdgeInsets.symmetric(vertical: isPhone ? 12 : 16, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Step circles
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < 6; i++) ...[
                      // Step Icon & Label
                      GestureDetector(
                        onTap: () => _tabController.animateTo(i),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: i == _tabController.index ? 42 : 34,
                              height: i == _tabController.index ? 42 : 34,
                              decoration: BoxDecoration(
                                gradient: (i <= _tabController.index)
                                    ? LinearGradient(
                                        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: (i <= _tabController.index) ? null : Colors.grey.shade200,
                                shape: BoxShape.circle,
                                boxShadow: i == _tabController.index
                                    ? [
                                        BoxShadow(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                i < _tabController.index ? Icons.check_rounded : [
                                  Icons.home_rounded,
                                  Icons.apartment_rounded,
                                  Icons.star_rounded,
                                  Icons.payments_rounded,
                                  Icons.photo_camera_rounded,
                                  Icons.contact_phone_rounded,
                                ][i],
                                size: i == _tabController.index ? 20 : 16,
                                color: (i <= _tabController.index) ? Colors.white : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ['Basics', 'Details', 'Amenities', 'Pricing', 'Media', 'Contact'][i],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: i == _tabController.index ? FontWeight.bold : FontWeight.w500,
                                color: i == _tabController.index
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Divider Line (only between steps)
                      if (i < 5)
                        Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.only(top: 19.5, left: 4, right: 4), 
                            decoration: BoxDecoration(
                              gradient: (i + 1 <= _tabController.index)
                                  ? LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary])
                                  : null,
                              color: (i + 1 <= _tabController.index) ? null : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ],
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
          // --- MERGED RESIDENTIAL FORM SECTIONS ---

          // 1. Configuration (Furnishing & Layout)
          _buildModernSectionCard(
            title: 'Configuration',
            subtitle: 'Property layout and furnishing',
            icon: Icons.weekend_rounded, // or settings_rounded
            gradientColors: [Colors.orange.shade400, Colors.deepOrange.shade400],
            child: Column(
              children: [
                // Furnishing
                ModernChipGroup<String>(
                  label: 'Furnishing Status',
                  items: _furnishingOptions,
                  selectedItems: [_furnishing],
                  onItemSelected: (v) { setState(() => _furnishing = v); _scheduleDraftSave(); },
                  labelBuilder: (s) => s.replaceAll('_', ' ').toUpperCase(),
                  iconBuilder: (s) => {
                    'Fully Furnished': Icons.weekend_rounded,
                    'Semi Furnished': Icons.chair_alt_rounded,
                    'Unfurnished': Icons.crop_square_rounded,
                  }[s] ?? Icons.circle,
                ),
                const SizedBox(height: 16),

                // BHK (Apartment) vs Bedrooms (House/Villa)
                if (_selectedPropertyType == 'apartment')
                  ModernChipGroup<String>(
                    label: 'Apartment Type',
                    items: _bhkOptions,
                    selectedItems: [_apartmentBhk],
                    onItemSelected: (v) { setState(() => _apartmentBhk = v); _scheduleDraftSave(); },
                    labelBuilder: (s) => s,
                  )
                else if (!['studio', 'pg', 'hostel', 'room'].contains(_selectedPropertyType))
                  ModernNumberStepper(
                    label: 'Bedrooms',
                    value: _bedrooms,
                    min: 1,
                    max: 10,
                    onChanged: (v) { setState(() => _bedrooms = v); _scheduleDraftSave(); },
                  ),

                // Bathrooms (except for Room/PG/Studio where it's handled differently or implicitly)
                if (!['room', 'pg', 'hostel', 'studio'].contains(_selectedPropertyType)) ...[
                  const SizedBox(height: 12),
                  ModernNumberStepper(
                    label: 'Bathrooms',
                    value: _bathrooms,
                    min: 1,
                    max: 6,
                    onChanged: (v) { setState(() => _bathrooms = v); _scheduleDraftSave(); },
                  ),
                ],

                // Room: Bathroom Arrangement
                if (_selectedPropertyType == 'room') ...[
                  const SizedBox(height: 16),
                  ModernChipGroup<String>(
                    label: 'Bathroom Arrangement',
                    items: _roomBathroomOptions,
                    selectedItems: [_roomBathroomType],
                    onItemSelected: (v) { setState(() => _roomBathroomType = v); _scheduleDraftSave(); },
                    labelBuilder: (s) => s,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Dimensions & Area
          if (!['room'].contains(_selectedPropertyType)) ...[
             _buildModernSectionCard(
               title: 'Size & Dimensions',
               subtitle: 'Property measurements',
               icon: Icons.square_foot_rounded,
               gradientColors: [Colors.indigo.shade400, Colors.blue.shade600],
               child: Column(
                 children: [
                   if (_selectedPropertyType == 'studio')
                     ModernTextFormField(
                       controller: _studioSizeController,
                       label: 'Studio Size (sq ft)',
                       prefixIcon: Icons.straighten_rounded,
                       keyboardType: TextInputType.number,
                     ),

                   if (['apartment', 'condo', 'townhouse', 'duplex', 'penthouse'].contains(_selectedPropertyType))
                     ModernTextFormField(
                       controller: _carpetAreaController,
                       label: 'Carpet Area (sq ft)',
                       prefixIcon: Icons.straighten_rounded,
                       keyboardType: TextInputType.number,
                     ),

                   if (['house', 'villa', 'bungalow'].contains(_selectedPropertyType)) ...[
                     ModernTextFormField(
                       controller: _plotAreaController,
                       label: 'Plot Area (sq ft)',
                       prefixIcon: Icons.landscape_rounded,
                       keyboardType: TextInputType.number,
                     ),
                     const SizedBox(height: 12),
                     ModernTextFormField(
                       controller: _parkingSpacesController,
                       label: 'Parking Spaces',
                       prefixIcon: Icons.directions_car_rounded,
                       keyboardType: TextInputType.number,
                     ),
                   ],

                   if (_selectedPropertyType == 'penthouse') ...[
                     const SizedBox(height: 12),
                     ModernTextFormField(
                       controller: _terraceAreaController,
                       label: 'Terrace Area (sq ft)',
                       prefixIcon: Icons.deck_rounded,
                       keyboardType: TextInputType.number,
                     ),
                   ],
                 ],
               ),
             ),
             const SizedBox(height: 16),
          ],

          // 3. Building Info (Apartments/Condos)
          if (['apartment', 'condo', 'townhouse', 'duplex', 'penthouse'].contains(_selectedPropertyType)) ...[
            _buildModernSectionCard(
               title: 'Building Details',
               subtitle: 'Floor and maintenance',
               icon: Icons.apartment_rounded,
               gradientColors: [Colors.blueGrey.shade400, Colors.blueGrey.shade600],
               child: Column(
                 children: [
                   Row(
                     children: [
                       Expanded(
                         child: ModernTextFormField(
                           controller: _floorController,
                           label: 'Floor No.',
                           prefixIcon: Icons.layers_rounded,
                           keyboardType: TextInputType.number,
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: ModernTextFormField(
                           controller: _totalFloorsController,
                           label: 'Total Floors',
                           prefixIcon: Icons.format_list_numbered_rounded,
                           keyboardType: TextInputType.number,
                         ),
                       ),
                     ],
                   ),
                   if (_selectedPropertyType == 'condo') ...[
                     const SizedBox(height: 12),
                     ModernTextFormField(
                       controller: _hoaFeeController,
                       label: 'HOA / Maintenance (₹)',
                       prefixIcon: Icons.attach_money_rounded,
                       keyboardType: TextInputType.number,
                     ),
                   ],
                 ],
               ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. PG / Hostel Details
          if (['pg', 'hostel'].contains(_selectedPropertyType)) ...[
            _buildModernSectionCard(
              title: 'PG Configuration',
              subtitle: 'Occupancy and rules',
              icon: Icons.group_rounded,
              gradientColors: [Colors.purple.shade300, Colors.deepPurple.shade400],
              child: Column(
                children: [
                  ModernTextFormField(
                    controller: _pgOccupancyController,
                    label: 'Persons per room',
                    prefixIcon: Icons.person_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ModernChipGroup<String>(
                    label: 'Gender Preference',
                    items: _pgGenderOptions,
                    selectedItems: [_pgGender],
                    onItemSelected: (v) { setState(() => _pgGender = v); _scheduleDraftSave(); },
                    labelBuilder: (s) => s,
                  ),
                  const SizedBox(height: 12),
                  ModernChipGroup<String>(
                    label: 'Meal Preference',
                    items: _pgMealsOptions,
                    selectedItems: [_pgMeals],
                    onItemSelected: (v) { setState(() => _pgMeals = v); _scheduleDraftSave(); },
                    labelBuilder: (s) => s,
                  ),
                  const SizedBox(height: 12),
                  ModernSwitchTile(
                     title: 'Attached Bathroom',
                     value: _pgAttachedBathroom,
                     onChanged: (v) { setState(() => _pgAttachedBathroom = v); _scheduleDraftSave(); },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 12),
          if (_selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel') ...[
             // PG Quick Select logic... (Already modern enough or keep as is? It uses ChoiceChip inside LayoutBuilder. I'll make it ModernChipGroup later or now?)
             // I'll modernize it now:
            Text(
              'PG Occupancy Quick Select',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ModernChipGroup<int>(
               label: '',
               items: const [1, 2, 3, 4, 5, 6],
               selectedItems: [int.tryParse(_pgOccupancyController.text) ?? 0],
               labelBuilder: (i) => '$i per room',
               onItemSelected: (i) {
                 setState(() {
                   _pgOccupancyController.text = i.toString();
                 });
                 _scheduleDraftSave();
               },
            ),
            const SizedBox(height: 12),
          ],
        // Removed duplicate LayoutBuilder block here.
        
        const SizedBox(height: 16),

        // Kitchen Details
        _buildModernSectionCard(
          title: 'Kitchen Details',
          subtitle: 'Layout and amenities',
          icon: Icons.kitchen_rounded,
          gradientColors: [Colors.orange.shade400, Colors.deepOrange.shade400],
          child: Column(
            children: [
              if (['apartment', 'house', 'villa', 'condo', 'townhouse', 'duplex', 'penthouse', 'studio'].contains(_selectedPropertyType)) ...[
                ModernCustomDropdown<String>(
                  label: 'Kitchen Type',
                  value: _kitchenType,
                  items: const ['Modular', 'Open', 'Closed', 'Kitchenette'],
                  itemLabelBuilder: (s) => s,
                  onChanged: (v) {
                     setState(() => _kitchenType = v);
                     _scheduleDraftSave();
                  },
                  prefixIcon: Icons.countertops_rounded,
                ),
                const SizedBox(height: 12),
                ModernTextFormField(
                  controller: _kitchenPlatformController,
                  label: 'Kitchen Platform / Counter Type',
                  hint: 'e.g., Granite platform',
                ),
                const SizedBox(height: 12),
                ModernChipGroup<String>(
                  label: 'Kitchen Amenities',
                  items: const ['Gas Connection', 'Chimney', 'Cabinets'],
                  selectedItems: [
                    if(_kitchenGasConnection) 'Gas Connection',
                    if(_kitchenChimney) 'Chimney',
                    if(_kitchenCabinets) 'Cabinets',
                  ],
                  labelBuilder: (s) => s,
                  multiSelect: true,
                  onItemSelected: (s) {
                    setState(() {
                      if (s == 'Gas Connection') _kitchenGasConnection = !_kitchenGasConnection;
                      if (s == 'Chimney') _kitchenChimney = !_kitchenChimney;
                      if (s == 'Cabinets') _kitchenCabinets = !_kitchenCabinets;
                    });
                    _scheduleDraftSave();
                  },
                ),
                const SizedBox(height: 12),
              ] else ...[
                ModernCustomDropdown<String>(
                  label: 'Kitchen Access',
                  value: _kitchenAccess,
                  items: const ['Full', 'Limited', 'No Access'],
                  itemLabelBuilder: (s) => s,
                  onChanged: (v) {
                    setState(() => _kitchenAccess = v);
                    _scheduleDraftSave();
                  },
                  prefixIcon: Icons.lock_open_rounded,
                ),
                const SizedBox(height: 8),
                ModernSwitchTile(
                   title: 'Common Kitchen Available',
                   value: _kitchenCommonKitchen,
                   onChanged: (v) {
                     setState(() => _kitchenCommonKitchen = v);
                     _scheduleDraftSave();
                   },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),

          // Bathroom Details
          _buildModernSectionCard(
            title: 'Bathroom Details',
            subtitle: 'Facilities and arrangement',
            icon: Icons.bathtub_rounded,
            gradientColors: [Colors.cyan.shade400, Colors.blue.shade400],
            child: Column(
              children: [
                if (!['room', 'pg', 'hostel'].contains(_selectedPropertyType)) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ModernCustomDropdown<String>(
                          label: 'Bathroom Style',
                          value: _bathroomStyle,
                          items: const ['Western', 'Indian', 'Both'],
                          itemLabelBuilder: (s) => s,
                          onChanged: (v) {
                            setState(() => _bathroomStyle = v);
                            _scheduleDraftSave();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ModernSwitchTile(
                          title: 'Geyser',
                          value: _bathroomHasGeyser,
                          onChanged: (v) {
                            setState(() => _bathroomHasGeyser = v);
                            _scheduleDraftSave();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ModernSwitchTile(
                    title: 'Exhaust Fan',
                    value: _bathroomHasExhaust,
                    onChanged: (v) {
                      setState(() => _bathroomHasExhaust = v);
                      _scheduleDraftSave();
                    },
                  ),
                ] else ...[
                  ModernTextFormField(
                    controller: _roomSharingCountController,
                    label: 'Number of people sharing bathroom (if shared)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ModernSwitchTile(
                    title: 'Hot Water Available',
                    value: _pgHotWater,
                    onChanged: (v) {
                      setState(() => _pgHotWater = v);
                      _scheduleDraftSave();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedPropertyType == 'room' || _selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel' || _selectedPropertyType == 'studio')
            _buildModernSectionCard(
               title: 'Room Module',
               subtitle: 'Specific room details',
               icon: Icons.meeting_room_rounded,
               gradientColors: [Colors.purple.shade400, Colors.deepPurple.shade400],
               child: Column(
                 children: [
                   ModernCustomDropdown<String>(
                     label: 'Room Type',
                     value: _roomType,
                     items: const [
                        'Single Room',
                        'Single Room (Attached Bathroom)',
                        'Single Room (Shared Bathroom)',
                        'Double Sharing',
                        'Triple Sharing',
                        '4+ Sharing',
                        'Dormitory Bed',
                        'Studio Room',
                        'Private Room in Shared Apartment'
                     ],
                     itemLabelBuilder: (s) => s,
                     onChanged: (v) {
                       setState(() => _roomType = v);
                       _scheduleDraftSave();
                     },
                   ),
                   const SizedBox(height: 12),
                   ModernTextFormField(
                     controller: _roomSizeController,
                     label: 'Room Size (sq ft)',
                     keyboardType: TextInputType.number,
                   ),
                   const SizedBox(height: 12),
                   ModernChipGroup<String>(
                     label: 'Room Amenities',
                     items: const [
                       'Bed', 'Mattress', 'Wardrobe', 'Fan', 'AC',
                       'Table', 'Chair', 'Mirror', 'Mini Fridge'
                     ],
                     selectedItems: [
                       if(_roomHasBed) 'Bed',
                       if(_roomHasMattress) 'Mattress',
                       if(_roomHasWardrobe) 'Wardrobe',
                       if(_roomHasFan) 'Fan',
                       if(_roomHasAC) 'AC',
                       if(_roomHasTable) 'Table',
                       if(_roomHasChair) 'Chair',
                       if(_roomHasMirror) 'Mirror',
                       if(_roomHasMiniFridge) 'Mini Fridge',
                     ],
                     multiSelect: true,
                     labelBuilder: (s) => s,
                     onItemSelected: (s) {
                       setState(() {
                         if (s == 'Bed') _roomHasBed = !_roomHasBed;
                         if (s == 'Mattress') _roomHasMattress = !_roomHasMattress;
                         if (s == 'Wardrobe') _roomHasWardrobe = !_roomHasWardrobe;
                         if (s == 'Fan') _roomHasFan = !_roomHasFan;
                         if (s == 'AC') _roomHasAC = !_roomHasAC;
                         if (s == 'Table') _roomHasTable = !_roomHasTable;
                         if (s == 'Chair') _roomHasChair = !_roomHasChair;
                         if (s == 'Mirror') _roomHasMirror = !_roomHasMirror;
                         if (s == 'Mini Fridge') _roomHasMiniFridge = !_roomHasMiniFridge;
                       });
                       _scheduleDraftSave();
                     },
                   ),
                 ],
               ),
            ),


          // Rules & Restrictions
          _buildModernSectionCard(
             title: 'Rules & Restrictions',
             subtitle: 'Set policies for your property',
             icon: Icons.gavel_rounded,
             gradientColors: [Colors.red.shade400, Colors.pink.shade400],
             child: Column(
               children: [
                 ModernSwitchTile(
                    title: 'Visitors Allowed',
                    value: _ruleVisitorsAllowed,
                    onChanged: (v) { setState(() => _ruleVisitorsAllowed = v); _scheduleDraftSave(); },
                 ),
                 ModernSwitchTile(
                    title: 'Overnight Guests Allowed',
                    value: _ruleOvernightGuestsAllowed,
                    onChanged: (v) { setState(() => _ruleOvernightGuestsAllowed = v); _scheduleDraftSave(); },
                 ),
                 ModernSwitchTile(
                    title: 'Smoking Allowed',
                    value: _ruleSmokingAllowed,
                    onChanged: (v) { setState(() => _ruleSmokingAllowed = v); _scheduleDraftSave(); },
                 ),
                 ModernSwitchTile(
                    title: 'Drinking Allowed',
                    value: _ruleDrinkingAllowed,
                    onChanged: (v) { setState(() => _ruleDrinkingAllowed = v); _scheduleDraftSave(); },
                 ),
                 ModernSwitchTile(
                    title: 'Cooking Allowed',
                    value: _ruleCookingAllowed,
                    onChanged: (v) { setState(() => _ruleCookingAllowed = v); _scheduleDraftSave(); },
                 ),
                 ModernSwitchTile(
                    title: 'Owner Stays on Property',
                    value: _ruleOwnerStaysOnProperty,
                    onChanged: (v) { setState(() => _ruleOwnerStaysOnProperty = v); _scheduleDraftSave(); },
                 ),
                 const SizedBox(height: 12),
                 ModernTextFormField(
                    controller: _gateClosingTimeController,
                    label: 'Gate closing time (optional)',
                    hint: 'e.g., 11:00 PM',
                    prefixIcon: Icons.access_time_rounded,
                 ),
               ],
             ),
          ),
          
          const SizedBox(height: 16),

          // Location Details
          _buildModernSectionCard(
             title: 'Location Details',
             subtitle: 'Accurate location helps search',
             icon: Icons.location_on_rounded,
             gradientColors: [Colors.green.shade400, Colors.teal.shade400],
             child: Column(
                children: [
                  ModernTextFormField(
                    controller: _addressController,
                    label: 'Address',
                    maxLines: 2,
                    prefixIcon: Icons.map_outlined,
                    validator: (value) => value?.isEmpty ?? true ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 12),
                  ModernTextFormField(
                    controller: _nearLandmarkController,
                    label: 'Near Landmark',
                    prefixIcon: Icons.landscape_rounded,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ModernCustomDropdown<String>(
                          label: 'State',
                          value: 'Select state', // Keeping dummy value as per original code
                          items: const ['Select state'],
                          itemLabelBuilder: (s) => s,
                          onChanged: (_) {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ModernTextFormField(
                          controller: _cityController,
                          label: 'City Name',
                          prefixIcon: Icons.location_city_rounded,
                          validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ModernTextFormField(
                    controller: _pincodeController,
                    label: 'Pincode',
                    prefixIcon: Icons.pin_drop_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  ),
                ],
             ),
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
            child: _buildStepNavigation(backStep: 0, nextStep: 2, nextLabel: 'Amenities'),
          ),
        ],
      ),
    );
  }

  // Helper: Modern Section Card
  Widget _buildModernSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors.map((c) => c.withValues(alpha: 0.15)).toList()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: gradientColors.first),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
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
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities & Features',
            style: TextStyle(
              fontSize: isPhone ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Select features to attract the right tenants',
            style: TextStyle(
              fontSize: isPhone ? 12 : 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          
          // Section: Property Amenities
          _buildModernSectionCard(
            title: 'Property Amenities', 
            subtitle: 'Select available facilities',
            icon: Icons.star_rounded,
            gradientColors: [Colors.amber.shade700, Colors.orange.shade500],
            child: ModernChipGroup<String>(
              label: '',
              items: amenities,
              selectedItems: _selectedAmenities,
              labelBuilder: (a) => a,
              onItemSelected: (amenity) {
                setState(() {
                  if (_selectedAmenities.contains(amenity)) {
                    _selectedAmenities.remove(amenity);
                  } else {
                    _selectedAmenities.add(amenity);
                  }
                });
                _scheduleDraftSave();
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Section: Nearby Facilities
          _buildModernSectionCard(
            title: 'Nearby Facilities', 
            subtitle: 'Establishments within 2km',
            icon: Icons.location_on_rounded,
            gradientColors: [Colors.blue.shade700, Colors.cyan.shade500],
            child: ModernChipGroup<String>(
              label: '',
              items: _nearbyFacilities,
              selectedItems: _selectedNearbyFacilities,
              labelBuilder: (f) => f,
              onItemSelected: (facility) {
                setState(() {
                  if (_selectedNearbyFacilities.contains(facility)) {
                    _selectedNearbyFacilities.remove(facility);
                  } else {
                    _selectedNearbyFacilities.add(facility);
                  }
                });
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Section: Preferences & Rules
          _buildModernSectionCard(
            title: 'Preferences & Rules', 
            subtitle: 'Set tenant criteria and house rules',
            icon: Icons.rule_rounded,
            gradientColors: [Colors.purple.shade700, Colors.purpleAccent.shade400],
            child: Column(
              children: [
                ModernTextFormField(
                    controller: _otherAmenitiesController,
                    label: 'Additional Features',
                    hint: 'Any other special perks...',
                    prefixIcon: Icons.add_circle_outline_rounded,
                    maxLines: 2,
                ),
                const SizedBox(height: 16),
                ModernCustomDropdown<String>(
                  label: 'Preferred Tenants',
                  value: _preferredTenant,
                  items: _tenantPreferences,
                  onChanged: (value) => setState(() => _preferredTenant = value),
                  itemLabelBuilder: (item) => item,
                  prefixIcon: Icons.people_outline_rounded,
                ),
                const SizedBox(height: 12),
                ModernCustomDropdown<String>(
                  label: 'Food Preference',
                  value: _foodPreference,
                  items: _foodPreferences,
                  onChanged: (value) => setState(() => _foodPreference = value),
                  itemLabelBuilder: (item) => item,
                  prefixIcon: Icons.restaurant_menu_rounded,
                ),
                const SizedBox(height: 16),
                ModernSwitchTile(
                  title: 'Pets Allowed',
                  subtitle: 'Small pets like cats/dogs',
                  icon: Icons.pets_rounded,
                  value: _petsAllowed,
                  onChanged: (value) => setState(() => _petsAllowed = value),
                ),
                ModernSwitchTile(
                  title: 'Require Verified ID',
                  subtitle: 'Govt. ID required for booking',
                  icon: Icons.badge_rounded,
                  value: _requireSeekerId,
                  onChanged: (value) {
                    setState(() => _requireSeekerId = value);
                    _scheduleDraftSave();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildStepNavigation(backStep: 1, nextStep: 3, nextLabel: 'Pricing'),
        ],
      ),
    );
  }

  Widget _buildPricingStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final isPG = _selectedPropertyType == 'pg' || _selectedPropertyType == 'hostel';
    final bottomPad = (isPhone ? 56.0 : 72.0) + MediaQuery.of(context).padding.bottom + 12.0;
    final rentLabel = isPG ? 'Base Rent (per room)*' : 'Monthly Rent*';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 2, 16, bottomPad),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing & Availability',
            style: TextStyle(fontSize: isPhone ? 15 : 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 16),

          // Section: Pricing Details
          _buildModernSectionCard(
            title: 'Pricing Details',
            subtitle: 'Set your rent and deposits',
            icon: Icons.currency_rupee_rounded,
            gradientColors: [Colors.green.shade700, Colors.teal.shade500],
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: ModernTextFormField(
                      controller: _monthlyRentController,
                      label: rentLabel,
                      prefixIcon: Icons.currency_rupee,
                      hint: 'e.g., 25000',
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernTextFormField(
                      controller: _securityDepositController,
                      label: 'Deposit (₹)',
                      hint: 'Optional',
                      keyboardType: TextInputType.number,
                      showRequiredMarker: false,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: ModernTextFormField(
                      controller: _discountPercentController,
                      label: 'Discount (%)',
                      hint: '0-90',
                      keyboardType: TextInputType.number,
                      showRequiredMarker: false,
                    ),
                  ),
                  if (isPG) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModernTextFormField(
                        controller: _pgBedRentController,
                        label: 'Bed Rent (₹)',
                        hint: 'Optional',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ] else 
                    const Spacer(),
                ]),
                const SizedBox(height: 16),
                ModernChipGroup<String>(
                  label: 'Charges Included',
                  items: _chargesIncluded,
                  selectedItems: _selectedChargesIncluded,
                  labelBuilder: (c) => c,
                  multiSelect: true,
                  onItemSelected: (charge) {
                    setState(() {
                       _selectedChargesIncluded.contains(charge) 
                          ? _selectedChargesIncluded.remove(charge) 
                          : _selectedChargesIncluded.add(charge);
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section: Rental Terms
          _buildModernSectionCard(
            title: 'Rental Terms',
            subtitle: 'Lease duration and rules',
            icon: Icons.gavel_rounded,
            gradientColors: [Colors.indigo.shade600, Colors.blue.shade500],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernTextFormField(
                  controller: _houseRulesController,
                  label: 'House Rules',
                  hint: 'e.g., No loud music after 10 PM...',
                  maxLines: 2,
                  prefixIcon: Icons.library_books_rounded,
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    const options = [
                      {'key': 'both', 'label': 'Daily & Monthly'},
                      {'key': 'rental', 'label': 'Daily Only'},
                      {'key': 'monthly', 'label': 'Monthly Only'},
                    ];
                    return ModernChipGroup<Map<String, String>>(
                      label: 'Rent Duration',
                      items: options,
                      selectedItems: options.where((m) => m['key'] == _rentalModeListing).toList(),
                      labelBuilder: (m) => m['label']!,
                      onItemSelected: (m) => setState(() => _rentalModeListing = m['key']!),
                    );
                  }
                ),
                if (_rentalModeListing == 'monthly') ...[
                  const SizedBox(height: 12),
                  ModernCustomDropdown<int>(
                    label: 'Minimum Stay',
                    value: _minStayMonthsMonthly,
                    items: const [0, 1, 3, 6, 11, 12],
                    itemLabelBuilder: (m) => m == 0 ? 'Any' : '$m Months',
                    onChanged: (v) => setState(() => _minStayMonthsMonthly = v),
                    prefixIcon: Icons.calendar_today_rounded,
                  ),
                  const SizedBox(height: 12),
                  ModernTextFormField(
                    controller: _noticePeriodDaysController,
                    label: 'Notice Period (Days)',
                    hint: '30',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.notifications_active_rounded,
                  ),
                ]
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section: Availability
          _buildModernSectionCard(
            title: 'Availability',
            subtitle: 'Occupancy and move-in dates',
            icon: Icons.event_available_rounded,
            gradientColors: [Colors.orange.shade700, Colors.deepOrange.shade500],
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: ModernTextFormField(
                      controller: _availableFromController,
                      label: 'Available From',
                      hint: 'DD-MM-YYYY',
                      prefixIcon: Icons.calendar_month_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernCustomDropdown<String>(
                      label: 'Status',
                      value: _availabilityStatus,
                      items: const ['Vacant', 'Occupied'],
                      onChanged: (v) => setState(() => _availabilityStatus = v),
                      itemLabelBuilder: (s) => s,
                      prefixIcon: Icons.info_outline,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                ModernSwitchTile(
                  title: 'Early Move-in Allowed',
                  value: _earlyMoveInAllowed,
                  onChanged: (v) => setState(() => _earlyMoveInAllowed = v),
                ),
                const SizedBox(height: 12),
                ModernTextFormField(
                  controller: _maxOccupancyController,
                  label: 'Max Occupancy',
                  hint: 'e.g., 4',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.groups_rounded,
                ),
                const SizedBox(height: 8),
                ModernChipGroup<int>(
                  label: '',
                  items: const [1, 2, 3, 4, 5, 6],
                  selectedItems: [
                    int.tryParse(_maxOccupancyController.text) ?? 0
                  ],
                  labelBuilder: (n) => '$n',
                  onItemSelected: (n) => setState(() => _maxOccupancyController.text = n.toString()),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          _buildStepNavigation(backStep: 2, nextStep: 4, nextLabel: 'Photos'),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              'Property Media',
              style: TextStyle(fontSize: isPhone ? 16 : 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
          ),
          
          _buildModernSectionCard(
            title: 'Photos',
            subtitle: 'Add high quality images',
            icon: Icons.photo_library_rounded,
            gradientColors: [Colors.pink.shade600, Colors.red.shade400],
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), style: BorderStyle.solid),
                      boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_photo_alternate_rounded, size: 32, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 12),
                        const Text('Click to Upload Photos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Max 5MB per image • JPEG, PNG', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                ),
                 if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('Selected Photos (${_selectedImages.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedImages.clear()), 
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear All'),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 8, mainAxisSpacing: 8),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      final isCover = index == 0;
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_selectedImages[index].path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                          ),
                          if (isCover)
                            Positioned(
                              left: 6, top: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
                                child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          Positioned(
                            right: 4, top: 4,
                            child: InkWell(
                              onTap: () => setState(() => _selectedImages.removeAt(index)),
                              child: const CircleAvatar(backgroundColor: Colors.white, radius: 10, child: Icon(Icons.close, size: 14, color: Colors.black)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
         
          const SizedBox(height: 24),
          _buildStepNavigation(backStep: 3, nextStep: 5, nextLabel: 'Contact'),
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
                  _buildModernSectionCard(
                    title: 'Owner Details',
                    subtitle: 'Provide contact info for tenants',
                    icon: Icons.contact_phone_rounded,
                    gradientColors: [Colors.teal.shade700, Colors.greenAccent.shade700],
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ModernTextFormField(
                                controller: _contactPersonController,
                                label: 'Contact Name',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ModernTextFormField(
                                controller: _phoneController, // Changed from _contactPhoneController to _phoneController
                                label: 'Phone Number',
                                prefixIcon: Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,
                                validator: (value) => value?.isEmpty ?? true ? 'Phone is required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ModernTextFormField(
                          controller: _emailController, // Changed from _contactEmailController to _emailController
                          label: 'Email Address',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value?.isEmpty ?? true ? 'Email is required' : null,
                        ),
                        const SizedBox(height: 16),
                        ModernTextFormField(
                           controller: _alternatePhoneController,
                           label: 'Alternate Number',
                           hint: 'Optional',
                           prefixIcon: Icons.phone_in_talk_rounded,
                           keyboardType: TextInputType.phone,
                           showRequiredMarker: false,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Preferences (Contact Modes)
                  // Using state variables for these would be better, but they seem to be dummy UI in the original code 
                  // (Checkbox onChanged was empty or local). 
                  // I'll keep them as dummy for now or use a placeholder list if real logic exists.
                  // Looking at original code: Checkbox(value: true, onChanged: (value) {}), Checkbox(value: false...)
                  // They were completely static/dummy. I will replace with a static ModernChipGroup for visual consistency.
                  
                  _buildModernSectionCard(
                    title: 'Communication Preferences',
                    subtitle: 'How should tenants contact you?',
                    icon: Icons.message_rounded,
                    gradientColors: [Colors.indigo.shade600, Colors.blueAccent.shade400],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         ModernChipGroup<String>(
                            label: 'Preferred Contact Method',
                            items: const ['Phone Call', 'WhatsApp', 'Email', 'SMS'],
                            selectedItems: const ['Phone Call'], // Mock selection as per original
                            labelBuilder: (s) => s,
                            multiSelect: true,
                            onItemSelected: (_) {}, // Dummy action
                         ),
                         const SizedBox(height: 16),
                         ModernSwitchTile(
                            title: 'Hide Phone Number',
                            subtitle: 'Inquiries will be forwarded to your email',
                            value: _hidePhoneNumber,
                            onChanged: (value) => setState(() => _hidePhoneNumber = value),
                            icon: Icons.phonelink_erase_rounded,
                         ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CheckboxListTile(
                    title: RichText(
                      text: TextSpan(
                        text: 'I agree to the ',
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                               fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    value: _agreeToTerms,
                    onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: theme.colorScheme.primary,
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