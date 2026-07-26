import 'dart:io';

class NetworkAvailabilityService {
  const NetworkAvailabilityService();

  /// Lightweight connectivity probe used before placing a call.
  Future<bool> hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('dns.google')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on Exception {
      return false;
    }
  }
}
