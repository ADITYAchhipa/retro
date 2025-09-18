# 🔧 Core Module - Business Logic & Services

## 📋 Overview

The `core` module contains the essential business logic, data models, and services that power the Rentaly app. This is the heart of the application's functionality.

## 📁 Structure

```
core/
├── constants/          # App-wide constants and configuration
├── database/          # Data models and structures
├── providers/         # State management (Business Logic Layer)
└── services/          # External API and service integrations
```

## 🔧 Constants

### `api_constants.dart`
- **Purpose**: Backend API configuration
- **Key Settings**:
  - `baseUrl`: Your backend server URL
  - `useDummyData`: Toggle between real/test data (currently `false`)
  - API endpoints and authentication settings

### `app_constants.dart`
- **Purpose**: General app constants
- **Contains**: Colors, sizes, default values, etc.

## 🗄️ Database Models

Located in `database/models/`:

- **`property_model.dart`**: Property data structure
- **`user_model.dart`**: User account and profile data
- **`booking_model.dart`**: Booking and reservation data

Each model includes:
- JSON serialization (`toJson()`, `fromJson()`)
- Data validation
- Type-safe property access

## 🔄 Providers (State Management)

### `property_provider.dart`
- **Manages**: Property listings, search results, featured properties
- **Key Methods**:
  - `loadProperties()`: Fetch property listings
  - `loadFeaturedProperties()`: Get featured properties
  - `searchProperties()`: Search with filters

### `booking_provider.dart`
- **Manages**: User bookings, booking creation
- **Key Methods**:
  - `loadUserBookings()`: Get user's bookings
  - `createBooking()`: Create new booking

### `user_provider.dart`
- **Manages**: Authentication, user profile
- **Key Methods**:
  - `login()`: User authentication
  - `register()`: New user registration
  - `logout()`: Sign out user

## 🌐 Services

### `real_api_service.dart`
- **Purpose**: HTTP API communication with backend
- **Features**:
  - Authentication token management
  - Error handling and retry logic
  - Type-safe API responses
  - Automatic JSON parsing

## 🔄 Data Flow

1. **UI Component** triggers action (e.g., load properties)
2. **Provider** receives action and calls service
3. **Service** makes HTTP request to backend
4. **Response** is parsed into models
5. **Provider** updates state and notifies UI
6. **UI** rebuilds with new data

## 🛠️ Usage Examples

### Using Providers in UI
```dart
// In a widget
Consumer<PropertyProvider>(
  builder: (context, propertyProvider, child) {
    if (propertyProvider.isLoading) {
      return CircularProgressIndicator();
    }
    return ListView.builder(
      itemCount: propertyProvider.properties.length,
      itemBuilder: (context, index) {
        final property = propertyProvider.properties[index];
        return PropertyCard(property: property);
      },
    );
  },
)
```

### Calling Provider Methods
```dart
// Trigger data loading
context.read<PropertyProvider>().loadProperties();

// Access current state
final properties = context.watch<PropertyProvider>().properties;
```

## 🔧 Configuration

### Backend Setup
1. Update `baseUrl` in `api_constants.dart`
2. Add API key if required
3. Ensure backend implements required endpoints

### Adding New Models
1. Create model file in `database/models/`
2. Implement `toJson()` and `fromJson()`
3. Add validation if needed

### Adding New Providers
1. Create provider file in `providers/`
2. Extend `ChangeNotifier`
3. Register in `main.dart` with `MultiProvider`

## 🐛 Debugging Tips

- Check provider state in Flutter Inspector
- Use `print()` statements in provider methods
- Verify API responses in service layer
- Check model serialization for data issues

## 🔒 Security Notes

- API tokens are managed securely
- Sensitive data is not logged
- Input validation in models
- Error messages don't expose internal details
