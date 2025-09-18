import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum KycStatus { notStarted, inProgress, submitted, verified, rejected }

class KycProfile {
  // Personal info
  final String? firstName;
  final String? lastName;
  final String? dob;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? country;

  // Document info
  final String documentType; // passport | drivers_license | national_id
  final String? frontIdPath;
  final String? backIdPath;
  final String? selfiePath;

  // Status
  final KycStatus status;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;

  const KycProfile({
    this.firstName,
    this.lastName,
    this.dob,
    this.address,
    this.city,
    this.postalCode,
    this.country,
    this.documentType = 'passport',
    this.frontIdPath,
    this.backIdPath,
    this.selfiePath,
    this.status = KycStatus.notStarted,
    this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
  });

  KycProfile copyWith({
    String? firstName,
    String? lastName,
    String? dob,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? documentType,
    String? frontIdPath,
    String? backIdPath,
    String? selfiePath,
    KycStatus? status,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? rejectionReason,
  }) {
    return KycProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      documentType: documentType ?? this.documentType,
      frontIdPath: frontIdPath ?? this.frontIdPath,
      backIdPath: backIdPath ?? this.backIdPath,
      selfiePath: selfiePath ?? this.selfiePath,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'dob': dob,
        'address': address,
        'city': city,
        'postalCode': postalCode,
        'country': country,
        'documentType': documentType,
        'frontIdPath': frontIdPath,
        'backIdPath': backIdPath,
        'selfiePath': selfiePath,
        'status': status.name,
        'submittedAt': submittedAt?.toIso8601String(),
        'verifiedAt': verifiedAt?.toIso8601String(),
        'rejectionReason': rejectionReason,
      };

  factory KycProfile.fromJson(Map<String, dynamic> json) {
    return KycProfile(
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      dob: json['dob'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      documentType: (json['documentType'] as String?) ?? 'passport',
      frontIdPath: json['frontIdPath'] as String?,
      backIdPath: json['backIdPath'] as String?,
      selfiePath: json['selfiePath'] as String?,
      status: KycStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => KycStatus.notStarted,
      ),
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
      verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt']) : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}

class KycService {
  KycService._();
  static final KycService instance = KycService._();

  static const _storageKey = 'kyc_profile_v1';

  Future<KycProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const KycProfile();
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return KycProfile.fromJson(data);
  }

  Future<void> _save(KycProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(profile.toJson()));
  }

  Future<void> savePersonalInfo({
    required String firstName,
    required String lastName,
    required String dob,
    required String address,
    required String city,
    required String postalCode,
    required String country,
  }) async {
    final current = await getProfile();
    final updated = current.copyWith(
      firstName: firstName,
      lastName: lastName,
      dob: dob,
      address: address,
      city: city,
      postalCode: postalCode,
      country: country,
      status: KycStatus.inProgress,
    );
    await _save(updated);
  }

  Future<void> saveDocumentType(String docType) async {
    final current = await getProfile();
    final updated = current.copyWith(documentType: docType, status: KycStatus.inProgress);
    await _save(updated);
  }

  Future<void> saveDocumentPaths({String? frontIdPath, String? backIdPath}) async {
    final current = await getProfile();
    final updated = current.copyWith(
      frontIdPath: frontIdPath ?? current.frontIdPath,
      backIdPath: backIdPath ?? current.backIdPath,
      status: KycStatus.inProgress,
    );
    await _save(updated);
  }

  Future<void> saveSelfiePath(String path) async {
    final current = await getProfile();
    final updated = current.copyWith(selfiePath: path, status: KycStatus.inProgress);
    await _save(updated);
  }

  Future<void> submit() async {
    final current = await getProfile();
    final updated = current.copyWith(status: KycStatus.submitted, submittedAt: DateTime.now());
    await _save(updated);
  }

  Future<void> markVerified() async {
    final current = await getProfile();
    final updated = current.copyWith(status: KycStatus.verified, verifiedAt: DateTime.now());
    await _save(updated);
  }

  Future<void> markRejected(String reason) async {
    final current = await getProfile();
    final updated = current.copyWith(status: KycStatus.rejected, rejectionReason: reason);
    await _save(updated);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
