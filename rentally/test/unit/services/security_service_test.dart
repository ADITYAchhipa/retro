import 'package:flutter_test/flutter_test.dart';
import 'package:rentally/core/services/security_service.dart';
import 'dart:typed_data';

void main() {
  group('SecurityService', () {
    late SecurityService service;

    setUp(() {
      service = SecurityService.instance;
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize successfully', () async {
      await service.initialize();
      expect(service, isNotNull);
    });

    test('should validate email input', () {
      final result = service.validateInput(
        'test@example.com',
        type: InputType.email,
      );
      
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('should reject invalid email', () {
      final result = service.validateInput(
        'invalid-email',
        type: InputType.email,
      );
      
      expect(result.isValid, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('should validate phone number', () {
      final result = service.validateInput(
        '+1234567890',
        type: InputType.phone,
      );
      
      expect(result.isValid, isTrue);
    });

    test('should validate password strength', () {
      final result = service.validateInput(
        'StrongPass123!',
        type: InputType.password,
      );
      
      expect(result.isValid, isTrue);
    });

    test('should reject weak password', () {
      final result = service.validateInput(
        'weak',
        type: InputType.password,
      );
      
      expect(result.isValid, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('should sanitize HTML input', () {
      final result = service.validateInput(
        '<script>alert("xss")</script>Hello',
        type: InputType.text,
      );
      
      expect(result.sanitizedInput, isNot(contains('<script>')));
    });

    test('should validate file upload', () {
      final fileData = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG header
      final result = service.validateFile(
        fileData,
        'test.png',
        allowedExtensions: ['png', 'jpg'],
        allowedMimeTypes: ['image/png'],
      );
      
      expect(result.isValid, isTrue);
    });

    test('should handle rate limiting', () {
      final allowed1 = service.checkRateLimit('test_user');
      expect(allowed1, isTrue);
      
      // Should still be allowed for reasonable requests
      final allowed2 = service.checkRateLimit('test_user');
      expect(allowed2, isTrue);
    });

    test('should generate secure tokens', () {
      final token1 = service.generateSecureToken(32);
      final token2 = service.generateSecureToken(32);
      
      expect(token1.length, equals(32));
      expect(token2.length, equals(32));
      expect(token1, isNot(equals(token2)));
    });

    test('should handle CSRF tokens', () {
      final token = service.generateCsrfToken();
      expect(token, isNotEmpty);
      
      final isValid = service.validateCsrfToken(token, token);
      expect(isValid, isTrue);
      
      final isInvalid = service.validateCsrfToken('wrong', token);
      expect(isInvalid, isFalse);
    });

    test('should encrypt and decrypt data', () {
      const originalData = 'sensitive information';
      
      final encrypted = service.encryptData(originalData);
      expect(encrypted, isNot(equals(originalData)));
      
      final decrypted = service.decryptData(encrypted);
      expect(decrypted, equals(originalData));
    });

    test('should hash and verify passwords', () {
      const password = 'mySecurePassword123!';
      
      final hash = service.hashPassword(password);
      expect(hash, isNot(equals(password)));
      
      final isValid = service.verifyPassword(password, hash);
      expect(isValid, isTrue);
      
      final isInvalid = service.verifyPassword('wrongPassword', hash);
      expect(isInvalid, isFalse);
    });

    test('should provide security headers', () {
      final headers = service.getSecurityHeaders();
      
      expect(headers, containsPair('X-Content-Type-Options', 'nosniff'));
      expect(headers, containsPair('X-Frame-Options', 'DENY'));
      expect(headers, containsPair('X-XSS-Protection', '1; mode=block'));
    });

    test('should maintain audit log', () {
      service.validateInput('test', type: InputType.text);
      
      final auditLog = service.getAuditLog(limit: 10);
      expect(auditLog, isNotEmpty);
    });
  });
}
