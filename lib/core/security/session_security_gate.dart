/// In-memory session security flags for the current app process.
///
/// Used to ensure TOTP (when enabled) is completed before protected routes
/// are usable after a cold start or login. Cleared on sign-out.
class SessionSecurityGate {
  SessionSecurityGate._();

  static bool _secondFactorVerified = false;

  /// True once 2FA has been satisfied this process (or is disabled for the user).
  static bool get isSecondFactorVerified => _secondFactorVerified;

  static void markSecondFactorVerified() {
    _secondFactorVerified = true;
  }

  static void clear() {
    _secondFactorVerified = false;
  }
}
