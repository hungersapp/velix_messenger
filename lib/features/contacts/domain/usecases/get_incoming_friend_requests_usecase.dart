import '../entities/friend_request_entity.dart';
import '../repositories/friends_repository.dart';

class GetIncomingFriendRequestsUseCase {
  const GetIncomingFriendRequestsUseCase(this._repository);

  final FriendsRepository _repository;

  Future<List<FriendRequestEntity>> call() {
    return _repository.getIncomingRequests();
  }
}
