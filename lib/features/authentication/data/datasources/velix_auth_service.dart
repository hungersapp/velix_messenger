import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/security/session_security_gate.dart';

/// Firebase Auth operations for Velix ID + password accounts.
class VelixAuthService {
  VelixAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;

  /// Waits until Firebase Auth has restored any persisted session.
  ///
  /// Emits the current user (or `null` if signed out) once Auth is ready.
  Future<User?> waitForRestoredSession() {
    return _firebaseAuth.authStateChanges().first;
  }

  /// Synthetic email used as the Firebase Auth identifier for a Velix ID.
  static String authEmailForVelixId(String velixId) {
    final local = velixId.trim().toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9._+-]'),
          '_',
        );
    return '$local@users.velix.app';
  }

  Future<UserCredential> createAccount({
    required String authEmail,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: authEmail,
      password: password,
    );
  }

  Future<UserCredential> signIn({
    required String authEmail,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: authEmail,
      password: password,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }
    await user.updatePassword(newPassword);
  }

  Future<void> signOut() async {
    SessionSecurityGate.clear();
    try {
      await SecureStorageService().clearSessionBound();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }

  Future<void> deleteCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
