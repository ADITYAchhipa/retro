import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:shared_preferences/shared_preferences.dart';

class TwoFactorService {
  TwoFactorService._();
  static final TwoFactorService instance = TwoFactorService._();

  static const _enabledKey = 'two_factor_enabled_v1';
  static const _secretKey = 'two_factor_secret_v1';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
    }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<String> getOrCreateSecret() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_secretKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final secret = _generateBase32Secret(length: 32);
    await prefs.setString(_secretKey, secret);
    return secret;
  }

  Future<String?> getSecret() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_secretKey);
  }

  Future<void> regenerateSecret() async {
    final prefs = await SharedPreferences.getInstance();
    final secret = _generateBase32Secret(length: 32);
    await prefs.setString(_secretKey, secret);
  }

  String buildOtpAuthUri({
    required String issuer,
    required String accountName,
    required String secretBase32,
    int digits = 6,
    int period = 30,
    String algorithm = 'SHA1',
  }) {
    final label = Uri.encodeComponent('$issuer:$accountName');
    final secret = secretBase32.toUpperCase();
    final query = 'secret=$secret&issuer=${Uri.encodeComponent(issuer)}&algorithm=$algorithm&digits=$digits&period=$period';
    return 'otpauth://totp/$label?$query';
  }

  Future<bool> verifyCode(String code, {int digits = 6, int period = 30, int allowedDriftSteps = 1}) async {
    final secret = await getSecret();
    if (secret == null || secret.isEmpty) return false;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final counter = nowSeconds ~/ period;

    for (int drift = -allowedDriftSteps; drift <= allowedDriftSteps; drift++) {
      final value = _generateTotp(secret, counter + drift, digits: digits, period: period);
      if (value == code.padLeft(digits, '0')) return true;
    }
    return false;
  }

  // --- Internal helpers ---
  String _generateBase32Secret({int length = 32}) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final rng = Random.secure();
    final sb = StringBuffer();
    for (int i = 0; i < length; i++) {
      sb.write(alphabet[rng.nextInt(alphabet.length)]);
    }
    return sb.toString();
  }

  String _generateTotp(String base32Secret, int counter, {int digits = 6, int period = 30}) {
    // Convert counter to 8-byte array (big-endian)
    final counterBytes = Uint8List(8);
    var c = counter;
    for (int i = 7; i >= 0; i--) {
      counterBytes[i] = c & 0xFF;
      c >>= 8;
    }

    final key = _base32Decode(base32Secret);
    final hmac = crypto.Hmac(crypto.sha1, key);
    final hash = hmac.convert(counterBytes).bytes;

    // Dynamic truncation
    final offset = hash[hash.length - 1] & 0x0F;
    var binary = ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);

    final otp = binary % pow(10, digits).toInt();
    return otp.toString().padLeft(digits, '0');
  }

  List<int> _base32Decode(String input) {
    final clean = input.replaceAll('=', '').toUpperCase();
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final buffer = <int>[];

    int bits = 0;
    int value = 0;

    for (int i = 0; i < clean.length; i++) {
      final ch = clean[i];
      final idx = alphabet.indexOf(ch);
      if (idx < 0) continue; // ignore invalid
      value = (value << 5) | idx;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        buffer.add((value >> bits) & 0xFF);
      }
    }
    return buffer;
  }
}
