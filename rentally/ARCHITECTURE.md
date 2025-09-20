# Rentaly App Architecture

## Overview
Rentaly is a Flutter-based rental marketplace application that allows users to rent properties and vehicles. The app follows a feature-first architecture with clean separation of concerns.

## Project Structure

```
lib/
├── app/                    # App-level configuration
│   ├── app_state.dart     # Global app state management
│   ├── auth_router.dart   # Authentication routing logic
│   ├── main_shell.dart    # Main app shell/layout
│   └── router.dart        # App routing configuration
├── features/              # Feature modules
│   ├── analytics/         # Analytics and tracking
│  
│   ├── auth/             # Authentication screens
│   ├── country/          # Country selection
│   ├── home/             # Home screen and dashboard
│   ├── monetization/     # Revenue features (subscriptions, wallet)
│   ├── onboarding/       # User onboarding flow
│   ├── owner/            # Property/vehicle owner features
│   ├── reviews/          # Review and rating system
│   └── settings/         # App settings and preferences
├── models/               # Data models
├── services/             # Business logic and API services
├── widgets/              # Reusable UI components
└── main.dart            # App entry point
```

## Architecture Principles

### 1. Feature-First Organization
- Each feature is self-contained in its own directory
- Features include screens, widgets, and feature-specific logic
- Promotes modularity and maintainability

### 2. State Management
- **Riverpod** for reactive state management
- Provider-based dependency injection
- Immutable state patterns

### 3. Routing
- **GoRouter** for declarative routing
- Route guards for authentication
- Deep linking support

### 4. UI/UX Design
- **Material 3** design system
- Responsive layouts for desktop/mobile
- Professional enterprise-grade UI

## Key Features

### Authentication Flow
1. **Splash Screen** → Initial app loading
2. **Onboarding** → 5-slide introduction flow
3. **Country Selection** → User location setup
4. **Login/Register** → User authentication

### Core Features
- **Property/Vehicle Listings** with image galleries
- **Search and Filtering** with advanced options
- **Booking Management** with real-time updates
- **Review System** (bidirectional: guest ↔ owner)
- **Monetization** (subscriptions, wallet, referrals)
- **AR Integration** for property viewing
- **Offline Support** with data synchronization

## Development Guidelines

### Code Style
- Follow Flutter/Dart conventions
- Use `const` constructors for performance
- Implement proper error handling
- Add comprehensive documentation

### Testing
- Widget tests for UI components
- Unit tests for business logic
- Integration tests for user flows

### Performance
- Lazy loading for large lists
- Image optimization and caching
- Efficient state management
- Memory leak prevention

## Dependencies

### Core Dependencies
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `shared_preferences` - Local storage
- `http` - API communication

### UI Dependencies
- `flutter_launcher_icons` - App icons
- `image_picker` - Image selection
- `google_maps_flutter` - Maps integration

### Development Dependencies
- `flutter_test` - Testing framework
- `flutter_lints` - Code analysis

## Getting Started

1. **Setup**: Follow instructions in `SETUP.md`
2. **Development**: Run `flutter run` for development
3. **Testing**: Run `flutter test` for unit tests
4. **Analysis**: Run `flutter analyze` for code quality

## Contributing

1. Follow the established architecture patterns
2. Write tests for new features
3. Update documentation for significant changes
4. Follow the Git workflow in `SETUP.md`
