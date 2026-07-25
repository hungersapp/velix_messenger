import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders a Velix identity QR from a deep-link [data] payload.
class VelixQrCode extends StatelessWidget {
  const VelixQrCode({
    super.key,
    required this.data,
    this.size = 240,
    this.padding = const EdgeInsets.all(16),
  });

  final String data;
  final double size;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (data.trim().isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.qr_code_2_rounded,
          size: size * 0.55,
          color: colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      );
    }

    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      padding: padding,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF0F172A),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF0F172A),
      ),
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }
}
