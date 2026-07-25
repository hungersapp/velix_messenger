import '../../domain/entities/discoverable_user_entity.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/entities/friend_request_entity.dart';
import '../../domain/repositories/friends_repository.dart';
import '../datasources/friend_requests_remote_datasource.dart';
import '../datasources/friends_remote_datasource.dart';
import '../datasources/user_discovery_remote_datasource.dart';
import '../models/friend_model.dart';
import '../models/friend_request_model.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  FriendsRepositoryImpl({
    required this.remoteDataSource,
    required this.requestsRemoteDataSource,
    required this.discoveryRemoteDataSource,
  });

  final FriendsRemoteDataSource remoteDataSource;
  final FriendRequestsRemoteDataSource requestsRemoteDataSource;
  final UserDiscoveryRemoteDataSource discoveryRemoteDataSource;

  @override
  Future<List<FriendEntity>> getFriends() async {
    final friends = await remoteDataSource.getFriends();
    return friends.map((f) => f.toEntity()).toList();
  }

  @override
  Future<List<FriendEntity>> searchFriends(String query) async {
    final friends = await getFriends();
    final search = query.trim().toLowerCase();
    if (search.isEmpty) return friends;

    return friends.where((friend) {
      return friend.displayName.toLowerCase().contains(search) ||
          friend.velixId.toLowerCase().contains(search);
    }).toList();
  }

  @override
  Future<bool> isFriend(String friendUid) {
    return remoteDataSource.isFriend(friendUid);
  }

  @override
  Future<void> addFriend({
    required FriendEntity friend,
    required FriendEntity selfProfile,
  }) {
    return remoteDataSource.addFriend(
      friend: FriendModel(
        uid: friend.uid,
        displayName: friend.displayName,
        velixId: friend.velixId,
        photoUrl: friend.photoUrl,
        createdAt: friend.createdAt,
        isOnline: friend.isOnline,
      ),
      selfProfile: FriendModel(
        uid: selfProfile.uid,
        displayName: selfProfile.displayName,
        velixId: selfProfile.velixId,
        photoUrl: selfProfile.photoUrl,
        createdAt: selfProfile.createdAt,
        isOnline: selfProfile.isOnline,
      ),
    );
  }

  @override
  Future<List<DiscoverableUserEntity>> searchDiscoverableUsers(
    String query,
  ) async {
    final raw = await discoveryRemoteDataSource.searchUsers(query);
    if (raw.isEmpty) return const [];

    final friends = await getFriends();
    final friendIds = friends.map((f) => f.uid).toSet();
    final blocked = await getBlockedUserIds();

    // One outgoing-request snapshot to avoid N+1 lookups.
    final outgoingIds = <String>{};
    for (final user in raw) {
      if (friendIds.contains(user.uid) || blocked.contains(user.uid)) {
        continue;
      }
      if (await requestsRemoteDataSource.hasOutgoingRequest(user.uid)) {
        outgoingIds.add(user.uid);
      }
    }

    return raw
        .where(
          (user) =>
              !blocked.contains(user.uid) && !friendIds.contains(user.uid),
        )
        .map(
          (user) => DiscoverableUserEntity(
            uid: user.uid,
            displayName: user.displayName,
            velixId: user.velixId,
            photoUrl: user.photoUrl,
            username: user.username,
            isFriend: false,
            hasOutgoingRequest: outgoingIds.contains(user.uid),
          ),
        )
        .toList();
  }

  @override
  Future<List<FriendRequestEntity>> getIncomingRequests() async {
    final requests = await requestsRemoteDataSource.getIncomingRequests();
    return requests.map((r) => r.toEntity()).toList();
  }

  @override
  Stream<List<FriendRequestEntity>> watchIncomingRequests() {
    return requestsRemoteDataSource.watchIncomingRequests().map(
          (requests) => requests.map((r) => r.toEntity()).toList(),
        );
  }

  @override
  Future<bool> hasOutgoingRequest(String toUid) {
    return requestsRemoteDataSource.hasOutgoingRequest(toUid);
  }

  @override
  Future<void> sendFriendRequest({
    required FriendRequestEntity requestFromSenderView,
    required FriendRequestEntity requestForReceiverView,
  }) {
    return requestsRemoteDataSource.sendRequest(
      outgoingPayload: FriendRequestModel(
        fromUid: requestFromSenderView.fromUid,
        toUid: requestFromSenderView.toUid,
        displayName: requestFromSenderView.displayName,
        velixId: requestFromSenderView.velixId,
        photoUrl: requestFromSenderView.photoUrl,
        username: requestFromSenderView.username,
        createdAt: requestFromSenderView.createdAt,
      ),
      incomingPayload: FriendRequestModel(
        fromUid: requestForReceiverView.fromUid,
        toUid: requestForReceiverView.toUid,
        displayName: requestForReceiverView.displayName,
        velixId: requestForReceiverView.velixId,
        photoUrl: requestForReceiverView.photoUrl,
        username: requestForReceiverView.username,
        createdAt: requestForReceiverView.createdAt,
      ),
    );
  }

  @override
  Future<void> deleteFriendRequest({
    required String fromUid,
    required String toUid,
  }) {
    return requestsRemoteDataSource.deleteRequest(
      fromUid: fromUid,
      toUid: toUid,
    );
  }

  @override
  Future<Set<String>> getBlockedUserIds() async {
    // Future support — block list not implemented yet.
    return const <String>{};
  }
}
