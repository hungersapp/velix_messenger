import '../entities/registration_request.dart';
import '../entities/registration_result.dart';
import '../repositories/auth_repository.dart';

class RegisterWithVelixUseCase {
  const RegisterWithVelixUseCase(this._repository);

  final AuthRepository _repository;

  Future<RegistrationResult> call(RegistrationRequest request) {
    return _repository.register(request);
  }
}
