# 🏗️ Rentaly Codebase Structure Guide

## 📁 Project Architecture Overview

This document provides a comprehensive guide to the Rentaly Flutter app codebase structure, designed to help developers quickly understand and navigate the project.

## 🎯 Architecture Pattern

The app follows **Clean Architecture** principles with **Provider** state management:

- **Presentation Layer**: UI components, screens, widgets
- **Business Logic Layer**: Providers, use cases, business rules
- **Data Layer**: API services, models, repositories

## 📂 Directory Structure

```
lib/
├── 🚀 app/                     # App-level configuration
│   ├── main_shell.dart         # Main app shell with navigation
│   ├── auth_router.dart        # Authentication routing logic
│   ├── app_state.dart          # Global app state management
│   ├── theme.dart              # App-wide theme configuration
│   └── router.dart             # Route definitions and navigation
│
├── 🔧 core/                    # Core business logic and utilities
│   ├── constants/              # App constants and configuration
│   │   ├── api_constants.dart  # API endpoints and configuration
│   │   └── app_constants.dart  # General app constants
│   ├── database/               # Data models and database logic
│   │   └── models/             # Data transfer objects
│   ├── providers/              # State management providers
│   │   ├── property_provider.dart
│   │   ├── booking_provider.dart
│   │   └── user_provider.dart
│   └── services/               # External service integrations
│       └── real_api_service.dart
│
├── 🎨 features/                # Feature-based modules
│   ├── auth/                   # Authentication features
│   ├── home/                   # Home screen and components
│   ├── property/               # Property-related features
│   ├── booking/                # Booking management
│   ├── profile/                # User profile features
│   ├── search/                 # Search functionality
│   ├── onboarding/             # App onboarding flow
│   └── splash/                 # Splash screen components
│
├── 🌍 l10n/                    # Internationalization
│   └── *.arb                   # Language files
│
├── 🔧 utils/                   # Utility functions and helpers
│
└── 🧩 widgets/                 # Reusable UI components
```

## 🎨 Feature Module Structure

Each feature follows a consistent structure:

```
features/feature_name/
├── screens/                    # Main screens for the feature
├── widgets/                    # Feature-specific widgets
├── models/                     # Feature-specific models (if any)
└── services/                   # Feature-specific services (if any)
```

## 🔄 Data Flow

1. **UI Layer** (Screens/Widgets) → Triggers actions
2. **Provider Layer** → Manages state and business logic
3. **Service Layer** → Handles API calls and external data
4. **Model Layer** → Defines data structure

## 🎯 Key Design Principles

### 1. **Separation of Concerns**
- Each module has a single responsibility
- UI logic separated from business logic
- Data layer isolated from presentation

### 2. **Scalability**
- Feature-based organization for easy expansion
- Modular architecture allows independent development
- Clear interfaces between layers

### 3. **Maintainability**
- Consistent naming conventions
- Comprehensive documentation
- Clear dependency management

### 4. **Testability**
- Providers can be easily mocked
- Services are injectable
- Pure functions for utilities

## 🔧 Configuration Files

### API Configuration
- `core/constants/api_constants.dart` - Backend API settings
- Set `baseUrl` to your backend server
- Configure authentication and endpoints

### Theme Configuration
- `app/theme.dart` - App-wide styling and colors
- Supports both light and dark themes
- Consistent design system

### Routing Configuration
- `app/router.dart` - Route definitions
- `app/auth_router.dart` - Authentication flow routing

## 🚀 Getting Started for New Developers

1. **Start with** `main.dart` to understand app initialization
2. **Review** `app/main_shell.dart` for overall app structure
3. **Explore** feature modules based on your task
4. **Check** providers for business logic
5. **Refer** to this guide for navigation

## 📱 Key Features

- **🏠 Property Browsing**: Search and view rental properties
- **📅 Booking Management**: Create and manage bookings
- **👤 User Authentication**: Login, register, profile management
- **🔍 Advanced Search**: Filter properties by various criteria
- **🌙 Dark Mode**: Full theme support
- **🌍 Internationalization**: Multi-language support
- **📱 Responsive Design**: Works on all screen sizes

## 🔗 External Dependencies

- **Provider**: State management
- **HTTP**: API communication
- **Flutter Localizations**: Internationalization
- **Material Design**: UI components

## 📝 Development Guidelines

1. **Follow the existing structure** when adding new features
2. **Use providers** for state management
3. **Keep widgets small** and focused
4. **Add documentation** for complex logic
5. **Maintain consistent** naming conventions
6. **Test your changes** thoroughly

## 🐛 Debugging Tips

- Check providers for state-related issues
- Review API service for network problems
- Use Flutter Inspector for UI debugging
- Check console logs for error messages

---

**Happy Coding! 🚀**

For questions or clarifications, refer to individual module README files or contact the development team.
