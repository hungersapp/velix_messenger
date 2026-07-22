import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/message.dart';
import 'chat_provider.dart';

/// Realtime Messages
final messageProvider =
    StreamProvider.family<List<Message>, String>(
  (ref, conversationId) {
    final getMessages =
        ref.watch(getMessagesUseCaseProvider);

    return getMessages(conversationId);
  },
);

/// Message Controller
class MessageController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  MessageController(this.ref)
      : super(const AsyncData(null));

  Future<void> sendMessage(
    Message message,
  ) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(sendMessageUseCaseProvider)
          .call(message);

      await ref
          .read(updateConversationUseCaseProvider)
          .call(
            conversationId: message.conversationId,
            lastMessage: message.message,
            lastMessageSenderId: message.senderId,
            lastMessageType: 'text',
          );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Message Controller Provider
final messageControllerProvider =
    StateNotifierProvider<
        MessageController,
        AsyncValue<void>>(
  (ref) {
    return MessageController(ref);
  },
);