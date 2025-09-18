# Rentaly Flutter App - Development Setup

## Prerequisites
- Flutter SDK (3.0+)
- Dart SDK
- Android Studio / VS Code
- Git

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/rentaly.git
   cd rentaly
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## Project Structure
- `lib/` - Main application code
- `lib/features/` - Feature-specific screens and widgets
- `lib/app/` - App configuration, routing, and state management
- `assets/` - Images, icons, and other assets

## Development Workflow

1. **Always pull latest changes before starting work:**
   ```bash
   git pull origin main
   ```

2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes and test thoroughly**

4. **Commit and push:**
   ```bash
   git add .
   git commit -m "Clear description of changes"
   git push origin feature/your-feature-name
   ```

5. **Create Pull Request on GitHub for code review**

## Key Features Implemented
- ✅ Responsive onboarding flow with animations
- ✅ Country selection screen
- ✅ Authentication system
- ✅ Navigation with GoRouter
- ✅ State management with Riverpod
- ✅ Modern Material 3 design

## Current Status
All major navigation issues have been resolved. The app successfully navigates:
- Splash → Onboarding → Country Selection → Authentication

## Need Help?
- Check existing issues on GitHub
- Review the code comments for context
- Test on both Android and iOS if possible
