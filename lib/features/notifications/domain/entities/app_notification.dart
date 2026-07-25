import '../../../contacts/domain/entities/friend_request_entity.dart';

/// Extensible in-app notification model for Velix.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.photoUrl,
    this.subtitle,
    this.friendRequest,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? photoUrl;
  final String? subtitle;

  /// Present when [type] is [NotificationType.friendRequest].
  final FriendRequestEntity? friendRequest;

  factory AppNotification.fromFriendRequest(FriendRequestEntity request) {
    return AppNotification(
      id: 'friend_request_${request.fromUid}',
      type: NotificationType.friendRequest,
      title: request.displayName,
      body: 'sent you a friend request',
      createdAt: request.createdAt,
      photoUrl: request.photoUrl.isEmpty ? null : request.photoUrl,
      subtitle: request.velixId,
      friendRequest: request,
      isRead: false,
    );
  }
}

/// Future notification kinds — keep this enum open for new channels.
enum NotificationType {
  friendRequest,
  timeCapsuleLike,
  mention,
  systemAnnouncement,
}
