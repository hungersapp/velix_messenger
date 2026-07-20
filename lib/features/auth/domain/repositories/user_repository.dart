import '../entities/user_entity.dart';

abstract class UserRepository {
  /// Save User
  Future<void> saveUser(UserEntity user);

  /// Check User Exists by UID
  Future<bool> userExists(String uid);

  /// Get User Details
  Future<UserEntity?> getUser(String uid);

  /// Check Mobile Number Exists
  Future<bool> isMobileExists(String mobile);
}