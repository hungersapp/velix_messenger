import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_keys.dart';

/// Platform secure storage (Android Keystore / iOS Keychain).
///
/// Stores only non-plaintext-secret session markers, device id, TOTP-enabled
/// flag, and recovery *flow* metadata. Never stores passwords, TOTP secrets,
/// or recovery keys.
class SecureStorageService {
  SecureStorageService({
    FlutterSecureStorage? storage,
    SharedPreferences? prefs,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            ),
        _prefsOverride = prefs;

  final FlutterSecureStorage _storage;
  final SharedPreferences? _prefsOverride;

  /// In-process guard so migrate / device-id paths do not re-hit prefs.
  bool _migrationCompleted = false;

  Future<SharedPreferences> get _prefs async {
    final override = _prefsOverride;
    if (override != null) return override;
    return SharedPreferences.getInstance();
  }

  // ─── Low-level helpers (corrupt / missing → safe defaults) ───────────────

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, st) {
      debugPrint('[SecureStorage] read failed for $key: $e\n$st');
      return null;
    }
  }

  Future<void> _write(String key, String? value) async {
    try {
      if (value == null || value.isEmpty) {
        await _storage.delete(key: key);
      } else {
        await _storage.write(key: key, value: value);
      }
    } catch (e, st) {
      debugPrint('[SecureStorage] write failed for $key: $e\n$st');
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e, st) {
      debugPrint('[SecureStorage] delete failed for $key: $e\n$st');
    }
  }

  // ─── Migration ───────────────────────────────────────────────────────────

  /// Moves legacy sensitive SharedPreferences values into secure storage once.
  Future<void> migrateFromLegacyPrefs() async {
    if (_migrationCompleted) return;
    try {
      final prefs = await _prefs;
      if (prefs.getBool(SecureStorageKeys.migrationFlagPrefs) == true) {
        _migrationCompleted = true;
        return;
      }

      final legacyDeviceId =
          prefs.getString(SecureStorageKeys.legacyDeviceIdPrefs);
      if (legacyDeviceId != null && legacyDeviceId.isNotEmpty) {
        final existing = await _read(SecureStorageKeys.deviceId);
        if (existing == null || existing.isEmpty) {
          await _write(SecureStorageKeys.deviceId, legacyDeviceId);
        }
        await prefs.remove(SecureStorageKeys.legacyDeviceIdPrefs);
      }

      await prefs.setBool(SecureStorageKeys.migrationFlagPrefs, true);
      _migrationCompleted = true;
    } catch (e, st) {
      debugPrint('[SecureStorage] migration failed: $e\n$st');
      // Do not block app start; retry on next launch.
    }
  }

  // ─── Device identifier ───────────────────────────────────────────────────

  Future<String> getOrCreateDeviceId() async {
    await migrateFromLegacyPrefs();

    final existing = await _read(SecureStorageKeys.deviceId);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    // Legacy fallback if migration did not run yet.
    try {
      final prefs = await _prefs;
      final legacy = prefs.getString(SecureStorageKeys.legacyDeviceIdPrefs);
      if (legacy != null && legacy.isNotEmpty) {
        await _write(SecureStorageKeys.deviceId, legacy);
        await prefs.remove(SecureStorageKeys.legacyDeviceIdPrefs);
        return legacy;
      }
    } catch (_) {}

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final id = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final deviceId = 'dev_$id';
    await _write(SecureStorageKeys.deviceId, deviceId);
    return deviceId;
  }

  // ─── Authentication state (markers only — not Firebase ID tokens) ────────

  Future<void> setAuthSession({required String uid}) async {
    if (uid.isEmpty) {
      await clearAuthSession();
      return;
    }
    await _write(SecureStorageKeys.authSessionUid, uid);
    await _write(SecureStorageKeys.authSessionActive, 'true');
  }

  Future<String?> getAuthSessionUid() =>
      _read(SecureStorageKeys.authSessionUid);

  Future<bool> isAuthSessionActive() async {
    final value = await _read(SecureStorageKeys.authSessionActive);
    return value == 'true';
  }

  Future<void> clearAuthSession() async {
    await _delete(SecureStorageKeys.authSessionUid);
    await _delete(SecureStorageKeys.authSessionActive);
  }

  // ─── TOTP enabled flag (boolean cache — never the TOTP secret) ───────────

  Future<void> setTotpEnabled(bool enabled) async {
    await _write(
      SecureStorageKeys.totpEnabled,
      enabled ? 'true' : 'false',
    );
  }

  Future<bool?> getTotpEnabled() async {
    final value = await _read(SecureStorageKeys.totpEnabled);
    if (value == null) return null;
    if (value == 'true') return true;
    if (value == 'false') return false;
    // Corrupted → treat as unknown.
    await _delete(SecureStorageKeys.totpEnabled);
    return null;
  }

  Future<void> clearTotpEnabled() => _delete(SecureStorageKeys.totpEnabled);

  // ─── Recovery flow temp (identifiers / steps only) ───────────────────────

  Future<void> saveRecoveryProgress({
    required String uid,
    required String velixId,
    required String username,
    required String step,
    required bool twoStepEnabled,
    required bool recoveryKeyVerified,
    required bool totpVerified,
  }) async {
    // Intentionally does NOT accept or store a recovery key / password / TOTP secret.
    await _write(SecureStorageKeys.recoveryAccountUid, uid);
    await _write(SecureStorageKeys.recoveryAccountVelixId, velixId);
    await _write(SecureStorageKeys.recoveryAccountUsername, username);
    await _write(SecureStorageKeys.recoveryStep, step);
    await _write(
      SecureStorageKeys.recoveryTwoStepEnabled,
      twoStepEnabled ? 'true' : 'false',
    );
    await _write(
      SecureStorageKeys.recoveryKeyVerified,
      recoveryKeyVerified ? 'true' : 'false',
    );
    await _write(
      SecureStorageKeys.recoveryTotpVerified,
      totpVerified ? 'true' : 'false',
    );
  }

  Future<RecoveryProgress?> readRecoveryProgress() async {
    try {
      final uid = await _read(SecureStorageKeys.recoveryAccountUid);
      final velixId = await _read(SecureStorageKeys.recoveryAccountVelixId);
      final step = await _read(SecureStorageKeys.recoveryStep);
      if (uid == null ||
          uid.isEmpty ||
          velixId == null ||
          velixId.isEmpty ||
          step == null ||
          step.isEmpty) {
        return null;
      }
      final username =
          await _read(SecureStorageKeys.recoveryAccountUsername) ?? '';
      final twoStep =
          await _read(SecureStorageKeys.recoveryTwoStepEnabled) == 'true';
      final keyVerified =
          await _read(SecureStorageKeys.recoveryKeyVerified) == 'true';
      final totpVerified =
          await _read(SecureStorageKeys.recoveryTotpVerified) == 'true';
      return RecoveryProgress(
        uid: uid,
        velixId: velixId,
        username: username,
        step: step,
        twoStepEnabled: twoStep,
        recoveryKeyVerified: keyVerified,
        totpVerified: totpVerified,
      );
    } catch (e, st) {
      debugPrint('[SecureStorage] readRecoveryProgress failed: $e\n$st');
      await clearRecoveryProgress();
      return null;
    }
  }

  Future<void> clearRecoveryProgress() async {
    await _delete(SecureStorageKeys.recoveryAccountUid);
    await _delete(SecureStorageKeys.recoveryAccountVelixId);
    await _delete(SecureStorageKeys.recoveryAccountUsername);
    await _delete(SecureStorageKeys.recoveryStep);
    await _delete(SecureStorageKeys.recoveryTwoStepEnabled);
    await _delete(SecureStorageKeys.recoveryKeyVerified);
    await _delete(SecureStorageKeys.recoveryTotpVerified);
  }

  /// Clears auth session markers, TOTP flag, and recovery progress.
  /// Does not wipe the durable device id.
  Future<void> clearSessionBound() async {
    await clearAuthSession();
    await clearTotpEnabled();
    await clearRecoveryProgress();
  }
}

/// Non-secret recovery flow snapshot for process restart resilience.
class RecoveryProgress {
  const RecoveryProgress({
    required this.uid,
    required this.velixId,
    required this.username,
    required this.step,
    required this.twoStepEnabled,
    required this.recoveryKeyVerified,
    required this.totpVerified,
  });

  final String uid;
  final String velixId;
  final String username;
  final String step;
  final bool twoStepEnabled;
  final bool recoveryKeyVerified;
  final bool totpVerified;
}
