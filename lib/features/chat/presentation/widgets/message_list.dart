import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/message.dart';
import '../providers/message_provider.dart';
import '../providers/pending_media_provider.dart';
import 'message_bubble.dart';
import 'pending_media_bubble.dart';

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
    final pending = ref
        .watch(pendingMediaProvider)
        .where((item) => item.conversationId == conversationId)
        .toList();

    return messages.when(
      loading: () {
        if (pending.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return _buildList(
          messageList: const [],
          pending: pending,
        );
      },
      error: (error, _) {
        if (pending.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return _buildList(
          messageList: const [],
          pending: pending,
        );
      },
      data: (messageList) {
        if (messageList.isEmpty && pending.isEmpty) {
          return const Center(
            child: Text(
              'Start your conversation 👋',
            ),
          );
        }

        return _buildList(
          messageList: messageList,
          pending: pending,
        );
      },
    );
  }

  Widget _buildList({
    required List<Message> messageList,
    required List<PendingMedia> pending,
  }) {
    final itemCount = messageList.length + pending.length;

    return ListView.builder(
      reverse: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < pending.length) {
          final pendingItem =
              pending[pending.length - 1 - index];

          return PendingMediaBubble(
            key: ValueKey('pending_${pendingItem.id}'),
            pending: pendingItem,
          );
        }

        final messageIndex = index - pending.length;
        final message = messageList[
            messageList.length - 1 - messageIndex];

        return MessageBubble(
          key: ValueKey('message_${message.id}'),
          messageId: message.id,
          message: message.message,
          messageType: message.messageType,
          mediaUrl: message.mediaUrl,
          thumbnailUrl: message.thumbnailUrl,
          fileName: message.fileName,
          fileSize: message.fileSize,
          sentAt: message.sentAt,
          isMe: message.senderId == currentUserId,
          status: message.status,
        );
      },
    );
  }
}
