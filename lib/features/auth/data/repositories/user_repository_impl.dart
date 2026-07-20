import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasource/firestore_user_datasource.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final FirestoreUserDatasource datasource;

  UserRepositoryImpl(this.datasource);

  @override
  Future<void> saveUser(UserEntity user) async {
    final userModel = UserModel(
      uid: user.uid,
      name: user.name,
      mobile: user.mobile,
      email: user.email,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
    );

    await datasource.saveUser(userModel);
  }

  @override
  Future<bool> userExists(String uid) async {
    return await datasource.userExists(uid);
  }

  @override
  Future<UserEntity?> getUser(String uid) async {
    return await datasource.getUser(uid);
  }

  @override
  Future<bool> isMobileExists(String mobile) async {
    return await datasource.isMobileExists(mobile);
  }
}