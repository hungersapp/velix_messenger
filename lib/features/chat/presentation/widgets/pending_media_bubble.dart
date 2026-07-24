import 'dart:io';

import 'package:flutter/material.dart';

import '../providers/pending_media_provider.dart';

class PendingMediaBubble extends StatelessWidget {
  final PendingMedia pending;

  const PendingMediaBubble({
    super.key,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerRight,
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
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MediaPreview(pending: pending),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sending...',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                          color: theme.colorScheme.onPrimary
                              .withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: theme.colorScheme.onPrimary
                            .withValues(alpha: 0.75),
                      ),
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

class _MediaPreview extends StatelessWidget {
  final PendingMedia pending;

  const _MediaPreview({required this.pending});

  @override
  Widget build(BuildContext context) {
    final isVideo =
        pending.mediaType == PendingMediaType.video;

    final previewPath = isVideo
        ? (pending.localThumbnailPath ?? pending.localPath)
        : pending.localPath;

    final previewFile = File(previewPath);
    final hasPreviewImage = !isVideo ||
        (pending.localThumbnailPath != null &&
            previewFile.existsSync());

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPreviewImage && !isVideo)
              Image.file(
                File(pending.localPath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const _BrokenPreview(),
              )
            else if (hasPreviewImage && isVideo)
              Image.file(
                previewFile,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const _VideoFallback(),
              )
            else
              const _VideoFallback(),
            Container(
              color: Colors.black26,
            ),
            if (isVideo)
              const Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black54,
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokenPreview extends StatelessWidget {
  const _BrokenPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: const Icon(
        Icons.broken_image,
        size: 50,
        color: Colors.white70,
      ),
    );
  }
}

class _VideoFallback extends StatelessWidget {
  const _VideoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: const Icon(
        Icons.videocam,
        size: 50,
        color: Colors.white70,
      ),
    );
  }
}
