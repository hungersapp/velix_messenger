import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/exceptions/velix_qr_exceptions.dart';
import '../../domain/services/velix_qr_payload.dart';
import '../providers/velix_qr_connect_provider.dart';
import 'profile_preview_screen.dart';

/// Scans Velix identity QR codes (`velix://user/@…`) with the device camera.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Velix QR'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(
                cutOutSize: MediaQuery.sizeOf(context).shortestSide * 0.7,
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              'Align a Velix QR code inside the frame',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          if (_handling)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;

    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .map((v) => v.trim())
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');

    if (raw.isEmpty) return;

    if (!VelixQrPayload.isValid(raw)) {
      _showMessage('Not a valid Velix QR code');
      return;
    }

    setState(() => _handling = true);
    await _controller.stop();

    try {
      final profile = await ref.read(resolveVelixQrUseCaseProvider)(raw);
      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ProfilePreviewScreen(profile: profile),
        ),
      );
    } on InvalidVelixQrException catch (e) {
      await _resumeAfterError(e.message);
    } on VelixUserNotFoundException catch (e) {
      await _resumeAfterError(e.message);
    } catch (e) {
      await _resumeAfterError('Unable to resolve this Velix QR.');
    }
  }

  Future<void> _resumeAfterError(String message) async {
    if (!mounted) return;
    _showMessage(message);
    setState(() => _handling = false);
    await _controller.start();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.cutOutSize});

  final double cutOutSize;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = const Color(0x99000000);
    final cutOut = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: cutOutSize,
        height: cutOutSize,
      ),
      const Radius.circular(24),
    );

    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(cutOut)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlay);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(cutOut, border);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.cutOutSize != cutOutSize;
  }
}
