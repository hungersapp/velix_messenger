import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/google_auth_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';

/// Google Auth Service
final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

/// Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    googleAuthService: ref.read(googleAuthServiceProvider),
  );
});

/// UseCase
final signInWithGoogleUseCaseProvider =
    Provider<SignInWithGoogleUseCase>((ref) {
  return SignInWithGoogleUseCase(
    ref.read(authRepositoryProvider),
  );
});

/// Authentication Provider
final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(
    ref.read(signInWithGoogleUseCaseProvider),
  ),
);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._signInWithGoogleUseCase)
      : super(const AsyncData(null));

  final SignInWithGoogleUseCase _signInWithGoogleUseCase;

  Future<UserCredential?> signInWithGoogle() async {
    state = const AsyncLoading();

    try {
      final credential = await _signInWithGoogleUseCase();

      state = const AsyncData(null);

      return credential;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return null;
    }
  }
}