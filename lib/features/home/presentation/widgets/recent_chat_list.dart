import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../chat/domain/entities/conversation.dart';
import '../../../chat/presentation/providers/conversation_provider.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../providers/home_provider.dart';
import '../providers/peer_user_provider.dart';
import '../utils/recent_chat_formatters.dart';
import 'recent_chat_card.dart';

/// Recent chats section as a sliver for CustomScrollView performance.
class RecentChatList extends ConsumerWidget {
  const RecentChatList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final searchQuery = ref.watch(
      homeProvider.select((state) => state.searchQuery),
    );

    if (currentUser == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final conversationsAsync = ref.watch(
      conversationProvider(currentUser.uid),
    );

    return conversationsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 32,
          ),
          child: Text(
            'Unable to load chats\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (conversations) {
        final visibleConversations = _filterConversations(
          ref: ref,
          conversations: conversations,
          currentUserId: currentUser.uid,
          searchQuery: searchQuery,
        );

        return SliverMainAxisGroup(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  'Recent Chats',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (conversations.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 32,
                  ),
                  child: Center(
                    child: Text(
                      'No conversations yet.\nTap + to start a chat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else if (visibleConversations.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 32,
                  ),
                  child: Center(
                    child: Text(
                      'No chats found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final conversation = visibleConversations[index];
                    return _RecentChatTile(
                      conversation: conversation,
                      currentUserId: currentUser.uid,
                    );
                  },
                  childCount: visibleConversations.length,
                ),
              ),
          ],
        );
      },
    );
  }

  List<Conversation> _filterConversations({
    required WidgetRef ref,
    required List<Conversation> conversations,
    required String currentUserId,
    required String searchQuery,
  }) {
    if (searchQuery.trim().isEmpty) {
      return conversations;
    }

    return conversations.where((conversation) {
      final otherUserId = otherParticipantId(
        conversation: conversation,
        currentUserId: currentUserId,
      );
      final peer = ref.watch(peerUserProvider(otherUserId)).valueOrNull;

      return matchesRecentChatSearch(
        query: searchQuery,
        conversation: conversation,
        name: peer?.name ?? '',
        phone: peer?.mobile ?? '',
      );
    }).toList();
  }
}

class _RecentChatTile extends ConsumerWidget {
  const _RecentChatTile({
    required this.conversation,
    required this.currentUserId,
  });

  final Conversation conversation;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId = otherParticipantId(
      conversation: conversation,
      currentUserId: currentUserId,
    );
    final peerAsync = ref.watch(peerUserProvider(otherUserId));
    final peer = peerAsync.valueOrNull;

    final name = peer?.name.isNotEmpty == true
        ? peer!.name
        : 'Velix User';
    final photoUrl = peer?.photoUrl;
    final profileImageUrl =
        (photoUrl != null && photoUrl.trim().isNotEmpty) ? photoUrl : null;

    return RecentChatCard(
      name: name,
      lastMessage: formatLastMessagePreview(conversation),
      time: formatConversationTime(conversation.lastMessageAt),
      profileImageUrl: profileImageUrl,
      unreadCount: conversation.unreadCount[currentUserId] ?? 0,
      onTap: () {
        context.push(
          AppRoutes.chat,
          extra: {
            'conversationId': conversation.id,
            'currentUserId': currentUserId,
            'otherUserId': otherUserId,
            'userName': name,
            'profileImageUrl': profileImageUrl,
          },
        );
      },
    );
  }
}
