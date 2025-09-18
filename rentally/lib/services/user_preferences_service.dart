import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// User preferences model
class UserPreferences {
  final String language;
  final bool isDarkMode;
  final String currency;
  final Map<String, dynamic> searchFilters;
  final List<String> recentSearches;
  final Map<String, bool> notificationSettings;
  final String defaultLocation;
  final bool enableLocationServices;

  const UserPreferences({
    this.language = 'en',
    this.isDarkMode = false,
    this.currency = 'USD',
    this.searchFilters = const {},
    this.recentSearches = const [],
    this.notificationSettings = const {
      'bookingUpdates': true,
      'newMessages': true,
      'promotions': false,
      'reminders': true,
    },
    this.defaultLocation = '',
    this.enableLocationServices = true,
  });

  Map<String, dynamic> toJson() => {
    'language': language,
    'isDarkMode': isDarkMode,
    'currency': currency,
    'searchFilters': searchFilters,
    'recentSearches': recentSearches,
    'notificationSettings': notificationSettings,
    'defaultLocation': defaultLocation,
    'enableLocationServices': enableLocationServices,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
    language: json['language'] ?? 'en',
    isDarkMode: json['isDarkMode'] ?? false,
    currency: json['currency'] ?? 'USD',
    searchFilters: Map<String, dynamic>.from(json['searchFilters'] ?? {}),
    recentSearches: List<String>.from(json['recentSearches'] ?? []),
    notificationSettings: Map<String, bool>.from(json['notificationSettings'] ?? {
      'bookingUpdates': true,
      'newMessages': true,
      'promotions': false,
      'reminders': true,
    }),
    defaultLocation: json['defaultLocation'] ?? '',
    enableLocationServices: json['enableLocationServices'] ?? true,
  );

  UserPreferences copyWith({
    String? language,
    bool? isDarkMode,
    String? currency,
    Map<String, dynamic>? searchFilters,
    List<String>? recentSearches,
    Map<String, bool>? notificationSettings,
    String? defaultLocation,
    bool? enableLocationServices,
  }) => UserPreferences(
    language: language ?? this.language,
    isDarkMode: isDarkMode ?? this.isDarkMode,
    currency: currency ?? this.currency,
    searchFilters: searchFilters ?? this.searchFilters,
    recentSearches: recentSearches ?? this.recentSearches,
    notificationSettings: notificationSettings ?? this.notificationSettings,
    defaultLocation: defaultLocation ?? this.defaultLocation,
    enableLocationServices: enableLocationServices ?? this.enableLocationServices,
  );
}

// User preferences service
class UserPreferencesService extends StateNotifier<UserPreferences> {
  UserPreferencesService() : super(const UserPreferences()) {
    _loadPreferences();
  }

  static const String _preferencesKey = 'user_preferences';

  // Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_preferencesKey);
      
      if (preferencesJson != null) {
        final Map<String, dynamic> decoded = json.decode(preferencesJson);
        state = UserPreferences.fromJson(decoded);
      }
    } catch (e) {
      // Handle error silently, use default preferences
    }
  }

  // Save preferences to storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = json.encode(state.toJson());
      await prefs.setString(_preferencesKey, preferencesJson);
    } catch (e) {
      // Handle error silently
    }
  }

  // Public methods
  Future<void> updateLanguage(String language) async {
    state = state.copyWith(language: language);
    await _savePreferences();
  }

  Future<void> updateTheme(bool isDarkMode) async {
    state = state.copyWith(isDarkMode: isDarkMode);
    await _savePreferences();
  }

  Future<void> updateCurrency(String currency) async {
    state = state.copyWith(currency: currency);
    await _savePreferences();
  }

  Future<void> updateSearchFilters(Map<String, dynamic> filters) async {
    state = state.copyWith(searchFilters: filters);
    await _savePreferences();
  }

  Future<void> addRecentSearch(String search) async {
    final recentSearches = List<String>.from(state.recentSearches);
    
    // Remove if already exists
    recentSearches.remove(search);
    
    // Add to beginning
    recentSearches.insert(0, search);
    
    // Keep only last 10 searches
    if (recentSearches.length > 10) {
      recentSearches.removeRange(10, recentSearches.length);
    }
    
    state = state.copyWith(recentSearches: recentSearches);
    await _savePreferences();
  }

  Future<void> clearRecentSearches() async {
    state = state.copyWith(recentSearches: []);
    await _savePreferences();
  }

  Future<void> updateNotificationSetting(String key, bool value) async {
    final notificationSettings = Map<String, bool>.from(state.notificationSettings);
    notificationSettings[key] = value;
    
    state = state.copyWith(notificationSettings: notificationSettings);
    await _savePreferences();
  }

  Future<void> updateDefaultLocation(String location) async {
    state = state.copyWith(defaultLocation: location);
    await _savePreferences();
  }

  Future<void> updateLocationServices(bool enabled) async {
    state = state.copyWith(enableLocationServices: enabled);
    await _savePreferences();
  }

  // Reset all preferences
  Future<void> resetPreferences() async {
    state = const UserPreferences();
    await _savePreferences();
  }
}

// Provider
final userPreferencesProvider = StateNotifierProvider<UserPreferencesService, UserPreferences>((ref) {
  return UserPreferencesService();
});

// Specific preference providers
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(userPreferencesProvider).isDarkMode;
});

final currentLanguageProvider = Provider<String>((ref) {
  return ref.watch(userPreferencesProvider).language;
});

final currentCurrencyProvider = Provider<String>((ref) {
  return ref.watch(userPreferencesProvider).currency;
});

final recentSearchesProvider = Provider<List<String>>((ref) {
  return ref.watch(userPreferencesProvider).recentSearches;
});

final notificationSettingsProvider = Provider<Map<String, bool>>((ref) {
  return ref.watch(userPreferencesProvider).notificationSettings;
});
