import '../repositories/friends_repository.dart';

class DeclineFriendRequestUseCase {
  const DeclineFriendRequestUseCase(this._repository);

  final FriendsRepository _repository;

  Future<void> call({
    required String fromUid,
    required String toUid,
  }) {
    return _repository.deleteFriendRequest(fromUid: fromUid, toUid: toUid);
  }
}
