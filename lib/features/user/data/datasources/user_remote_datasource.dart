import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<UserModel?> getCurrentUser();

  Future<void> updateCurrentUser(UserModel user);

  Future<void> updateOnlineStatus({
    required bool isOnline,
    required DateTime lastSeen,
  });

  Future<void> updateNotificationToken(String token);
}