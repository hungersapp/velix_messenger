import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_provider.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/new_chat_fab.dart';
import '../widgets/recent_chat_list.dart';
import '../widgets/time_capsule_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),

      appBar: HomeAppBar(
        photoUrl: '',
        onSearch: () {
          // TODO: Open Search Screen
        },
        onProfile: () {
          // TODO: Open Profile Screen
        },
      ),

      body: SafeArea(
        child: homeState.isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TimeCapsuleSection(
                    onYourTcTap: () {
                      // TODO: Create Time Capsule
                    },
                    onUserTap: (userName) {
                      // TODO: View User Time Capsule
                    },
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: homeState.hasChats
                        ? const RecentChatList()
                        : const _EmptyChatView(),
                  ),
                ],
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

class _EmptyChatView extends StatelessWidget {
  const _EmptyChatView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 72,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Start a new conversation using the chat button below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}