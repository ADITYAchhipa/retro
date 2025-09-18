import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import 'country_list_item.dart';

/// List view widget for displaying filtered countries
class CountryListView extends StatelessWidget {
  const CountryListView({
    super.key,
    required this.countries,
    required this.selectedCountry,
    required this.isDesktop,
    required this.onCountrySelected,
  });

  final List<Map<String, dynamic>> countries;
  final String? selectedCountry;
  final bool isDesktop;
  final ValueChanged<String> onCountrySelected;

  /// Get responsive height based on screen size and orientation
  double _getResponsiveHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    
    // Tablet landscape
    if (screenWidth > 768 && orientation == Orientation.landscape) {
      return screenHeight * 0.47; // slightly reduced
    }
    // Desktop
    else if (isDesktop) {
      return screenHeight * 0.42; // slightly reduced
    }
    // Mobile landscape
    else if (orientation == Orientation.landscape) {
      return screenHeight * 0.47; // slightly reduced
    }
    // Mobile portrait (default) - increased height for better visibility
    else {
      return screenHeight * 0.40; // slightly reduced
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isDesktop 
            ? AppConstants.maxContentWidth 
            : AppConstants.maxContentWidthMobile,
      ),
      height: _getResponsiveHeight(context),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: isDark ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF161B22).withOpacity(0.9), // Modern glass surface
            const Color(0xFF21262D).withOpacity(0.95), // Elevated glass
            const Color(0xFF30363D), // Solid accent
          ],
          stops: const [0.0, 0.6, 1.0],
        ) : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusXXL),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF58A6FF).withOpacity(0.2)
              : theme.colorScheme.primary.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? const Color(0xFF000000).withOpacity(0.5)
                : theme.colorScheme.primary.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          if (isDark) BoxShadow(
            color: const Color(0xFF58A6FF).withOpacity(0.1),
            blurRadius: 50,
            offset: const Offset(0, 25),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusXXL),
        child: ListView.builder(
          padding: EdgeInsets.all(
            isDesktop ? AppConstants.spacingL : AppConstants.spacingM,
          ),
          itemCount: countries.length,
          itemBuilder: (context, index) {
            final country = countries[index];
            final isSelected = selectedCountry == country['name'];
            
            return CountryListItem(
              country: country,
              isSelected: isSelected,
              isDesktop: isDesktop,
              onTap: () => onCountrySelected(country['name']!),
            );
          },
        ),
      ),
    );
  }
}
