import 'package:permission_handler/permission_handler.dart';

enum MicrophonePermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

class MicrophonePermissionService {
  const MicrophonePermissionService();

  Future<MicrophonePermissionResult> ensureGranted() async {
    final current = await Permission.microphone.status;
    if (current.isGranted || current.isLimited) {
      return MicrophonePermissionResult.granted;
    }

    final requested = await Permission.microphone.request();
    if (requested.isGranted || requested.isLimited) {
      return MicrophonePermissionResult.granted;
    }

    if (requested.isPermanentlyDenied) {
      return MicrophonePermissionResult.permanentlyDenied;
    }

    return MicrophonePermissionResult.denied;
  }

  Future<bool> openSettings() {
    return openAppSettings();
  }
}
