import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  /// Returns the currently signed-in user.
  User? get currentUser;

  /// Sign in using Google.
  Future<UserCredential?> signInWithGoogle();

  /// Sign out the current user.
  Future<void> signOut();
}