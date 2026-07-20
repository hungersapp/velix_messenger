import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/auth_repository.dart';
import '../datasources/google_auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._googleAuthService,
  });

  final GoogleAuthService _googleAuthService;

  @override
  User? get currentUser => _googleAuthService.currentUser;

  @override
  Future<UserCredential?> signInWithGoogle() {
    return _googleAuthService.signInWithGoogle();
  }

  @override
  Future<void> signOut() {
    return _googleAuthService.signOut();
  }
}
