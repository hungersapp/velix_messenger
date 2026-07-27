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
import 'dart:io';
import '../../../settings/domain/entities/settings_models.dart';
import '../../../settings/presentation/providers/settings_feature_providers.dart';

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
  final Set<String> _deliveredDone = {};
  final Set<String> _readDone = {};
  bool _unreadClearInFlight = false;
  int _unreadClearGeneration = 0;
  Future<void> _receiptsQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    navLog('Chat', 'initState', {
      'conversationId': widget.conversationId,
      'currentUser': widget.currentUserId,
      'otherUserId': widget.otherUserId,
    });
    // Clear conversation summary badge immediately — do not scan messages.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _clearUnreadBadge();
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
  void deactivate() {
    // Clear typing while ref is still valid (dispose cannot use ref safely).
    try {
      ref.read(typingControllerProvider.notifier).updateTypingStatus(
            conversationId: widget.conversationId,
            userId: widget.currentUserId,
            isTyping: false,
          );
    } catch (_) {}
    _unreadClearGeneration++;
    super.deactivate();
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

  Future<void> _clearUnreadBadge() async {
    if (_unreadClearInFlight) return;
    final generation = _unreadClearGeneration;
    if (!mounted || generation != _unreadClearGeneration) return;

    _unreadClearInFlight = true;
    try {
      // Skip if the user already left before the write starts.
      if (!mounted || generation != _unreadClearGeneration) return;
      await ref.read(messageControllerProvider.notifier).clearConversationUnread(
            conversationId: widget.conversationId,
            userId: widget.currentUserId,
          );
    } catch (_) {
      // Badge clear is best-effort; receipts still run independently.
    } finally {
      _unreadClearInFlight = false;
    }
  }

  Future<void> _processMessageReceipts(
    List<Message> messages,
  ) {
    // Serialize overlapping listen callbacks so delivered cannot race past read.
    _receiptsQueue = _receiptsQueue
        .catchError((_) {})
        .then((_) => _processMessageReceiptsBody(messages));
    return _receiptsQueue;
  }

  Future<void> _processMessageReceiptsBody(
    List<Message> messages,
  ) async {
    if (!mounted) return;

    final receiptController =
        ref.read(messageReceiptControllerProvider);
    final conversationId = widget.conversationId;
    final currentUserId = widget.currentUserId;

    final deliverIds = <String>[];
    final readIds = <String>[];

    for (final message in messages) {
      if (message.senderId == currentUserId) continue;
      if (message.id.isEmpty) continue;

      final messageId = message.id;

      if (message.status == 'sent' &&
          !_deliveredInFlight.contains(messageId) &&
          !_deliveredDone.contains(messageId) &&
          !_readDone.contains(messageId)) {
        deliverIds.add(messageId);
      }

      if (message.status != 'read' &&
          !_readInFlight.contains(messageId) &&
          !_readDone.contains(messageId)) {
        readIds.add(messageId);
      }
    }

    // Cap concurrent receipt writes to avoid write storms on large pages.
    const batchSize = 8;
    for (var i = 0; i < deliverIds.length; i += batchSize) {
      final batch = deliverIds.skip(i).take(batchSize).toList();
      await Future.wait(
        batch.map((messageId) async {
          if (_readDone.contains(messageId)) return;
          _deliveredInFlight.add(messageId);
          try {
            await receiptController.markDelivered(
              conversationId: conversationId,
              messageId: messageId,
            );
            _deliveredDone.add(messageId);
          } catch (_) {
            // Allow retry on a future stream emission.
          } finally {
            _deliveredInFlight.remove(messageId);
          }
        }),
      );
    }

    var markedAnyRead = false;
    for (var i = 0; i < readIds.length; i += batchSize) {
      final batch = readIds.skip(i).take(batchSize).toList();
      await Future.wait(
        batch.map((messageId) async {
          _readInFlight.add(messageId);
          try {
            await receiptController.markRead(
              conversationId: conversationId,
              messageId: messageId,
            );
            _readDone.add(messageId);
            markedAnyRead = true;
          } catch (_) {
            // Allow retry on a future stream emission.
          } finally {
            _readInFlight.remove(messageId);
          }
        }),
      );
    }

    // Keep Home badge in sync while this chat stays open (1 summary write).
    if (mounted && (markedAnyRead || readIds.isNotEmpty)) {
      await _clearUnreadBadge();
    }
  }

  Future<bool> _ensureNotBlocked() async {
    try {
      final blocked = await ref.read(settingsRepositoryProvider).isBlockedEitherWay(
            userA: widget.currentUserId,
            userB: widget.otherUserId,
          );
      if (!blocked) return true;
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Messaging is unavailable with this user.'),
        ),
      );
      return false;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      return false;
    }
  }

  Future<void> _blockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block user?'),
        content: Text(
          'Block ${widget.userName}? They will not be able to message or call you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(settingsRepositoryProvider).blockUser(
            currentUserId: widget.currentUserId,
            user: BlockedUser(
              uid: widget.otherUserId,
              displayName: widget.userName,
              velixId: '',
              photoUrl: widget.profileImageUrl ?? '',
              blockedAt: DateTime.now(),
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.userName} blocked')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty) return;
    if (!await _ensureNotBlocked()) return;

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
    final mediaUrl = result.mediaUrl.trim();
    if (mediaUrl.isEmpty) {
      debugPrint(
        '[FirestoreWrite] skip video: empty mediaUrl '
        'conversationId=${widget.conversationId}',
      );
      throw Exception('Cannot save video message without a download URL.');
    }

    final message = Message(
      id: '',
      conversationId: widget.conversationId,
      senderId: widget.currentUserId,
      messageType: 'video',
      message: '',
      mediaUrl: mediaUrl,
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

    try {
      await ref.read(messageControllerProvider.notifier).sendMessage(message);
    } catch (e, st) {
      debugPrint('[FirestoreWrite] video message failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> _sendImageMessage(String imageUrl) async {
    final mediaUrl = imageUrl.trim();
    if (mediaUrl.isEmpty) {
      debugPrint(
        '[FirestoreWrite] skip image: empty mediaUrl '
        'conversationId=${widget.conversationId}',
      );
      throw Exception('Cannot save image message without a download URL.');
    }

    final message = Message(
      id: '',
      conversationId: widget.conversationId,
      senderId: widget.currentUserId,
      messageType: 'image',
      message: '',
      mediaUrl: mediaUrl,
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

    try {
      await ref.read(messageControllerProvider.notifier).sendMessage(message);
    } catch (e, st) {
      debugPrint('[FirestoreWrite] image message failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> _sendFileMessage(FileUploadResult result) async {
    final mediaUrl = result.mediaUrl.trim();
    if (mediaUrl.isEmpty) {
      debugPrint(
        '[FirestoreWrite] skip file: empty mediaUrl '
        'conversationId=${widget.conversationId}',
      );
      throw Exception('Cannot save file message without a download URL.');
    }

    final message = Message(
      id: '',
      conversationId: widget.conversationId,
      senderId: widget.currentUserId,
      messageType: 'file',
      message: result.fileName,
      mediaUrl: mediaUrl,
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

    try {
      await ref.read(messageControllerProvider.notifier).sendMessage(message);
    } catch (e, st) {
      debugPrint('[FirestoreWrite] file message failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> _sendVoiceMessage(VoiceUploadResult result) async {
    final mediaUrl = result.mediaUrl.trim();
    if (mediaUrl.isEmpty) {
      debugPrint(
        '[FirestoreWrite] skip voice: empty mediaUrl '
        'conversationId=${widget.conversationId}',
      );
      throw Exception('Cannot save voice message without a download URL.');
    }

    final message = Message(
      id: '',
      conversationId: widget.conversationId,
      senderId: widget.currentUserId,
      messageType: 'voice',
      message: result.durationMs.toString(),
      mediaUrl: mediaUrl,
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

    try {
      await ref.read(messageControllerProvider.notifier).sendMessage(message);
    } catch (e, st) {
      debugPrint('[FirestoreWrite] voice message failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> _startVoiceCall() async {
    if (!await _ensureNotBlocked()) return;
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
    if (!await _ensureNotBlocked()) return;
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
            onBlockPressed: _blockUser,
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
          onBlockPressed: _blockUser,
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
          onBlockPressed: _blockUser,
        ),
      ),
      body: Builder(
        builder: (context) {
          final wallpaperPath = ref.watch(chatWallpaperPathProvider).valueOrNull;
          final hasWallpaper = wallpaperPath != null &&
              wallpaperPath.isNotEmpty &&
              File(wallpaperPath).existsSync();
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              image: hasWallpaper
                  ? DecorationImage(
                      image: FileImage(File(wallpaperPath)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Column(
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
        },
      ),
    );
  }
}