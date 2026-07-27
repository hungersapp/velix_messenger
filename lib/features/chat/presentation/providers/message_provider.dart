import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/message.dart';
import 'chat_provider.dart';

/// Page size for live window + older history fetches.
const int kMessagePageSize = 50;

/// Combined realtime latest page + paginated older history.
class ChatMessagesState {
  const ChatMessagesState({
    this.messages = const [],
    this.isInitialLoading = true,
    this.isLoadingOlder = false,
    this.hasMore = true,
    this.error,
  });

  final List<Message> messages;
  final bool isInitialLoading;
  final bool isLoadingOlder;
  final bool hasMore;
  final Object? error;

  ChatMessagesState copyWith({
    List<Message>? messages,
    bool? isInitialLoading,
    bool? isLoadingOlder,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Keeps one realtime listener on the latest [kMessagePageSize] messages and
/// appends older pages via cursor queries without interrupting the stream.
class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  ChatMessagesNotifier({
    required this.ref,
    required this.conversationId,
  }) : super(const ChatMessagesState()) {
    _subscribeLive();
  }

  final Ref ref;
  final String conversationId;

  StreamSubscription<List<Message>>? _liveSub;
  List<Message> _live = const [];
  List<Message> _older = const [];
  bool _loadInFlight = false;

  void _subscribeLive() {
    _liveSub?.cancel();
    _liveSub = ref.read(getMessagesUseCaseProvider)(conversationId).listen(
      _applyLiveUpdate,
      onError: (Object e, StackTrace st) {
        if (state.messages.isEmpty) {
          state = state.copyWith(
            isInitialLoading: false,
            error: e,
          );
        }
      },
    );
  }

  void _applyLiveUpdate(List<Message> live) {
    final liveIds = live.map((m) => m.id).where((id) => id.isNotEmpty).toSet();

    // Messages that slid out of the latest page must stay in `_older`
    // so they do not vanish until pagination (or a later live hit) covers them.
    final demoted = <Message>[];
    for (final prev in _live) {
      if (prev.id.isEmpty || liveIds.contains(prev.id)) continue;
      final alreadyOlder = _older.any((m) => m.id == prev.id);
      if (!alreadyOlder) {
        demoted.add(prev);
      }
    }

    _older = [
      ...demoted,
      ..._older.where((m) => !liveIds.contains(m.id)),
    ];
    _live = live;

    final hadFirstPage = !state.isInitialLoading;
    state = state.copyWith(
      messages: _merge(),
      isInitialLoading: false,
      clearError: true,
      // Only infer hasMore from the first live page; later live updates
      // must not re-enable pagination after history is exhausted.
      hasMore: hadFirstPage
          ? state.hasMore
          : live.length >= kMessagePageSize,
    );
  }

  List<Message> _merge() {
    final byId = <String, Message>{};
    for (final message in _older) {
      if (message.id.isEmpty) continue;
      byId[message.id] = message;
    }
    // Live window wins for status / content updates on overlapping ids.
    for (final message in _live) {
      if (message.id.isEmpty) continue;
      byId[message.id] = message;
    }

    final merged = byId.values.toList()
      ..sort((a, b) {
        final byTime = a.sentAt.compareTo(b.sentAt);
        if (byTime != 0) return byTime;
        return a.id.compareTo(b.id);
      });
    return merged;
  }

  /// Loads the next older page when the user scrolls to the top.
  Future<void> loadOlder() async {
    if (_loadInFlight ||
        state.isLoadingOlder ||
        !state.hasMore ||
        state.isInitialLoading) {
      return;
    }

    final cursorId = state.messages.isEmpty ? null : state.messages.first.id;
    if (cursorId == null || cursorId.isEmpty) {
      state = state.copyWith(hasMore: false);
      return;
    }

    _loadInFlight = true;
    state = state.copyWith(isLoadingOlder: true, clearError: true);

    try {
      final page = await ref.read(getOlderMessagesUseCaseProvider)(
        conversationId: conversationId,
        beforeMessageId: cursorId,
        limit: kMessagePageSize,
      );

      final existingIds = <String>{
        ..._older.map((m) => m.id),
        ..._live.map((m) => m.id),
      };

      final fresh = page
          .where((m) => m.id.isNotEmpty && !existingIds.contains(m.id))
          .toList();

      if (fresh.isNotEmpty) {
        // [fresh] is ascending; it is older than current history → prepend.
        _older = [...fresh, ..._older];
      }

      state = state.copyWith(
        messages: _merge(),
        isLoadingOlder: false,
        hasMore: page.length >= kMessagePageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingOlder: false,
        error: e,
      );
    } finally {
      _loadInFlight = false;
    }
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    _liveSub = null;
    super.dispose();
  }
}

final chatMessagesProvider = StateNotifierProvider.autoDispose
    .family<ChatMessagesNotifier, ChatMessagesState, String>(
  (ref, conversationId) {
    return ChatMessagesNotifier(
      ref: ref,
      conversationId: conversationId,
    );
  },
);

/// Compatibility view for receipts / existing listeners: latest merged list.
final messageProvider =
    Provider.autoDispose.family<AsyncValue<List<Message>>, String>(
  (ref, conversationId) {
    final state = ref.watch(chatMessagesProvider(conversationId));

    if (state.isInitialLoading && state.messages.isEmpty) {
      return const AsyncValue.loading();
    }
    if (state.error != null && state.messages.isEmpty) {
      return AsyncValue.error(state.error!, StackTrace.current);
    }
    return AsyncValue.data(state.messages);
  },
);

/// Message Controller
class MessageController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  MessageController(this.ref) : super(const AsyncData(null));

  Future<void> sendMessage(
    Message message,
  ) async {
    state = const AsyncLoading();

    try {
      // Repository sendMessage already updates the conversation summary
      // (last message + unreadCount increments) — do not write twice.
      await ref.read(sendMessageUseCaseProvider).call(message);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> clearConversationUnread({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await ref.read(clearConversationUnreadUseCaseProvider).call(
            conversationId: conversationId,
            userId: userId,
          );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateMessageStatus({
    required String conversationId,
    required String messageId,
    required String status,
  }) async {
    try {
      await ref.read(updateMessageStatusUseCaseProvider).call(
            conversationId: conversationId,
            messageId: messageId,
            status: status,
          );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markMessageAsDelivered({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await ref.read(markMessageAsDeliveredUseCaseProvider).call(
            conversationId: conversationId,
            messageId: messageId,
          );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markMessageAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await ref.read(markMessageAsReadUseCaseProvider).call(
            conversationId: conversationId,
            messageId: messageId,
          );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Message Controller Provider
final messageControllerProvider =
    StateNotifierProvider<MessageController, AsyncValue<void>>(
  (ref) {
    return MessageController(ref);
  },
);
