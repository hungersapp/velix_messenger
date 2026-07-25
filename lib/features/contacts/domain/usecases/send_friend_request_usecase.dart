import '../../../user/domain/entities/user_entity.dart';
import '../entities/discoverable_user_entity.dart';
import '../entities/friend_request_entity.dart';
import '../exceptions/friend_request_exceptions.dart';
import '../repositories/friends_repository.dart';
import '../../../profile/domain/services/velix_qr_payload.dart';

class SendFriendRequestUseCase {
  const SendFriendRequestUseCase(this._repository);

  final FriendsRepository _repository;

  Future<void> call({
    required UserEntity currentUser,
    required DiscoverableUserEntity target,
  }) async {
    if (target.uid.isEmpty || target.uid == currentUser.uid) {
      throw CannotRequestSelfException();
    }

    if (await _repository.isFriend(target.uid)) {
      throw AlreadyFriendsException();
    }

    if (await _repository.hasOutgoingRequest(target.uid)) {
      throw FriendRequestAlreadySentException();
    }

    final now = DateTime.now();
    final selfHandle = VelixQrPayload.displayHandle(currentUser.velixId);
    final peerHandle = VelixQrPayload.displayHandle(target.velixId);
    final selfUsername = _usernameFromVelixId(selfHandle);
    final peerUsername = target.username.isNotEmpty
        ? target.username
        : _usernameFromVelixId(peerHandle);

    // Outgoing doc stores the receiver's profile for the sender's records.
    final outgoing = FriendRequestEntity(
      fromUid: currentUser.uid,
      toUid: target.uid,
      displayName: target.displayName,
      velixId: peerHandle,
      photoUrl: target.photoUrl,
      username: peerUsername,
      createdAt: now,
    );

    // Incoming doc stores the sender's profile for the receiver's inbox.
    final incoming = FriendRequestEntity(
      fromUid: currentUser.uid,
      toUid: target.uid,
      displayName: currentUser.name,
      velixId: selfHandle,
      photoUrl: currentUser.photoUrl,
      username: selfUsername,
      createdAt: now,
    );

    await _repository.sendFriendRequest(
      requestFromSenderView: outgoing,
      requestForReceiverView: incoming,
    );
  }

  String _usernameFromVelixId(String velixId) {
    final handle = VelixQrPayload.displayHandle(velixId);
    final vx = handle.lastIndexOf('_VX');
    if (vx > 0) return handle.substring(0, vx);
    return handle;
  }
}
