import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// Seals the account password with the Recovery Security Key so password
/// reset can re-authenticate to Firebase Auth without email/SMS.
class PasswordVault {
  const PasswordVault();

  /// Returns a portable ciphertext string for Firestore.
  String seal({
    required String password,
    required String recoverySecurityKey,
  }) {
    final key = encrypt.Key(Uint8List.fromList(
      sha256.convert(utf8.encode(recoverySecurityKey.trim().toUpperCase())).bytes,
    ));
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(password, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  String open({
    required String sealedPassword,
    required String recoverySecurityKey,
  }) {
    final parts = sealedPassword.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid Recovery Security Key');
    }

    final key = encrypt.Key(Uint8List.fromList(
      sha256.convert(utf8.encode(recoverySecurityKey.trim().toUpperCase())).bytes,
    ));
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    try {
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (_) {
      throw Exception('Invalid Recovery Security Key');
    }
  }
}

/// RFC 6238 TOTP verifier for Google Authenticator.
class TotpVerifier {
  const TotpVerifier();

  bool verify({
    required String secretBase32,
    required String otp,
    int window = 1,
  }) {
    final code = otp.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return false;
    }

    final secret = _decodeBase32(secretBase32.trim().toUpperCase());
    if (secret.isEmpty) return false;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timestep = now ~/ 30;

    for (var i = -window; i <= window; i++) {
      final candidate = _generateTotp(secret, timestep + i);
      if (candidate == code) return true;
    }
    return false;
  }

  String _generateTotp(List<int> secret, int timestep) {
    final data = ByteData(8)..setInt64(0, timestep);
    final hmac = Hmac(sha1, secret);
    final hash = hmac.convert(data.buffer.asUint8List()).bytes;
    final offset = hash[hash.length - 1] & 0x0f;
    final binary =
        ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);
    final otp = binary % 1000000;
    return otp.toString().padLeft(6, '0');
  }

  List<int> _decodeBase32(String input) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final cleaned = input.replaceAll('=', '').replaceAll(' ', '');
    var buffer = 0;
    var bitsLeft = 0;
    final output = <int>[];

    for (final rune in cleaned.runes) {
      final char = String.fromCharCode(rune);
      final val = alphabet.indexOf(char);
      if (val < 0) return [];
      buffer = (buffer << 5) | val;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        output.add((buffer >> (bitsLeft - 8)) & 0xff);
        bitsLeft -= 8;
      }
    }
    return output;
  }
}

/// Generates a random Base32 secret for future 2FA enrollment.
class TotpSecretGenerator {
  TotpSecretGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  String generate({int length = 16}) {
    return List.generate(
      length,
      (_) => _alphabet[_random.nextInt(_alphabet.length)],
    ).join();
  }
}
