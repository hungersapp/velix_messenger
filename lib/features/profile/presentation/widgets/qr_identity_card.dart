import 'package:flutter/material.dart';

import '../../domain/services/velix_qr_payload.dart';
import 'velix_qr_code.dart';

/// Compact QR preview for profile surfaces (identity connect, not payment).
class QrIdentityCard extends StatelessWidget {
  const QrIdentityCard({
    super.key,
    required this.velixId,
    this.size = 220,
  });

  /// Velix ID with or without leading `@`.
  final String velixId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final payload = VelixQrPayload.fromVelixId(velixId);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: VelixQrCode(
        data: payload,
        size: size,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
