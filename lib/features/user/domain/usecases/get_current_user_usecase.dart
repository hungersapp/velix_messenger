import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final UserRepository _repository;

  Future<UserEntity?> call() async {
    return _repository.getCurrentUser();
  }
}