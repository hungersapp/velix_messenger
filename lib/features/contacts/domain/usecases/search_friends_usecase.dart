import '../entities/friend_entity.dart';
import '../repositories/friends_repository.dart';

class SearchFriendsUseCase {
  const SearchFriendsUseCase(this._repository);

  final FriendsRepository _repository;

  Future<List<FriendEntity>> call(String query) {
    return _repository.searchFriends(query);
  }
}
