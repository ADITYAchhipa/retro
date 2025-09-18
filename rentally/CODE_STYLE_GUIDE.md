# Rentaly Code Style Guide

## Overview
This guide ensures consistent, maintainable, and professional code across the Rentaly Flutter application.

## File Organization

### Directory Structure
```
lib/features/[feature_name]/
├── screens/           # UI screens for the feature
├── widgets/           # Feature-specific widgets
├── models/            # Feature-specific data models
├── services/          # Feature business logic
└── [feature_name]_screen.dart  # Main screen file
```

### File Naming
- Use `snake_case` for file names
- Screen files: `[feature_name]_screen.dart`
- Widget files: `[widget_name]_widget.dart`
- Model files: `[model_name]_model.dart`
- Service files: `[service_name]_service.dart`

## Code Structure

### Class Organization
```dart
class ExampleScreen extends StatefulWidget {
  // 1. Static constants
  static const String routeName = '/example';
  
  // 2. Constructor
  const ExampleScreen({super.key});
  
  // 3. Override methods
  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  // 1. Private fields
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _controller;
  
  // 2. Lifecycle methods
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  // 3. Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(/* ... */);
  }
  
  // 4. Private helper methods
  void _handleSubmit() {
    // Implementation
  }
  
  Widget _buildSection() {
    // Implementation
  }
}
```

## Naming Conventions

### Variables and Methods
- Use `camelCase` for variables and methods
- Use descriptive names: `userController` not `ctrl`
- Boolean variables: `isLoading`, `hasError`, `canSubmit`
- Private members: prefix with underscore `_privateMethod`

### Classes and Widgets
- Use `PascalCase` for class names
- Widget names should be descriptive: `PropertyListCard`, `UserProfileHeader`
- Screen names: `[Feature]Screen` (e.g., `LoginScreen`, `HomeScreen`)

### Constants
- Use `SCREAMING_SNAKE_CASE` for compile-time constants
- Use `camelCase` for runtime constants

```dart
// Compile-time constants
static const String API_BASE_URL = 'https://api.rentaly.com';
static const int MAX_UPLOAD_SIZE = 5 * 1024 * 1024; // 5MB

// Runtime constants
final primaryColor = Theme.of(context).primaryColor;
```

## Widget Best Practices

### Constructor Guidelines
```dart
// ✅ Good - Use const constructors when possible
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final String text;
  final bool isLoading;
}

// ✅ Good - Use const for immutable widgets
const SizedBox(height: 16)
const Divider()
```

### State Management
```dart
// ✅ Good - Use Riverpod providers
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});

// ✅ Good - Consumer widgets for reactive UI
Consumer(
  builder: (context, ref, child) {
    final user = ref.watch(userProvider);
    return Text(user.name);
  },
)
```

## Error Handling

### Try-Catch Patterns
```dart
// ✅ Good - Comprehensive error handling
Future<void> _saveData() async {
  try {
    setState(() => _isLoading = true);
    
    await _dataService.save(data);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data saved successfully')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### Validation Patterns
```dart
// ✅ Good - Form validation
String? _validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Please enter a valid email';
  }
  return null;
}
```

## Documentation Standards

### Class Documentation
```dart
/// A customizable button widget that handles loading states.
/// 
/// This widget provides a consistent button design across the app
/// with built-in loading state management and accessibility features.
/// 
/// Example usage:
/// ```dart
/// CustomButton(
///   text: 'Save',
///   onPressed: _handleSave,
///   isLoading: _isLoading,
/// )
/// ```
class CustomButton extends StatelessWidget {
  /// Creates a custom button.
  /// 
  /// The [text] and [onPressed] parameters are required.
  /// Set [isLoading] to true to show a loading indicator.
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  /// The text to display on the button.
  final String text;
  
  /// Called when the button is pressed.
  final VoidCallback onPressed;
  
  /// Whether to show a loading indicator instead of text.
  final bool isLoading;
}
```

### Method Documentation
```dart
/// Validates user input and saves the form data.
/// 
/// Returns `true` if the data was saved successfully, `false` otherwise.
/// Shows appropriate error messages to the user.
/// 
/// Throws [ValidationException] if the form data is invalid.
Future<bool> _saveFormData() async {
  // Implementation
}
```

## Performance Guidelines

### Widget Optimization
```dart
// ✅ Good - Use const constructors
const Text('Static text')

// ✅ Good - Extract widgets to reduce rebuilds
class _StaticHeader extends StatelessWidget {
  const _StaticHeader();
  
  @override
  Widget build(BuildContext context) {
    return Container(/* ... */);
  }
}

// ✅ Good - Use ListView.builder for large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

### Memory Management
```dart
// ✅ Good - Dispose controllers and subscriptions
@override
void dispose() {
  _textController.dispose();
  _animationController.dispose();
  _subscription?.cancel();
  super.dispose();
}
```

## Testing Guidelines

### Widget Tests
```dart
testWidgets('CustomButton shows loading indicator when isLoading is true', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CustomButton(
        text: 'Test',
        onPressed: () {},
        isLoading: true,
      ),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.text('Test'), findsNothing);
});
```

### Unit Tests
```dart
group('UserService', () {
  late UserService userService;
  
  setUp(() {
    userService = UserService();
  });
  
  test('should validate email correctly', () {
    expect(userService.isValidEmail('test@example.com'), isTrue);
    expect(userService.isValidEmail('invalid-email'), isFalse);
  });
});
```

## Import Organization

```dart
// 1. Dart imports
import 'dart:async';
import 'dart:io';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 4. Local imports (relative)
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'widgets/custom_button.dart';
```

## Common Patterns

### Loading States
```dart
if (_isLoading)
  const Center(child: CircularProgressIndicator())
else
  _buildContent()
```

### Error States
```dart
if (_error != null)
  ErrorWidget(
    message: _error!,
    onRetry: _retry,
  )
else
  _buildContent()
```

### Empty States
```dart
if (_items.isEmpty)
  const EmptyStateWidget(
    message: 'No items found',
    icon: Icons.inbox,
  )
else
  _buildItemsList()
```

This style guide ensures consistent, maintainable, and professional code across the Rentaly application.
