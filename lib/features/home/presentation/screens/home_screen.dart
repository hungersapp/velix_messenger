import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/domain/entities/user_entity.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/new_chat_fab.dart';
import '../widgets/recent_chat_list.dart';
import '../widgets/time_capsule_section.dart';

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

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.user,
  });

  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        user: user,
        onSearch: () {
          // TODO: Search Screen
        },
        onProfile: () {
          // TODO: Profile Screen
        },
      ),

      body: const SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 12),

              TimeCapsuleSection(),

              SizedBox(height: 16),

              RecentChatList(),

              SizedBox(height: 80),
            ],
          ),
        ),
      ),

      floatingActionButton: NewChatFab(
  onPressed: () {
    // TODO: Navigate to New Chat Screen
  },
),
    );
  }
}