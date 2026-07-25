import '../repositories/auth_repository.dart';

class SignInWithVelixUseCase {
  const SignInWithVelixUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String velixId,
    required String password,
  }) {
    return _repository.signInWithVelixId(
      velixId: velixId,
      password: password,
    );
  }
}
