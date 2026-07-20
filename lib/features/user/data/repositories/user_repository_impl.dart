import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required this._remoteDataSource,
  });

  final UserRemoteDataSource _remoteDataSource;

  @override
  Future<UserEntity?> getCurrentUser() async {
    final userModel = await _remoteDataSource.getCurrentUser();
    return userModel?.toEntity();
  }

  @override
  Future<void> updateCurrentUser(UserEntity user) async {
    await _remoteDataSource.updateCurrentUser(
      UserModel.fromEntity(user),
    );
  }

  @override
  Future<void> updateOnlineStatus({
    required bool isOnline,
    required DateTime lastSeen,
  }) async {
    await _remoteDataSource.updateOnlineStatus(
      isOnline: isOnline,
      lastSeen: lastSeen,
    );
  }

  @override
  Future<void> updateNotificationToken(String token) async {
    await _remoteDataSource.updateNotificationToken(token);
  }
}