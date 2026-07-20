import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_provider.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/greeting_card.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/recent_chat_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: const HomeAppBar(
        photoUrl: '',
      ),

      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: const [
            ChatsPage(),
            PeoplePage(),
            CallsPage(),
            ProfilePage(),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        elevation: 5,
        backgroundColor: const Color(0xFF7C4DFF),
        onPressed: () {
          // TODO : Open New Chat Screen
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomNavigation(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(homeProvider.notifier).changeIndex(index);
        },
      ),
    );
  }
}

/// ---------------- CHAT ----------------

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        GreetingCard(),
        RecentChatList(),
      ],
    );
  }
}

/// ---------------- PEOPLE ----------------

class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "👥\nPeople\n\nComing Soon",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// ---------------- CALLS ----------------

class CallsPage extends StatelessWidget {
  const CallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "📞\nCalls\n\nComing Soon",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// ---------------- PROFILE ----------------

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "👤\nProfile\n\nComing Soon",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}