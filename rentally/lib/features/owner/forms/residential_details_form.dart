import 'package:flutter/material.dart';

/// Modern Residential Details Form with Multi-Step Wizard
/// Features: Grouped sections, chip selectors, animations, progress indicators
class ResidentialDetailsForm extends StatefulWidget {
  final String propertyType;

  // Furnishing
  final String furnishing;
  final List<String> furnishingOptions;
  final ValueChanged<String> onFurnishingChanged;

  // Apartment configuration
  final String apartmentBhk;
  final List<String> bhkOptions;
  final ValueChanged<String> onApartmentBhkChanged;

  // Beds/Baths
  final int bedrooms;
  final ValueChanged<int> onBedroomsChanged;
  final int bathrooms;
  final ValueChanged<int> onBathroomsChanged;

  // Room-specific
  final String roomBathroomType;
  final List<String> roomBathroomOptions;
  final ValueChanged<String> onRoomBathroomTypeChanged;

  // Controllers
  final TextEditingController studioSizeController;
  final TextEditingController floorController;
  final TextEditingController totalFloorsController;
  final TextEditingController plotAreaController;
  final TextEditingController parkingSpacesController;
  final TextEditingController hoaFeeController;
  final TextEditingController carpetAreaController;
  final TextEditingController terraceAreaController;

  // PG/Hostel
  final TextEditingController pgOccupancyController;
  final String pgGender;
  final List<String> pgGenderOptions;
  final ValueChanged<String> onPgGenderChanged;
  final String pgMeals;
  final List<String> pgMealsOptions;
  final ValueChanged<String> onPgMealsChanged;
  final bool pgAttachedBathroom;
  final ValueChanged<bool> onPgAttachedBathroomChanged;

  const ResidentialDetailsForm({
    super.key,
    required this.propertyType,
    required this.furnishing,
    required this.furnishingOptions,
    required this.onFurnishingChanged,
    required this.apartmentBhk,
    required this.bhkOptions,
    required this.onApartmentBhkChanged,
    required this.bedrooms,
    required this.onBedroomsChanged,
    required this.bathrooms,
    required this.onBathroomsChanged,
    required this.roomBathroomType,
    required this.roomBathroomOptions,
    required this.onRoomBathroomTypeChanged,
    required this.studioSizeController,
    required this.floorController,
    required this.totalFloorsController,
    required this.plotAreaController,
    required this.parkingSpacesController,
    required this.hoaFeeController,
    required this.carpetAreaController,
    required this.terraceAreaController,
    required this.pgOccupancyController,
    required this.pgGender,
    required this.pgGenderOptions,
    required this.onPgGenderChanged,
    required this.pgMeals,
    required this.pgMealsOptions,
    required this.onPgMealsChanged,
    required this.pgAttachedBathroom,
    required this.onPgAttachedBathroomChanged,
  });

  @override
  State<ResidentialDetailsForm> createState() => _ResidentialDetailsFormState();
}

