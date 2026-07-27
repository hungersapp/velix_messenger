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
    final computed = hash(recoverySecurityKey);
    if (computed.length != storedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < computed.length; i++) {
      diff |= computed.codeUnitAt(i) ^ storedHash.codeUnitAt(i);
    }
    return diff == 0;
  }
}
