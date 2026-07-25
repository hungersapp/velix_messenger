import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/recovery_account.dart';
import '../../domain/entities/registration_request.dart';
import '../../domain/entities/registration_result.dart';
import '../../domain/entities/velix_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/password_rules.dart';
import '../../domain/services/password_vault.dart';
import '../../domain/services/recovery_key_generator.dart';
import '../../domain/services/recovery_key_hasher.dart';
import '../../domain/services/username_rules.dart';
import '../../domain/services/velix_id_generator.dart';
import '../datasources/velix_auth_service.dart';
import '../datasources/velix_user_remote_datasource.dart';
import '../models/velix_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.authService,
    required this.userDatasource,
    VelixIdGenerator? velixIdGenerator,
    RecoveryKeyGenerator? recoveryKeyGenerator,
    RecoveryKeyHasher? recoveryKeyHasher,
    PasswordVault? passwordVault,
    TotpVerifier? totpVerifier,
  })  : velixIdGenerator = velixIdGenerator ?? VelixIdGenerator(),
        recoveryKeyGenerator =
            recoveryKeyGenerator ?? RecoveryKeyGenerator(),
        recoveryKeyHasher = recoveryKeyHasher ?? const RecoveryKeyHasher(),
        passwordVault = passwordVault ?? const PasswordVault(),
        totpVerifier = totpVerifier ?? const TotpVerifier();

  final VelixAuthService authService;
  final VelixUserRemoteDatasource userDatasource;
  final VelixIdGenerator velixIdGenerator;
  final RecoveryKeyGenerator recoveryKeyGenerator;
  final RecoveryKeyHasher recoveryKeyHasher;
  final PasswordVault passwordVault;
  final TotpVerifier totpVerifier;

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final normalized = UsernameRules.normalize(username);
    if (!UsernameRules.isValid(normalized)) {
      return false;
    }
    return !(await userDatasource.isUsernameTaken(normalized));
  }

  @override
  Future<RegistrationResult> register(RegistrationRequest request) async {
    final displayName = request.displayName.trim();
    final username = UsernameRules.normalize(request.username);
    final password = request.password;

    _validateRegistration(
      displayName: displayName,
      username: username,
      password: password,
      ageConfirmed: request.ageConfirmed,
    );

    if (await userDatasource.isUsernameTaken(username)) {
      throw Exception('Username is already taken');
    }

    final velixId = await _generateUniqueVelixId(username);
    final recoveryKey = recoveryKeyGenerator.generate();
    final recoveryHash = recoveryKeyHasher.hash(recoveryKey);
    final sealedPassword = passwordVault.seal(
      password: password,
      recoverySecurityKey: recoveryKey,
    );
    final authEmail = VelixAuthService.authEmailForVelixId(velixId);

    UserCredential credential;
    try {
      credential = await authService.createAccount(
        authEmail: authEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    }

    final uid = credential.user?.uid;
    if (uid == null) {
      throw Exception('Failed to create account');
    }

    final now = DateTime.now();
    final user = VelixUser(
      uid: uid,
      displayName: displayName,
      username: username,
      velixId: velixId,
      recoverySecurityKeyHash: recoveryHash,
      passwordVault: sealedPassword,
      twoStepVerificationEnabled: false,
      totpSecret: null,
      photoUrl: '',
      about: '',
      status: 'active',
      notificationToken: '',
      profileCompleted: true,
      storyPrivacy: 'everyone',
      createdAt: now,
      updatedAt: now,
    );

    try {
      await userDatasource.saveUser(VelixUserModel.fromEntity(user));
    } catch (_) {
      try {
        await authService.deleteCurrentUser();
      } catch (_) {}
      rethrow;
    }

    await authService.signOut();

    return RegistrationResult(
      velixId: velixId,
      recoverySecurityKey: recoveryKey,
    );
  }

  @override
  Future<void> signInWithVelixId({
    required String velixId,
    required String password,
  }) async {
    var normalizedId = _normalizeVelixId(velixId);
    if (normalizedId.isEmpty) {
      throw Exception('Enter your Velix ID');
    }
    if (password.isEmpty) {
      throw Exception('Enter your password');
    }

    if (!_looksLikeVelixUserId(normalizedId)) {
      final profile = await userDatasource.findByUsername(normalizedId);
      final resolved = profile?['velixId'] as String?;
      if (resolved == null || resolved.isEmpty) {
        throw Exception('Invalid Velix ID or password');
      }
      normalizedId = resolved;
    }

    final authEmail = VelixAuthService.authEmailForVelixId(normalizedId);

    try {
      await authService.signIn(authEmail: authEmail, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    }
  }

  @override
  Future<RecoveryAccount> findAccountForRecovery(String identifier) async {
    final normalized = _normalizeVelixId(identifier);
    if (normalized.isEmpty) {
      throw Exception('Invalid username');
    }

    final body = normalized.substring(1);
    if (body.isEmpty) {
      throw Exception('Invalid username');
    }

    final profile = await userDatasource.findByIdentifier(normalized);
    if (profile == null) {
      throw Exception('Account not found');
    }

    final velixId = profile['velixId'] as String? ?? '';
    final username = profile['username'] as String? ?? '';
    final uid = profile['uid'] as String? ?? '';
    if (velixId.isEmpty || uid.isEmpty) {
      throw Exception('Account not found');
    }

    return RecoveryAccount(
      uid: uid,
      velixId: velixId,
      username: username,
      twoStepVerificationEnabled:
          profile['twoStepVerificationEnabled'] as bool? ?? false,
    );
  }

  @override
  Future<void> verifyRecoveryKey({
    required String velixId,
    required String recoverySecurityKey,
  }) async {
    final profile = await _requireProfile(velixId);
    final storedHash = profile['recoverySecurityKey'] as String? ?? '';
    final key = recoverySecurityKey.trim();

    if (key.isEmpty ||
        !recoveryKeyHasher.matches(
          recoverySecurityKey: key,
          storedHash: storedHash,
        )) {
      throw Exception('Invalid Recovery Security Key');
    }
  }

  @override
  Future<void> verifyTotp({
    required String velixId,
    required String otp,
  }) async {
    final profile = await _requireProfile(velixId);
    final enabled = profile['twoStepVerificationEnabled'] as bool? ?? false;
    if (!enabled) {
      return;
    }

    final secret = profile['totpSecret'] as String? ?? '';
    if (secret.isEmpty) {
      throw Exception('Two-Step Verification is misconfigured');
    }

    final valid = totpVerifier.verify(secretBase32: secret, otp: otp);
    if (!valid) {
      throw Exception('Invalid Google Authenticator OTP');
    }
  }

  @override
  Future<void> resetPassword({
    required String velixId,
    required String recoverySecurityKey,
    required String newPassword,
  }) async {
    final passwordError = PasswordRules.validationError(newPassword);
    if (passwordError != null) {
      throw Exception(passwordError);
    }
    if (PasswordRules.strengthOf(newPassword) != PasswordStrength.strong) {
      throw Exception('Weak password');
    }

    await verifyRecoveryKey(
      velixId: velixId,
      recoverySecurityKey: recoverySecurityKey,
    );

    final profile = await _requireProfile(velixId);
    final sealed = profile['passwordVault'] as String? ?? '';
    if (sealed.isEmpty) {
      throw Exception(
        'Password recovery is unavailable for this account. '
        'Please contact support.',
      );
    }

    final uid = profile['uid'] as String? ?? '';
    final currentPassword = passwordVault.open(
      sealedPassword: sealed,
      recoverySecurityKey: recoverySecurityKey,
    );

    final authEmail = VelixAuthService.authEmailForVelixId(velixId);

    try {
      await authService.signIn(
        authEmail: authEmail,
        password: currentPassword,
      );
      await authService.updatePassword(newPassword);

      final resealed = passwordVault.seal(
        password: newPassword,
        recoverySecurityKey: recoverySecurityKey,
      );
      await userDatasource.updatePasswordVault(
        uid: uid,
        passwordVault: resealed,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } finally {
      try {
        await authService.signOut();
      } catch (_) {}
    }
  }

  @override
  Future<void> signOut() => authService.signOut();

  Future<Map<String, dynamic>> _requireProfile(String velixId) async {
    final normalized = _normalizeVelixId(velixId);
    final profile = await userDatasource.findByVelixId(normalized);
    if (profile == null) {
      throw Exception('Account not found');
    }
    return profile;
  }

  bool _looksLikeVelixUserId(String value) {
    return RegExp(r'_VX[A-Z0-9]+$', caseSensitive: false).hasMatch(value);
  }

  Future<String> _generateUniqueVelixId(String username) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final candidate = velixIdGenerator.generate(username);
      if (!await userDatasource.isVelixIdTaken(candidate)) {
        return candidate;
      }
    }
    throw Exception('Could not generate a unique Velix ID. Please try again.');
  }

  String _normalizeVelixId(String velixId) {
    var value = velixId.trim();
    if (value.isEmpty) return '';
    value = value.replaceFirst(RegExp(r'^@+'), '');
    if (value.isEmpty) return '';
    return '@$value';
  }

  void _validateRegistration({
    required String displayName,
    required String username,
    required String password,
    required bool ageConfirmed,
  }) {
    if (displayName.isEmpty) {
      throw Exception('Enter your display name');
    }
    if (displayName.length > 40) {
      throw Exception('Display name must be 40 characters or fewer');
    }
    if (!UsernameRules.isValid(username)) {
      throw Exception(
        'Username must be @ followed by 3–20 characters '
        '(lowercase letters, numbers, underscore)',
      );
    }
    final passwordError = PasswordRules.validationError(password);
    if (passwordError != null) {
      throw Exception(passwordError);
    }
    if (!ageConfirmed) {
      throw Exception('Confirm that you are 18 years or older');
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for this Velix ID';
      case 'invalid-email':
        return 'Invalid Velix ID';
      case 'weak-password':
        return 'Weak password';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid Velix ID or password';
      case 'requires-recent-login':
        return 'Please try password recovery again';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
