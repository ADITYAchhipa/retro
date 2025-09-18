import '../services/location_service.dart';

/// Service class for managing country data and operations
class CountryService {
  CountryService._();
  
  /// List of supported countries with their details
  static const List<Map<String, dynamic>> _countries = [
    {'name': 'United States', 'code': 'US', 'currency': 'USD', 'alias': 'USA', 'color': 0xFF1E40AF},
    {'name': 'Canada', 'code': 'CA', 'currency': 'CAD', 'alias': 'CAN', 'color': 0xFF7C2D12},
    {'name': 'United Kingdom', 'code': 'GB', 'currency': 'GBP', 'alias': 'UK', 'color': 0xFF7C3AED},
    {'name': 'Germany', 'code': 'DE', 'currency': 'EUR', 'alias': 'GER', 'color': 0xFF059669},
    {'name': 'France', 'code': 'FR', 'currency': 'EUR', 'alias': 'FR', 'color': 0xFFDC2626},
    {'name': 'Australia', 'code': 'AU', 'currency': 'AUD', 'alias': 'AUS', 'color': 0xFFEA580C},
    {'name': 'Japan', 'code': 'JP', 'currency': 'JPY', 'alias': 'JPN', 'color': 0xFFDB2777},
    {'name': 'India', 'code': 'IN', 'currency': 'INR', 'alias': 'IND', 'color': 0xFF0891B2},
    {'name': 'Brazil', 'code': 'BR', 'currency': 'BRL', 'alias': 'BRA', 'color': 0xFF65A30D},
    {'name': 'Mexico', 'code': 'MX', 'currency': 'MXN', 'alias': 'MEX', 'color': 0xFFBE185D},
  ];
  
  /// Returns all available countries
  static List<Map<String, dynamic>> getAllCountries() {
    return List.from(_countries);
  }
  
  /// Filters countries based on search query
  /// Searches both country name and country code
  static List<Map<String, dynamic>> filterCountries(String query) {
    if (query.isEmpty) {
      return getAllCountries();
    }
    
    final lowercaseQuery = query.toLowerCase();
    return _countries.where((country) {
      final name = country['name']!.toLowerCase();
      final code = country['code']!.toLowerCase();
      return name.contains(lowercaseQuery) || code.contains(lowercaseQuery);
    }).toList();
  }
  
  /// Finds a country by name
  static Map<String, dynamic>? findCountryByName(String name) {
    try {
      return _countries.firstWhere(
        (country) => country['name'] == name,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Finds a country by code
  static Map<String, dynamic>? findCountryByCode(String code) {
    try {
      return _countries.firstWhere(
        (country) => country['code'] == code,
      );
    } catch (e) {
      return null;
    }
  }

  /// Gets currency for a country
  static String getCurrencyForCountry(String countryName) {
    final country = findCountryByName(countryName);
    return country?['currency'] ?? 'USD';
  }

  /// Maps location country names to app country names
  static String? mapLocationCountryToAppCountry(String locationCountry) {
    final countryMappings = {
      'United States': 'United States',
      'US': 'United States',
      'USA': 'United States',
      'Canada': 'Canada',
      'United Kingdom': 'United Kingdom',
      'UK': 'United Kingdom',
      'Britain': 'United Kingdom',
      'Germany': 'Germany',
      'France': 'France',
      'Australia': 'Australia',
      'Japan': 'Japan',
      'India': 'India',
      'Brazil': 'Brazil',
      'Mexico': 'Mexico',
    };
    
    return countryMappings[locationCountry];
  }

  /// Auto-detects country from location service
  static Future<String?> detectCountryFromLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      
      if (position != null) {
        final placemarks = await locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks != null && placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final locationCountry = placemark.country;
          
          if (locationCountry != null) {
            final mappedCountry = mapLocationCountryToAppCountry(locationCountry);
            return mappedCountry;
          }
        }
      }
      
      return null;
    } catch (e) {
      // Silent fail - location detection is optional
      return null;
    }
  }
}
