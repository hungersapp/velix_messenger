import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/conversation.dart';
import 'chat_provider.dart';

/// Get all conversations of a user
final conversationProvider =
    StreamProvider.family<List<Conversation>, String>(
  (ref, userId) {
    final useCase = ref.watch(
      getConversationsUseCaseProvider,
    );

    return useCase(userId);
  },
);

/// Watch a single conversation in realtime
final conversationByIdProvider =
    StreamProvider.family<Conversation?, String>(
  (ref, conversationId) {
    final useCase = ref.watch(
      watchConversationByIdUseCaseProvider,
    );

    return useCase(conversationId);
  },
);

/// Get a single conversation by conversationKey
final conversationByKeyProvider =
    FutureProvider.family<Conversation?, String>(
  (ref, conversationKey) {
    final useCase = ref.watch(
      getConversationByKeyUseCaseProvider,
    );

    return useCase(conversationKey);
  },
);