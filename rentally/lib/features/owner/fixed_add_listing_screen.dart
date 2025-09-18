import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
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

  late TabController _tabController;
  String _selectedPropertyType = 'apartment';
  int _bedrooms = 1;
  int _bathrooms = 1;
  String _furnishing = 'Select';
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

  final List<String> _propertyTypes = [
    'apartment',
    'house',
    'villa',
    'studio',
    'townhouse',
    'condo',
  ];

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

      // Create listing
      final listing = Listing(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
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

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Listing created successfully!');
        context.pop();
      }
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

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'List Your Property',
          style: (theme.textTheme.titleLarge ?? theme.textTheme.titleMedium)?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            height: 1.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
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
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Step Navigation - Centered
          Container(
            color: theme.colorScheme.surface,
            child: Center(
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 2.0,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                labelStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: theme.textTheme.labelMedium,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 2),
                tabs: const [
                  Tab(icon: Icon(Icons.home), text: 'Basics'),
                  Tab(icon: Icon(Icons.info), text: 'Details'),
                  Tab(icon: Icon(Icons.star), text: 'Amenities'),
                  Tab(icon: Icon(Icons.photo), text: 'Photos'),
                  Tab(icon: Icon(Icons.person), text: 'Contact'),
                ],
              ),
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

  Widget _buildBasicsStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final bottomPad = (isPhone ? 56.0 : 72.0) + MediaQuery.of(context).padding.bottom + 12.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Basics',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Property Title',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedPropertyType,
            decoration: InputDecoration(
              labelText: 'Property Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            isExpanded: true,
            selectedItemBuilder: (context) => _propertyTypes
                .map((type) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        type.substring(0, 1).toUpperCase() + type.substring(1),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            items: _propertyTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.substring(0, 1).toUpperCase() + type.substring(1)),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedPropertyType = value!),
          ),
          const SizedBox(height: 16),
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
              alignment: WrapAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next: Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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

  Widget _buildDetailsStep() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final bottomPad = (isPhone ? 56.0 : 72.0) + MediaQuery.of(context).padding.bottom + 12.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Details',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, cons) {
            final isXS = cons.maxWidth < 360;
            if (isXS) {
              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _furnishing,
                    decoration: InputDecoration(
                      labelText: 'Furnishing',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    isExpanded: true,
                    selectedItemBuilder: (context) => _furnishingOptions
                        .map((o) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(o, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    items: _furnishingOptions.map((option) {
                      return DropdownMenuItem(value: option, child: Text(option));
                    }).toList(),
                    onChanged: (value) => setState(() => _furnishing = value!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _bedrooms,
                    decoration: InputDecoration(
                      labelText: 'Bedrooms',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    isExpanded: true,
                    items: List.generate(6, (index) => index + 1).map((number) {
                      return DropdownMenuItem(value: number, child: Text('$number'));
                    }).toList(),
                    onChanged: (value) => setState(() => _bedrooms = value!),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _furnishing,
                    decoration: InputDecoration(
                      labelText: 'Furnishing',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    isExpanded: true,
                    selectedItemBuilder: (context) => _furnishingOptions
                        .map((o) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(o, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    items: _furnishingOptions.map((option) {
                      return DropdownMenuItem(value: option, child: Text(option));
                    }).toList(),
                    onChanged: (value) => setState(() => _furnishing = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _bedrooms,
                    decoration: InputDecoration(
                      labelText: 'Bedrooms',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    isExpanded: true,
                    items: List.generate(6, (index) => index + 1).map((number) {
                      return DropdownMenuItem(value: number, child: Text('$number'));
                    }).toList(),
                    onChanged: (value) => setState(() => _bedrooms = value!),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, cons) {
            final isXS = cons.maxWidth < 360;
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
          Text('Location Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: const Icon(Icons.location_on),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Address is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nearLandmarkController,
            decoration: InputDecoration(
              labelText: 'Near Landmark',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, cons) {
            final isXS = cons.maxWidth < 360;
            if (isXS) {
              return Column(children: [
                DropdownButtonFormField<String>(
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
                child: DropdownButtonFormField<String>(
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
              ),
            ]);
          }),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pincodeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Pincode',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
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
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 8),
                      Text('Back', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
    final bottomPad = (isPhone ? 56.0 : 72.0) + MediaQuery.of(context).padding.bottom + 12.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities & Features',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all amenities that apply to your property. This helps tenants find what they\'re looking for.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          Text('Property Amenities', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableAmenities.map((amenity) {
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
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text('Nearby Facilities', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
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
          const SizedBox(height: 12),
          Text('Rental Terms', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, cons) {
            final isXS = cons.maxWidth < 360;
            if (isXS) {
              return Column(children: [
                TextFormField(
                  controller: _monthlyRentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monthly Rent*',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixText: '₹ ',
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Price is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _securityDepositController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Security Deposit',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixText: '₹ ',
                  ),
                ),
              ]);
            }
            return Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _monthlyRentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monthly Rent*',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixText: '₹ ',
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Price is required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _securityDepositController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Security Deposit',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixText: '₹ ',
                  ),
                ),
              ),
            ]);
          }),
          const SizedBox(height: 12),
          Text('Charges Included in Rent', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
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
          const SizedBox(height: 12),
          TextFormField(
            controller: _otherAmenitiesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Other Amenities or Features',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              hintText: 'Mention any other amenities or special features...',
            ),
          ),
          const SizedBox(height: 12),
          Text('Tenant Preferences', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Pets Allowed'),
            subtitle: const Text('Allow tenants to keep pets in the property'),
            value: _petsAllowed,
            onChanged: (value) => setState(() => _petsAllowed = value),
          ),
          const SizedBox(height: 16),
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
    final crossAxisCount = width < 600 ? 2 : 3;
    final isPhone = width < 600;
    final bottomPad = (isPhone ? 56.0 : 72.0) + MediaQuery.of(context).padding.bottom + 12.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Photos',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload Photos (Min 3, Max 10)*',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          
          // Photo Upload Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload, size: 36, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                  'Drag & drop photos here',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'or click to browse (JPEG, PNG, max 5MB each)',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('+ Select Photos'),
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
            const SizedBox(height: 16),
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
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'or click to browse (MP4, max 50MB)',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
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
                    Icon(Icons.lightbulb_outline, size: 16, color: Colors.grey),
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
          const SizedBox(height: 16),
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
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _contactPersonController,
                  decoration: InputDecoration(
                    labelText: 'Contact Person Name*',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number*',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Phone number is required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          Text(
            'Preferred Contact Method*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
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
                      Text('Back', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                            Text('Submit Listing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
