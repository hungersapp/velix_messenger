import '../entities/recovery_account.dart';
import '../entities/registration_request.dart';
import '../entities/registration_result.dart';

abstract class AuthRepository {
  /// Returns true when [username] (with or without `@`) is available.
  Future<bool> isUsernameAvailable(String username);

  /// Creates Firebase Auth credentials, generates Velix User ID + recovery key,
  /// writes the user record to Firestore, then signs out.
  Future<RegistrationResult> register(RegistrationRequest request);

  /// Authenticates with permanent Velix User ID + password.
  Future<void> signInWithVelixId({
    required String velixId,
    required String password,
  });

  /// Resolves username or Velix User ID for password recovery.
  Future<RecoveryAccount> findAccountForRecovery(String identifier);

  /// Verifies the Recovery Security Key for the given Velix User ID.
  Future<void> verifyRecoveryKey({
    required String velixId,
    required String recoverySecurityKey,
  });

  /// Verifies Google Authenticator OTP when two-step verification is enabled.
  Future<void> verifyTotp({
    required String velixId,
    required String otp,
  });

  /// Resets the Firebase Auth password after recovery verification.
  Future<void> resetPassword({
    required String velixId,
    required String recoverySecurityKey,
    required String newPassword,
  });

  /// Signs out the current Firebase Auth session.
  Future<void> signOut();
}
