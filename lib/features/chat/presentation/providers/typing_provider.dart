import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_provider.dart';

/// Update Typing Status Controller
///
/// Debounces `isTyping: true` writes so keystrokes do not hammer Firestore.
/// Clearing typing (`false`) is sent immediately.
class TypingController extends StateNotifier<AsyncValue<void>> {
  TypingController(this.ref) : super(const AsyncData(null));

  final Ref ref;
  Timer? _debounce;
  String? _pendingConversationId;
  String? _pendingUserId;
  bool? _lastWritten;

  Future<void> updateTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    _debounce?.cancel();
    _pendingConversationId = conversationId;
    _pendingUserId = userId;

    if (!isTyping) {
      await _write(
        conversationId: conversationId,
        userId: userId,
        isTyping: false,
      );
      return;
    }

    if (_lastWritten == true &&
        _pendingConversationId == conversationId &&
        _pendingUserId == userId) {
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(
        _write(
          conversationId: conversationId,
          userId: userId,
          isTyping: true,
        ),
      );
    });
  }

  Future<void> _write({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    if (_lastWritten == isTyping &&
        _pendingConversationId == conversationId &&
        _pendingUserId == userId) {
      return;
    }

    state = const AsyncLoading();
    try {
      await ref.read(updateTypingStatusUseCaseProvider).call(
            conversationId: conversationId,
            userId: userId,
            isTyping: isTyping,
          );
      _lastWritten = isTyping;
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // Best-effort clear so peers do not see a stuck typing indicator.
    final conversationId = _pendingConversationId;
    final userId = _pendingUserId;
    if (conversationId != null &&
        userId != null &&
        _lastWritten == true) {
      unawaited(
        ref.read(updateTypingStatusUseCaseProvider).call(
              conversationId: conversationId,
              userId: userId,
              isTyping: false,
            ),
      );
    }
    super.dispose();
  }
}

/// Provider
final typingControllerProvider =
    StateNotifierProvider<TypingController, AsyncValue<void>>(
  (ref) => TypingController(ref),
);