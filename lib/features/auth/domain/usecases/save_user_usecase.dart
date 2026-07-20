import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class SaveUserUseCase {
  final UserRepository repository;

  SaveUserUseCase(this.repository);

  Future<void> call(UserEntity user) async {
    await repository.saveUser(user);
  }
}