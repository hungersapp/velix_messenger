import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/voice_playback_provider.dart';

class VoiceMessageBubble extends ConsumerWidget {
  const VoiceMessageBubble({
    super.key,
    required this.messageId,
    required this.mediaUrl,
    required this.isMe,
    this.durationMs,
  });

  final String messageId;
  final String mediaUrl;
  final bool isMe;
  final int? durationMs;

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(1, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playback = ref.watch(voicePlaybackProvider);
    final isActive = playback.isActive(messageId);
    final knownDuration = durationMs != null && durationMs! > 0
        ? Duration(milliseconds: durationMs!)
        : Duration.zero;

    final displayDuration = isActive && playback.duration > Duration.zero
        ? playback.duration
        : knownDuration;
    final position = isActive ? playback.position : Duration.zero;
    final progress = displayDuration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / displayDuration.inMilliseconds)
            .clamp(0.0, 1.0);

    final onColor =
        isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final subtle = onColor.withValues(alpha: 0.75);

    final IconData icon;
    if (isActive && playback.status == VoicePlaybackStatus.loading) {
      icon = Icons.hourglass_top_rounded;
    } else if (isActive && playback.status == VoicePlaybackStatus.playing) {
      icon = Icons.pause_rounded;
    } else {
      icon = Icons.play_arrow_rounded;
    }

    return Material(
      color: onColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Material(
              color: onColor.withValues(alpha: 0.16),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  final controller =
                      ref.read(voicePlaybackProvider.notifier);
                  await controller.toggle(
                    messageId: messageId,
                    mediaUrl: mediaUrl,
                    knownDuration: knownDuration > Duration.zero
                        ? knownDuration
                        : null,
                  );
                  final latest = ref.read(voicePlaybackProvider);
                  if (latest.status == VoicePlaybackStatus.error &&
                      context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          latest.errorMessage ??
                              'Unable to play this voice message.',
                        ),
                      ),
                    );
                  }
                },
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(icon, color: onColor),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: onColor,
                      inactiveTrackColor: onColor.withValues(alpha: 0.25),
                      thumbColor: onColor,
                      overlayColor: onColor.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: isActive
                          ? (value) {
                              if (displayDuration.inMilliseconds <= 0) {
                                return;
                              }
                              final seekTo = Duration(
                                milliseconds:
                                    (displayDuration.inMilliseconds * value)
                                        .round(),
                              );
                              ref
                                  .read(voicePlaybackProvider.notifier)
                                  .seek(seekTo);
                            }
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(
                            isActive ? position : Duration.zero,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtle,
                          ),
                        ),
                        Text(
                          _formatDuration(displayDuration),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
