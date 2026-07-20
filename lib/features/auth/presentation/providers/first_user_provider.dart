import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import 'auth_dependency_provider.dart';

/// Loading State
class FirstUserNotifier extends StateNotifier<bool> {
  final Ref ref;

  FirstUserNotifier(this.ref) : super(false);

  /// User Exists Check
  Future<bool> userExists(String uid) async {
    final getUserUseCase = ref.read(getUserUseCaseProvider);
    final user = await getUserUseCase(uid);
    return user != null;
  }

  /// Mobile Exists Check
  Future<bool> mobileExists(String mobile) async {
    final checkMobileUseCase =
        ref.read(checkMobileExistsUseCaseProvider);

    return await checkMobileUseCase(mobile);
  }

  /// Save User
  Future<void> saveUser(UserEntity user) async {
    state = true;

    try {
     
      final saveUserUseCase =
          ref.read(saveUserUseCaseProvider);

      

      await saveUserUseCase(user);

      
    } catch (e) {
        
      rethrow;
    } finally {
      
      state = false;
    }
  }
}

/// Provider
final firstUserProvider =
    StateNotifierProvider<FirstUserNotifier, bool>(
  (ref) => FirstUserNotifier(ref),
);