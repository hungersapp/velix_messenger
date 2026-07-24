import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_dependency_provider.dart';

/// Resolves a peer user profile for Recent Chats (name, phone, photo).
/// Uses existing GetUserUseCase — does not modify Auth/Chat modules.
final peerUserProvider =
    FutureProvider.family<UserEntity?, String>((ref, userId) async {
  if (userId.isEmpty) {
    return null;
  }

  return ref.watch(getUserUseCaseProvider)(userId);
});
