import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/message_provider.dart';
import 'message_bubble.dart';

class MessageList extends ConsumerWidget {
  final String conversationId;
  final String currentUserId;

  const MessageList({
    super.key,
    required this.conversationId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages =
        ref.watch(messageProvider(conversationId));

    return messages.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),

      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error.toString(),
            textAlign: TextAlign.center,
          ),
        ),
      ),

      data: (messageList) {
        if (messageList.isEmpty) {
          return const Center(
            child: Text(
              'Start your conversation 👋',
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          physics:
              const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.symmetric(
            vertical: 12,
          ),
          itemCount: messageList.length,
          itemBuilder: (context, index) {
            final message =
                messageList[
                    messageList.length -
                        1 -
                        index];

            return MessageBubble(
  message: message.message,
  messageType: message.messageType,
  mediaUrl: message.mediaUrl,
  sentAt: message.sentAt,
  isMe: message.senderId == currentUserId,
  status: message.status,
);
          },
        );
      },
    );
  }
}