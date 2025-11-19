import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../services/image_service.dart';
import '../../services/listing_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../app/app_state.dart';

class _VenueRoomType {
  String name;
  String rooms;
  String pricePerNight;
  String mealPlan;
  String extraBedCharges;
  List<int> photoIndices;

  _VenueRoomType()
      : name = '',
        rooms = '',
        pricePerNight = '',
        mealPlan = '',
        extraBedCharges = '',
        photoIndices = <int>[];
}

class VenueListingFormScreen extends ConsumerStatefulWidget {
  const VenueListingFormScreen({super.key});

  @override
  ConsumerState<VenueListingFormScreen> createState() => _VenueListingFormScreenState();
}

class _VenueListingFormScreenState extends ConsumerState<VenueListingFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Basics
  final _venueNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _venueType = 'Banquet Hall';
  final List<String> _venueTypeOptions = const [
    'Banquet Hall',
    'Wedding Venue',
    'Party Hall',
    'Conference Room',
    'Meeting Room',
    'Auditorium / Theatre',
    'Outdoor Lawn / Garden',
    'Rooftop Venue',
    'Hotel Ballroom',
    'Resort Venue',
    'Farmhouse / Villa Event Space',
    'Studio (Photo / Video / Music)',
    'Exhibition Center',
    'Club / Lounge Event Space',
    'Private Dining Room',
    'Co-working Event Lounge',
    'Retreat Site / Campground',
  ];

  final Set<String> _selectedVenueCategories = <String>{};

  final List<String> _eventTypeOptions = const [
    'Wedding',
    'Reception',
    'Birthday Party',
    'Corporate Event',
    'Workshop / Training',
    'Concert / Performance',
    'Exhibition',
    'Photoshoot / Filming',
    'Private Dinner',
    'Religious Event',
    'Festival Event',
    'Engagement / Anniversary',
    'Others',
  ];
  final Set<String> _selectedEventTypes = <String>{};

  String _availabilityType = 'Full venue';
  final List<String> _availabilityOptions = const [
    'Full venue',
    'Partial areas',
    'Rooms + venue',
  ];

  // Location
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _mapLinkController = TextEditingController();

  String _parkingRange = '0-10';
  final List<String> _parkingRangeOptions = const [
    '0-10',
    '10-50',
    '50-100',
    '100+',
  ];

  final List<String> _publicTransportOptions = const [
    'Metro',
    'Bus',
    'Train',
    'Highway',
  ];
  final Set<String> _selectedPublicTransport = <String>{};

  // Size, capacity & layout (common)
  final _indoorAreaController = TextEditingController();
  final _outdoorAreaController = TextEditingController();
  final _floatingCapacityController = TextEditingController();
  final _seatingCapacityController = TextEditingController();
  final _maxGuestsController = TextEditingController();
  final _eventSpacesController = TextEditingController();
  bool _fireSafetyCompliant = false;

  // Banquet / wedding / party / ballroom / club / rooftop
  final _hallDimensionsController = TextEditingController();
  final _hallHeightController = TextEditingController();
  final _mandapAreaController = TextEditingController();
  bool _stageIncluded = false;
  bool _brideGroomRooms = false;
  bool _baraatEntryAllowed = false;
  bool _danceFloorAvailable = false;
  final _djVolumeLimitController = TextEditingController();

  // Outdoor lawn / garden / retreat / farmhouse / villa events
  final _lawnSizeController = TextEditingController();
  String _lawnSurfaceType = 'Grass';
  final List<String> _lawnSurfaceOptions = const [
    'Grass',
    'Turf',
    'Mixed',
  ];
  bool _weatherBackupSpace = false;
  bool _tentPandalAllowed = false;
  bool _lawnWaterPowerAccess = false;
  final _noiseCurfewController = TextEditingController();

  // Auditorium / theatre
  final _fixedSeatingCountController = TextEditingController();
  final _auditoriumStageSizeController = TextEditingController();
  final _backstageRoomsController = TextEditingController();
  final _soundSystemSpecsController = TextEditingController();
  final _lightingRigSpecsController = TextEditingController();
  final _greenRoomsController = TextEditingController();
  final _acousticRatingController = TextEditingController();

  // Conference / meeting / co-working lounge
  final _boardroomCapacityController = TextEditingController();
  final _tableLayoutOptionsController = TextEditingController();
  bool _hasTvProjector = false;
  bool _hasWhiteboard = false;
  bool _hasConferencePhone = false;
  final _wifiSpeedRatingController = TextEditingController();

  // Resort / hotel / farmhouse / villa
  final _ballroomSizeController = TextEditingController();
  final _poolsideAreaController = TextEditingController();
  final _outdoorStageOptionsController = TextEditingController();
  final _villaSizeController = TextEditingController();
  final _villaBedroomsController = TextEditingController();
  bool _villaPoolAccess = false;
  bool _villaMusicAllowed = false;
  final _stayEventPackagesController = TextEditingController();
  final _maxOvernightGuestsController = TextEditingController();
  final List<_VenueRoomType> _roomTypes = [];

  // Studio (photo / video / music)
  String _studioType = 'Photo';
  final List<String> _studioTypeOptions = const [
    'Photo',
    'Video',
    'Sound',
  ];
  final _studioCeilingHeightController = TextEditingController();
  bool _studioCycloramaWall = false;
  bool _studioLightingIncluded = false;
  final _soundproofRatingController = TextEditingController();
  final _studioPropsController = TextEditingController();

  // Exhibition hall
  final _exhibitionCarpetAreaController = TextEditingController();
  final _maxBoothCapacityController = TextEditingController();
  final _powerLoadController = TextEditingController();
  bool _loadingAccess = false;
  bool _storageAvailable = false;

  // Club / lounge / rooftop extras
  final _indoorSeatingController = TextEditingController();
  final _outdoorSeatingController = TextEditingController();
  final _soundLimitController = TextEditingController();
  bool _alcoholServiceAllowed = false;
  bool _barSetupIncluded = false;
  bool _liveMusicLicense = false;

  // Generic layout notes
  final _layoutNotesController = TextEditingController();

  // Amenities & facilities
  final List<String> _amenityOptions = const [
    'AC / Climate Control',
    'Heating',
    'Power Backup',
    'Male/Female Washrooms',
    'Accessible Washroom',
    'Changing Rooms',
    'WiFi',
    'Generator',
    'Security Personnel',
    'CCTV',
    'In-house Decoration Team',
    'Storage Area',
    'Coat Check',
  ];
  final Set<String> _selectedAmenities = <String>{};
  final _generatorCapacityController = TextEditingController();

  // Food, beverages & vendors + pricing
  String _inHouseCateringRequirement = 'Required';
  final List<String> _inHouseCateringOptions = const [
    'Required',
    'Optional',
  ];
  bool _outsideCateringAllowed = false;
  bool _vegAvailable = true;
  bool _nonVegAvailable = false;
  final _perPlatePriceController = TextEditingController();
  bool _buffetAvailable = false;
  bool _liveCountersAvailable = false;

  String _alcoholPolicy = 'Not allowed';
  final List<String> _alcoholPolicyOptions = const [
    'Allowed',
    'Not allowed',
    'Allowed with permit',
  ];

  bool _decoratorsAllowedOutside = false;
  bool _djAllowed = false;
  bool _photographerAllowed = true;
  final _cleaningChargesController = TextEditingController();

  // Pricing & booking rules
  final List<String> _pricingModelOptions = const [
    'Hourly',
    'Half Day',
    'Full Day',
    'Per Event',
    'Package-Based',
    'Seasonal Pricing',
  ];
  final Set<String> _selectedPricingModels = <String>{};

  final _venueRentalPriceController = TextEditingController();
  final _securityDepositController = TextEditingController();
  final _serviceChargeController = TextEditingController();
  final _overtimeChargeController = TextEditingController();
  final _minimumHoursController = TextEditingController();
  final List<String> _minimumHoursPresetOptions = const [
    '2',
    '3',
    '4',
    '6',
    '8',
    '12',
    '24',
  ];
  final _curfewTimeController = TextEditingController();
  final List<String> _curfewTimePresetOptions = const [
    '10:00 PM',
    '11:00 PM',
    '12:00 AM',
    'No strict curfew',
  ];
  final _noiseRestrictionsController = TextEditingController();
  String _cancellationPolicy = 'Moderate';
  final List<String> _cancellationPolicyOptions = const [
    'Flexible',
    'Moderate',
    'Strict',
  ];
  bool _reschedulingAllowed = true;

  // Media & contact
  List<XFile> _selectedImages = [];
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactRoleController = TextEditingController();
  final List<String> _contactRoleOptions = const [
    'Owner',
    'Manager',
    'Owner & Manager',
    'Sales / Booking',
  ];
  final _businessNameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _socialLinksController = TextEditingController();
  final _menuLinkController = TextEditingController();

  bool _isLoading = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _selectedVenueCategories.add(_venueType);
  }

  @override
  void dispose() {
    _tabController.dispose();

    _venueNameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();

    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _zipCodeController.dispose();
    _mapLinkController.dispose();

    _indoorAreaController.dispose();
    _outdoorAreaController.dispose();
    _floatingCapacityController.dispose();
    _seatingCapacityController.dispose();
    _maxGuestsController.dispose();
    _eventSpacesController.dispose();
    _layoutNotesController.dispose();

    _generatorCapacityController.dispose();

    _perPlatePriceController.dispose();
    _cleaningChargesController.dispose();
    _venueRentalPriceController.dispose();
    _securityDepositController.dispose();
    _serviceChargeController.dispose();
    _overtimeChargeController.dispose();
    _minimumHoursController.dispose();
    _curfewTimeController.dispose();
    _noiseRestrictionsController.dispose();

    _contactPersonController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _contactRoleController.dispose();
    _businessNameController.dispose();
    _websiteController.dispose();
    _socialLinksController.dispose();
    _menuLinkController.dispose();

    super.dispose();
  }

  String _slugify(String label) {
    return label
        .toLowerCase()
        .replaceAll(' / ', '_')
        .replaceAll('/', '_')
        .replaceAll(' & ', '_')
        .replaceAll(' ', '_');
  }

  bool get _isBanquetLike => [
        'Banquet Hall',
        'Wedding Venue',
        'Party Hall',
        'Hotel Ballroom',
        'Private Dining Room',
      ].contains(_venueType);

  bool get _isOutdoorLike => [
        'Outdoor Lawn / Garden',
        'Retreat Site / Campground',
        'Farmhouse / Villa Event Space',
      ].contains(_venueType);

  bool get _isAuditoriumLike => _venueType == 'Auditorium / Theatre';

  bool get _isConferenceLike => [
        'Conference Room',
        'Meeting Room',
        'Co-working Event Lounge',
      ].contains(_venueType);

  bool get _isResortLike => [
        'Resort Venue',
        'Farmhouse / Villa Event Space',
      ].contains(_venueType);

  bool get _isStudioLike => _venueType == 'Studio (Photo / Video / Music)';

  bool get _isExhibitionLike => _venueType == 'Exhibition Center';

  bool get _isClubLike => [
        'Club / Lounge Event Space',
        'Rooftop Venue',
      ].contains(_venueType);

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isEmpty) return;
      if (images.length > 15) {
        if (mounted) {
          SnackBarUtils.showWarning(
            context,
            'You can select maximum 15 images',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final isRequired = validator != null;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: isPhone ? 16 : 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isPhone ? 10 : 12,
        ),
      ),
      style: TextStyle(fontSize: isPhone ? 12 : 13),
    );
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

      if (!mounted) return;

      final amenities = <String, dynamic>{};

      amenities['category'] = 'Venue';
      amenities['venue_type'] = _slugify(_venueType);
      if (_selectedVenueCategories.isNotEmpty) {
        amenities['venue_categories'] =
            _selectedVenueCategories.map(_slugify).toList();
      }
      if (_selectedEventTypes.isNotEmpty) {
        amenities['event_types_allowed'] =
            _selectedEventTypes.map(_slugify).toList();
      }
      amenities['availability_type'] = _slugify(_availabilityType);

      // Location
      amenities['country'] = _countryController.text.trim();
      amenities['state'] = _stateController.text.trim();
      amenities['city'] = _cityController.text.trim();
      amenities['area'] = _areaController.text.trim();
      amenities['landmark'] = _landmarkController.text.trim();
      amenities['map_link'] = _mapLinkController.text.trim();
      amenities['parking_range'] = _parkingRange;
      if (_selectedPublicTransport.isNotEmpty) {
        amenities['public_transport'] =
            _selectedPublicTransport.map(_slugify).toList();
      }

      // Size & capacity (common)
      final indoorArea = int.tryParse(_indoorAreaController.text.trim());
      final outdoorArea = int.tryParse(_outdoorAreaController.text.trim());
      final floatingCap = int.tryParse(_floatingCapacityController.text.trim());
      final seatingCap = int.tryParse(_seatingCapacityController.text.trim());
      final maxGuests = int.tryParse(_maxGuestsController.text.trim());
      final eventSpaces = int.tryParse(_eventSpacesController.text.trim());
      if (indoorArea != null) amenities['indoor_area_sqft'] = indoorArea;
      if (outdoorArea != null) amenities['outdoor_area_sqft'] = outdoorArea;
      if (floatingCap != null) amenities['floating_capacity'] = floatingCap;
      if (seatingCap != null) {
        amenities['seating_capacity'] = seatingCap;
        amenities['venue_seated_capacity'] = seatingCap;
      }
      if (maxGuests != null) amenities['max_guests'] = maxGuests;
      if (eventSpaces != null) amenities['event_spaces_count'] = eventSpaces;
      amenities['fire_safety_compliant'] = _fireSafetyCompliant;
      final layoutNotes = _layoutNotesController.text.trim();
      if (layoutNotes.isNotEmpty) {
        amenities['layout_notes'] = layoutNotes;
      }

      // Small per-type validation for key layout fields
      if (_isBanquetLike ||
          _isOutdoorLike ||
          _isAuditoriumLike ||
          _isConferenceLike ||
          _isResortLike ||
          _isStudioLike ||
          _isExhibitionLike ||
          _isClubLike) {
        if (seatingCap == null || seatingCap <= 0) {
          SnackBarUtils.showWarning(
            context,
            'Please enter a valid seating capacity for this venue.',
          );
          return;
        }
      }

      if (_isOutdoorLike) {
        final lawnSizeVal = int.tryParse(_lawnSizeController.text.trim());
        if (lawnSizeVal == null || lawnSizeVal <= 0) {
          SnackBarUtils.showWarning(
            context,
            'Please enter a valid lawn size.',
          );
          return;
        }
      }

      if (_isAuditoriumLike) {
        final fixedSeatsVal =
            int.tryParse(_fixedSeatingCountController.text.trim());
        if (fixedSeatsVal == null || fixedSeatsVal <= 0) {
          SnackBarUtils.showWarning(
            context,
            'Please enter a valid fixed seating count for the auditorium.',
          );
          return;
        }
      }

      if (_isConferenceLike) {
        final boardCapVal =
            int.tryParse(_boardroomCapacityController.text.trim());
        if (boardCapVal == null || boardCapVal <= 0) {
          SnackBarUtils.showWarning(
            context,
            'Please enter a valid boardroom capacity.',
          );
          return;
        }
      }

      if (_isResortLike) {
        final maxOvernightVal =
            int.tryParse(_maxOvernightGuestsController.text.trim());
        if (maxOvernightVal == null || maxOvernightVal <= 0) {
          SnackBarUtils.showWarning(
            context,
            'Please enter a valid maximum overnight guests count.',
          );
          return;
        }
      }

      if (_isExhibitionLike) {
        final carpetVal =
            int.tryParse(_exhibitionCarpetAreaController.text.trim());
        if (carpetVal == null || carpetVal <= 0) {
          SnackBarUtils.showWarning(
            context,
            'Please enter a valid exhibition carpet area.',
          );
          return;
        }
      }

      if (_isClubLike) {
        final indoorSeatVal =
            int.tryParse(_indoorSeatingController.text.trim());
        if (indoorSeatVal == null || indoorSeatVal <= 0) {
          SnackBarUtils.showWarning(
            context,
            'Please enter a valid indoor seating count.',
          );
          return;
        }
      }

      // Banquet / wedding / party / ballroom / private dining
      if (_isBanquetLike) {
        final hallDims = _hallDimensionsController.text.trim();
        if (hallDims.isNotEmpty) amenities['hall_dimensions'] = hallDims;
        final hallHeight = int.tryParse(_hallHeightController.text.trim());
        if (hallHeight != null) amenities['hall_height_ft'] = hallHeight;
        amenities['stage_included'] = _stageIncluded;
        amenities['bride_groom_rooms'] = _brideGroomRooms;
        final mandap = _mandapAreaController.text.trim();
        if (mandap.isNotEmpty) amenities['mandap_area'] = mandap;
        amenities['baraat_entry_allowed'] = _baraatEntryAllowed;
        amenities['dance_floor_available'] = _danceFloorAvailable;
        final djLimit = _djVolumeLimitController.text.trim();
        if (djLimit.isNotEmpty) amenities['dj_volume_limit'] = djLimit;
      }

      // Outdoor lawn / garden / retreat / farmhouse / villa events
      if (_isOutdoorLike) {
        final lawnSize = int.tryParse(_lawnSizeController.text.trim());
        if (lawnSize != null) amenities['lawn_size_sqft'] = lawnSize;
        amenities['lawn_surface_type'] = _slugify(_lawnSurfaceType);
        amenities['weather_backup_space'] = _weatherBackupSpace;
        amenities['tent_pandal_allowed'] = _tentPandalAllowed;
        amenities['lawn_water_power_access'] = _lawnWaterPowerAccess;
        final curfew = _noiseCurfewController.text.trim();
        if (curfew.isNotEmpty) amenities['noise_curfew_time'] = curfew;
      }

      // Auditorium / theatre
      if (_isAuditoriumLike) {
        final fixedSeats =
            int.tryParse(_fixedSeatingCountController.text.trim());
        if (fixedSeats != null) amenities['fixed_seating_count'] = fixedSeats;
        final stageSize = _auditoriumStageSizeController.text.trim();
        if (stageSize.isNotEmpty) amenities['auditorium_stage_size'] = stageSize;
        final backstageRooms =
            int.tryParse(_backstageRoomsController.text.trim());
        if (backstageRooms != null) amenities['backstage_rooms'] = backstageRooms;
        final soundSpecs = _soundSystemSpecsController.text.trim();
        if (soundSpecs.isNotEmpty) amenities['sound_system_specs'] = soundSpecs;
        final lightingSpecs = _lightingRigSpecsController.text.trim();
        if (lightingSpecs.isNotEmpty) amenities['lighting_rig_specs'] = lightingSpecs;
        final greenRooms = int.tryParse(_greenRoomsController.text.trim());
        if (greenRooms != null) amenities['green_rooms'] = greenRooms;
        final acoustic = _acousticRatingController.text.trim();
        if (acoustic.isNotEmpty) amenities['acoustic_rating'] = acoustic;
      }

      // Conference / meeting / co-working event lounge
      if (_isConferenceLike) {
        final boardCap =
            int.tryParse(_boardroomCapacityController.text.trim());
        if (boardCap != null) amenities['boardroom_capacity'] = boardCap;
        final layouts = _tableLayoutOptionsController.text.trim();
        if (layouts.isNotEmpty) amenities['table_layout_options'] = layouts;
        amenities['tv_projector'] = _hasTvProjector;
        amenities['whiteboard'] = _hasWhiteboard;
        amenities['conference_phone'] = _hasConferencePhone;
        final wifi = _wifiSpeedRatingController.text.trim();
        if (wifi.isNotEmpty) amenities['wifi_speed_rating'] = wifi;
      }

      // Resort / hotel / farmhouse / villa
      if (_isResortLike) {
        final ballroomSize =
            int.tryParse(_ballroomSizeController.text.trim());
        if (ballroomSize != null) amenities['ballroom_size_sqft'] = ballroomSize;
        final poolArea = int.tryParse(_poolsideAreaController.text.trim());
        if (poolArea != null) amenities['poolside_area_sqft'] = poolArea;
        final stageOpts = _outdoorStageOptionsController.text.trim();
        if (stageOpts.isNotEmpty) amenities['outdoor_stage_options'] = stageOpts;

        final villaSize = int.tryParse(_villaSizeController.text.trim());
        if (villaSize != null) amenities['villa_size_sqft'] = villaSize;
        final villaBeds = int.tryParse(_villaBedroomsController.text.trim());
        if (villaBeds != null) amenities['villa_bedrooms_included'] = villaBeds;
        amenities['villa_pool_access'] = _villaPoolAccess;
        amenities['villa_music_allowed'] = _villaMusicAllowed;
        final stayPkgs = _stayEventPackagesController.text.trim();
        if (stayPkgs.isNotEmpty) amenities['stay_event_packages'] = stayPkgs;
        final maxOvernight =
            int.tryParse(_maxOvernightGuestsController.text.trim());
        if (maxOvernight != null) {
          amenities['max_overnight_guests'] = maxOvernight;
        }

        final roomTypes = _roomTypes
            .where((r) => r.name.trim().isNotEmpty)
            .map((r) {
              final roomPhotoUrls = <String>[];
              for (final idx in r.photoIndices) {
                if (idx >= 0 && idx < imageUrls.length) {
                  roomPhotoUrls.add(imageUrls[idx]);
                }
              }
              return {
                'name': r.name.trim(),
                'rooms': int.tryParse(r.rooms.trim()) ?? 0,
                'price_per_night':
                    double.tryParse(r.pricePerNight.trim()) ?? 0.0,
                'meal_plan': r.mealPlan.trim(),
                'extra_bed_charges':
                    double.tryParse(r.extraBedCharges.trim()) ?? 0.0,
                if (roomPhotoUrls.isNotEmpty) 'photo_urls': roomPhotoUrls,
              };
            })
            .toList();
        if (roomTypes.isNotEmpty) {
          amenities['venue_room_types'] = roomTypes;
        }
      }

      // Studio
      if (_isStudioLike) {
        amenities['studio_type'] = _slugify(_studioType);
        final ceilHeight =
            int.tryParse(_studioCeilingHeightController.text.trim());
        if (ceilHeight != null) {
          amenities['studio_ceiling_height_ft'] = ceilHeight;
        }
        amenities['studio_cyclorama_wall'] = _studioCycloramaWall;
        amenities['studio_lighting_included'] = _studioLightingIncluded;
        final sp = _soundproofRatingController.text.trim();
        if (sp.isNotEmpty) {
          amenities['studio_soundproofing_rating'] = sp;
        }
        final props = _studioPropsController.text.trim();
        if (props.isNotEmpty) amenities['studio_props_available'] = props;
      }

      // Exhibition hall
      if (_isExhibitionLike) {
        final carpet =
            int.tryParse(_exhibitionCarpetAreaController.text.trim());
        if (carpet != null) {
          amenities['exhibition_carpet_area_sqft'] = carpet;
        }
        final booths =
            int.tryParse(_maxBoothCapacityController.text.trim());
        if (booths != null) amenities['max_booth_capacity'] = booths;
        final powerLoad = double.tryParse(_powerLoadController.text.trim());
        if (powerLoad != null) amenities['power_load_kw'] = powerLoad;
        amenities['loading_unloading_access'] = _loadingAccess;
        amenities['warehouse_storage_available'] = _storageAvailable;
      }

      // Club / lounge / rooftop
      if (_isClubLike) {
        final indoorSeat = int.tryParse(_indoorSeatingController.text.trim());
        final outdoorSeat = int.tryParse(_outdoorSeatingController.text.trim());
        if (indoorSeat != null) amenities['indoor_seating'] = indoorSeat;
        if (outdoorSeat != null) amenities['outdoor_seating'] = outdoorSeat;
        final soundLimit = _soundLimitController.text.trim();
        if (soundLimit.isNotEmpty) amenities['sound_limit'] = soundLimit;
        amenities['alcohol_service_allowed'] = _alcoholServiceAllowed;
        amenities['bar_setup_included'] = _barSetupIncluded;
        amenities['live_music_license'] = _liveMusicLicense;
      }

      // Amenities
      if (_selectedAmenities.isNotEmpty) {
        amenities['amenities'] = _selectedAmenities.map(_slugify).toList();
      }
      final genCap = double.tryParse(_generatorCapacityController.text.trim());
      if (genCap != null) amenities['generator_capacity_kva'] = genCap;

      // Food & beverages
      amenities['in_house_catering_requirement'] =
          _slugify(_inHouseCateringRequirement);
      amenities['outside_catering_allowed'] = _outsideCateringAllowed;
      amenities['veg_available'] = _vegAvailable;
      amenities['non_veg_available'] = _nonVegAvailable;
      final perPlate = double.tryParse(_perPlatePriceController.text.trim());
      if (perPlate != null) amenities['per_plate_price'] = perPlate;
      amenities['buffet_available'] = _buffetAvailable;
      amenities['live_counters_available'] = _liveCountersAvailable;

      // Alcohol & vendors
      amenities['alcohol_policy'] = _slugify(_alcoholPolicy);
      amenities['decorators_allowed_outside'] = _decoratorsAllowedOutside;
      amenities['dj_allowed'] = _djAllowed;
      amenities['photographer_allowed'] = _photographerAllowed;
      final cleaning = double.tryParse(_cleaningChargesController.text.trim());
      if (cleaning != null) amenities['cleaning_charges'] = cleaning;

      // Pricing & booking
      if (_selectedPricingModels.isNotEmpty) {
        amenities['pricing_models'] =
            _selectedPricingModels.map(_slugify).toList();
      }
      final venuePrice =
          double.tryParse(_venueRentalPriceController.text.trim());
      final secDep = double.tryParse(_securityDepositController.text.trim());
      final serviceCharge =
          double.tryParse(_serviceChargeController.text.trim());
      final overtime = double.tryParse(_overtimeChargeController.text.trim());
      final minHours = int.tryParse(_minimumHoursController.text.trim());
      if (serviceCharge != null) {
        amenities['service_charge'] = serviceCharge;
      }
      if (overtime != null) amenities['overtime_charge'] = overtime;
      if (minHours != null) amenities['minimum_hours'] = minHours;
      amenities['curfew_time'] = _curfewTimeController.text.trim();
      amenities['noise_restrictions'] =
          _noiseRestrictionsController.text.trim();
      amenities['cancellation_policy'] = _slugify(_cancellationPolicy);
      amenities['rescheduling_allowed'] = _reschedulingAllowed;

      // Contact & extras
      amenities['contact_role'] = _contactRoleController.text.trim();
      amenities['business_name'] = _businessNameController.text.trim();
      amenities['website'] = _websiteController.text.trim();
      amenities['social_links'] = _socialLinksController.text.trim();
      amenities['menu_link'] = _menuLinkController.text.trim();

      final listing = Listing(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: venuePrice ?? 0,
        type: 'venue_${_slugify(_venueType)}',
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        images: imageUrls,
        ownerId: user.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        amenities: amenities,
        rentalUnit: null,
        securityDeposit: secDep,
      );

      await ref.read(listingProvider.notifier).addListing(listing);
      if (!mounted) return;
      SnackBarUtils.showSuccess(
        context,
        'Venue listing created successfully!',
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
            'Venue Basics',
            style: TextStyle(
              fontSize: isPhone ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _venueNameController,
            label: 'Venue Name',
            hint: 'e.g., Grand Palace Banquet',
            prefixIcon: Icons.apartment,
            validator: (v) => (v == null || v.isEmpty)
                ? 'Venue name is required'
                : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _titleController,
            label: 'Listing Title',
            hint: 'e.g., Elegant Lawn + Banquet for Weddings & Events',
            prefixIcon: Icons.title_rounded,
            validator: (v) => (v == null || v.isEmpty)
                ? 'Title is required'
                : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: 'Short Description',
            hint: 'Describe ambience, ideal events, and highlights.',
            prefixIcon: Icons.description_outlined,
            maxLines: 4,
            validator: (v) => (v == null || v.isEmpty)
                ? 'Description is required'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _venueType,
            decoration: InputDecoration(
              labelText: 'Primary Venue Type',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            items: _venueTypeOptions
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _venueType = v;
                _selectedVenueCategories.add(v);
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Additional Venue Categories (optional)',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Select all categories that also fit this venue to help it appear in more searches.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontSize: isPhone ? 11 : 12,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _venueTypeOptions.map((c) {
              final selected = _selectedVenueCategories.contains(c);
              return FilterChip(
                label: Text(c),
                selected: selected,
                showCheckmark: false,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.8)
                        : theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedVenueCategories.add(c);
                    } else {
                      _selectedVenueCategories.remove(c);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Event Types Allowed',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _eventTypeOptions.map((e) {
              final selected = _selectedEventTypes.contains(e);
              return FilterChip(
                label: Text(e),
                selected: selected,
                showCheckmark: false,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.8)
                        : theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedEventTypes.add(e);
                    } else {
                      _selectedEventTypes.remove(e);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Availability Type',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _availabilityOptions.map((opt) {
              final selected = _availabilityType == opt;
              return ChoiceChip(
                label: Text(opt),
                selected: selected,
                showCheckmark: false,
                selectedColor: theme.colorScheme.secondary.withValues(alpha: 0.9),
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                onSelected: (v) {
                  if (!v) return;
                  setState(() => _availabilityType = opt);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _countryController,
                  label: 'Country',
                  keyboardType: TextInputType.text,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _stateController,
                  label: 'State',
                  keyboardType: TextInputType.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: 'City',
                  keyboardType: TextInputType.text,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'City is required'
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _areaController,
                  label: 'Area / Neighborhood',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressController,
            label: 'Complete Address',
            prefixIcon: Icons.location_on_outlined,
            validator: (v) => (v == null || v.isEmpty)
                ? 'Address is required'
                : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _landmarkController,
            label: 'Landmark',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _zipCodeController,
                  label: 'Pincode',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _mapLinkController,
                  label: 'Google Map Pin / Link',
                  keyboardType: TextInputType.url,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Parking Capacity Range',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _parkingRange,
            decoration: InputDecoration(
              labelText: 'Parking Capacity',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            items: _parkingRangeOptions
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _parkingRange = v);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Public Transport Nearby',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _publicTransportOptions.map((p) {
              final selected = _selectedPublicTransport.contains(p);
              return FilterChip(
                label: Text(p),
                selected: selected,
                showCheckmark: false,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.8)
                        : theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedPublicTransport.add(p);
                    } else {
                      _selectedPublicTransport.remove(p);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(2),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizeLayoutStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Size, Capacity & Layout',
            style: TextStyle(
              fontSize: isPhone ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _indoorAreaController,
                  label: 'Indoor Area (sq ft)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _outdoorAreaController,
                  label: 'Outdoor Area (sq ft)',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _floatingCapacityController,
                  label: 'Floating Capacity',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _seatingCapacityController,
                  label: 'Seating Capacity',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _maxGuestsController,
                  label: 'Maximum Guest Limit',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _eventSpacesController,
                  label: 'Number of Event Spaces',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _fireSafetyCompliant,
            onChanged: (v) => setState(() => _fireSafetyCompliant = v),
            title: const Text('Fire Safety Compliance (Yes/No)'),
          ),
          const SizedBox(height: 16),
          if (_isBanquetLike) ...[
            Text(
              'Banquet / Hall Layout',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _hallDimensionsController,
              label: 'Hall Dimensions',
              hint: 'e.g., 80 ft x 40 ft',
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _hallHeightController,
              label: 'Height Clearance (ft)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _stageIncluded,
              onChanged: (v) => setState(() => _stageIncluded = v),
              title: const Text('Stage Included'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _brideGroomRooms,
              onChanged: (v) => setState(() => _brideGroomRooms = v),
              title: const Text('Bride / Groom Rooms Available'),
            ),
            _buildTextField(
              controller: _mandapAreaController,
              label: 'Mandap Area',
              hint: 'e.g., 20 ft x 20 ft',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _baraatEntryAllowed,
              onChanged: (v) => setState(() => _baraatEntryAllowed = v),
              title: const Text('Baraat Entry Allowed'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _danceFloorAvailable,
              onChanged: (v) => setState(() => _danceFloorAvailable = v),
              title: const Text('Dance Floor Available'),
            ),
            _buildTextField(
              controller: _djVolumeLimitController,
              label: 'DJ Volume Limit / Timing Notes',
            ),
            const SizedBox(height: 16),
          ],
          if (_isOutdoorLike) ...[
            Text(
              'Outdoor Lawn / Garden',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _lawnSizeController,
              label: 'Lawn Size (sq ft)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _lawnSurfaceType,
              decoration: InputDecoration(
                labelText: 'Surface Type',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              items: _lawnSurfaceOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _lawnSurfaceType = v);
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _weatherBackupSpace,
              onChanged: (v) => setState(() => _weatherBackupSpace = v),
              title: const Text('Weather Backup Indoor Space'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _tentPandalAllowed,
              onChanged: (v) => setState(() => _tentPandalAllowed = v),
              title: const Text('Tent / Pandal Allowed'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _lawnWaterPowerAccess,
              onChanged: (v) => setState(() => _lawnWaterPowerAccess = v),
              title: const Text('Water / Power Access Points Available'),
            ),
            _buildTextField(
              controller: _noiseCurfewController,
              label: 'Noise Curfew Time',
              hint: 'e.g., 10:00 PM',
            ),
            const SizedBox(height: 16),
          ],
          if (_isAuditoriumLike) ...[
            Text(
              'Auditorium / Theatre',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _fixedSeatingCountController,
              label: 'Fixed Seating Count',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _auditoriumStageSizeController,
              label: 'Stage Size',
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _backstageRoomsController,
              label: 'Backstage Rooms',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _soundSystemSpecsController,
              label: 'Sound System Specs',
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _lightingRigSpecsController,
              label: 'Lighting Rig Specs',
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _greenRoomsController,
              label: 'Green Rooms',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _acousticRatingController,
              label: 'Acoustic Rating',
            ),
            const SizedBox(height: 16),
          ],
          if (_isConferenceLike) ...[
            Text(
              'Conference / Meeting Room',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _boardroomCapacityController,
              label: 'Boardroom Capacity',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _tableLayoutOptionsController,
              label: 'Table Layout Options',
              hint: 'e.g., U-shape, Classroom, Theatre',
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _hasTvProjector,
              onChanged: (v) => setState(() => _hasTvProjector = v),
              title: const Text('TV / Projector Available'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _hasWhiteboard,
              onChanged: (v) => setState(() => _hasWhiteboard = v),
              title: const Text('Whiteboard / Flipchart'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _hasConferencePhone,
              onChanged: (v) => setState(() => _hasConferencePhone = v),
              title: const Text('Conference Phone'),
            ),
            _buildTextField(
              controller: _wifiSpeedRatingController,
              label: 'Wi-Fi Speed Rating',
              hint: 'e.g., 100 Mbps+',
            ),
            const SizedBox(height: 16),
          ],
          if (_isResortLike) ...[
            Text(
              'Resort / Farmhouse / Villa',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _ballroomSizeController,
              label: 'Ballroom Size (sq ft)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _poolsideAreaController,
              label: 'Poolside Area (sq ft)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _outdoorStageOptionsController,
              label: 'Outdoor Stage Options',
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _villaSizeController,
              label: 'Total Villa Size (sq ft)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _villaBedroomsController,
              label: 'Bedrooms Included',
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _villaPoolAccess,
              onChanged: (v) => setState(() => _villaPoolAccess = v),
              title: const Text('Pool Access Included'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _villaMusicAllowed,
              onChanged: (v) => setState(() => _villaMusicAllowed = v),
              title: const Text('Music Allowed (Outdoor / Late Night)'),
            ),
            _buildTextField(
              controller: _stayEventPackagesController,
              label: 'Stay + Event Packages',
              hint: 'Summary of package options',
              maxLines: 2,
            ),
            _buildTextField(
              controller: _maxOvernightGuestsController,
              label: 'Maximum Overnight Guests',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Text(
              'Room Types & Pricing',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._roomTypes.asMap().entries.map((entry) {
              final index = entry.key;
              final room = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: room.name,
                            decoration: InputDecoration(
                              labelText: 'Room Type',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                            onChanged: (v) => room.name = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: room.rooms,
                            decoration: InputDecoration(
                              labelText: 'Rooms',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => room.rooms = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: room.pricePerNight,
                            decoration: InputDecoration(
                              labelText: 'Price / Night',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => room.pricePerNight = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: room.mealPlan,
                            decoration: InputDecoration(
                              labelText: 'Meal Plan',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                            onChanged: (v) => room.mealPlan = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: room.extraBedCharges,
                            decoration: InputDecoration(
                              labelText: 'Extra Bed Charges',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => room.extraBedCharges = v,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _roomTypes.removeAt(index);
                            });
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Assign Photos',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 64,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (ctx, photoIndex) {
                            final isSelectedForRoom =
                                room.photoIndices.contains(photoIndex);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelectedForRoom) {
                                    room.photoIndices.remove(photoIndex);
                                  } else {
                                    room.photoIndices.add(photoIndex);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelectedForRoom
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline
                                            .withValues(alpha: 0.4),
                                    width: isSelectedForRoom ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_selectedImages[photoIndex].path),
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    if (isSelectedForRoom)
                                      Positioned(
                                        right: 2,
                                        top: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _roomTypes.add(_VenueRoomType());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Room Type'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isStudioLike) ...[
            Text(
              'Studio Details',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _studioType,
              decoration: InputDecoration(
                labelText: 'Studio Type',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              items: _studioTypeOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _studioType = v);
              },
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _studioCeilingHeightController,
              label: 'Ceiling Height (ft)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _studioCycloramaWall,
              onChanged: (v) => setState(() => _studioCycloramaWall = v),
              title: const Text('Cyclorama Wall'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _studioLightingIncluded,
              onChanged: (v) => setState(() => _studioLightingIncluded = v),
              title: const Text('Lighting Equipment Included'),
            ),
            _buildTextField(
              controller: _soundproofRatingController,
              label: 'Soundproofing Rating',
            ),
            _buildTextField(
              controller: _studioPropsController,
              label: 'Props Available',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
          ],
          if (_isExhibitionLike) ...[
            Text(
              'Exhibition Hall',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _exhibitionCarpetAreaController,
              label: 'Carpet Area (sq ft)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _maxBoothCapacityController,
              label: 'Max Booth Capacity',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _powerLoadController,
              label: 'Power Load (kW)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _loadingAccess,
              onChanged: (v) => setState(() => _loadingAccess = v),
              title: const Text('Loading / Unloading Access'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _storageAvailable,
              onChanged: (v) => setState(() => _storageAvailable = v),
              title: const Text('Warehouse / Storage Available'),
            ),
            const SizedBox(height: 16),
          ],
          if (_isClubLike) ...[
            Text(
              'Club / Lounge / Rooftop',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _indoorSeatingController,
                    label: 'Indoor Seating',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _outdoorSeatingController,
                    label: 'Outdoor Seating',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _soundLimitController,
              label: 'Sound Limit / Restrictions',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _alcoholServiceAllowed,
              onChanged: (v) => setState(() => _alcoholServiceAllowed = v),
              title: const Text('Alcohol Service Allowed'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _barSetupIncluded,
              onChanged: (v) => setState(() => _barSetupIncluded = v),
              title: const Text('Bar Setup Included'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _liveMusicLicense,
              onChanged: (v) => setState(() => _liveMusicLicense = v),
              title: const Text('Live Music License'),
            ),
            const SizedBox(height: 16),
          ],
          _buildTextField(
            controller: _layoutNotesController,
            label: 'Layout / Stage / Rooms Notes',
            hint: 'Stage, lawn size, rooms, pool, etc.',
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(3),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesFoodStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities, Food & Vendors',
            style: TextStyle(
              fontSize: isPhone ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'General Amenities',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _amenityOptions.map((a) {
              final selected = _selectedAmenities.contains(a);
              return FilterChip(
                label: Text(a),
                selected: selected,
                showCheckmark: false,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.8)
                        : theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedAmenities.add(a);
                    } else {
                      _selectedAmenities.remove(a);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _generatorCapacityController,
            label: 'Generator Capacity (kVA)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Text(
            'Food & Beverage Options',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _inHouseCateringRequirement,
            decoration: InputDecoration(
              labelText: 'In-house Catering',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            items: _inHouseCateringOptions
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _inHouseCateringRequirement = v);
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _outsideCateringAllowed,
            onChanged: (v) => setState(() => _outsideCateringAllowed = v),
            title: const Text('Outside Catering Allowed'),
          ),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _vegAvailable,
                  onChanged: (v) => setState(() => _vegAvailable = v),
                  title: const Text('Veg Packages'),
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _nonVegAvailable,
                  onChanged: (v) => setState(() => _nonVegAvailable = v),
                  title: const Text('Non-Veg Packages'),
                ),
              ),
            ],
          ),
          _buildTextField(
            controller: _perPlatePriceController,
            label: 'Starting Per Plate Price (₹)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _buffetAvailable,
                  onChanged: (v) => setState(() => _buffetAvailable = v),
                  title: const Text('Buffet Available'),
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _liveCountersAvailable,
                  onChanged: (v) => setState(() => _liveCountersAvailable = v),
                  title: const Text('Live Counters'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Alcohol & Vendor Policies',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _alcoholPolicy,
            decoration: InputDecoration(
              labelText: 'Alcohol Policy',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            items: _alcoholPolicyOptions
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _alcoholPolicy = v);
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _decoratorsAllowedOutside,
            onChanged: (v) => setState(() => _decoratorsAllowedOutside = v),
            title: const Text('External Decorators Allowed'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _djAllowed,
            onChanged: (v) => setState(() => _djAllowed = v),
            title: const Text('External DJ Allowed'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _photographerAllowed,
            onChanged: (v) => setState(() => _photographerAllowed = v),
            title: const Text('External Photographer Allowed'),
          ),
          _buildTextField(
            controller: _cleaningChargesController,
            label: 'Cleaning Charges (₹)',
            keyboardType: TextInputType.number,
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

  Widget _buildPricingRulesStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing & Booking Rules',
            style: TextStyle(
              fontSize: isPhone ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pricing Models',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pricingModelOptions.map((p) {
              final selected = _selectedPricingModels.contains(p);
              return FilterChip(
                label: Text(p),
                selected: selected,
                showCheckmark: false,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.8)
                        : theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedPricingModels.add(p);
                    } else {
                      _selectedPricingModels.remove(p);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Core Charges',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _venueRentalPriceController,
            label: 'Venue Rental Price (₹)',
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Price is required';
              final n = double.tryParse(v.trim());
              if (n == null || n <= 0) return 'Enter a valid amount';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _securityDepositController,
                  label: 'Refundable Security Deposit (₹)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _serviceChargeController,
                  label: 'Mandatory Service Charges (₹)',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _overtimeChargeController,
                  label: 'Overtime Charge (₹ / hour)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _minimumHoursController,
                  label: 'Minimum Booking Hours',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _minimumHoursPresetOptions.map((h) {
              return ChoiceChip(
                label: Text('$h hrs'),
                selected: _minimumHoursController.text.trim() == h,
                showCheckmark: false,
                selectedColor: theme.colorScheme.secondary.withValues(alpha: 0.9),
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                onSelected: (v) {
                  setState(() {
                    _minimumHoursController.text = h;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Restrictions & Policies',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _curfewTimeController,
            label: 'Curfew Time',
            hint: 'e.g., 11:00 PM',
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _curfewTimePresetOptions.map((opt) {
              return ChoiceChip(
                label: Text(opt),
                selected: _curfewTimeController.text.trim() == opt,
                showCheckmark: false,
                selectedColor: theme.colorScheme.secondary.withValues(alpha: 0.9),
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                onSelected: (v) {
                  setState(() {
                    _curfewTimeController.text = opt;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _noiseRestrictionsController,
            label: 'Noise Restrictions',
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _cancellationPolicy,
            decoration: InputDecoration(
              labelText: 'Cancellation Policy',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            items: _cancellationPolicyOptions
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _cancellationPolicy = v);
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _reschedulingAllowed,
            onChanged: (v) => setState(() => _reschedulingAllowed = v),
            title: const Text('Rescheduling Allowed'),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(3),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(5),
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
            'Upload clear photos of hall, lawn, stage, rooms and setup examples.',
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
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
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
            'Owner / Manager Contact',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _contactPersonController,
            label: 'Full Name',
            prefixIcon: Icons.person_outline,
            validator: (v) => (v == null || v.isEmpty)
                ? 'Contact name is required'
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _phoneController,
                  label: 'Phone*',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.call,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Phone is required'
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _whatsappController,
                  label: 'WhatsApp',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.chat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _contactRoleController,
            label: 'Role (Owner / Manager / Sales)',
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _contactRoleOptions.map((role) {
              return ChoiceChip(
                label: Text(role),
                selected: _contactRoleController.text.trim() == role,
                showCheckmark: false,
                selectedColor: theme.colorScheme.secondary.withValues(alpha: 0.9),
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                onSelected: (v) {
                  setState(() {
                    _contactRoleController.text = role;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _businessNameController,
            label: 'Business / Brand Name',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _websiteController,
            label: 'Website',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _socialLinksController,
            label: 'Social Media Links',
            hint: 'Instagram, Facebook, Google Maps profile, etc.',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _menuLinkController,
            label: 'Menu / Brochure Link (optional)',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _tabController.animateTo(4),
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
                        ? 'Publishing Venue Listing...'
                        : 'Publish Venue Listing',
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
            'Create Venue Listing',
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
                Tab(text: 'Size & Layout'),
                Tab(text: 'Amenities & Food'),
                Tab(text: 'Pricing & Rules'),
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
                  _buildSizeLayoutStep(),
                  _buildAmenitiesFoodStep(),
                  _buildPricingRulesStep(),
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
