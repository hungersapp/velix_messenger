import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/velix_auth_service.dart';
import '../../data/datasources/velix_user_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/registration_request.dart';
import '../../domain/entities/registration_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/username_rules.dart';
import '../../domain/usecases/check_username_available_usecase.dart';
import '../../domain/usecases/register_with_velix_usecase.dart';
import '../../domain/usecases/sign_in_with_velix_usecase.dart';

final velixAuthServiceProvider = Provider<VelixAuthService>((ref) {
  return VelixAuthService();
});

final velixUserRemoteDatasourceProvider =
    Provider<VelixUserRemoteDatasource>((ref) {
  return VelixUserRemoteDatasource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authService: ref.read(velixAuthServiceProvider),
    userDatasource: ref.read(velixUserRemoteDatasourceProvider),
  );
});

final registerWithVelixUseCaseProvider =
    Provider<RegisterWithVelixUseCase>((ref) {
  return RegisterWithVelixUseCase(ref.read(authRepositoryProvider));
});

final signInWithVelixUseCaseProvider =
    Provider<SignInWithVelixUseCase>((ref) {
  return SignInWithVelixUseCase(ref.read(authRepositoryProvider));
});

final checkUsernameAvailableUseCaseProvider =
    Provider<CheckUsernameAvailableUseCase>((ref) {
  return CheckUsernameAvailableUseCase(ref.read(authRepositoryProvider));
});

enum UsernameAvailability {
  idle,
  invalid,
  checking,
  available,
  taken,
}

/// Authentication actions for Login / Registration screens.
final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(
    registerUseCase: ref.read(registerWithVelixUseCaseProvider),
    signInUseCase: ref.read(signInWithVelixUseCaseProvider),
    checkUsernameUseCase: ref.read(checkUsernameAvailableUseCaseProvider),
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier({
    required this.registerUseCase,
    required this.signInUseCase,
    required this.checkUsernameUseCase,
  }) : super(const AsyncData(null));

  final RegisterWithVelixUseCase registerUseCase;
  final SignInWithVelixUseCase signInUseCase;
  final CheckUsernameAvailableUseCase checkUsernameUseCase;

  UsernameAvailability usernameAvailability = UsernameAvailability.idle;

  Future<RegistrationResult?> register(RegistrationRequest request) async {
    state = const AsyncLoading();

    try {
      final result = await registerUseCase(request);
      state = const AsyncData(null);
      return result;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return null;
    }
  }

  Future<bool> signIn({
    required String velixId,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      await signInUseCase(velixId: velixId, password: password);
      state = const AsyncData(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  Future<UsernameAvailability> checkUsername(String username) async {
    final normalized = UsernameRules.normalize(username);
    if (!UsernameRules.isValid(normalized)) {
      usernameAvailability = UsernameAvailability.invalid;
      return usernameAvailability;
    }

    usernameAvailability = UsernameAvailability.checking;

    try {
      final available = await checkUsernameUseCase(normalized);
      usernameAvailability = available
          ? UsernameAvailability.available
          : UsernameAvailability.taken;
    } catch (_) {
      usernameAvailability = UsernameAvailability.idle;
    }

    return usernameAvailability;
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }
}
