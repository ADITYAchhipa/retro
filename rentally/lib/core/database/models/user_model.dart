/// User model representing app users in the database
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? avatar;
  final UserRole role;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserPreferences preferences;
  final UserStats stats;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.avatar,
    required this.role,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.preferences,
    required this.stats,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      avatar: json['avatar'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.guest,
      ),
      isVerified: json['isVerified'] as bool,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      preferences: UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>),
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'role': role.name,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preferences': preferences.toJson(),
      'stats': stats.toJson(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? avatar,
    UserRole? role,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserPreferences? preferences,
    UserStats? stats,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
    );
  }
}

enum UserRole {
  guest,
  seeker,
  owner,
  admin,
}

class UserPreferences {
  final String currency;
  final String language;
  final bool darkMode;
  final bool notifications;
  final bool emailUpdates;

  UserPreferences({
    required this.currency,
    required this.language,
    required this.darkMode,
    required this.notifications,
    required this.emailUpdates,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      currency: json['currency'] as String,
      language: json['language'] as String,
      darkMode: json['darkMode'] as bool,
      notifications: json['notifications'] as bool,
      emailUpdates: json['emailUpdates'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'language': language,
      'darkMode': darkMode,
      'notifications': notifications,
      'emailUpdates': emailUpdates,
    };
  }

  UserPreferences copyWith({
    String? currency,
    String? language,
    bool? darkMode,
    bool? notifications,
    bool? emailUpdates,
  }) {
    return UserPreferences(
      currency: currency ?? this.currency,
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      notifications: notifications ?? this.notifications,
      emailUpdates: emailUpdates ?? this.emailUpdates,
    );
  }
}

class UserStats {
  final int totalBookings;
  final int totalProperties;
  final double totalEarnings;
  final double averageRating;
  final int reviewCount;
  final int referralCount;
  final int tokenBalance;

  UserStats({
    required this.totalBookings,
    required this.totalProperties,
    required this.totalEarnings,
    required this.averageRating,
    required this.reviewCount,
    required this.referralCount,
    required this.tokenBalance,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalBookings: json['totalBookings'] as int,
      totalProperties: json['totalProperties'] as int,
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      averageRating: (json['averageRating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      referralCount: json['referralCount'] as int,
      tokenBalance: json['tokenBalance'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBookings': totalBookings,
      'totalProperties': totalProperties,
      'totalEarnings': totalEarnings,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'referralCount': referralCount,
      'tokenBalance': tokenBalance,
    };
  }

  UserStats copyWith({
    int? totalBookings,
    int? totalProperties,
    double? totalEarnings,
    double? averageRating,
    int? reviewCount,
    int? referralCount,
    int? tokenBalance,
  }) {
    return UserStats(
      totalBookings: totalBookings ?? this.totalBookings,
      totalProperties: totalProperties ?? this.totalProperties,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      referralCount: referralCount ?? this.referralCount,
      tokenBalance: tokenBalance ?? this.tokenBalance,
    );
  }
}
