# 📱 Rentaly Flutter App - Developer Guide

## 🎯 Quick Start for Developers

This is the main library directory containing all the Flutter app source code. The codebase is organized following Clean Architecture principles for maximum maintainability and scalability.

## 🏗️ Architecture Overview

```
lib/
├── main.dart                   # 🚀 App entry point
├── app/                        # 🔧 App configuration & routing
├── core/                       # 💼 Business logic & services
├── features/                   # 🎨 UI features & screens
├── l10n/                       # 🌍 Internationalization
├── utils/                      # 🔧 Helper functions
└── widgets/                    # 🧩 Reusable components
```

## 🚀 Getting Started

1. **Entry Point**: Start with `main.dart` to understand app initialization
2. **App Shell**: Check `app/main_shell.dart` for overall structure
3. **Features**: Explore `features/` for specific functionality
4. **State Management**: Review `core/providers/` for business logic

## 🔧 Key Configuration Files

- **`app/theme.dart`** - App styling and colors
- **`core/constants/api_constants.dart`** - Backend API configuration
- **`app/router.dart`** - Navigation and routing

## 🎨 Adding New Features

1. Create feature directory in `features/`
2. Follow existing structure: `screens/`, `widgets/`, etc.
3. Add provider in `core/providers/` if needed
4. Update routing in `app/router.dart`

## 📱 Current Features

- 🏠 Property browsing and search
- 📅 Booking management
- 👤 User authentication
- 🌙 Dark/light theme support
- 🌍 Multi-language support
- 📱 Responsive design

## 🔄 State Management

Uses **Provider** pattern:
- Providers in `core/providers/`
- UI consumes via `Consumer<T>` or `context.watch<T>()`
- Business logic separated from UI

## 🌐 Backend Integration

- API service: `core/services/real_api_service.dart`
- Configure endpoints in `core/constants/api_constants.dart`
- Models in `core/database/models/`

## 📝 Code Style

- Feature-based organization
- Consistent naming conventions
- Comprehensive documentation
- Separation of concerns

For detailed structure information, see `../CODEBASE_STRUCTURE.md`
