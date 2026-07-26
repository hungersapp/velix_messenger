import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/call_controller.dart';

/// Outgoing / active voice call UI for Tap-to-Call.
class ActiveCallScreen extends ConsumerWidget {
  const ActiveCallScreen({super.key});

  String _formatElapsed(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final call = ref.watch(callControllerProvider);
    final session = call.session;

    ref.listen<CallUiState>(callControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage &&
          context.mounted) {
        final message = next.errorMessage!;
        final openSettings = message.contains('permanently denied');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: openSettings
                ? SnackBarAction(
                    label: 'Settings',
                    onPressed: openAppSettings,
                  )
                : null,
          ),
        );
        ref.read(callControllerProvider.notifier).clearError();
      }

      if (next.phase == CallPhase.ended &&
          previous?.phase != CallPhase.ended &&
          context.mounted &&
          Navigator.of(context).canPop()) {
        Future<void>.delayed(const Duration(milliseconds: 600), () {
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            ref.read(callControllerProvider.notifier).resetToIdle();
          }
        });
      }
    });

    final displayName = session == null
        ? 'Unknown'
        : (call.isOutgoing ? session.receiverName : session.callerName);
    final photoUrl = session == null
        ? null
        : (call.isOutgoing ? session.receiverPhotoUrl : session.callerPhotoUrl);
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;

    final statusText = switch (call.phase) {
      CallPhase.dialing => 'Calling...',
      CallPhase.connecting => 'Connecting...',
      CallPhase.connected => _formatElapsed(call.elapsed),
      CallPhase.ended => call.statusLabel.isEmpty ? 'Call ended' : call.statusLabel,
      _ => call.statusLabel.isEmpty ? 'Voice call' : call.statusLabel,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await ref.read(callControllerProvider.notifier).endCall();
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              children: [
                Text(
                  call.phase == CallPhase.connected
                      ? 'Voice call'
                      : (call.isOutgoing ? 'Voice call' : 'Incoming call'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 64,
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                  child: hasPhoto
                      ? null
                      : Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.headlineLarge,
                        ),
                ),
                const SizedBox(height: 20),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  statusText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: call.phase == CallPhase.connected
                        ? const [FontFeature.tabularFigures()]
                        : null,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CallControl(
                      icon: call.isMuted ? Icons.mic_off : Icons.mic,
                      label: call.isMuted ? 'Unmute' : 'Mute',
                      selected: call.isMuted,
                      onTap: () {
                        ref.read(callControllerProvider.notifier).toggleMute();
                      },
                    ),
                    _CallControl(
                      icon: call.isSpeakerOn
                          ? Icons.volume_up
                          : Icons.volume_down,
                      label: 'Speaker',
                      selected: call.isSpeakerOn,
                      onTap: () {
                        ref
                            .read(callControllerProvider.notifier)
                            .toggleSpeaker();
                      },
                    ),
                    _CallControl(
                      icon: Icons.call_end,
                      label: 'End Call',
                      color: Colors.red,
                      onTap: () async {
                        await ref
                            .read(callControllerProvider.notifier)
                            .endCall();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = color ??
        (selected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest);

    return Column(
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(
                icon,
                color: color != null
                    ? Colors.white
                    : (selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
