import '../entities/discoverable_user_entity.dart';
import '../repositories/friends_repository.dart';

class SearchVelixUsersUseCase {
  const SearchVelixUsersUseCase(this._repository);

  final FriendsRepository _repository;

  Future<List<DiscoverableUserEntity>> call(String query) {
    return _repository.searchDiscoverableUsers(query);
  }
}
