import 'package:flutter/material.dart';

import '../screens/image_viewer_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/video_player_screen.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String messageType;
  final String? mediaUrl;
  final DateTime sentAt;
  final bool isMe;
  final String status;
  final String? thumbnailUrl;

  const MessageBubble({
    super.key,
    required this.message,
    required this.messageType,
    this.mediaUrl,
    required this.sentAt,
    required this.isMe,
    required this.status,
    this.thumbnailUrl,
  });

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  IconData _statusIcon() {
    switch (status) {
      case 'sending':
        return Icons.schedule;
      case 'sent':
        return Icons.done;
      case 'delivered':
        return Icons.done_all;
      case 'read':
        return Icons.done_all;
      default:
        return Icons.done;
    }
  }

  Color _statusColor(BuildContext context) {
    switch (status) {
      case 'read':
        return Colors.blue;
      case 'sending':
        return Colors.grey;
      default:
        return isMe
            ? Theme.of(context)
                .colorScheme
                .onPrimary
                .withValues(alpha: 0.75)
            : Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 320,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isMe
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                10,
                10,
                8,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
               children: [
  /// IMAGE MESSAGE
  if (messageType == 'image' &&
      mediaUrl != null &&
      mediaUrl!.isNotEmpty)
    GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageViewerScreen(
              imageUrl: mediaUrl!,
              heroTag: mediaUrl!,
            ),
          ),
        );
      },
      child: Hero(
        tag: mediaUrl!,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: mediaUrl!,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(
              width: 220,
              height: 220,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => const SizedBox(
              width: 220,
              height: 220,
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ),
    )
  else if (messageType == 'video' &&
      mediaUrl != null &&
      mediaUrl!.isNotEmpty)
   VideoMessagePreview(
  videoUrl: mediaUrl!,
  thumbnailUrl: thumbnailUrl,
)
  else
    Text(
      message,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: isMe
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
      ),
    ),

  const SizedBox(height: 6),

  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        _formatTime(sentAt),
        style: theme.textTheme.bodySmall?.copyWith(
          color: isMe
              ? theme.colorScheme.onPrimary.withValues(alpha: 0.75)
              : Colors.grey,
        ),
      ),
      if (isMe) ...[
        const SizedBox(width: 4),
        Icon(
          _statusIcon(),
          size: 16,
          color: _statusColor(context),
        ),
      ],
    ],
  ),
],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class VideoMessagePreview extends StatelessWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const VideoMessagePreview({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              videoUrl: videoUrl,
            ),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: thumbnailUrl ?? '',
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              placeholder: (_, _) => const SizedBox(
                width: 220,
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (_, _, _) => Container(
                width: 220,
                height: 220,
                color: Colors.black12,
                child: const Icon(
                  Icons.videocam,
                  size: 50,
                ),
              ),
            ),
          ),
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.black54,
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}