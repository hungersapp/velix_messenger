import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/debug/nav_debug_log.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/entities/friend_entity.dart';
import '../providers/contacts_provider.dart';
import '../providers/friends_state.dart';
import '../widgets/friend_tile.dart';
import '../widgets/search_bar.dart';
import 'friend_requests_screen.dart';

/// Displays only Velix friends (accepted QR / search requests).
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    navLog('Contacts', 'initState');
    Future.microtask(() {
      ref.read(friendsProvider.notifier).loadFriends();
    });
  }

  @override
  void dispose() {
    navLog('Contacts', 'dispose');
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FriendsState state = ref.watch(friendsProvider);

    navLog('Contacts', 'build', {
      'isLoading': state.isLoading,
      'friendsCount': state.friends.length,
      'goRouterLocation': goRouterLocationOf(context),
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Friend requests',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FriendRequestsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(friendsProvider.notifier).refresh(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: FriendsSearchBar(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(friendsProvider.notifier).search(value);
                },
              ),
            ),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(FriendsState state) {
    if (state.isLoading && state.friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.friends.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.4,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (state.friends.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'No friends yet.\nTap the + button to scan a Velix QR.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.4),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.friends.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final FriendEntity friend = state.friends[index];
        return FriendTile(
          friend: friend,
          onTap: () => _openChat(friend),
        );
      },
    );
  }

  Future<void> _openChat(FriendEntity friend) async {
    final currentUser = ref.read(currentUserProvider).value;

    navLog('Contacts', 'openChat start', {
      'currentUser': currentUser?.uid,
      'friendUid': friend.uid,
      'friendName': friend.displayName,
    });

    if (currentUser == null || friend.uid.isEmpty) {
      return;
    }

    final conversationId = await ref.read(openChatUseCaseProvider).call(
          currentUserUid: currentUser.uid,
          otherUserUid: friend.uid,
        );

    if (!mounted) return;

    context.push(
      AppRoutes.chat,
      extra: {
        'conversationId': conversationId,
        'currentUserId': currentUser.uid,
        'otherUserId': friend.uid,
        'userName': friend.displayName,
        'profileImageUrl':
            friend.photoUrl.isEmpty ? null : friend.photoUrl,
      },
    );
  }
}
