import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String velixId,
    required String recoverySecurityKey,
    required String newPassword,
  }) {
    return _repository.resetPassword(
      velixId: velixId,
      recoverySecurityKey: recoverySecurityKey,
      newPassword: newPassword,
    );
  }
}
