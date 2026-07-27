import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/message.dart';
import '../../../settings/domain/entities/settings_models.dart';
import '../../../settings/presentation/providers/settings_feature_providers.dart';
import '../providers/message_provider.dart';
import '../providers/pending_media_provider.dart';
import 'message_bubble.dart';
import 'pending_media_bubble.dart';

class MessageList extends ConsumerStatefulWidget {
  final String conversationId;
  final String currentUserId;

  const MessageList({
    super.key,
    required this.conversationId,
    required this.currentUserId,
  });

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // reverse:true → older messages are toward maxScrollExtent (visual top).
    if (position.pixels >= position.maxScrollExtent - 96) {
      ref
          .read(chatMessagesProvider(widget.conversationId).notifier)
          .loadOlder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatMessagesProvider(widget.conversationId));
    final pending = ref
        .watch(pendingMediaProvider)
        .where((item) => item.conversationId == widget.conversationId)
        .toList();
    final fontSize =
        ref.watch(chatFontSizeProvider).valueOrNull ??
            ChatFontSizeOption.medium;

    if (chatState.isInitialLoading &&
        chatState.messages.isEmpty &&
        pending.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (chatState.error != null &&
        chatState.messages.isEmpty &&
        pending.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            chatState.error.toString(),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (chatState.messages.isEmpty && pending.isEmpty) {
      return const Center(
        child: Text(
          'Start your conversation 👋',
        ),
      );
    }

    return _buildList(
      messageList: chatState.messages,
      pending: pending,
      fontSize: fontSize,
      isLoadingOlder: chatState.isLoadingOlder,
    );
  }

  Widget _buildList({
    required List<Message> messageList,
    required List<PendingMedia> pending,
    required ChatFontSizeOption fontSize,
    required bool isLoadingOlder,
  }) {
    final baseCount = messageList.length + pending.length;
    // In a reverse ListView, the last index sits at the visual top.
    final itemCount = baseCount + (isLoadingOlder ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (isLoadingOlder && index == itemCount - 1) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (index < pending.length) {
          final pendingItem = pending[pending.length - 1 - index];

          return PendingMediaBubble(
            key: ValueKey('pending_${pendingItem.id}'),
            pending: pendingItem,
          );
        }

        final messageIndex = index - pending.length;
        final message = messageList[messageList.length - 1 - messageIndex];

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
          isMe: message.senderId == widget.currentUserId,
          status: message.status,
          fontScale: fontSize.scale,
        );
      },
    );
  }
}
