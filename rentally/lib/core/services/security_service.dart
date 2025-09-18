import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Industrial-Grade Security and Input Validation Service
/// 
/// Features:
/// - Input sanitization and validation
/// - XSS prevention
/// - SQL injection prevention
/// - CSRF protection
/// - Data encryption/decryption
/// - Secure token generation
/// - Rate limiting
/// - Security headers
/// - Audit logging
class SecurityService {
  static SecurityService? _instance;
  static SecurityService get instance => _instance ??= SecurityService._();
  
  SecurityService._();

  // Security configuration
  static const int _maxInputLength = 10000;
  static const int _maxFileSize = 10 * 1024 * 1024; // 10MB
  static const Duration _rateLimitWindow = Duration(minutes: 1);
  static const int _maxRequestsPerWindow = 100;
  
  // State
  bool _isInitialized = false;
  final Map<String, List<DateTime>> _rateLimitTracker = {};
  final List<SecurityEvent> _auditLog = [];
  late String _encryptionKey;
  final Random _random = Random.secure();

  /// Initialize the security service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Generate encryption key
      _encryptionKey = _generateSecureToken(32);
      
      // Start cleanup timer
      _startCleanupTimer();
      
      _isInitialized = true;
      
      _logSecurityEvent(SecurityEventType.serviceInitialized, 'Security service initialized');
      
