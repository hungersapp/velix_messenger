import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/call_controller.dart';

class ActiveVideoCallScreen extends ConsumerWidget {
  const ActiveVideoCallScreen({super.key});

  String _formatElapsed(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final call = ref.watch(callControllerProvider);
    final controller = ref.read(callControllerProvider.notifier);
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
    final localRenderer = controller.localRenderer;
    final remoteRenderer = controller.remoteRenderer;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await ref.read(callControllerProvider.notifier).endCall();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: remoteRenderer != null &&
                        remoteRenderer.srcObject != null
                    ? RTCVideoView(
                        remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : Container(
                        color: Colors.black87,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam_off,
                              color: Colors.white54,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              call.isReconnecting
                                  ? 'Reconnecting...'
                                  : call.statusLabel.isEmpty
                                      ? 'Connecting video...'
                                      : call.statusLabel,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            call.isReconnecting
                                ? 'Reconnecting...'
                                : call.phase == CallPhase.connected
                                    ? _formatElapsed(call.elapsed)
                                    : call.statusLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                top: 88,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 110,
                    height: 160,
                    color: Colors.black54,
                    child: call.isCameraEnabled &&
                            localRenderer != null &&
                            localRenderer.srcObject != null
                        ? RTCVideoView(
                            localRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                          )
                        : const Center(
                            child: Icon(
                              Icons.videocam_off,
                              color: Colors.white70,
                            ),
                          ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _VideoControl(
                      icon: call.isMuted ? Icons.mic_off : Icons.mic,
                      label: call.isMuted ? 'Unmute' : 'Mute',
                      onTap: () {
                        ref.read(callControllerProvider.notifier).toggleMute();
                      },
                    ),
                    _VideoControl(
                      icon: call.isCameraEnabled
                          ? Icons.videocam
                          : Icons.videocam_off,
                      label: call.isCameraEnabled ? 'Camera' : 'Cam off',
                      onTap: () {
                        ref
                            .read(callControllerProvider.notifier)
                            .toggleCamera();
                      },
                    ),
                    _VideoControl(
                      icon: Icons.cameraswitch,
                      label: 'Flip',
                      onTap: call.isCameraEnabled
                          ? () {
                              ref
                                  .read(callControllerProvider.notifier)
                                  .switchCamera();
                            }
                          : null,
                    ),
                    _VideoControl(
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
                    _VideoControl(
                      icon: Icons.call_end,
                      label: 'End',
                      color: Colors.red,
                      onTap: () async {
                        await ref
                            .read(callControllerProvider.notifier)
                            .endCall();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoControl extends StatelessWidget {
  const _VideoControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ??
        (selected ? Colors.white : Colors.white24);
    final fg = color != null
        ? Colors.white
        : (selected ? Colors.black : Colors.white);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(icon, color: fg),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
