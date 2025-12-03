# Rentaly Flutter App

End-user Flutter app for the Rentaly marketplace (web + mobile).

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK (matching your Flutter version)
- Git
- A running backend API (see `/backend` in the repo)

### Setup

```bash
git clone <repository-url>
cd rentaly/rentally

flutter pub get
flutter run            # or: flutter run -d chrome
```

For web development, you can use:

```bash
flutter run -d chrome
# or
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=5173
```

Make sure the backend is running (by default on `http://localhost:4000`).

## 🏗️ Project Structure (lib/)

```text
lib/
├── main.dart                 # App entry point
├── app/                      # App-level config, routing, global state
│   ├── auth_router.dart      # GoRouter configuration & auth redirects
│   ├── app_state.dart        # Auth + global app state (Riverpod)
│   └── main_shell.dart       # Main shell with bottom navigation etc.
├── core/                     # Shared logic & configuration
│   ├── constants/            # API endpoints, app constants
│   │   └── api_constants.dart
│   ├── providers/            # ChangeNotifier-based providers
│   ├── theme/                # Enterprise light/dark themes
│   └── widgets/              # Core UI helpers (loading, layouts, etc.)
├── features/                 # Feature-based modules (UI + logic)
│   ├── auth/                 # Login, register, forgot/reset password
│   ├── home/                 # Home screen and sections
│   ├── booking/              # Booking flows & history
│   ├── owner/                # Host/owner dashboards & tools
│   ├── search/               # Search & filters
│   ├── wishlist/             # Saved listings
│   ├── settings/             # Settings & preferences
│   └── ...                   # Other feature modules
├── l10n/                     # Localization (.arb files + generated Dart)
└── services/                 # API + domain services (auth, bookings, etc.)
```

## 🔗 Backend Configuration

All API base URLs are defined in:

- `lib/core/constants/api_constants.dart`

By default:

- `baseUrl     = 'http://localhost:4000/api'`
- `authBaseUrl = 'http://localhost:4000/api/user'`

If you deploy the backend elsewhere, update these constants accordingly.

Authentication state is managed by `AuthNotifier` in:

- `lib/app/app_state.dart`

This integrates with the backend login/register/logout endpoints and stores JWT tokens using `TokenStorageService`.

## 🧑‍💻 Development Workflow

1. Pull latest changes:

   ```bash
   git checkout main
   git pull origin main
   ```

2. Create a feature branch:

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. Run the app and use hot reload while editing:

   ```bash
   flutter run -d chrome
   # press `r` in the terminal for hot reload
   ```

4. Before committing, run basic checks (optional but recommended):

   ```bash
   flutter analyze
   flutter test            # if you add tests
   ```

5. Commit and push:

   ```bash
   git add .
   git commit -m "feat: short description of change"
   git push origin feature/your-feature-name
   ```

## 🔧 Key Commands

```bash
flutter run                   # run on default device
flutter run -d chrome         # run on web (Chrome)
flutter build apk             # build Android APK
flutter build web --release   # build web for production

flutter analyze               # static analysis
flutter test                  # run tests (if present)
```

## 📚 Related Docs

- `lib/README.md` – additional details about the `lib/` layout (optional)
- Root-level `README.md` – monorepo overview and backend/admin docs

## ❓ Need Help?

- Ensure the backend is running and reachable from the device/emulator.
- Check `api_constants.dart` if network calls fail.
- Use Flutter DevTools and the console for runtime errors.

