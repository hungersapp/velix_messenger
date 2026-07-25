import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Hashes recovery security keys before persistence.
class RecoveryKeyHasher {
  const RecoveryKeyHasher();

  String hash(String recoverySecurityKey) {
    final bytes = utf8.encode(recoverySecurityKey.trim().toUpperCase());
    return sha256.convert(bytes).toString();
  }

  bool matches({
    required String recoverySecurityKey,
    required String storedHash,
  }) {
    return hash(recoverySecurityKey) == storedHash;
  }
}
