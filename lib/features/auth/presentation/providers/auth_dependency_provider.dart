import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasource/firestore_user_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/check_mobile_exists_usecase.dart';
import '../../domain/usecases/get_user_usecase.dart';
import '../../domain/usecases/save_user_usecase.dart';

/// Datasource
final firestoreUserDatasourceProvider =
    Provider<FirestoreUserDatasource>((ref) {
  return FirestoreUserDatasource();
});

/// Repository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    ref.read(firestoreUserDatasourceProvider),
  );
});

/// Save User UseCase
final saveUserUseCaseProvider =
    Provider<SaveUserUseCase>((ref) {
  return SaveUserUseCase(
    ref.read(userRepositoryProvider),
  );
});

/// Get User UseCase
final getUserUseCaseProvider =
    Provider<GetUserUseCase>((ref) {
  return GetUserUseCase(
    ref.read(userRepositoryProvider),
  );
});

/// Check Mobile Exists UseCase
final checkMobileExistsUseCaseProvider =
    Provider<CheckMobileExistsUseCase>((ref) {
  return CheckMobileExistsUseCase(
    ref.read(userRepositoryProvider),
  );
});