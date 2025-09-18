/// User model for the Rentaly app
class User {
  final String id;
  final String email;
  final String? name;
  final String? profileImageUrl;
  final String? phoneNumber;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final Map<String, dynamic>? preferences;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.profileImageUrl,
    this.phoneNumber,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.preferences,
  });

  /// Creates a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.seeker,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  /// Converts User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isVerified': isVerified,
      'preferences': preferences,
    };
  }

  /// Creates a copy of User with updated fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImageUrl,
    String? phoneNumber,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, role: $role)';
  }
}

/// User roles in the app
enum UserRole {
  seeker,
  owner,
  admin,
}
