import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/message.dart';
import '../providers/conversation_provider.dart';
import '../providers/message_provider.dart';
import '../providers/typing_provider.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/message_input.dart';
import '../widgets/message_list.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String currentUserId;
  final String otherUserId;
  final String userName;
  final String? profileImageUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.otherUserId,
    required this.userName,
    this.profileImageUrl,
  });

  @override
  ConsumerState<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends ConsumerState<ChatScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    ref
        .read(typingControllerProvider.notifier)
        .updateTypingStatus(
          conversationId: widget.conversationId,
          userId: widget.currentUserId,
          isTyping: false,
        );

    _controller.dispose();

    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    final message = Message(
  id: '',
  conversationId: widget.conversationId,
  senderId: widget.currentUserId,
  messageType: 'text',
  message: text,
  mediaUrl: null,
  thumbnailUrl: null,
  fileName: null,
  fileSize: null,
  mimeType: null,
  status: 'sent',
  sentAt: DateTime.now(),
  deliveredAt: null,
  readAt: null,
  replyToMessageId: null,
  isEdited: false,
  isDeleted: false,
  deletedFor: const [],
);
    await ref
        .read(messageControllerProvider.notifier)
        .sendMessage(message);

    _controller.clear();

    await ref
        .read(typingControllerProvider.notifier)
        .updateTypingStatus(
          conversationId: widget.conversationId,
          userId: widget.currentUserId,
          isTyping: false,
        );
  }

  @override
  Widget build(BuildContext context) {
    final conversationAsync = ref.watch(
      conversationByIdProvider(
        widget.conversationId,
      ),
    );

    return Scaffold(
      appBar: conversationAsync.when(
        data: (conversation) {
          final isTyping =
              conversation?.typingStatus[
                      widget.otherUserId] ??
                  false;

          return ChatAppBar(
            userName: widget.userName,
            profileImageUrl:
                widget.profileImageUrl,
            isOnline: false,
            isTyping: isTyping,
            onBack: () => Navigator.pop(context),
          );
        },
        loading: () => ChatAppBar(
          userName: widget.userName,
          profileImageUrl:
              widget.profileImageUrl,
          isOnline: false,
          isTyping: false,
          onBack: () => Navigator.pop(context),
        ),
        error: (_, _) => ChatAppBar(
          userName: widget.userName,
          profileImageUrl:
              widget.profileImageUrl,
          isOnline: false,
          isTyping: false,
          onBack: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: MessageList(
              conversationId:
                  widget.conversationId,
              currentUserId:
                  widget.currentUserId,
            ),
          ),

          conversationAsync.when(
            data: (conversation) {
              final isTyping =
                  conversation?.typingStatus[
                          widget.otherUserId] ??
                      false;

              return TypingIndicator(
                isTyping: isTyping,
              );
            },
            loading: () =>
                const SizedBox.shrink(),
            error: (_, _) =>
              const SizedBox.shrink(),
          ),

          MessageInput(
            controller: _controller,

            onChanged: (value) {
              ref
                  .read(
                    typingControllerProvider
                        .notifier,
                  )
                  .updateTypingStatus(
                    conversationId:
                        widget.conversationId,
                    userId:
                        widget.currentUserId,
                    isTyping: value
                        .trim()
                        .isNotEmpty,
                  );
            },

            onSend: _sendMessage,

            onEmojiPressed: () {
              // TODO
            },

            onVelixPressed: () {
              // TODO
            },

            onVoice: () {
              // Reserved for future V2
            },
          ),
        ],
      ),
    );
  }
}