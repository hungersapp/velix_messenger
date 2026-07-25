/// Persisted Velix account profile written to Firestore at registration.
class VelixUser {
  const VelixUser({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.velixId,
    required this.recoverySecurityKeyHash,
    required this.passwordVault,
    required this.twoStepVerificationEnabled,
    this.totpSecret,
    required this.photoUrl,
    required this.about,
    required this.status,
    required this.notificationToken,
    required this.profileCompleted,
    required this.storyPrivacy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String displayName;

  /// Handle with leading `@`, e.g. `@murali007`.
  final String username;

  /// Permanent Velix User ID, e.g. `@murali007_VX8A4K2`.
  final String velixId;

  /// SHA-256 hash of the recovery security key.
  final String recoverySecurityKeyHash;

  /// Password sealed with the recovery security key for client-side reset.
  final String passwordVault;

  /// When true, recovery also requires Google Authenticator OTP.
  final bool twoStepVerificationEnabled;

  /// Base32 TOTP secret — present only when 2FA is enabled.
  final String? totpSecret;

  final String photoUrl;
  final String about;
  final String status;
  final String notificationToken;
  final bool profileCompleted;
  final String storyPrivacy;
  final DateTime createdAt;
  final DateTime updatedAt;
}
