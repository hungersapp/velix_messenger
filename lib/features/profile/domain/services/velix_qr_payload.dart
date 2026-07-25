/// Builds and parses the deep-link payload encoded in a Velix identity QR.
///
/// Example: `velix://user/@murali_VX82A7`
class VelixQrPayload {
  VelixQrPayload._();

  static const String scheme = 'velix';
  static const String userPath = 'user';

  /// `velix://user/@handle_VXxxxxx` (case-insensitive scheme/path).
  static final RegExp _payloadPattern = RegExp(
    r'^velix://user/(@[A-Za-z0-9._]+_VX[A-Za-z0-9]+)$',
    caseSensitive: false,
  );

  /// Normalizes [velixId] (with or without leading `@`) into a connect URI.
  static String fromVelixId(String velixId) {
    final handle = displayHandle(velixId);
    if (handle.isEmpty) return '';
    return '$scheme://$userPath/$handle';
  }

  /// Display form of a Velix ID, always with a leading `@`.
  static String displayHandle(String velixId) {
    final trimmed = velixId.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  /// Returns true when [raw] is a valid Velix identity QR payload.
  static bool isValid(String? raw) => tryParseVelixId(raw) != null;

  /// Extracts the Velix ID (`@username_VXxxxx`) from a QR payload, or null.
  static String? tryParseVelixId(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final match = _payloadPattern.firstMatch(trimmed);
    if (match == null) return null;

    final handle = match.group(1)!;
    // Preserve canonical leading @ with original suffix casing from QR.
    return handle.startsWith('@') ? handle : '@$handle';
  }
}
