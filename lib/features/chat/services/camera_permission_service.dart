import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

class CameraPermissionService {
  const CameraPermissionService();

  Future<CameraPermissionResult> ensureGranted() async {
    final current = await Permission.camera.status;
    if (current.isGranted || current.isLimited) {
      return CameraPermissionResult.granted;
    }

    final requested = await Permission.camera.request();
    if (requested.isGranted || requested.isLimited) {
      return CameraPermissionResult.granted;
    }

    if (requested.isPermanentlyDenied) {
      return CameraPermissionResult.permanentlyDenied;
    }

    return CameraPermissionResult.denied;
  }

  Future<bool> openSettings() {
    return openAppSettings();
  }
}
