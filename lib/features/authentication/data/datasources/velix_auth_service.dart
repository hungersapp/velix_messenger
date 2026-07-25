import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Auth operations for Velix ID + password accounts.
class VelixAuthService {
  VelixAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;

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

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<void> deleteCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
