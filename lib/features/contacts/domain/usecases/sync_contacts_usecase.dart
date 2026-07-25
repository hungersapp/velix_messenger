import '../entities/contact_entity.dart';
import '../entities/friend_entity.dart';
import '../repositories/friends_repository.dart';

/// Time Capsule compatibility: friend list as [ContactEntity] projections.
///
/// Do not use for the Contacts UI — prefer [GetFriendsUseCase].
class SyncContactsUseCase {
  const SyncContactsUseCase(this._repository);

  final FriendsRepository _repository;

  Future<List<ContactEntity>> call() async {
    final friends = await _repository.getFriends();
    return friends.map(_toContact).toList();
  }

  ContactEntity _toContact(FriendEntity friend) {
    return ContactEntity(
      id: friend.uid,
      name: friend.displayName,
      phoneNumber: friend.velixId,
      photoUrl: friend.photoUrl.isEmpty ? null : friend.photoUrl,
      isVelixUser: true,
      uid: friend.uid,
    );
  }
}
