import '../entities/friend_request_entity.dart';
import '../repositories/friends_repository.dart';

class WatchIncomingFriendRequestsUseCase {
  const WatchIncomingFriendRequestsUseCase(this._repository);

  final FriendsRepository _repository;

  Stream<List<FriendRequestEntity>> call() {
    return _repository.watchIncomingRequests();
  }
}
