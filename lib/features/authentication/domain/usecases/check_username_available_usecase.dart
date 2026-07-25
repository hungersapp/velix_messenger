import '../repositories/auth_repository.dart';

class CheckUsernameAvailableUseCase {
  const CheckUsernameAvailableUseCase(this._repository);

  final AuthRepository _repository;

  Future<bool> call(String username) {
    return _repository.isUsernameAvailable(username);
  }
}
