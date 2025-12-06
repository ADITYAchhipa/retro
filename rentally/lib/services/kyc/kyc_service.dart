import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../token_storage_service.dart';

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
  static const _frontIdBytesKey = 'kyc_front_id_bytes';
  static const _backIdBytesKey = 'kyc_back_id_bytes';
  static const _selfieBytesKey = 'kyc_selfie_bytes';
  static const String _baseUrl = 'http://localhost:4000/api';

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

  /// Save image bytes (for web compatibility)
  Future<void> saveFrontIdBytes(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_frontIdBytesKey, base64Encode(bytes));
  }

  Future<void> saveBackIdBytes(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backIdBytesKey, base64Encode(bytes));
  }

  Future<void> saveSelfieBytes(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selfieBytesKey, base64Encode(bytes));
  }

  /// Get image bytes (for web compatibility)
  Future<Uint8List?> getFrontIdBytes() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_frontIdBytesKey);
    if (encoded == null || encoded.isEmpty) return null;
    return base64Decode(encoded);
  }

  Future<Uint8List?> getBackIdBytes() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_backIdBytesKey);
    if (encoded == null || encoded.isEmpty) return null;
    return base64Decode(encoded);
  }

  Future<Uint8List?> getSelfieBytes() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_selfieBytesKey);
    if (encoded == null || encoded.isEmpty) return null;
    return base64Decode(encoded);
  }

  Future<void> submit() async {
    final current = await getProfile();
    final updated = current.copyWith(status: KycStatus.submitted, submittedAt: DateTime.now());
    await _save(updated);
  }

  /// Submit KYC to backend API with all documents
  /// Returns a map with 'success' and 'message' keys
  /// Works on both web and mobile platforms
  Future<Map<String, dynamic>> submitToBackend() async {
    try {
      final profile = await getProfile();
      final token = await TokenStorageService.getToken();

      if (token == null) {
        return {'success': false, 'message': 'Not authenticated. Please login first.'};
      }

      // Validate required fields
      if (profile.firstName == null || profile.lastName == null || 
          profile.dob == null || profile.address == null || 
          profile.city == null || profile.postalCode == null || 
          profile.country == null) {
        return {'success': false, 'message': 'Please fill in all personal information.'};
      }

      // Get image bytes - works on both web and mobile
      Uint8List? frontIdBytes;
      Uint8List? backIdBytes;
      Uint8List? selfieBytes;

      if (kIsWeb) {
        // On web, get bytes from stored base64
        frontIdBytes = await getFrontIdBytes();
        backIdBytes = await getBackIdBytes();
        selfieBytes = await getSelfieBytes();
      } else {
        // On mobile, read from file paths
        if (profile.frontIdPath != null) {
          final frontIdFile = File(profile.frontIdPath!);
          if (await frontIdFile.exists()) {
            frontIdBytes = await frontIdFile.readAsBytes();
          }
        }
        if (profile.backIdPath != null) {
          final backIdFile = File(profile.backIdPath!);
          if (await backIdFile.exists()) {
            backIdBytes = await backIdFile.readAsBytes();
          }
        }
        if (profile.selfiePath != null) {
          final selfieFile = File(profile.selfiePath!);
          if (await selfieFile.exists()) {
            selfieBytes = await selfieFile.readAsBytes();
          }
        }
      }

      // Validate required images
      if (frontIdBytes == null || frontIdBytes.isEmpty) {
        return {'success': false, 'message': 'Please upload front ID image.'};
      }

      if (selfieBytes == null || selfieBytes.isEmpty) {
        return {'success': false, 'message': 'Please take a selfie.'};
      }

      // Create multipart request
      final uri = Uri.parse('$_baseUrl/identity-verification/submit');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add personal info fields
      request.fields['firstName'] = profile.firstName!;
      request.fields['lastName'] = profile.lastName!;
      request.fields['dob'] = profile.dob!;
      request.fields['address'] = profile.address!;
      request.fields['city'] = profile.city!;
      request.fields['postalCode'] = profile.postalCode!;
      request.fields['country'] = profile.country!;
      request.fields['documentType'] = profile.documentType;

      // Add front ID image using bytes
      request.files.add(http.MultipartFile.fromBytes(
        'frontId',
        frontIdBytes,
        filename: 'front_id.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

      // Add back ID image (if exists and document type is not passport)
      if (backIdBytes != null && backIdBytes.isNotEmpty && profile.documentType != 'passport') {
        request.files.add(http.MultipartFile.fromBytes(
          'backId',
          backIdBytes,
          filename: 'back_id.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      // Add selfie image using bytes
      request.files.add(http.MultipartFile.fromBytes(
        'selfie',
        selfieBytes,
        filename: 'selfie.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local status
          await submit();
          return {'success': true, 'message': 'KYC submitted successfully!'};
        } else {
          return {'success': false, 'message': data['message'] ?? 'Failed to submit KYC'};
        }
      } else {
        return {'success': false, 'message': 'Server error. Please try again later.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get KYC status from backend
  Future<Map<String, dynamic>> getBackendStatus() async {
    try {
      final token = await TokenStorageService.getToken();

      if (token == null) {
        return {'success': false, 'status': 'not_authenticated'};
      }

      final uri = Uri.parse('$_baseUrl/identity-verification/status');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'success': false, 'message': 'Failed to get KYC status'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
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
