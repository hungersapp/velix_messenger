import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary
                              .withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary
                              .withValues(alpha: 0.85),
                        ),
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
    if (pending.mediaType == PendingMediaType.file) {
      return _DocumentPreview(pending: pending);
    }

    if (pending.mediaType == PendingMediaType.voice) {
      return _VoicePreview(pending: pending);
    }

    final isVideo = pending.mediaType == PendingMediaType.video;

    final previewPath = isVideo
        ? (pending.localThumbnailPath ?? pending.localPath)
        : pending.localPath;

    final previewFile = File(previewPath);
    final hasPreviewImage = !isVideo ||
        (pending.localThumbnailPath != null && previewFile.existsSync());

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
                errorBuilder: (_, _, _) => const _BrokenPreview(),
              )
            else if (hasPreviewImage && isVideo)
              Image.file(
                previewFile,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _VideoFallback(),
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

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.pending});

  final PendingMedia pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = pending.fileName?.trim().isNotEmpty == true
        ? pending.fileName!
        : path.basename(pending.localPath);
    final sizeLabel = pending.fileSize != null
        ? _formatBytes(pending.fileSize!)
        : null;

    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            size: 36,
            color: theme.colorScheme.onPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sizeLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    sizeLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary
                          .withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class _VoicePreview extends StatelessWidget {
  const _VoicePreview({required this.pending});

  final PendingMedia pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onColor = theme.colorScheme.onPrimary;
    final durationLabel = pending.durationMs != null && pending.durationMs! > 0
        ? _formatDuration(Duration(milliseconds: pending.durationMs!))
        : null;

    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mic_rounded,
            size: 36,
            color: onColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice message',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (durationLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    durationLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onColor.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: onColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
