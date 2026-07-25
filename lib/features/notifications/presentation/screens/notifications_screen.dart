import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/presentation/providers/conversation_provider.dart';
import '../../../contacts/domain/entities/friend_request_entity.dart';
import '../../../contacts/domain/exceptions/friend_request_exceptions.dart';
import '../../../contacts/presentation/providers/contacts_provider.dart';
import '../../../profile/domain/services/velix_qr_payload.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_tile.dart';

/// Extensible notifications inbox. Currently renders friend requests;
/// add new [NotificationType] sections as channels come online.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _busy = {};

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Unable to load notifications.'),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text('No notifications yet'),
            );
          }

          final friendRequests = notifications
              .where((n) => n.type == NotificationType.friendRequest)
              .toList();
          final others = notifications
              .where((n) => n.type != NotificationType.friendRequest)
              .toList();

          return ListView(
            children: [
              if (friendRequests.isNotEmpty) ...[
                _SectionHeader(title: 'Friend Requests'),
                ...friendRequests.map(_buildFriendRequestTile),
              ],
              if (others.isNotEmpty) ...[
                _SectionHeader(title: 'Other'),
                ...others.map(
                  (n) => NotificationTile(notification: n),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildFriendRequestTile(AppNotification notification) {
    final request = notification.friendRequest;
    if (request == null) {
      return NotificationTile(notification: notification);
    }

    final handle = VelixQrPayload.displayHandle(request.velixId);
    final busy = _busy.contains(request.fromUid);
    final display = AppNotification(
      id: notification.id,
      type: notification.type,
      title: request.displayName,
      body: 'wants to connect on Velix',
      createdAt: request.createdAt,
      photoUrl: notification.photoUrl,
      subtitle: handle,
      friendRequest: request,
    );

    return NotificationTile(
      notification: display,
      trailing: busy
          ? const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => _decline(request),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _accept(request),
                  child: const Text('Accept'),
                ),
              ],
            ),
    );
  }

  Future<void> _accept(FriendRequestEntity request) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() => _busy.add(request.fromUid));

    try {
      await ref.read(acceptFriendRequestUseCaseProvider)(
        currentUser: currentUser,
        request: request,
      );

      ref.invalidate(friendsProvider);
      ref.invalidate(contactsProvider);
      ref.invalidate(syncContactsUseCaseProvider);
      ref.invalidate(conversationProvider(currentUser.uid));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend added successfully.')),
      );
    } on FriendRequestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to accept request.')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy.remove(request.fromUid));
      }
    }
  }

  Future<void> _decline(FriendRequestEntity request) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() => _busy.add(request.fromUid));

    try {
      await ref.read(declineFriendRequestUseCaseProvider)(
        fromUid: request.fromUid,
        toUid: currentUser.uid,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to decline request.')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy.remove(request.fromUid));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
