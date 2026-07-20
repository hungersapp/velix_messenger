import '../entities/user_entity.dart';

abstract class UserRepository {
  /// Get currently logged-in user
  Future<UserEntity?> getCurrentUser();

  /// Update current user profile
  Future<void> updateCurrentUser(UserEntity user);

  /// Update online/offline status
  Future<void> updateOnlineStatus({
    required bool isOnline,
    required DateTime lastSeen,
  });

  /// Update notification token
  Future<void> updateNotificationToken(String token);
}