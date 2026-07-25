class InvalidVelixQrException implements Exception {
  InvalidVelixQrException([
    this.message = 'This QR code is not a valid Velix identity.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class VelixUserNotFoundException implements Exception {
  VelixUserNotFoundException([
    this.message = 'No Velix user found for this QR code.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class CannotConnectSelfException implements Exception {
  CannotConnectSelfException([
    this.message = 'You cannot connect with yourself.',
  ]);

  final String message;

  @override
  String toString() => message;
}
