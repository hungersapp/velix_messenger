import '../../../chat/domain/usecases/open_chat_usecase.dart';
import '../../../user/domain/entities/user_entity.dart';
import '../entities/friend_entity.dart';
import '../entities/friend_request_entity.dart';
import '../exceptions/friend_request_exceptions.dart';
import '../repositories/friends_repository.dart';
import 'add_friend_usecase.dart';

class AcceptFriendRequestUseCase {
  const AcceptFriendRequestUseCase({
    required this.repository,
    required this.addFriendUseCase,
    required this.openChatUseCase,
  });

  final FriendsRepository repository;
  final AddFriendUseCase addFriendUseCase;
  final OpenChatUseCase openChatUseCase;

  /// Accepts [request] (incoming for [currentUser]) and returns conversation id.
  Future<String> call({
    required UserEntity currentUser,
    required FriendRequestEntity request,
  }) async {
    if (request.fromUid.isEmpty || request.fromUid == currentUser.uid) {
      throw CannotRequestSelfException();
    }

    final now = DateTime.now();

    await addFriendUseCase(
      friend: FriendEntity(
        uid: request.fromUid,
        displayName: request.displayName,
        velixId: request.velixId,
        photoUrl: request.photoUrl,
        createdAt: now,
      ),
      selfProfile: FriendEntity(
        uid: currentUser.uid,
        displayName: currentUser.name,
        velixId: currentUser.velixId,
        photoUrl: currentUser.photoUrl,
        createdAt: now,
      ),
    );

    await repository.deleteFriendRequest(
      fromUid: request.fromUid,
      toUid: currentUser.uid,
    );

    return openChatUseCase(
      currentUserUid: currentUser.uid,
      otherUserUid: request.fromUid,
    );
  }
}
