import '../../../authentication/data/datasources/velix_user_remote_datasource.dart';
import '../../../chat/domain/usecases/open_chat_usecase.dart';
import '../../../contacts/domain/entities/friend_entity.dart';
import '../../../contacts/domain/usecases/add_friend_usecase.dart';
import '../../../user/domain/entities/user_entity.dart';
import '../entities/velix_public_profile.dart';
import '../exceptions/velix_qr_exceptions.dart';
import '../services/velix_qr_payload.dart';

/// QR Connect: immediately creates friendship + conversation (no friend request).
class ConnectVelixUserUseCase {
  const ConnectVelixUserUseCase({
    required this.userDatasource,
    required this.addFriendUseCase,
    required this.openChatUseCase,
  });

  final VelixUserRemoteDatasource userDatasource;
  final AddFriendUseCase addFriendUseCase;
  final OpenChatUseCase openChatUseCase;

  Future<String> call({
    required UserEntity currentUser,
    required VelixPublicProfile peer,
  }) async {
    if (peer.uid.isEmpty || peer.velixId.trim().isEmpty) {
      throw VelixUserNotFoundException();
    }

    if (peer.uid == currentUser.uid) {
      throw CannotConnectSelfException();
    }

    final selfHandle = VelixQrPayload.displayHandle(currentUser.velixId);
    final peerHandle = VelixQrPayload.displayHandle(peer.velixId);

    if (selfHandle.isNotEmpty &&
        peerHandle.isNotEmpty &&
        selfHandle.toLowerCase() == peerHandle.toLowerCase()) {
      throw CannotConnectSelfException();
    }

    final live = await userDatasource.findByVelixId(peerHandle);
    if (live == null) {
      throw VelixUserNotFoundException();
    }

    final verified = VelixPublicProfile.fromFirestore(live);
    if (verified.uid.isEmpty || verified.uid != peer.uid) {
      throw VelixUserNotFoundException();
    }

    final now = DateTime.now();
    final verifiedHandle = VelixQrPayload.displayHandle(verified.velixId);

    await addFriendUseCase(
      friend: FriendEntity(
        uid: verified.uid,
        displayName: verified.displayName,
        velixId: verifiedHandle,
        photoUrl: verified.photoUrl,
        createdAt: now,
      ),
      selfProfile: FriendEntity(
        uid: currentUser.uid,
        displayName: currentUser.name,
        velixId: selfHandle,
        photoUrl: currentUser.photoUrl,
        createdAt: now,
      ),
    );

    return openChatUseCase(
      currentUserUid: currentUser.uid,
      otherUserUid: verified.uid,
    );
  }
}
