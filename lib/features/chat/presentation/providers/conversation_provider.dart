import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/conversation.dart';
import 'chat_provider.dart';

/// Page size for live Home window + older conversation pages.
const int kConversationPageSize = 30;

/// Combined realtime latest page + paginated older conversations.
class ChatConversationsState {
  const ChatConversationsState({
    this.conversations = const [],
    this.isInitialLoading = true,
    this.isLoadingOlder = false,
    this.hasMore = true,
    this.error,
  });

  final List<Conversation> conversations;
  final bool isInitialLoading;
  final bool isLoadingOlder;
  final bool hasMore;
  final Object? error;

  ChatConversationsState copyWith({
    List<Conversation>? conversations,
    bool? isInitialLoading,
    bool? isLoadingOlder,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return ChatConversationsState(
      conversations: conversations ?? this.conversations,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// One live listener on the latest [kConversationPageSize] conversations;
/// older pages are one-shot cursor queries.
class ChatConversationsNotifier
    extends StateNotifier<ChatConversationsState> {
  ChatConversationsNotifier({
    required this.ref,
    required this.userId,
  }) : super(const ChatConversationsState()) {
    _subscribeLive();
  }

  final Ref ref;
  final String userId;

  StreamSubscription<List<Conversation>>? _liveSub;
  List<Conversation> _live = const [];
  List<Conversation> _older = const [];
  bool _loadInFlight = false;

  void _subscribeLive() {
    _liveSub?.cancel();
    _liveSub = ref.read(getConversationsUseCaseProvider)(userId).listen(
      (live) {
        _applyLiveUpdate(live);
      },
      onError: (Object e, StackTrace st) {
        if (state.conversations.isEmpty) {
          state = state.copyWith(
            isInitialLoading: false,
            error: e,
          );
        }
      },
    );
  }

  void _applyLiveUpdate(List<Conversation> live) {
    final liveIds = live.map((c) => c.id).where((id) => id.isNotEmpty).toSet();

    // Demoted out of the live window → keep locally so the row does not vanish.
    final demoted = <Conversation>[];
    for (final prev in _live) {
      if (prev.id.isEmpty || liveIds.contains(prev.id)) continue;
      final alreadyOlder = _older.any((c) => c.id == prev.id);
      if (!alreadyOlder) {
        demoted.add(prev);
      }
    }

    // Promoted into live → drop stale older copy (live wins on merge).
    _older = [
      ...demoted,
      ..._older.where((c) => !liveIds.contains(c.id)),
    ];

    _live = live;

    final hadFirstPage = !state.isInitialLoading;
    state = state.copyWith(
      conversations: _merge(),
      isInitialLoading: false,
      clearError: true,
      hasMore: hadFirstPage
          ? state.hasMore
          : live.length >= kConversationPageSize,
    );
  }

  List<Conversation> _merge() {
    final byId = <String, Conversation>{};
    for (final conversation in _older) {
      if (conversation.id.isEmpty) continue;
      byId[conversation.id] = conversation;
    }
    for (final conversation in _live) {
      if (conversation.id.isEmpty) continue;
      byId[conversation.id] = conversation;
    }

    final merged = byId.values.toList()
      ..sort((a, b) {
        final byTime = b.lastMessageAt.compareTo(a.lastMessageAt);
        if (byTime != 0) return byTime;
        return a.id.compareTo(b.id);
      });
    return merged;
  }

  /// Loads the next older page when the user scrolls near the bottom.
  Future<void> loadOlder() async {
    if (_loadInFlight ||
        state.isLoadingOlder ||
        !state.hasMore ||
        state.isInitialLoading) {
      return;
    }

    final cursorId =
        state.conversations.isEmpty ? null : state.conversations.last.id;
    if (cursorId == null || cursorId.isEmpty) {
      state = state.copyWith(hasMore: false);
      return;
    }

    _loadInFlight = true;
    state = state.copyWith(isLoadingOlder: true, clearError: true);

    try {
      final page = await ref.read(getOlderConversationsUseCaseProvider)(
        userId: userId,
        beforeConversationId: cursorId,
        limit: kConversationPageSize,
      );

      final existingIds = <String>{
        ..._older.map((c) => c.id),
        ..._live.map((c) => c.id),
      };

      final fresh = page
          .where((c) => c.id.isNotEmpty && !existingIds.contains(c.id))
          .toList();

      if (fresh.isNotEmpty) {
        _older = [..._older, ...fresh];
      }

      state = state.copyWith(
        conversations: _merge(),
        isLoadingOlder: false,
        hasMore: page.length >= kConversationPageSize,
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

/// Home chats list — autoDispose cancels the live listener when Home is gone.
final chatConversationsProvider = StateNotifierProvider.autoDispose
    .family<ChatConversationsNotifier, ChatConversationsState, String>(
  (ref, userId) {
    return ChatConversationsNotifier(
      ref: ref,
      userId: userId,
    );
  },
);

/// Compatibility AsyncValue view for existing invalidate / watch call sites.
final conversationProvider =
    Provider.autoDispose.family<AsyncValue<List<Conversation>>, String>(
  (ref, userId) {
    final state = ref.watch(chatConversationsProvider(userId));

    if (state.isInitialLoading && state.conversations.isEmpty) {
      return const AsyncValue.loading();
    }
    if (state.error != null && state.conversations.isEmpty) {
      return AsyncValue.error(state.error!, StackTrace.current);
    }
    return AsyncValue.data(state.conversations);
  },
);

/// Watch a single conversation in realtime.
/// autoDispose: typing / metadata listener only while chat is open.
final conversationByIdProvider =
    StreamProvider.autoDispose.family<Conversation?, String>(
  (ref, conversationId) {
    final useCase = ref.watch(
      watchConversationByIdUseCaseProvider,
    );

    return useCase(conversationId);
  },
);

/// Get a single conversation by conversationKey
final conversationByKeyProvider =
    FutureProvider.autoDispose.family<Conversation?, String>(
  (ref, conversationKey) {
    final useCase = ref.watch(
      getConversationByKeyUseCaseProvider,
    );

    return useCase(conversationKey);
  },
);
