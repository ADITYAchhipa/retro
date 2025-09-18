# Rentaly Developer Guide

## Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 2.17+
- Android Studio / VS Code
- Git

### Setup
```bash
# Clone and setup
git clone <repository-url>
cd rentally
flutter pub get
flutter run
```

## Development Workflow

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/new-feature-name

# Make changes following CODE_STYLE_GUIDE.md
# Test your changes
flutter test
flutter analyze

# Commit and push
git add .
git commit -m "feat: add new feature description"
git push origin feature/new-feature-name
```

### 2. Code Quality Checks
```bash
# Run all quality checks
flutter analyze          # Static analysis
flutter test            # Run tests
dart format lib/        # Format code
dart fix --apply        # Auto-fix lint issues
```

### 3. Common Commands
```bash
# Development
flutter run                    # Run app
flutter run -d chrome         # Run on web
flutter hot-reload            # Hot reload (r in terminal)
flutter hot-restart           # Hot restart (R in terminal)

# Testing
flutter test                  # Run all tests
flutter test test/widget_test.dart  # Run specific test
flutter test --coverage      # Generate coverage report

# Build
flutter build apk            # Android APK
flutter build ios           # iOS build
flutter build web           # Web build
```

## Project Structure Deep Dive

### Core Directories

#### `/lib/app/`
- **Purpose**: App-level configuration and routing
- **Key Files**:
  - `main.dart` - App entry point
  - `router.dart` - Route definitions
  - `auth_router.dart` - Authentication routing logic
  - `app_state.dart` - Global app state

#### `/lib/features/`
- **Purpose**: Feature-based modules
- **Structure**: Each feature is self-contained
- **Examples**:
  - `onboarding/` - User onboarding flow
  - `auth/` - Authentication screens
  - `home/` - Main dashboard
  - `monetization/` - Revenue features

#### `/lib/widgets/`
- **Purpose**: Reusable UI components
- **Examples**:
  - `responsive_layout.dart` - Responsive wrapper
  - `custom_button.dart` - Branded buttons
  - `loading_widget.dart` - Loading indicators

#### `/lib/services/`
- **Purpose**: Business logic and API communication
- **Examples**:
  - `auth_service.dart` - Authentication logic
  - `api_service.dart` - HTTP client wrapper
  - `storage_service.dart` - Local data persistence

## State Management with Riverpod

### Provider Types
```dart
// Simple state
final counterProvider = StateProvider<int>((ref) => 0);

// Complex state with notifier
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});

// Async data
final postsProvider = FutureProvider<List<Post>>((ref) async {
  return await ApiService.getPosts();
});
```

### Consumer Patterns
```dart
// Basic consumer
Consumer(
  builder: (context, ref, child) {
    final count = ref.watch(counterProvider);
    return Text('Count: $count');
  },
)

// Consumer widget
class CounterWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('Count: $count');
  }
}

// Stateful consumer
class CounterPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends ConsumerState<CounterPage> {
  @override
  Widget build(BuildContext context) {
    final count = ref.watch(counterProvider);
    return Scaffold(/* ... */);
  }
}
```

## Routing with GoRouter

### Route Definition
```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/profile/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ProfileScreen(userId: userId);
      },
    ),
  ],
);
```

### Navigation
```dart
// Navigate to route
context.go('/profile/123');
context.push('/settings');

// With query parameters
context.go('/search?query=apartment');

// Replace current route
context.pushReplacement('/login');

// Go back
context.pop();
```

## UI/UX Guidelines

### Responsive Design
```dart
// Use ResponsiveLayout wrapper
ResponsiveLayout(
  maxWidth: 800,
  child: YourWidget(),
)

// Responsive breakpoints
class Breakpoints {
  static const mobile = 600;
  static const tablet = 900;
  static const desktop = 1200;
}
```

### Theme Usage
```dart
// Access theme
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

// Use theme colors
Container(
  color: theme.colorScheme.surface,
  child: Text(
    'Hello',
    style: theme.textTheme.headlineMedium,
  ),
)
```

### Material 3 Components
```dart
// Buttons
FilledButton(onPressed: () {}, child: Text('Primary'));
OutlinedButton(onPressed: () {}, child: Text('Secondary'));
TextButton(onPressed: () {}, child: Text('Tertiary'));

// Cards
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(children: [...]),
  ),
)

// Navigation
NavigationBar(
  destinations: [
    NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
  ],
)
```

## Testing Strategies

### Widget Testing
```dart
testWidgets('Login form validates input', (tester) async {
  // Arrange
  await tester.pumpWidget(
    MaterialApp(home: LoginScreen()),
  );

  // Act
  await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  // Assert
  expect(find.text('Please enter a valid email'), findsOneWidget);
});
```

### Unit Testing
```dart
group('UserService', () {
  late UserService service;
  
  setUp(() {
    service = UserService();
  });
  
  test('should validate email format', () {
    expect(service.isValidEmail('test@example.com'), isTrue);
    expect(service.isValidEmail('invalid'), isFalse);
  });
});
```

### Integration Testing
```dart
void main() {
  group('App Integration Tests', () {
    testWidgets('Complete onboarding flow', (tester) async {
      await tester.pumpWidget(MyApp());
      
      // Navigate through onboarding
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      
      // Verify final screen
      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}
```

## Performance Optimization

### Widget Performance
```dart
// Use const constructors
const Text('Static text');

// Extract static widgets
class _StaticHeader extends StatelessWidget {
  const _StaticHeader();
  @override
  Widget build(BuildContext context) => Container(/* ... */);
}

// Use RepaintBoundary for complex widgets
RepaintBoundary(
  child: ComplexAnimatedWidget(),
)
```

### List Performance
```dart
// Use builder constructors for large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemTile(items[index]),
)

// Use separators for better performance
ListView.separated(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemTile(items[index]),
  separatorBuilder: (context, index) => const Divider(),
)
```

### Memory Management
```dart
class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _subscription;
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _subscription = stream.listen(/* ... */);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _subscription.cancel();
    super.dispose();
  }
}
```

## Debugging Tips

### Common Issues
1. **Widget not updating**: Check if using correct provider watch/read
2. **Navigation errors**: Verify route definitions and context usage
3. **Performance issues**: Use Flutter Inspector and Performance tab
4. **State not persisting**: Check provider scope and lifecycle

### Debug Tools
```dart
// Debug prints
debugPrint('Debug message');

// Assert in debug mode
assert(condition, 'Error message');

// Debug flags
if (kDebugMode) {
  print('Debug only code');
}
```

### Flutter Inspector
- Use Flutter Inspector in IDE
- Check widget tree structure
- Monitor performance metrics
- Debug layout issues

## Deployment

### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (recommended)
flutter build appbundle --release
```

### iOS
```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release
```

### Web
```bash
# Debug build
flutter build web

# Release build
flutter build web --release
```

## Contributing Guidelines

### Code Review Checklist
- [ ] Follows CODE_STYLE_GUIDE.md
- [ ] Includes appropriate tests
- [ ] Updates documentation if needed
- [ ] Passes `flutter analyze`
- [ ] No performance regressions
- [ ] Handles error cases
- [ ] Follows accessibility guidelines

### Git Commit Messages
```
feat: add user authentication
fix: resolve navigation bug
docs: update API documentation
style: format code according to style guide
refactor: restructure user service
test: add unit tests for user model
chore: update dependencies
```

This guide provides everything developers need to contribute effectively to the Rentaly project.