class _ResidentialDetailsFormState extends State<ResidentialDetailsForm> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool get _isApartment => widget.propertyType == 'apartment';
  bool get _isCondo => widget.propertyType == 'condo';
  bool get _isTownhouse => widget.propertyType == 'townhouse';
  bool get _isDuplex => widget.propertyType == 'duplex';
  bool get _isPenthouse => widget.propertyType == 'penthouse';
  bool get _isBungalow => widget.propertyType == 'bungalow';
  bool get _isHouse => widget.propertyType == 'house';
  bool get _isVilla => widget.propertyType == 'villa';
  bool get _isStudio => widget.propertyType == 'studio';
  bool get _isRoom => widget.propertyType == 'room';
  bool get _isPG => widget.propertyType == 'pg' || widget.propertyType == 'hostel';

  List<_WizardStep> get _steps {
    final steps = <_WizardStep>[];
    
    // Step 1: Configuration (always shown)
    steps.add(_WizardStep(
      title: 'Configuration',
      subtitle: 'Set up your property basics',
      icon: Icons.settings_rounded,
      builder: _buildConfigurationStep,
    ));

    // Step 2: Size & Dimensions
    if (!_isRoom) {
      steps.add(_WizardStep(
        title: 'Size & Dimensions',
        subtitle: 'Property measurements',
        icon: Icons.square_foot_rounded,
        builder: _buildDimensionsStep,
      ));
    }

    // Step 3: Building Info (for apartments/condos)
    if (_isApartment || _isCondo || _isTownhouse || _isDuplex || _isPenthouse) {
      steps.add(_WizardStep(
        title: 'Building Info',
        subtitle: 'Floor and building details',
        icon: Icons.apartment_rounded,
        builder: _buildBuildingStep,
      ));
    }

    // Step 4: PG/Hostel specific
    if (_isPG) {
      steps.add(_WizardStep(
        title: 'PG Details',
        subtitle: 'Occupancy and preferences',
        icon: Icons.group_rounded,
        builder: _buildPGStep,
      ));
    }

    return steps;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _animController.reverse().then((_) {
        setState(() => _currentStep++);
        _animController.forward();
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _animController.reverse().then((_) {
        setState(() => _currentStep--);
        _animController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final steps = _steps;

    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(theme, isDark, steps),
        const SizedBox(height: 20),
        
        // Step content
        FadeTransition(
          opacity: _fadeAnim,
          child: steps[_currentStep].builder(),
        ),
        
        const SizedBox(height: 24),
        
        // Navigation buttons
        _buildNavigationButtons(theme, steps),
      ],
    );
  }

  Widget _buildProgressIndicator(ThemeData theme, bool isDark, List<_WizardStep> steps) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.08),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Step indicators
          Row(
            children: List.generate(steps.length, (index) {
              final isActive = index == _currentStep;
              final isComplete = index < _currentStep;
              
              return Expanded(
                child: Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: isComplete || isActive
                                ? LinearGradient(colors: [theme.primaryColor, theme.colorScheme.secondary])
                                : null,
                            color: isComplete || isActive ? null : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: () {
                        if (index < _currentStep) {
                          _animController.reverse().then((_) {
                            setState(() => _currentStep = index);
                            _animController.forward();
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isActive ? 44 : 36,
                        height: isActive ? 44 : 36,
                        decoration: BoxDecoration(
                          gradient: isActive || isComplete
                              ? LinearGradient(
                                  colors: [theme.primaryColor, theme.colorScheme.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isActive || isComplete ? null : Colors.grey.shade200,
                          shape: BoxShape.circle,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: theme.primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isComplete ? Icons.check_rounded : steps[index].icon,
                          size: isActive ? 22 : 18,
                          color: isActive || isComplete ? Colors.white : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Current step info
          Text(
            steps[_currentStep].title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryColor,
            ),
          ),
          Text(
            steps[_currentStep].subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme, List<_WizardStep> steps) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: theme.primaryColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: _currentStep == 0 ? 1 : 1,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, theme.colorScheme.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _currentStep < steps.length - 1 ? _nextStep : null,
              icon: Icon(
                _currentStep < steps.length - 1 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                size: 18,
              ),
              label: Text(_currentStep < steps.length - 1 ? 'Continue' : 'Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Step 1: Configuration
  Widget _buildConfigurationStep() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Furnishing section
        _buildSectionCard(
          theme: theme,
          icon: Icons.chair_rounded,
          title: 'Furnishing Status',
          subtitle: 'What\'s included with the property?',
          child: _buildChipSelector(
            options: widget.furnishingOptions,
            selected: widget.furnishing,
            onSelected: widget.onFurnishingChanged,
            icons: {
              'fully_furnished': Icons.weekend_rounded,
              'semi_furnished': Icons.chair_alt_rounded,
              'unfurnished': Icons.crop_square_rounded,
            },
          ),
        ),
        const SizedBox(height: 16),

        // BHK / Bedrooms
        if (_isApartment)
          _buildSectionCard(
            theme: theme,
            icon: Icons.home_rounded,
            title: 'Configuration',
            subtitle: 'Select apartment type',
            child: _buildChipSelector(
              options: widget.bhkOptions,
              selected: widget.apartmentBhk,
              onSelected: widget.onApartmentBhkChanged,
            ),
          )
        else if (!_isStudio && !_isPG && !_isRoom)
          _buildSectionCard(
            theme: theme,
            icon: Icons.bed_rounded,
            title: 'Bedrooms',
            subtitle: 'Number of bedrooms',
            child: _buildNumberStepper(
              value: widget.bedrooms,
              min: 1,
              max: 10,
              onChanged: widget.onBedroomsChanged,
            ),
          ),

        if (!_isRoom && !_isPG && !_isStudio) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            theme: theme,
            icon: Icons.bathtub_rounded,
            title: 'Bathrooms',
            subtitle: 'Number of bathrooms',
            child: _buildNumberStepper(
              value: widget.bathrooms,
              min: 1,
              max: 6,
              onChanged: widget.onBathroomsChanged,
            ),
          ),
        ],

        // Room bathroom type
        if (_isRoom) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            theme: theme,
            icon: Icons.bathroom_rounded,
            title: 'Bathroom Type',
            subtitle: 'Bathroom arrangement',
            child: _buildChipSelector(
              options: widget.roomBathroomOptions,
              selected: widget.roomBathroomType,
              onSelected: widget.onRoomBathroomTypeChanged,
            ),
          ),
        ],
      ],
    );
  }

  // Step 2: Size & Dimensions
  Widget _buildDimensionsStep() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        if (_isStudio)
          _buildSectionCard(
            theme: theme,
            icon: Icons.square_foot_rounded,
            title: 'Studio Size',
            subtitle: 'Total area of your studio',
            child: _buildModernTextField(
              controller: widget.studioSizeController,
              label: 'Size in sq ft',
              icon: Icons.straighten_rounded,
              keyboardType: TextInputType.number,
            ),
          ),

        if (_isApartment || _isCondo || _isTownhouse || _isDuplex || _isPenthouse) ...[
          _buildSectionCard(
            theme: theme,
            icon: Icons.crop_square_rounded,
            title: 'Carpet Area',
            subtitle: 'Usable floor area',
            child: _buildModernTextField(
              controller: widget.carpetAreaController,
              label: 'Carpet area in sq ft',
              icon: Icons.straighten_rounded,
              keyboardType: TextInputType.number,
            ),
          ),
        ],

        if (_isHouse || _isVilla || _isBungalow) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            theme: theme,
            icon: Icons.landscape_rounded,
            title: 'Plot Area',
            subtitle: 'Total land area',
            child: _buildModernTextField(
              controller: widget.plotAreaController,
              label: 'Plot area in sq ft',
              icon: Icons.straighten_rounded,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            theme: theme,
            icon: Icons.local_parking_rounded,
            title: 'Parking',
            subtitle: 'Available parking spaces',
            child: _buildModernTextField(
              controller: widget.parkingSpacesController,
              label: 'Number of parking spaces',
              icon: Icons.directions_car_rounded,
              keyboardType: TextInputType.number,
            ),
          ),
        ],

        if (_isPenthouse) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            theme: theme,
            icon: Icons.deck_rounded,
            title: 'Terrace Area',
            subtitle: 'Private terrace space',
            child: _buildModernTextField(
              controller: widget.terraceAreaController,
              label: 'Terrace area in sq ft',
              icon: Icons.straighten_rounded,
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ],
    );
  }

  // Step 3: Building Info
  Widget _buildBuildingStep() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        _buildSectionCard(
          theme: theme,
          icon: Icons.stairs_rounded,
          title: 'Floor Details',
          subtitle: 'Which floor is your property?',
          child: Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  controller: widget.floorController,
                  label: 'Floor No.',
                  icon: Icons.arrow_upward_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernTextField(
                  controller: widget.totalFloorsController,
                  label: 'Total Floors',
                  icon: Icons.apartment_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ),

        if (_isCondo) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            theme: theme,
            icon: Icons.payments_rounded,
            title: 'HOA / Maintenance',
            subtitle: 'Monthly maintenance charges',
            child: _buildModernTextField(
              controller: widget.hoaFeeController,
              label: 'Monthly fee (₹)',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ],
    );
  }

  // Step 4: PG/Hostel
  Widget _buildPGStep() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        _buildSectionCard(
          theme: theme,
          icon: Icons.group_rounded,
          title: 'Occupancy',
          subtitle: 'How many people per room?',
          child: _buildModernTextField(
            controller: widget.pgOccupancyController,
            label: 'Persons per room',
            icon: Icons.people_rounded,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          theme: theme,
          icon: Icons.wc_rounded,
          title: 'Gender Preference',
          subtitle: 'Who can stay here?',
          child: _buildChipSelector(
            options: widget.pgGenderOptions,
            selected: widget.pgGender,
            onSelected: widget.onPgGenderChanged,
            icons: {
              'Male': Icons.male_rounded,
              'Female': Icons.female_rounded,
              'Any': Icons.people_rounded,
            },
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          theme: theme,
          icon: Icons.restaurant_rounded,
          title: 'Meal Preference',
          subtitle: 'Food arrangements',
          child: _buildChipSelector(
            options: widget.pgMealsOptions,
            selected: widget.pgMeals,
            onSelected: widget.onPgMealsChanged,
            icons: {
              'With Meals': Icons.restaurant_menu_rounded,
              'Without Meals': Icons.no_meals_rounded,
              'Optional': Icons.restaurant_rounded,
            },
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          theme: theme,
          icon: Icons.bathroom_rounded,
          title: 'Bathroom',
          subtitle: 'Bathroom arrangement',
          child: _buildAnimatedToggle(
            value: widget.pgAttachedBathroom,
            onChanged: widget.onPgAttachedBathroomChanged,
            label: 'Attached Bathroom',
            activeLabel: 'Attached',
            inactiveLabel: 'Shared',
          ),
        ),
      ],
    );
  }

  // Helper: Section Card
  Widget _buildSectionCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
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
                      theme.primaryColor.withValues(alpha: 0.15),
                      theme.colorScheme.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: theme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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

  // Helper: Chip Selector
  Widget _buildChipSelector({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
    Map<String, IconData>? icons,
  }) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: options.asMap().entries.map((entry) {
          final option = entry.value;
          final isSelected = option == selected;
          final icon = icons?[option];
          
          return Padding(
            padding: EdgeInsets.only(right: entry.key < options.length - 1 ? 10 : 0),
            child: GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [theme.primaryColor, theme.colorScheme.secondary],
                        )
                      : null,
                  color: isSelected ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey.shade600),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Helper: Number Stepper
  Widget _buildNumberStepper({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepperButton(
          icon: Icons.remove_rounded,
          onTap: value > min ? () => onChanged(value - 1) : null,
          theme: theme,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor.withValues(alpha: 0.1), theme.colorScheme.secondary.withValues(alpha: 0.08)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryColor,
            ),
          ),
        ),
        _buildStepperButton(
          icon: Icons.add_rounded,
          onTap: value < max ? () => onChanged(value + 1) : null,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback? onTap,
    required ThemeData theme,
  }) {
    final enabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(colors: [theme.primaryColor, theme.colorScheme.secondary])
              : null,
          color: enabled ? null : Colors.grey.shade200,
          shape: BoxShape.circle,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey.shade400,
          size: 22,
        ),
      ),
    );
  }

  // Helper: Modern Text Field
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: theme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // Helper: Animated Toggle
  Widget _buildAnimatedToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String label,
    required String activeLabel,
    required String inactiveLabel,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: !value
                    ? LinearGradient(colors: [theme.primaryColor, theme.colorScheme.secondary])
                    : null,
                color: !value ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  inactiveLabel,
                  style: TextStyle(
                    color: !value ? Colors.white : Colors.grey.shade600,
                    fontWeight: !value ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: value
                    ? LinearGradient(colors: [theme.primaryColor, theme.colorScheme.secondary])
                    : null,
                color: value ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  activeLabel,
                  style: TextStyle(
                    color: value ? Colors.white : Colors.grey.shade600,
                    fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WizardStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;

  _WizardStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });
}
