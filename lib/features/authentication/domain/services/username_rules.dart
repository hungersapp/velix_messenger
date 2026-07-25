/// Username rules for Velix V1 (`@handle`).
class UsernameRules {
  UsernameRules._();

  /// Body without `@`: 3–20 chars, starts with letter, [a-z0-9_].
  static final RegExp bodyPattern = RegExp(r'^[a-z][a-z0-9_]{2,19}$');

  /// Normalizes to `@lowercase_body`. Returns empty string if unusable.
  static String normalize(String input) {
    var value = input.trim().toLowerCase();
    if (value.startsWith('@')) {
      value = value.substring(1);
    }
    value = value.trim();
    if (value.isEmpty) return '';
    return '@$value';
  }

  static String bodyOf(String normalizedUsername) {
    if (normalizedUsername.startsWith('@')) {
      return normalizedUsername.substring(1);
    }
    return normalizedUsername;
  }

  static bool isValid(String normalizedUsername) {
    return bodyPattern.hasMatch(bodyOf(normalizedUsername));
  }
}
