import 'package:flutter/material.dart';

import 'recent_chat_card.dart';

class RecentChatList extends StatelessWidget {
  const RecentChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Recent Chats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        RecentChatCard(
          name: 'Arun',
          lastMessage: 'Hey! How are you?',
          time: '10:45 AM',
          unreadCount: 2,
          isOnline: true,
          onTap: () {
            // TODO: Open Chat Screen
          },
        ),

        RecentChatCard(
          name: 'Priya',
          lastMessage: 'Photo received 📷',
          time: '09:30 AM',
          unreadCount: 0,
          isOnline: false,
          onTap: () {
            // TODO: Open Chat Screen
          },
        ),

        RecentChatCard(
          name: 'Karthik',
          lastMessage: "Let's meet tomorrow.",
          time: 'Yesterday',
          unreadCount: 1,
          isOnline: true,
          isPinned: true,
          onTap: () {
            // TODO: Open Chat Screen
          },
        ),

        RecentChatCard(
          name: 'Naveen',
          lastMessage: 'Thank you 😊',
          time: 'Yesterday',
          unreadCount: 0,
          isMuted: true,
          onTap: () {
            // TODO: Open Chat Screen
          },
        ),

        RecentChatCard(
          name: 'Ram',
          lastMessage: 'Voice message 🎤',
          time: 'Monday',
          unreadCount: 5,
          isOnline: true,
          onTap: () {
            // TODO: Open Chat Screen
          },
        ),
      ],
    );
  }
}