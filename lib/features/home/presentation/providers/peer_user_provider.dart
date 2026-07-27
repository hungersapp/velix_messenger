import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_dependency_provider.dart';

/// Resolves a peer user profile for Recent Chats (name, phone, photo).
/// Uses existing GetUserUseCase — does not modify Auth/Chat modules.
/// autoDispose: drops unused peer lookups when chats scroll off-screen.
final peerUserProvider =
    FutureProvider.autoDispose.family<UserEntity?, String>((ref, userId) async {
  if (userId.isEmpty) {
    return null;
  }

  // Keep briefly so rapid list rebuilds do not refetch.
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 2), link.close);
  ref.onDispose(timer.cancel);

  return ref.watch(getUserUseCaseProvider)(userId);
});
