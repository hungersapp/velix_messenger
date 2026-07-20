import '../repositories/user_repository.dart';

class CheckMobileExistsUseCase {
  final UserRepository repository;

  CheckMobileExistsUseCase(this.repository);

  Future<bool> call(String mobile) async {
    return repository.isMobileExists(mobile);
  }
}