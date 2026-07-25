/// A registered Velix user that can be discovered via search.
class DiscoverableUserEntity {
  const DiscoverableUserEntity({
    required this.uid,
    required this.displayName,
    required this.velixId,
    required this.photoUrl,
    required this.username,
    this.isFriend = false,
    this.hasOutgoingRequest = false,
  });

  final String uid;
  final String displayName;
  final String velixId;
  final String photoUrl;
  final String username;
  final bool isFriend;
  final bool hasOutgoingRequest;

  bool get canSendRequest => !isFriend && !hasOutgoingRequest;
}
