import 'package:flutter/material.dart';

class NewChatFab extends StatelessWidget {
  const NewChatFab({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      elevation: 4,
      backgroundColor: const Color(0xFF2563EB),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.chat_rounded,
        size: 28,
      ),
    );
  }
}