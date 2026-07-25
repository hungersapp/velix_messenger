import 'package:flutter/material.dart';

import '../../../user/domain/entities/user_entity.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    required this.user,
    this.onSearch,
    this.onAdd,
    this.onNotifications,
    this.onProfile,
    this.isSearchActive = false,
    this.unreadNotificationCount = 0,
  });

  final UserEntity? user;
  final VoidCallback? onSearch;
  final VoidCallback? onAdd;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final bool isSearchActive;
  final int unreadNotificationCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Image.asset(
            'assets/images/app_logo.png',
            width: 45,
            height: 45,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Text(
            'Velix',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: onSearch,
          icon: Icon(
            isSearchActive ? Icons.close : Icons.search,
          ),
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
        ),
        IconButton(
          onPressed: onNotifications,
          tooltip: 'Notifications',
          icon: Badge(
            isLabelVisible: unreadNotificationCount > 0,
            label: Text(
              unreadNotificationCount > 99
                  ? '99+'
                  : '$unreadNotificationCount',
            ),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 8),
          child: InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(24),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blueGrey.shade100,
              backgroundImage: _buildProfileImage(),
              child: _buildProfileImage() == null
                  ? Text(
                      _initials(user?.name),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? _buildProfileImage() {
    if (user == null) return null;
    if (user!.photoUrl.trim().isEmpty) return null;
    return NetworkImage(user!.photoUrl);
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
