import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_provider.dart';

/// Update Typing Status Controller
class TypingController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  TypingController(this.ref)
      : super(const AsyncData(null));

  Future<void> updateTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(updateTypingStatusUseCaseProvider)
          .call(
            conversationId: conversationId,
            userId: userId,
            isTyping: isTyping,
          );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider
final typingControllerProvider =
    StateNotifierProvider<
        TypingController,
        AsyncValue<void>>(
  (ref) => TypingController(ref),
);