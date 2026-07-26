import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_routes.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/entities/call_history_entry.dart';
import '../../domain/entities/call_session.dart';
import '../providers/call_history_provider.dart';

class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({
    super.key,
    this.showAppBar = true,
  });

  /// When embedded as a home tab, the parent already provides chrome.
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(callHistoryProvider);
    final theme = Theme.of(context);

    final body = historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unable to load call history\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No calls yet.\nVoice and video calls will appear here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            return CallHistoryTile(entry: entries[index]);
          },
        );
      },
    );

    if (!showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
      ),
      body: body,
    );
  }
}

class CallHistoryTile extends ConsumerWidget {
  const CallHistoryTile({
    super.key,
    required this.entry,
  });

  final CallHistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasPhoto =
        entry.peerPhotoUrl != null && entry.peerPhotoUrl!.trim().isNotEmpty;
    final when = entry.startedAt ?? entry.createdAt;
    final dateLabel = DateFormat.MMMd().format(when);
    final timeLabel = DateFormat.jm().format(when);
    final durationLabel = _formatDuration(entry.durationSeconds);
    final directionColor = entry.isMissed
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: hasPhoto ? NetworkImage(entry.peerPhotoUrl!) : null,
        child: hasPhoto
            ? null
            : Text(
                entry.peerName.isNotEmpty
                    ? entry.peerName[0].toUpperCase()
                    : '?',
              ),
      ),
      title: Text(
        entry.peerName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: entry.isMissed ? theme.colorScheme.error : null,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            _directionIcon(entry),
            size: 16,
            color: directionColor,
          ),
          const SizedBox(width: 4),
          Icon(
            entry.callType == CallType.video
                ? Icons.videocam_outlined
                : Icons.call_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              [
                dateLabel,
                timeLabel,
                ?durationLabel,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      trailing: Icon(
        entry.callType == CallType.video ? Icons.videocam : Icons.call,
        color: theme.colorScheme.primary,
      ),
      onTap: () => _openChat(context, ref),
    );
  }

  IconData _directionIcon(CallHistoryEntry entry) {
    if (entry.isMissed) {
      return entry.direction == CallDirection.incoming
          ? Icons.call_missed
          : Icons.call_missed_outgoing;
    }
    return entry.direction == CallDirection.incoming
        ? Icons.call_received
        : Icons.call_made;
  }

  String? _formatDuration(int seconds) {
    if (seconds <= 0) return null;
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    if (minutes <= 0) return '${remaining}s';
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null || entry.peerId.isEmpty) return;

    final conversationId = await ref.read(openChatUseCaseProvider).call(
          currentUserUid: currentUser.uid,
          otherUserUid: entry.peerId,
        );

    if (!context.mounted) return;

    context.push(
      AppRoutes.chat,
      extra: {
        'conversationId': conversationId,
        'currentUserId': currentUser.uid,
        'otherUserId': entry.peerId,
        'userName': entry.peerName,
        'profileImageUrl': entry.peerPhotoUrl,
      },
    );
  }
}
