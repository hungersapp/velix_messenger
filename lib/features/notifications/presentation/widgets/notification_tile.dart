import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/app_notification.dart';

/// Generic notification row — specialized content is composed by the screen.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.trailing,
    this.onTap,
  });

  final AppNotification notification;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto =
        notification.photoUrl != null && notification.photoUrl!.trim().isNotEmpty;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage:
            hasPhoto ? NetworkImage(notification.photoUrl!) : null,
        child: hasPhoto
            ? null
            : Icon(
                _iconForType(notification.type),
                color: theme.colorScheme.onPrimaryContainer,
              ),
      ),
      title: Text(
        notification.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.subtitle != null &&
              notification.subtitle!.trim().isNotEmpty)
            Text(notification.subtitle!),
          Text(
            notification.body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatTime(notification.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: trailing,
    );
  }

  IconData _iconForType(NotificationType type) {
    return switch (type) {
      NotificationType.friendRequest => Icons.person_add_alt_1_rounded,
      NotificationType.timeCapsuleLike => Icons.favorite_rounded,
      NotificationType.mention => Icons.alternate_email_rounded,
      NotificationType.systemAnnouncement => Icons.campaign_rounded,
    };
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().add_jm().format(local);
  }
}
