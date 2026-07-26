import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/call_session.dart';
import '../providers/call_controller.dart';
import 'active_call_screen.dart';
import 'active_video_call_screen.dart';

class IncomingCallScreen extends ConsumerWidget {
  const IncomingCallScreen({
    super.key,
    required this.session,
  });

  final CallSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final photo = session.callerPhotoUrl;
    final hasPhoto = photo != null && photo.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              Text(
                session.isVideo
                    ? 'Incoming video call'
                    : 'Incoming voice call',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              CircleAvatar(
                radius: 64,
                backgroundImage: hasPhoto ? NetworkImage(photo) : null,
                child: hasPhoto
                    ? null
                    : Text(
                        session.callerName.isNotEmpty
                            ? session.callerName[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.headlineLarge,
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                session.callerName,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundAction(
                    color: Colors.red,
                    icon: Icons.call_end,
                    label: 'Decline',
                    onTap: () async {
                      await ref
                          .read(callControllerProvider.notifier)
                          .declineIncomingCall(session);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ref.read(callControllerProvider.notifier).resetToIdle();
                      }
                    },
                  ),
                  _RoundAction(
                    color: Colors.green,
                    icon: session.isVideo ? Icons.videocam : Icons.call,
                    label: 'Accept',
                    onTap: () async {
                      await ref
                          .read(callControllerProvider.notifier)
                          .acceptIncomingCall(session);
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          fullscreenDialog: true,
                          builder: (_) => session.isVideo
                              ? const ActiveVideoCallScreen()
                              : const ActiveCallScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(label),
      ],
    );
  }
}
