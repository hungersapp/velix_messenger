import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:velix_messenger/app/app_routes.dart';
import 'recent_chat_card.dart';

class RecentChatList extends StatelessWidget {
  const RecentChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        children: [
          RecentChatCard(
            name: "Arun",
            message: "Hey! How are you?",
            time: "10:45 AM",
            unreadCount: 2,
            isOnline: true,
            onTap: () {
              context.push(
                AppRoutes.chat,
                extra: {
                  'conversationId': 'conversation_arun',
                  'currentUserId': 'current_user_001',
                  'userName': 'Arun',
                  'profileImageUrl': null,
                },
              );
            },
          ),

          RecentChatCard(
            name: "Priya",
            message: "Photo received 📷",
            time: "09:30 AM",
            unreadCount: 0,
            isOnline: false,
            onTap: () {
              context.push(
                AppRoutes.chat,
                extra: {
                  'conversationId': 'conversation_priya',
                  'currentUserId': 'current_user_001',
                  'userName': 'Priya',
                  'profileImageUrl': null,
                },
              );
            },
          ),

          RecentChatCard(
            name: "Karthik",
            message: "Let's meet tomorrow.",
            time: "Yesterday",
            unreadCount: 1,
            isOnline: true,
            onTap: () {
              context.push(
                AppRoutes.chat,
                extra: {
                  'conversationId': 'conversation_karthik',
                  'currentUserId': 'current_user_001',
                  'userName': 'Karthik',
                  'profileImageUrl': null,
                },
              );
            },
          ),

          RecentChatCard(
            name: "Naveen",
            message: "Thank you 😊",
            time: "Yesterday",
            unreadCount: 0,
            isOnline: false,
            onTap: () {
              context.push(
                AppRoutes.chat,
                extra: {
                  'conversationId': 'conversation_naveen',
                  'currentUserId': 'current_user_001',
                  'userName': 'Naveen',
                  'profileImageUrl': null,
                },
              );
            },
          ),

          RecentChatCard(
            name: "Ram",
            message: "Voice message 🎤",
            time: "Monday",
            unreadCount: 5,
            isOnline: true,
            onTap: () {
              context.push(
                AppRoutes.chat,
                extra: {
                  'conversationId': 'conversation_ram',
                  'currentUserId': 'current_user_001',
                  'userName': 'Ram',
                  'profileImageUrl': null,
                },
              );
            },
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}