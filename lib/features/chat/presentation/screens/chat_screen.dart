import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/debug/nav_debug_log.dart';
import '../../../calling/presentation/providers/call_controller.dart';
import '../../../calling/presentation/screens/active_call_screen.dart';
import '../../../calling/presentation/screens/active_video_call_screen.dart';
import '../../../calling/domain/entities/call_session.dart';
import '../../domain/entities/file_upload_result.dart';
import '../../domain/entities/media_upload_result.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/voice_upload_result.dart';
import '../providers/conversation_provider.dart';
import '../providers/message_provider.dart';
import '../providers/message_receipt_controller.dart';
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
  final Set<String> _deliveredInFlight = {};
  final Set<String> _readInFlight = {};

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    navLog('Chat', 'initState', {
      'conversationId': widget.conversationId,
      'currentUser': widget.currentUserId,
      'otherUserId': widget.otherUserId,
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    navLog('Chat', 'didChangeDependencies', {
      'conversationId': widget.conversationId,
      'currentUser': widget.currentUserId,
      'goRouterLocation': goRouterLocationOf(context),
      'mounted': mounted,
    });
  }

  @override
  void dispose() {
    navLog('Chat', 'dispose', {
      'conversationId': widget.conversationId,
      'currentUser': widget.currentUserId,
    });
    _controller.dispose();
    super.dispose();
  }

  void _onBackPressed() {
    navLog('Chat', 'navigation start', {
      'operation': 'Navigator.pop',
      'conversationId': widget.conversationId,
      'currentUser': widget.currentUserId,
      'goRouterLocation': goRouterLocationOf(context),
      'mounted': mounted,
    });
    Navigator.pop(context);
    navLog('Chat', 'navigation end', {
      'operation': 'Navigator.pop',
      'conversationId': widget.conversationId,
      'mounted': mounted,
    });
  }

  Future<void> _processMessageReceipts(
    List<Message> messages,
  ) async {
    final receiptController =
        ref.read(messageReceiptControllerProvider);
    final conversationId = widget.conversationId;
    final currentUserId = widget.currentUserId;

    for (final message in messages) {
      if (message.senderId == currentUserId) continue;
      if (message.id.isEmpty) continue;

      final messageId = message.id;

      if (message.status == 'sent' &&
          !_deliveredInFlight.contains(messageId)) {
        _deliveredInFlight.add(messageId);
        try {
          await receiptController.markDelivered(
            conversationId: conversationId,
            messageId: messageId,
          );
        } catch (_) {
          // Allow retry on a future stream emission.
        } finally {
          _deliveredInFlight.remove(messageId);
        }
      }

      if (message.status != 'read' &&
          !_readInFlight.contains(messageId)) {
        _readInFlight.add(messageId);
        try {
          await receiptController.markRead(
            conversationId: conversationId,
            messageId: messageId,
          );
        } catch (_) {
          // Allow retry on a future stream emission.
        } finally {
          _readInFlight.remove(messageId);
        }
      }
    }
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

  Future<void> _sendVideoMessage(MediaUploadResult result) async {
  final message = Message(
    id: '',
    conversationId: widget.conversationId,
    senderId: widget.currentUserId,
    messageType: 'video',
    message: '',
    mediaUrl: result.mediaUrl,
    thumbnailUrl: result.thumbnailUrl,
    fileName: null,
    fileSize: null,
    mimeType: 'video/mp4',
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
}

Future<void> _sendImageMessage(String imageUrl) async {
  final message = Message(
    id: '',
    conversationId: widget.conversationId,
    senderId: widget.currentUserId,
    messageType: 'image',
    message: '',
    mediaUrl: imageUrl,
    thumbnailUrl: null,
    fileName: null,
    fileSize: null,
    mimeType: 'image/jpeg',
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
}

  Future<void> _sendFileMessage(FileUploadResult result) async {
    final message = Message(
      id: '',
      conversationId: widget.conversationId,
      senderId: widget.currentUserId,
      messageType: 'file',
      message: result.fileName,
      mediaUrl: result.mediaUrl,
      thumbnailUrl: null,
      fileName: result.fileName,
      fileSize: result.fileSize,
      mimeType: result.mimeType,
      status: 'sent',
      sentAt: DateTime.now(),
      deliveredAt: null,
      readAt: null,
      replyToMessageId: null,
      isEdited: false,
      isDeleted: false,
      deletedFor: const [],
    );

    await ref.read(messageControllerProvider.notifier).sendMessage(message);
  }

  Future<void> _sendVoiceMessage(VoiceUploadResult result) async {
    final message = Message(
      id: '',
      conversationId: widget.conversationId,
      senderId: widget.currentUserId,
      messageType: 'voice',
      message: result.durationMs.toString(),
      mediaUrl: result.mediaUrl,
      thumbnailUrl: null,
      fileName: result.fileName,
      fileSize: result.fileSize,
      mimeType: result.mimeType,
      status: 'sent',
      sentAt: DateTime.now(),
      deliveredAt: null,
      readAt: null,
      replyToMessageId: null,
      isEdited: false,
      isDeleted: false,
      deletedFor: const [],
    );

    await ref.read(messageControllerProvider.notifier).sendMessage(message);
  }

  Future<void> _startVoiceCall() async {
    final started =
        await ref.read(callControllerProvider.notifier).startOutgoingCall(
              conversationId: widget.conversationId,
              receiverId: widget.otherUserId,
              receiverName: widget.userName,
              receiverPhotoUrl: widget.profileImageUrl,
              callType: CallType.voice,
            );

    if (!started) {
      final error = ref.read(callControllerProvider).errorMessage;
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        ref.read(callControllerProvider.notifier).clearError();
      }
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const ActiveCallScreen(),
      ),
    );
  }

  Future<void> _startVideoCall() async {
    final started =
        await ref.read(callControllerProvider.notifier).startOutgoingCall(
              conversationId: widget.conversationId,
              receiverId: widget.otherUserId,
              receiverName: widget.userName,
              receiverPhotoUrl: widget.profileImageUrl,
              callType: CallType.video,
            );

    if (!started) {
      final error = ref.read(callControllerProvider).errorMessage;
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        ref.read(callControllerProvider.notifier).clearError();
      }
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const ActiveVideoCallScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    navLog('Chat', 'build', {
      'conversationId': widget.conversationId,
      'currentUser': widget.currentUserId,
      'otherUserId': widget.otherUserId,
      'goRouterLocation': goRouterLocationOf(context),
      'mounted': mounted,
    });

    ref.listen<AsyncValue<List<Message>>>(
      messageProvider(widget.conversationId),
      (previous, next) {
        next.whenData(_processMessageReceipts);
      },
    );

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
            onBack: _onBackPressed,
            onVoiceCallPressed: _startVoiceCall,
            onVideoCallPressed: _startVideoCall,
          );
        },
        loading: () => ChatAppBar(
          userName: widget.userName,
          profileImageUrl:
              widget.profileImageUrl,
          isOnline: false,
          isTyping: false,
          onBack: _onBackPressed,
          onVoiceCallPressed: _startVoiceCall,
          onVideoCallPressed: _startVideoCall,
        ),
        error: (_, _) => ChatAppBar(
          userName: widget.userName,
          profileImageUrl:
              widget.profileImageUrl,
          isOnline: false,
          isTyping: false,
          onBack: _onBackPressed,
          onVoiceCallPressed: _startVoiceCall,
          onVideoCallPressed: _startVideoCall,
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
           conversationId: widget.conversationId,
           senderId: widget.currentUserId,
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
            onImageSelected: _sendImageMessage,
            onVideoSelected: _sendVideoMessage,
            onFileSelected: _sendFileMessage,
            onVoiceSelected: _sendVoiceMessage,

            onVelixPressed: () {
              // TODO
            },
          ),
        ],
      ),
    );
  }
}