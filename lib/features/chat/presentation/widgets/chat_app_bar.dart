import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String userName;
  final String? profileImageUrl;
  final bool isOnline;
  final bool isTyping;
  final VoidCallback onBack;
  final VoidCallback? onMenuPressed;

  const ChatAppBar({
    super.key,
    required this.userName,
    required this.onBack,
    this.profileImageUrl,
    this.isOnline = false,
    this.isTyping = false,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasProfileImage =
        profileImageUrl?.trim().isNotEmpty ?? false;

    return AppBar(
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage:
                hasProfileImage
                    ? NetworkImage(profileImageUrl!)
                    : null,
            child: hasProfileImage
                ? null
                : Text(
                    userName.isNotEmpty
                        ? userName[0].toUpperCase()
                        : '?',
                  ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  isTyping
                      ? 'Typing...'
                      : isOnline
                          ? 'Online'
                          : 'Last seen recently',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (onMenuPressed != null)
          IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(Icons.more_vert),
          ),
      ],
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight);
}