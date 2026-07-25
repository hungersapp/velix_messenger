import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../contacts/domain/entities/friend_request_entity.dart';
import '../../../contacts/presentation/providers/contacts_provider.dart';
import '../../domain/entities/app_notification.dart';

/// Live incoming friend requests (source for friend-request notifications).
final incomingFriendRequestsProvider =
    StreamProvider<List<FriendRequestEntity>>((ref) {
  return ref.watch(watchIncomingFriendRequestsUseCaseProvider)();
});

/// Aggregated notifications feed — currently maps friend requests;
/// extend by merging additional streams for likes, mentions, etc.
final notificationsProvider =
    Provider<AsyncValue<List<AppNotification>>>((ref) {
  final requestsAsync = ref.watch(incomingFriendRequestsProvider);

  return requestsAsync.when(
    data: (requests) {
      final items = <AppNotification>[
        for (final request in requests)
          AppNotification.fromFriendRequest(request),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return AsyncValue<List<AppNotification>>.data(items);
    },
    loading: () => const AsyncValue<List<AppNotification>>.loading(),
    error: (error, stackTrace) =>
        AsyncValue<List<AppNotification>>.error(error, stackTrace),
  );
});

/// Unread count for the Home AppBar badge.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (items) => items.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});
