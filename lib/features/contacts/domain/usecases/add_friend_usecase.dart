import '../entities/friend_entity.dart';
import '../repositories/friends_repository.dart';

class AddFriendUseCase {
  const AddFriendUseCase(this._repository);

  final FriendsRepository _repository;

  Future<void> call({
    required FriendEntity friend,
    required FriendEntity selfProfile,
  }) {
    return _repository.addFriend(
      friend: friend,
      selfProfile: selfProfile,
    );
  }
}
