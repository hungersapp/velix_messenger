import '../entities/recovery_account.dart';
import '../repositories/auth_repository.dart';

class FindAccountForRecoveryUseCase {
  const FindAccountForRecoveryUseCase(this._repository);

  final AuthRepository _repository;

  Future<RecoveryAccount> call(String identifier) {
    return _repository.findAccountForRecovery(identifier);
  }
}
