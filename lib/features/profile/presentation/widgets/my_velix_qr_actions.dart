import 'package:flutter/material.dart';

/// Bottom actions for the My Velix QR screen.
///
/// [onShareQr] is prepared for a later `share_plus` integration.
/// [onOpenScanner] is prepared for navigation to the QR Scanner page.
class MyVelixQrActions extends StatelessWidget {
  const MyVelixQrActions({
    super.key,
    this.onShareQr,
    this.onOpenScanner,
  });

  final VoidCallback? onShareQr;
  final VoidCallback? onOpenScanner;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onShareQr,
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text(
            'Share QR',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onOpenScanner,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text(
            'Open Scanner',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.45),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}
