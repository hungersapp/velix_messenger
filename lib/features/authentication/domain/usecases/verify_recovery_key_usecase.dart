import '../repositories/auth_repository.dart';

class VerifyRecoveryKeyUseCase {
  const VerifyRecoveryKeyUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String velixId,
    required String recoverySecurityKey,
  }) {
    return _repository.verifyRecoveryKey(
      velixId: velixId,
      recoverySecurityKey: recoverySecurityKey,
    );
  }
}
