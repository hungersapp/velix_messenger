import 'package:flutter/material.dart';

import '../../../user/domain/entities/user_entity.dart';
import '../../domain/services/velix_qr_payload.dart';
import 'profile_avatar.dart';
import 'velix_qr_code.dart';

/// Premium digital-identity card: avatar, name, Velix ID, and large QR.
class MyVelixQrCard extends StatelessWidget {
  const MyVelixQrCard({
    super.key,
    required this.user,
    this.caption = 'Scan this QR to connect on Velix',
  });

  final UserEntity user;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final handle = VelixQrPayload.displayHandle(user.velixId);
    final payload = VelixQrPayload.fromVelixId(user.velixId);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final qrSize = (screenWidth * 0.58).clamp(200.0, 280.0);

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileAvatar(
              displayName: user.name,
              photoUrl: user.photoUrl.isEmpty ? null : user.photoUrl,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (handle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                handle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 28),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: VelixQrCode(
                  data: payload,
                  size: qrSize,
                  padding: const EdgeInsets.all(18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
