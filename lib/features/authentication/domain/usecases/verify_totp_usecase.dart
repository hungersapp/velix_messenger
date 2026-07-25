import '../repositories/auth_repository.dart';

class VerifyTotpUseCase {
  const VerifyTotpUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String velixId,
    required String otp,
  }) {
    return _repository.verifyTotp(velixId: velixId, otp: otp);
  }
}
