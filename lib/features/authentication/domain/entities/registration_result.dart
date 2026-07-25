/// One-time registration output shown to the user after account creation.
class RegistrationResult {
  const RegistrationResult({
    required this.velixId,
    required this.recoverySecurityKey,
  });

  /// Permanent Velix User ID, e.g. `@murali007_VX8A4K2`.
  final String velixId;

  /// Plaintext recovery key — shown once, never persisted in plaintext.
  final String recoverySecurityKey;
}
