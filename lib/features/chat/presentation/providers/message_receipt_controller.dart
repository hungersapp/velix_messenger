import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'message_provider.dart';

class MessageReceiptController {
  final Ref ref;

  MessageReceiptController(this.ref);

  /// Message delivered to receiver
  Future<void> markDelivered({
    required String conversationId,
    required String messageId,
  }) async {
    await ref
        .read(messageControllerProvider.notifier)
        .markMessageAsDelivered(
          conversationId: conversationId,
          messageId: messageId,
        );
  }

  /// Message read by receiver
  Future<void> markRead({
    required String conversationId,
    required String messageId,
  }) async {
    await ref
        .read(messageControllerProvider.notifier)
        .markMessageAsRead(
          conversationId: conversationId,
          messageId: messageId,
        );
  }
}

final messageReceiptControllerProvider =
    Provider<MessageReceiptController>(
  (ref) => MessageReceiptController(ref),
);