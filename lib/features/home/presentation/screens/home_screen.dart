import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/domain/entities/user_entity.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/recent_chat_list.dart';
import '../widgets/time_capsule_section.dart';
import 'package:velix_messenger/features/contacts/presentation/screens/contacts_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text(
            'Something went wrong\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (user) => _HomeContent(user: user),
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent({
    required this.user,
  });

  final UserEntity? user;

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  final TextEditingController _searchController =
      TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);

    return Scaffold(
      appBar: HomeAppBar(
        user: widget.user,
        isSearchActive: homeState.isSearchActive,
        onSearch: () {
          final notifier = ref.read(homeProvider.notifier);
          if (homeState.isSearchActive) {
            _searchController.clear();
            notifier.closeSearch();
          } else {
            notifier.openSearch();
          }
        },
        onProfile: () {
          // TODO: Profile Screen
        },
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            if (homeState.isSearchActive)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) {
                      ref
                          .read(homeProvider.notifier)
                          .updateSearch(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search chats...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: homeState.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(homeProvider.notifier)
                                    .clearSearch();
                              },
                            )
                          : null,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 12),
            ),
            const SliverToBoxAdapter(
              child: TimeCapsuleSection(),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
            const RecentChatList(),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ContactsScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
