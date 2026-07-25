import '../entities/discoverable_user_entity.dart';
import '../entities/friend_entity.dart';
import '../entities/friend_request_entity.dart';

abstract class FriendsRepository {
  Future<List<FriendEntity>> getFriends();

  Future<List<FriendEntity>> searchFriends(String query);

  Future<bool> isFriend(String friendUid);

  /// Bidirectional friendship; no-ops when already connected.
  Future<void> addFriend({
    required FriendEntity friend,
    required FriendEntity selfProfile,
  });

  Future<List<DiscoverableUserEntity>> searchDiscoverableUsers(String query);

  Future<List<FriendRequestEntity>> getIncomingRequests();

  Stream<List<FriendRequestEntity>> watchIncomingRequests();

  Future<bool> hasOutgoingRequest(String toUid);

  Future<void> sendFriendRequest({
    required FriendRequestEntity requestFromSenderView,
    required FriendRequestEntity requestForReceiverView,
  });

  Future<void> deleteFriendRequest({
    required String fromUid,
    required String toUid,
  });

  /// Reserved for future block list. Currently always empty.
  Future<Set<String>> getBlockedUserIds();
}