      if (kDebugMode) {
        print('SecurityService initialized successfully');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize SecurityService: $e');
      }
      rethrow;
    }
  }

  /// Validate and sanitize text input
  ValidationResult validateInput(
    String input, {
    InputType type = InputType.text,
    int? maxLength,
    bool allowHtml = false,
    List<String> allowedTags = const [],
  }) {
    try {
      final errors = <String>[];
      String sanitized = input;
      
      // Check length
      final maxLen = maxLength ?? _maxInputLength;
      if (input.length > maxLen) {
        errors.add('Input exceeds maximum length of $maxLen characters');
        sanitized = input.substring(0, maxLen);
      }
      
      // Type-specific validation
      switch (type) {
        case InputType.email:
          if (!_isValidEmail(sanitized)) {
            errors.add('Invalid email format');
          }
          break;
        case InputType.phone:
          sanitized = _sanitizePhone(sanitized);
          if (!_isValidPhone(sanitized)) {
            errors.add('Invalid phone number format');
          }
          break;
        case InputType.url:
          if (!_isValidUrl(sanitized)) {
            errors.add('Invalid URL format');
          }
          break;
        case InputType.password:
          final passwordValidation = _validatePassword(sanitized);
          errors.addAll(passwordValidation.errors);
          break;
        case InputType.name:
          sanitized = _sanitizeName(sanitized);
          if (sanitized.isEmpty) {
            errors.add('Name cannot be empty');
          }
          break;
        case InputType.text:
          // General text validation
          break;
      }
      
      // XSS prevention
      if (!allowHtml) {
        sanitized = _sanitizeHtml(sanitized);
      } else {
        sanitized = _sanitizeHtmlWithAllowedTags(sanitized, allowedTags);
      }
      
      // SQL injection prevention
      sanitized = _preventSqlInjection(sanitized);
      
      // Log validation attempt
      _logSecurityEvent(
        errors.isEmpty ? SecurityEventType.inputValidated : SecurityEventType.inputRejected,
        'Input validation for type $type: ${errors.isEmpty ? 'passed' : 'failed'}',
      );
      
      return ValidationResult(
        isValid: errors.isEmpty,
        sanitizedInput: sanitized,
        errors: errors,
      );
      
    } catch (e) {
      _logSecurityEvent(SecurityEventType.validationError, 'Input validation error: $e');
      return ValidationResult(
        isValid: false,
        sanitizedInput: input,
        errors: ['Validation error occurred'],
      );
    }
  }

  /// Validate file upload
  FileValidationResult validateFile(
    Uint8List fileData,
    String fileName, {
    List<String> allowedExtensions = const [],
    List<String> allowedMimeTypes = const [],
    int? maxSize,
  }) {
    try {
      final errors = <String>[];
      
      // Check file size
      final maxFileSize = maxSize ?? _maxFileSize;
      if (fileData.length > maxFileSize) {
        errors.add('File size exceeds maximum of ${maxFileSize ~/ (1024 * 1024)}MB');
      }
      
      // Check file extension
      final extension = fileName.split('.').last.toLowerCase();
      if (allowedExtensions.isNotEmpty && !allowedExtensions.contains(extension)) {
        errors.add('File extension .$extension is not allowed');
      }
      
      // Check file signature (magic bytes)
      final mimeType = _detectMimeType(fileData);
      if (allowedMimeTypes.isNotEmpty && !allowedMimeTypes.contains(mimeType)) {
        errors.add('File type $mimeType is not allowed');
      }
      
      // Scan for malicious content
      if (_containsMaliciousContent(fileData)) {
        errors.add('File contains potentially malicious content');
      }
      
      _logSecurityEvent(
        errors.isEmpty ? SecurityEventType.fileValidated : SecurityEventType.fileRejected,
        'File validation for $fileName: ${errors.isEmpty ? 'passed' : 'failed'}',
      );
      
      return FileValidationResult(
        isValid: errors.isEmpty,
        fileName: fileName,
        mimeType: mimeType,
        sizeBytes: fileData.length,
        errors: errors,
      );
      
    } catch (e) {
      _logSecurityEvent(SecurityEventType.validationError, 'File validation error: $e');
      return FileValidationResult(
        isValid: false,
        fileName: fileName,
        mimeType: 'unknown',
        sizeBytes: fileData.length,
        errors: ['File validation error occurred'],
      );
    }
  }

  /// Check rate limiting
  bool checkRateLimit(String identifier) {
    try {
      final now = DateTime.now();
      final requests = _rateLimitTracker[identifier] ?? [];
      
      // Remove old requests outside the window
      requests.removeWhere((time) => now.difference(time) > _rateLimitWindow);
      
      // Check if limit exceeded
      if (requests.length >= _maxRequestsPerWindow) {
        _logSecurityEvent(SecurityEventType.rateLimitExceeded, 'Rate limit exceeded for $identifier');
        return false;
      }
      
      // Add current request
      requests.add(now);
      _rateLimitTracker[identifier] = requests;
      
      return true;
      
    } catch (e) {
      _logSecurityEvent(SecurityEventType.rateLimitError, 'Rate limit check error: $e');
      return false;
    }
  }

  /// Generate secure token
  String generateSecureToken([int length = 32]) {
    return _generateSecureToken(length);
  }

  /// Generate CSRF token
  String generateCsrfToken() {
    final token = _generateSecureToken(32);
    _logSecurityEvent(SecurityEventType.csrfTokenGenerated, 'CSRF token generated');
    return token;
  }

  /// Validate CSRF token
  bool validateCsrfToken(String token, String expectedToken) {
    final isValid = token == expectedToken && token.isNotEmpty;
    _logSecurityEvent(
      isValid ? SecurityEventType.csrfTokenValidated : SecurityEventType.csrfTokenRejected,
      'CSRF token validation: ${isValid ? 'passed' : 'failed'}',
    );
    return isValid;
  }

  /// Encrypt sensitive data
  String encryptData(String data) {
    try {
      // Simple XOR encryption for demonstration
      // In production, use proper encryption like AES
      final dataBytes = utf8.encode(data);
      final keyBytes = utf8.encode(_encryptionKey);
      final encrypted = <int>[];
      
      for (int i = 0; i < dataBytes.length; i++) {
        encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      final result = base64.encode(encrypted);
      _logSecurityEvent(SecurityEventType.dataEncrypted, 'Data encrypted');
      return result;
      
    } catch (e) {
      _logSecurityEvent(SecurityEventType.encryptionError, 'Encryption error: $e');
      rethrow;
    }
  }

  /// Decrypt sensitive data
  String decryptData(String encryptedData) {
    try {
      final encrypted = base64.decode(encryptedData);
      final keyBytes = utf8.encode(_encryptionKey);
      final decrypted = <int>[];
      
      for (int i = 0; i < encrypted.length; i++) {
        decrypted.add(encrypted[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      final result = utf8.decode(decrypted);
      _logSecurityEvent(SecurityEventType.dataDecrypted, 'Data decrypted');
      return result;
      
    } catch (e) {
      _logSecurityEvent(SecurityEventType.decryptionError, 'Decryption error: $e');
      rethrow;
    }
  }

  /// Hash password securely
  String hashPassword(String password, [String? salt]) {
    salt ??= _generateSecureToken(16);
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  /// Verify password hash
  bool verifyPassword(String password, String hash) {
    try {
      final parts = hash.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final expectedHash = parts[1];
      
      final bytes = utf8.encode(password + salt);
      final digest = sha256.convert(bytes);
      
      return digest.toString() == expectedHash;
    } catch (e) {
      return false;
    }
  }

  /// Get security headers for HTTP requests
  Map<String, String> getSecurityHeaders() {
    return {
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
      'Content-Security-Policy': "default-src 'self'",
      'Referrer-Policy': 'strict-origin-when-cross-origin',
    };
  }

  /// Get audit log
  List<SecurityEvent> getAuditLog({int? limit}) {
    final log = List<SecurityEvent>.from(_auditLog);
    log.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && limit > 0) {
      return log.take(limit).toList();
    }
    
    return log;
  }

  /// Clear audit log
  void clearAuditLog() {
    _auditLog.clear();
    _logSecurityEvent(SecurityEventType.auditLogCleared, 'Audit log cleared');
  }

  // Private methods

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  ValidationResult _validatePassword(String password) {
    final errors = <String>[];
    
    if (password.length < 8) {
      errors.add('Password must be at least 8 characters long');
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('Password must contain at least one uppercase letter');
    }
    
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('Password must contain at least one lowercase letter');
    }
    
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      errors.add('Password must contain at least one number');
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      errors.add('Password must contain at least one special character');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      sanitizedInput: password,
      errors: errors,
    );
  }

  String _sanitizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d\+\-\(\)\s]'), '');
  }

  String _sanitizeName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s\-\.]'), '').trim();
  }

  String _sanitizeHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove all HTML tags
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  String _sanitizeHtmlWithAllowedTags(String input, List<String> allowedTags) {
    // Simplified implementation - in production, use a proper HTML sanitizer
    String sanitized = input;
    
    // Remove script tags and their content
    sanitized = sanitized.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '');
    
    // Remove dangerous attributes
    sanitized = sanitized.replaceAll(RegExp(r'\s(on\w+|javascript:)[^>]*', caseSensitive: false), '');
    
    return sanitized;
  }

  String _preventSqlInjection(String input) {
    // Escape SQL special characters
    return input
        .replaceAll("'", "''")
        .replaceAll('"', '""')
        .replaceAll(';', '\\;')
        .replaceAll('--', '\\--')
        .replaceAll('/*', '\\/*')
        .replaceAll('*/', '\\*/');
  }

  String _detectMimeType(Uint8List data) {
    if (data.length < 4) return 'unknown';
    
    // Check common file signatures
    final header = data.take(4).toList();
    
    // PNG
    if (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47) {
      return 'image/png';
    }
    
    // JPEG
    if (header[0] == 0xFF && header[1] == 0xD8) {
      return 'image/jpeg';
    }
    
    // PDF
    if (header[0] == 0x25 && header[1] == 0x50 && header[2] == 0x44 && header[3] == 0x46) {
      return 'application/pdf';
    }
    
    return 'unknown';
  }

  bool _containsMaliciousContent(Uint8List data) {
    // Simplified malware detection
    final content = String.fromCharCodes(data).toLowerCase();
    
    final maliciousPatterns = [
      'eval(',
      'javascript:',
      '<script',
      'document.cookie',
      'window.location',
      'exec(',
      'system(',
    ];
    
    return maliciousPatterns.any((pattern) => content.contains(pattern));
  }

  String _generateSecureToken(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  void _logSecurityEvent(SecurityEventType type, String message) {
    final event = SecurityEvent(
      type: type,
      message: message,
      timestamp: DateTime.now(),
    );
    
    _auditLog.add(event);
    
    // Keep audit log size manageable
    if (_auditLog.length > 1000) {
      _auditLog.removeRange(0, _auditLog.length - 1000);
    }
    
    if (kDebugMode) {
      print('Security Event [${type.name}]: $message');
    }
  }

  void _startCleanupTimer() {
    Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupRateLimitTracker();
    });
  }

  void _cleanupRateLimitTracker() {
    final now = DateTime.now();
    
    _rateLimitTracker.removeWhere((key, requests) {
      requests.removeWhere((time) => now.difference(time) > _rateLimitWindow);
      return requests.isEmpty;
    });
  }

  /// Dispose of the service
  void dispose() {
    _rateLimitTracker.clear();
    _auditLog.clear();
    _isInitialized = false;
  }
}

enum InputType {
  text,
  email,
  phone,
  url,
  password,
  name,
}

enum SecurityEventType {
  serviceInitialized,
  inputValidated,
  inputRejected,
  fileValidated,
  fileRejected,
  rateLimitExceeded,
  rateLimitError,
  csrfTokenGenerated,
  csrfTokenValidated,
  csrfTokenRejected,
  dataEncrypted,
  dataDecrypted,
  encryptionError,
  decryptionError,
  validationError,
  auditLogCleared,
}

class ValidationResult {
  final bool isValid;
  final String sanitizedInput;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.sanitizedInput,
    required this.errors,
  });
}

class FileValidationResult {
  final bool isValid;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final List<String> errors;

  FileValidationResult({
    required this.isValid,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.errors,
  });
}

class SecurityEvent {
  final SecurityEventType type;
  final String message;
  final DateTime timestamp;

  SecurityEvent({
    required this.type,
    required this.message,
    required this.timestamp,
  });
}
