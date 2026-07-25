/// A pending Velix friend request (incoming or outgoing).
class FriendRequestEntity {
  const FriendRequestEntity({
    required this.fromUid,
    required this.toUid,
    required this.displayName,
    required this.velixId,
    required this.photoUrl,
    required this.username,
    required this.createdAt,
    this.status = FriendRequestStatus.pending,
  });

  final String fromUid;
  final String toUid;
  final String displayName;
  final String velixId;
  final String photoUrl;
  final String username;
  final DateTime createdAt;
  final FriendRequestStatus status;
}

enum FriendRequestStatus { pending }
