import '../entities/friend_entity.dart';
import '../repositories/friends_repository.dart';

class GetFriendsUseCase {
  const GetFriendsUseCase(this._repository);

  final FriendsRepository _repository;

  Future<List<FriendEntity>> call() => _repository.getFriends();
}
