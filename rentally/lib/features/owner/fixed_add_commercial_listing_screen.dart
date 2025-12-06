import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../services/image_service.dart';
import '../../services/listing_service.dart';
import '../../app/app_state.dart';
import '../../utils/snackbar_utils.dart';
import 'forms/modern_form_controls.dart';

class FixedAddCommercialListingScreen extends ConsumerStatefulWidget {
  const FixedAddCommercialListingScreen({super.key});

  @override
  ConsumerState<FixedAddCommercialListingScreen> createState() =>
      _FixedAddCommercialListingScreenState();
}

class _FixedAddCommercialListingScreenState
    extends ConsumerState<FixedAddCommercialListingScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Basics
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _securityDepositController = TextEditingController();

  // Location
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  // Contact
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Commercial type
  String _propertyType = 'office';
  final List<String> _commercialTypes = const [
    'office',
    'shop',
    'showroom',
    'warehouse',
    'coworking',
    'clinic',
    'restaurant',
    'industrial',
  ];

  // Office
  final _officeCarpetAreaController = TextEditingController();
  final _officeCabinsController = TextEditingController();
  final _officeConferenceRoomsController = TextEditingController();
  bool _officePantry = false;
  final _officeWorkstationsController = TextEditingController();
  final _officeMeetingRoomsController = TextEditingController();
  String _officeType = 'Bare Shell';
  bool _officeReceptionArea = false;
  bool _officeServerRoom = false;
  String _officeWashroomType = 'Not specified';
  final List<String> _officeTypeOptions = const [
    'Bare Shell',
    'Warm Shell',
    'Fully Furnished',
  ];
  final List<String> _officeWashroomOptions = const [
    'Not specified',
    'Attached',
    'Common',
    'Attached & Common',
  ];

  // Shop / Showroom
  final _shopCarpetAreaController = TextEditingController();
  final _shopFrontageController = TextEditingController();
  String _shopFootfall = 'Medium';
  bool _shopWashroom = false;
  bool _shopDisplayWindow = false;
  bool _shopExhaust = false;
  bool _shopGreaseTrap = false;

  // Warehouse / Industrial
  final _warehouseBuiltUpAreaController = TextEditingController();
  final _warehouseCeilingHeightController = TextEditingController();
  final _warehouseLoadingBaysController = TextEditingController();
  final _warehousePowerController = TextEditingController();
  bool _warehouseTruckAccess = true;

  final _warehouseShutterHeightController = TextEditingController();
  final _warehouseFloorLoadController = TextEditingController();
  String _warehouseType = 'RCC';
  final List<String> _warehouseTypeOptions = const [
    'RCC',
    'PEB',
    'Cold Storage',
  ];

  // Generic commercial
  final _commercialBuiltUpAreaController = TextEditingController();

  // Hospitality / Healthcare
  final _hospitalRoomsController = TextEditingController();
  final _hospitalKitchenSetupController = TextEditingController();
  final _hospitalDiningCapacityController = TextEditingController();
  final _clinicOtIcuDiagController = TextEditingController();

  // Type-specific amenity flags
  bool _restLiquorLicense = false;
  bool _restOutdoorSeating = false;
  bool _restLiveMusic = false;
  bool _clinicEmergency24x7 = false;
  bool _clinicInHousePharmacy = false;
  bool _clinicDaycare = false;
  bool _warehouseSecurityCabin = false;
  bool _warehouseWeighbridge = false;
  bool _warehouseSprinklerSystem = false;

  // Building meta
  final _floorNumberController = TextEditingController();
  final _totalFloorsBuildingController = TextEditingController();
  final _buildingAgeController = TextEditingController();
  String _facingDirection = 'Not specified';
  final List<String> _facingOptions = const [
    'Not specified',
    'North',
    'East',
    'South',
    'West',
    'North-East',
    'North-West',
    'South-East',
    'South-West',
  ];

  // Retail meta
  final _retailSuitableForController = TextEditingController();

  // Financial terms
  final _maintenanceController = TextEditingController();
  final _leasePeriodController = TextEditingController();
  final _lockinPeriodController = TextEditingController();
  final _noticePeriodController = TextEditingController();
  final _escalationRateController = TextEditingController();
  bool _gstApplicable = true;

  // Meta
  String _availableFor = 'Rent/Lease';
  String _propertyStatus = 'Ready to move';

  // Amenities
  final List<String> _buildingAmenities = const [
    'Lifts',
    '24x7 Security',
    'CCTV',
    'Power Backup',
    'Fire Safety',
    'HVAC / Air Conditioning',
    'Water Supply',
    'Maintenance Staff',
  ];
  final List<String> _parkingAmenities = const [
    'Open Parking',
    'Covered Parking',
    'Visitor Parking',
  ];
  final Set<String> _selectedAmenities = <String>{};

  // Media
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _monthlyRentController.dispose();
    _securityDepositController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _landmarkController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _officeCarpetAreaController.dispose();
    _officeCabinsController.dispose();
    _officeConferenceRoomsController.dispose();
    _officeWorkstationsController.dispose();
    _officeMeetingRoomsController.dispose();
    _shopCarpetAreaController.dispose();
    _shopFrontageController.dispose();
    _warehouseBuiltUpAreaController.dispose();
    _warehouseCeilingHeightController.dispose();
    _warehouseLoadingBaysController.dispose();
    _warehousePowerController.dispose();
    _warehouseShutterHeightController.dispose();
    _warehouseFloorLoadController.dispose();
    _commercialBuiltUpAreaController.dispose();
    _hospitalRoomsController.dispose();
    _hospitalKitchenSetupController.dispose();
    _hospitalDiningCapacityController.dispose();
    _clinicOtIcuDiagController.dispose();
    _floorNumberController.dispose();
    _totalFloorsBuildingController.dispose();
    _buildingAgeController.dispose();
    _retailSuitableForController.dispose();
    _maintenanceController.dispose();
    _leasePeriodController.dispose();
    _lockinPeriodController.dispose();
    _noticePeriodController.dispose();
    _escalationRateController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isEmpty) return;
      if (images.length > 10) {
        if (mounted) {
          SnackBarUtils.showWarning(
            context,
            'You can select maximum 10 images',
          );
        }
        return;
      }
      setState(() => _selectedImages = images);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to pick images: $e');
      }
    }
  }



  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.length < 4) {
      SnackBarUtils.showWarning(
        context,
        'Please upload at least 4 photos (first photo will be used as cover)',
      );
      return;
    }

    final auth = ref.read(authProvider);
    final user = auth.user;
    if (user == null || user.role != UserRole.owner) {
      SnackBarUtils.showWarning(
        context,
        'Only owners can create listings. Please switch to Owner role.',
      );
      if (mounted) context.go('/role');
      return;
    }
    if (!user.isKycVerified) {
      SnackBarUtils.showWarning(
        context,
        'Please complete owner verification (KYC) before listing.',
      );
      if (mounted) context.push('/kyc');
      return;
    }

    try {
      setState(() => _isLoading = true);

      final imageService = ref.read(imageServiceProvider);
      final imageUrls = <String>[];
      for (final img in _selectedImages) {
        final url = await imageService.uploadImage(img);
        if (url != null) imageUrls.add(url);
      }

      final amenities = <String, dynamic>{};

      // Tag as commercial
      amenities['category'] = 'Commercial';
      amenities['available_for'] =
          _availableFor.toLowerCase().replaceAll(' ', '_');
      amenities['status'] =
          _propertyStatus.toLowerCase().replaceAll(' ', '_');

      // Building & parking amenities
      for (final a in _selectedAmenities) {
        amenities[a.toLowerCase().replaceAll(' ', '_')] = true;
      }

      // Type-specific amenity extras
      if (_propertyType == 'restaurant') {
        amenities['rest_liquor_license'] = _restLiquorLicense;
        amenities['rest_outdoor_seating'] = _restOutdoorSeating;
        amenities['rest_live_music'] = _restLiveMusic;
      }
      if (_propertyType == 'clinic') {
        amenities['clinic_emergency_24x7'] = _clinicEmergency24x7;
        amenities['clinic_in_house_pharmacy'] = _clinicInHousePharmacy;
        amenities['clinic_daycare'] = _clinicDaycare;
      }
      if (_propertyType == 'warehouse' || _propertyType == 'industrial') {
        amenities['wh_security_cabin'] = _warehouseSecurityCabin;
        amenities['wh_weighbridge'] = _warehouseWeighbridge;
        amenities['wh_sprinkler_system'] = _warehouseSprinklerSystem;
      }

      // Type-specific details
      if (_propertyType == 'office') {
        final area = int.tryParse(_officeCarpetAreaController.text.trim());
        final cabins = int.tryParse(_officeCabinsController.text.trim());
        final conf = int.tryParse(_officeConferenceRoomsController.text.trim());
        if (area != null) amenities['office_carpet_area_sqft'] = area;
        if (cabins != null) amenities['office_cabins'] = cabins;
        if (conf != null) amenities['office_conference_rooms'] = conf;
        amenities['office_pantry'] = _officePantry;
        if (_officeType.isNotEmpty) {
          amenities['office_type'] =
              _officeType.toLowerCase().replaceAll(' ', '_');
        }
        final ws = int.tryParse(_officeWorkstationsController.text.trim());
        if (ws != null) amenities['office_workstations'] = ws;
        final mr = int.tryParse(_officeMeetingRoomsController.text.trim());
        if (mr != null) amenities['office_meeting_rooms'] = mr;
        amenities['office_reception_area'] = _officeReceptionArea;
        amenities['office_server_room'] = _officeServerRoom;
        if (_officeWashroomType != 'Not specified') {
          amenities['office_washrooms'] =
              _officeWashroomType.toLowerCase().replaceAll(' ', '_');
        }
      } else if (_propertyType == 'shop' || _propertyType == 'showroom') {
        final area = int.tryParse(_shopCarpetAreaController.text.trim());
        final frontage = int.tryParse(_shopFrontageController.text.trim());
        if (area != null) amenities['shop_carpet_area_sqft'] = area;
        if (frontage != null) amenities['shop_frontage_ft'] = frontage;
        amenities['shop_footfall'] = _shopFootfall.toLowerCase();
        amenities['shop_washroom'] = _shopWashroom;
        amenities['shop_display_window'] = _shopDisplayWindow;
        amenities['shop_exhaust'] = _shopExhaust;
        amenities['shop_grease_trap'] = _shopGreaseTrap;
        final suitable = _retailSuitableForController.text.trim();
        if (suitable.isNotEmpty) {
          amenities['shop_suitable_for'] = suitable;
        }
      } else if (_propertyType == 'warehouse' || _propertyType == 'industrial') {
        final area = int.tryParse(_warehouseBuiltUpAreaController.text.trim());
        final height = int.tryParse(_warehouseCeilingHeightController.text.trim());
        final bays = int.tryParse(_warehouseLoadingBaysController.text.trim());
        final power = int.tryParse(_warehousePowerController.text.trim());
        final shutter =
            int.tryParse(_warehouseShutterHeightController.text.trim());
        final floorLoad =
            double.tryParse(_warehouseFloorLoadController.text.trim());
        if (area != null) amenities['wh_builtup_area_sqft'] = area;
        if (height != null) amenities['wh_ceiling_height_ft'] = height;
        if (bays != null) amenities['wh_loading_bays'] = bays;
        if (power != null) amenities['wh_power_kva'] = power;
        if (shutter != null) amenities['wh_shutter_height_ft'] = shutter;
        if (floorLoad != null) {
          amenities['wh_floor_load_capacity'] = floorLoad;
        }
        amenities['wh_type'] =
            _warehouseType.toLowerCase().replaceAll(' ', '_');
        amenities['wh_truck_access'] = _warehouseTruckAccess;
      } else {
        final built = int.tryParse(_commercialBuiltUpAreaController.text.trim());
        if (built != null) amenities['commercial_builtup_area_sqft'] = built;
      }

      // Hospitality / Healthcare
      if (_propertyType == 'restaurant') {
        final rooms = int.tryParse(_hospitalRoomsController.text.trim());
        if (rooms != null) amenities['hospitality_rooms'] = rooms;
        final diningCap =
            int.tryParse(_hospitalDiningCapacityController.text.trim());
        if (diningCap != null) {
          amenities['hospitality_dining_capacity'] = diningCap;
        }
        final kitchen = _hospitalKitchenSetupController.text.trim();
        if (kitchen.isNotEmpty) {
          amenities['hospitality_kitchen_setup'] = kitchen;
        }
      } else if (_propertyType == 'clinic') {
        final details = _clinicOtIcuDiagController.text.trim();
        if (details.isNotEmpty) {
          amenities['healthcare_ot_icu_diagnostic'] = details;
        }
      }

      // Building meta
      final floorNo = int.tryParse(_floorNumberController.text.trim());
      if (floorNo != null) amenities['floor'] = floorNo;
      final totalFloors = int.tryParse(_totalFloorsBuildingController.text.trim());
      if (totalFloors != null) amenities['total_floors'] = totalFloors;
      final ageYears = int.tryParse(_buildingAgeController.text.trim());
      if (ageYears != null) amenities['building_age_years'] = ageYears;
      if (_facingDirection != 'Not specified') {
        amenities['facing_direction'] =
            _facingDirection.toLowerCase().replaceAll(' ', '_');
      }

      // Financial terms
      final maintenance = double.tryParse(_maintenanceController.text.trim());
      if (maintenance != null) {
        amenities['maintenance_monthly'] = maintenance;
      }
      final leaseYrs = int.tryParse(_leasePeriodController.text.trim());
      if (leaseYrs != null) {
        amenities['lease_period_years'] = leaseYrs;
      }
      final lockin = int.tryParse(_lockinPeriodController.text.trim());
      if (lockin != null) {
        amenities['lockin_months'] = lockin;
      }
      final notice = int.tryParse(_noticePeriodController.text.trim());
      if (notice != null) {
        amenities['notice_period_days'] = notice;
      }
      final esc = double.tryParse(_escalationRateController.text.trim());
      if (esc != null) {
        amenities['rent_escalation_percent'] = esc;
      }
      amenities['gst_applicable'] = _gstApplicable;

      final rent = double.tryParse(_monthlyRentController.text.trim()) ?? 0;
      final secDep =
          double.tryParse(_securityDepositController.text.trim());

      final listing = Listing(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: rent,
        type: _propertyType,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        images: imageUrls,
        ownerId: 'current_user_id',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        amenities: amenities,
        rentalUnit: 'month',
        securityDeposit: secDep,
      );

      await ref.read(listingProvider.notifier).addListing(listing);
      if (!mounted) return;
      SnackBarUtils.showSuccess(
        context,
        'Commercial listing created successfully!',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to create listing: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildBasicsStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

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
            ),
          ),
          const SizedBox(height: 16),
          ModernTextFormField(
            controller: _titleController,
            label: 'Listing Title',
            hint: 'e.g., 1200 sq ft Furnished Office in IT Park',
            prefixIcon: Icons.title_rounded,
            validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
          ),
          const SizedBox(height: 12),
          ModernTextFormField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Describe layout, furnishing, connectivity and ideal businesses.',
            prefixIcon: Icons.description_outlined,
            maxLines: 4,
            validator: (v) => (v == null || v.isEmpty) ? 'Description is required' : null,
          ),
          const SizedBox(height: 12),
          ModernCustomDropdown<String>(
            label: 'Commercial Property Type',
            value: _propertyType,
            items: _commercialTypes,
            itemLabelBuilder: (t) => t[0].toUpperCase() + t.substring(1),
            prefixIcon: Icons.business_rounded,
            onChanged: (v) => setState(() => _propertyType = v),
          ),
          const SizedBox(height: 12),
          ModernCustomDropdown<String>(
            label: 'Available For',
            value: _availableFor,
            items: const [
              'Rent/Lease',
              'Sub-Lease',
              'Co-Lease / Shared Space',
            ],
            itemLabelBuilder: (v) => v,
            prefixIcon: Icons.handshake_rounded,
            onChanged: (v) => setState(() => _availableFor = v),
          ),
          const SizedBox(height: 12),
          ModernCustomDropdown<String>(
            label: 'Property Status',
            value: _propertyStatus,
            items: const [
              'Ready to move',
              'Under construction',
              'Newly constructed',
              'Furnishing in progress',
            ],
            itemLabelBuilder: (v) => v,
            prefixIcon: Icons.info_outline_rounded,
            onChanged: (v) => setState(() => _propertyStatus = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ModernTextFormField(
                  controller: _monthlyRentController,
                  label: 'Monthly Rent (₹)',
                  hint: 'e.g., 75000',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Rent is required';
                    if ((double.tryParse(v.trim()) ?? 0) <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ModernTextFormField(
                  controller: _securityDepositController,
                  label: 'Security Deposit (₹)',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.savings_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ModernChipGroup<int>(
            label: 'Building Age (Years)',
            items: const [1, 3, 5, 10, 20],
            selectedItems: [int.tryParse(_buildingAgeController.text) ?? 0],
            labelBuilder: (y) => '$y yr${y > 1 ? 's' : ''}',
            onItemSelected: (y) => setState(() => _buildingAgeController.text = y.toString()),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final isWarehouseLike =
        _propertyType == 'warehouse' || _propertyType == 'industrial';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Details',
            style: TextStyle(
              fontSize: isPhone ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ModernTextFormField(
            controller: _addressController,
            label: 'Address',
            hint: 'Building name, street, area',
            prefixIcon: Icons.location_on_outlined,
            validator: (v) => (v == null || v.isEmpty) ? 'Address is required' : null,
          ),
          const SizedBox(height: 12),
          ModernTextFormField(
            controller: _landmarkController,
            label: 'Nearby Landmark',
            hint: 'e.g., Near Metro Station',
            prefixIcon: Icons.map_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ModernTextFormField(
                  controller: _cityController,
                  label: 'City',
                  prefixIcon: Icons.location_city_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ModernTextFormField(
                  controller: _stateController,
                  label: 'State',
                  prefixIcon: Icons.flag_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ModernTextFormField(
            controller: _zipCodeController,
            label: 'Pin Code',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.pin_drop_rounded,
          ),
          const SizedBox(height: 24),
          Text(
            'Building Details',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (!isWarehouseLike) ...[
            Row(
              children: [
                Expanded(
                  child: ModernTextFormField(
                    controller: _floorNumberController,
                    label: 'Floor Number',
                    hint: 'e.g., 1',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ModernTextFormField(
                    controller: _totalFloorsBuildingController,
                    label: 'Total Floors',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: ModernCustomDropdown<String>(
                  label: 'Facing Direction',
                  value: _facingDirection,
                  items: _facingOptions,
                  itemLabelBuilder: (d) => d,
                  prefixIcon: Icons.compass_calibration_rounded,
                  onChanged: (v) => setState(() => _facingDirection = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(2),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
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
            'Property Specifications',
            style: TextStyle(
              fontSize: isPhone ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // 1. Office & Coworking
          if (_propertyType == 'office' || _propertyType == 'coworking') ...[
            ModernTextFormField(
              controller: _officeCarpetAreaController,
              label: 'Carpet Area (sq ft)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.square_foot_rounded,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ModernTextFormField(
                    controller: _officeCabinsController,
                    label: 'Cabins',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.meeting_room_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ModernTextFormField(
                    controller: _officeConferenceRoomsController,
                    label: 'Conf. Rooms',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_propertyType == 'office') ...[
              ModernCustomDropdown<String>(
                label: 'Office Type',
                value: _officeType,
                items: _officeTypeOptions,
                itemLabelBuilder: (t) => t,
                onChanged: (v) => setState(() => _officeType = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ModernTextFormField(
                      controller: _officeWorkstationsController,
                      label: 'Workstations',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.computer_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ModernTextFormField(
                      controller: _officeMeetingRoomsController,
                      label: 'Meeting Rooms',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ModernSwitchTile(
                title: 'Reception Area',
                value: _officeReceptionArea,
                onChanged: (v) => setState(() => _officeReceptionArea = v),
              ),
              ModernSwitchTile(
                title: 'Server Room',
                value: _officeServerRoom,
                onChanged: (v) => setState(() => _officeServerRoom = v),
              ),
              const SizedBox(height: 8),
              ModernCustomDropdown<String>(
                label: 'Washrooms',
                value: _officeWashroomType,
                items: _officeWashroomOptions,
                itemLabelBuilder: (t) => t,
                prefixIcon: Icons.wc_rounded,
                onChanged: (v) => setState(() => _officeWashroomType = v),
              ),
            ],
            const SizedBox(height: 8),
            ModernSwitchTile(
              title: 'Pantry Available',
              value: _officePantry,
              onChanged: (v) => setState(() => _officePantry = v),
              icon: Icons.coffee_rounded,
            ),
          ],

          // 2. Shop & Showroom
          if (_propertyType == 'shop' || _propertyType == 'showroom') ...[
            Row(
              children: [
                Expanded(
                  child: ModernTextFormField(
                    controller: _shopCarpetAreaController,
                    label: 'Carpet Area (sq ft)',
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ModernTextFormField(
                    controller: _shopFrontageController,
                    label: 'Frontage (ft)',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ModernCustomDropdown<String>(
              label: 'Footfall',
              value: _shopFootfall,
              items: const ['Low', 'Medium', 'High'],
              itemLabelBuilder: (f) => f,
              onChanged: (v) => setState(() => _shopFootfall = v),
            ),
            const SizedBox(height: 8),
            ModernTextFormField(
              controller: _retailSuitableForController,
              label: 'Suitable For (optional)',
              hint: 'e.g., Café, Salon, Electronics',
            ),
            const SizedBox(height: 12),
            ModernSwitchTile(
              title: 'Washroom Available',
              value: _shopWashroom,
              onChanged: (v) => setState(() => _shopWashroom = v),
            ),
            ModernSwitchTile(
              title: 'Display Window',
              value: _shopDisplayWindow,
              onChanged: (v) => setState(() => _shopDisplayWindow = v),
            ),
            ModernSwitchTile(
              title: 'Exhaust (for kitchen)',
              value: _shopExhaust,
              onChanged: (v) => setState(() => _shopExhaust = v),
            ),
            ModernSwitchTile(
              title: 'Grease Trap Installed',
              value: _shopGreaseTrap,
              onChanged: (v) => setState(() => _shopGreaseTrap = v),
            ),
          ],

          // 3. Warehouse & Industrial
          if (_propertyType == 'warehouse' || _propertyType == 'industrial') ...[
            ModernTextFormField(
              controller: _warehouseBuiltUpAreaController,
              label: 'Built-up Area (sq ft)',
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            if (_propertyType == 'warehouse')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ModernCustomDropdown<String>(
                  label: 'Warehouse Type',
                  value: _warehouseType,
                  items: _warehouseTypeOptions,
                  itemLabelBuilder: (t) => t,
                  onChanged: (v) => setState(() => _warehouseType = v),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ModernTextFormField(
                    controller: _warehouseCeilingHeightController,
                    label: 'Ceiling Height (ft)',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ModernTextFormField(
                    controller: _warehouseLoadingBaysController,
                    label: 'Loading Bays',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ModernTextFormField(
              controller: _warehousePowerController,
              label: 'Power (kVA)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.electric_bolt_rounded,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ModernTextFormField(
                    controller: _warehouseShutterHeightController,
                    label: 'Shutter Ht (ft)',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ModernTextFormField(
                    controller: _warehouseFloorLoadController,
                    label: 'Floor Load',
                    hint: 'kg/sq m',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ModernSwitchTile(
              title: 'Truck Access',
              value: _warehouseTruckAccess,
              onChanged: (v) => setState(() => _warehouseTruckAccess = v),
              icon: Icons.local_shipping_rounded,
            ),
          ],

          // 4. Hospitality (Restaurant) - Additions
          if (_propertyType == 'restaurant') ...[
            const SizedBox(height: 24),
            Text(
              'Hospitality Details',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ModernTextFormField(
                    controller: _hospitalRoomsController,
                    label: 'No. of Rooms',
                    hint: 'If Hotel/Resort',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ModernTextFormField(
                    controller: _hospitalDiningCapacityController,
                    label: 'Dining Capacity',
                    hint: 'Covers',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.dining_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ModernTextFormField(
              controller: _hospitalKitchenSetupController,
              label: 'Kitchen Setup',
              hint: 'e.g., Equipped, FSSAI compliant',
              maxLines: 2,
            ),
          ],

          // 5. Healthcare (Clinic) - Additions
          if (_propertyType == 'clinic') ...[
            const SizedBox(height: 24),
            Text(
              'Healthcare Details',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ModernTextFormField(
              controller: _clinicOtIcuDiagController,
              label: 'Facilities',
              hint: 'e.g., 1 OT, 2 ICU beds, X-ray, MRI',
              maxLines: 2,
              prefixIcon: Icons.local_hospital_rounded,
            ),
          ],
          
          // Generic fallback
          if (!['office', 'coworking', 'shop', 'showroom', 'warehouse', 'industrial'].contains(_propertyType)) ...[
             ModernTextFormField(
               controller: _commercialBuiltUpAreaController,
               label: 'Built-up Area (sq ft)',
               keyboardType: TextInputType.number,
               validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
             ),
          ],

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(3),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesFinancialsStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities & Financials',
            style: TextStyle(
              fontSize: isPhone ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          
          ModernChipGroup<String>(
            label: 'Building Amenities',
            items: _buildingAmenities,
            selectedItems: _selectedAmenities.toList(),
            labelBuilder: (a) => a,
            onItemSelected: (a) {
              setState(() {
                if (_selectedAmenities.contains(a)) {
                  _selectedAmenities.remove(a);
                } else {
                  _selectedAmenities.add(a);
                }
              });
            },
          ),
          const SizedBox(height: 16),
          
          ModernChipGroup<String>(
            label: 'Parking',
            items: _parkingAmenities,
            selectedItems: _selectedAmenities.toList(),
            labelBuilder: (a) => a,
            onItemSelected: (a) {
              setState(() {
                if (_selectedAmenities.contains(a)) {
                  _selectedAmenities.remove(a);
                } else {
                  _selectedAmenities.add(a);
                }
              });
            },
          ),
          const SizedBox(height: 16),

          if (_propertyType == 'restaurant') ...[
            Text(
              'Restaurant Specific',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ModernSwitchTile(
              title: 'Liquor License',
              value: _restLiquorLicense,
              onChanged: (v) => setState(() => _restLiquorLicense = v),
            ),
            ModernSwitchTile(
              title: 'Outdoor Seating',
              value: _restOutdoorSeating,
              onChanged: (v) => setState(() => _restOutdoorSeating = v),
            ),
            ModernSwitchTile(
              title: 'Live Music / Entertainment',
              value: _restLiveMusic,
              onChanged: (v) => setState(() => _restLiveMusic = v),
            ),
            const SizedBox(height: 16),
          ],

          if (_propertyType == 'clinic') ...[
            Text(
              'Clinic Specific',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ModernSwitchTile(
              title: '24x7 Emergency',
              value: _clinicEmergency24x7,
              onChanged: (v) => setState(() => _clinicEmergency24x7 = v),
            ),
            ModernSwitchTile(
              title: 'In-house Pharmacy',
              value: _clinicInHousePharmacy,
              onChanged: (v) => setState(() => _clinicInHousePharmacy = v),
            ),
            ModernSwitchTile(
              title: 'Daycare Facility',
              value: _clinicDaycare,
              onChanged: (v) => setState(() => _clinicDaycare = v),
            ),
            const SizedBox(height: 16),
          ],

          if (_propertyType == 'warehouse' || _propertyType == 'industrial') ...[
            Text(
              'Warehouse Specific',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ModernSwitchTile(
              title: 'Security Cabin',
              value: _warehouseSecurityCabin,
              onChanged: (v) => setState(() => _warehouseSecurityCabin = v),
            ),
            ModernSwitchTile(
              title: 'Weighbridge',
              value: _warehouseWeighbridge,
              onChanged: (v) => setState(() => _warehouseWeighbridge = v),
            ),
            ModernSwitchTile(
              title: 'Sprinkler System',
              value: _warehouseSprinklerSystem,
              onChanged: (v) => setState(() => _warehouseSprinklerSystem = v),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            'Financial Terms',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ModernTextFormField(
            controller: _maintenanceController,
            label: 'Maintenance (₹ / month)',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.currency_rupee_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ModernTextFormField(
                  controller: _leasePeriodController,
                  label: 'Lease (years)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ModernTextFormField(
                  controller: _lockinPeriodController,
                  label: 'Lock-in (months)',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ModernChipGroup<int>(
            label: 'Quick Select Lease Period',
            items: const [1, 3, 5, 9, 15],
            selectedItems: [int.tryParse(_leasePeriodController.text) ?? 0],
            labelBuilder: (y) => '$y yr${y > 1 ? 's' : ''}',
            onItemSelected: (y) => setState(() => _leasePeriodController.text = y.toString()),
          ),
          const SizedBox(height: 12),

          ModernChipGroup<int>(
            label: 'Quick Select Lock-in Period',
            items: const [3, 6, 9, 12, 18, 24],
            selectedItems: [int.tryParse(_lockinPeriodController.text) ?? 0],
            labelBuilder: (m) => '$m mo',
            onItemSelected: (m) => setState(() => _lockinPeriodController.text = m.toString()),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ModernTextFormField(
                  controller: _noticePeriodController,
                  label: 'Notice Period (days)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ModernTextFormField(
                  controller: _escalationRateController,
                  label: 'Rent Escalation (% / year)',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ModernChipGroup<int>(
            label: 'Quick Select Notice Period',
            items: const [15, 30, 45, 60, 90],
            selectedItems: [int.tryParse(_noticePeriodController.text) ?? 0],
            labelBuilder: (d) => '$d days',
            onItemSelected: (d) => setState(() => _noticePeriodController.text = d.toString()),
          ),
          
          const SizedBox(height: 12),
          ModernSwitchTile(
            title: 'GST applicable on rent',
            value: _gstApplicable,
            onChanged: (v) => setState(() => _gstApplicable = v),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(2),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(4),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContactStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(12, 12, 12, isPhone ? 72 : 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photos & Contact',
            style: TextStyle(
              fontSize: isPhone ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload clear photos and share how tenants can contact you.',
            style: TextStyle(
              fontSize: isPhone ? 11 : 12,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Minimum 4 photos required. The first photo will be used as the cover.',
            style: TextStyle(
              fontSize: isPhone ? 11 : 12,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final img = entry.value;
                final isCover = index == 0;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(img.path),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isCover)
                      Positioned(
                        left: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                              final imgToMakeCover =
                                  _selectedImages.removeAt(index);
                              _selectedImages.insert(0, imgToMakeCover);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                      right: 4,
                      bottom: 4,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              InkWell(
                onTap: _pickImages,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    color: theme.colorScheme.surface,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add Photos',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Contact Details',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ModernTextFormField(
            controller: _contactPersonController,
            label: 'Contact Person',
            prefixIcon: Icons.person_rounded,
            validator: (v) => (v == null || v.isEmpty) ? 'Contact person is required' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ModernTextFormField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_rounded,
                  validator: (v) => (v == null || v.isEmpty) ? 'Phone is required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ModernTextFormField(
                  controller: _alternatePhoneController,
                  label: 'Alternate Phone',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_in_talk_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ModernTextFormField(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_rounded,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed:
                    _isLoading ? null : () => _tabController.animateTo(3),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveListing,
                  icon: _isLoading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    _isLoading
                        ? 'Publishing Commercial Listing...'
                        : 'Publish Commercial Listing',
                    style: TextStyle(fontSize: isPhone ? 12 : 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(
                      vertical: isPhone ? 13 : 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isPhone = size.width < 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isPhone ? 56 : 64),
        child: AppBar(
          title: Text(
            'Create Commercial Listing',
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
          // Progress indicator
          Container(
            height: 1,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            ),
            child: LinearProgressIndicator(
              value: (_tabController.index + 1) / 5,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
              minHeight: 1,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              color: theme.colorScheme.surface,
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 2.5,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.5),
              labelStyle: TextStyle(
                fontSize: isPhone ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: isPhone ? 10 : 11,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'Basics'),
                Tab(text: 'Location'),
                Tab(text: 'Specifications'),
                Tab(text: 'Amenities & Financials'),
                Tab(text: 'Photos & Contact'),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(
                  parent: PageScrollPhysics(),
                ),
                children: [
                  _buildBasicsStep(),
                  _buildLocationStep(),
                  _buildDetailsStep(),
                  _buildAmenitiesFinancialsStep(),
                  _buildMediaContactStep(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
