import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/user_remote_datasource.dart';
import '../../data/datasources/user_remote_datasource_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';

final userRemoteDataSourceProvider =
    Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSourceImpl();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.watch(userRemoteDataSourceProvider),
  );
});

final getCurrentUserUseCaseProvider =
    Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(
    ref.watch(userRepositoryProvider),
  );
});

class CurrentUserNotifier extends AsyncNotifier<UserEntity?> {
  @override
  Future<UserEntity?> build() async {
    return ref.watch(getCurrentUserUseCaseProvider)();
  }

  Future<void> refreshUser() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return ref.read(getCurrentUserUseCaseProvider)();
    });
  }
}

final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, UserEntity?>(
  CurrentUserNotifier.new,
);