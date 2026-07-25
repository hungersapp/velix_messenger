class FriendRequestException implements Exception {
  FriendRequestException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AlreadyFriendsException extends FriendRequestException {
  AlreadyFriendsException([
    super.message = 'You are already friends with this user.',
  ]);
}

class FriendRequestAlreadySentException extends FriendRequestException {
  FriendRequestAlreadySentException([
    super.message = 'Friend request already sent.',
  ]);
}

class CannotRequestSelfException extends FriendRequestException {
  CannotRequestSelfException([
    super.message = 'You cannot send a friend request to yourself.',
  ]);
}
