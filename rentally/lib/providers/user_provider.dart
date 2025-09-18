import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

/// User state notifier for managing user data
class UserNotifier extends StateNotifier<User?> {
  UserNotifier() : super(null);

  /// Update user data
  void updateUser(User user) {
    state = user;
  }

  /// Clear user data (logout)
  void clearUser() {
    state = null;
  }

  /// Update user profile
  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? avatar,
  }) {
    if (state != null) {
      state = state!.copyWith(
        name: name ?? state!.name,
        email: email ?? state!.email,
        phoneNumber: phone ?? state!.phoneNumber,
        profileImageUrl: avatar ?? state!.profileImageUrl,
      );
    }
  }
}

/// User provider for accessing user state
final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier();
});

/// Current user provider (computed)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(userProvider);
});

/// Is user logged in provider
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user != null;
});
