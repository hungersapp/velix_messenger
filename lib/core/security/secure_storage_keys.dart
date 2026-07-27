/// Keys for [SecureStorageService]. Never store plaintext passwords,
/// TOTP secrets, or recovery keys under these (or any) keys.
abstract final class SecureStorageKeys {
  static const deviceId = 'velix_device_id';
  static const authSessionUid = 'velix_auth_session_uid';
  static const authSessionActive = 'velix_auth_session_active';
  static const totpEnabled = 'velix_totp_enabled';

  /// Non-secret recovery flow markers only (no recovery key / password).
  static const recoveryAccountUid = 'velix_recovery_account_uid';
  static const recoveryAccountVelixId = 'velix_recovery_account_velix_id';
  static const recoveryAccountUsername = 'velix_recovery_account_username';
  static const recoveryStep = 'velix_recovery_step';
  static const recoveryKeyVerified = 'velix_recovery_key_verified';
  static const recoveryTotpVerified = 'velix_recovery_totp_verified';
  static const recoveryTwoStepEnabled = 'velix_recovery_two_step_enabled';

  /// SharedPreferences bookkeeping for one-time migration.
  static const migrationFlagPrefs = 'velix_secure_storage_migrated_v1';
  static const legacyDeviceIdPrefs = 'velix_device_id';
}
