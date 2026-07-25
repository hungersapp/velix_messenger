enum PasswordStrength {
  weak,
  fair,
  good,
  strong,
}

/// Password policy for Velix V1 registration.
class PasswordRules {
  PasswordRules._();

  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`]');

  static bool hasMinLength(String password) => password.length >= 8;
  static bool hasUppercase(String password) => _upper.hasMatch(password);
  static bool hasLowercase(String password) => _lower.hasMatch(password);
  static bool hasDigit(String password) => _digit.hasMatch(password);
  static bool hasSpecial(String password) => _special.hasMatch(password);

  static bool isValid(String password) {
    return hasMinLength(password) &&
        hasUppercase(password) &&
        hasLowercase(password) &&
        hasDigit(password) &&
        hasSpecial(password);
  }

  static String? validationError(String password) {
    if (!hasMinLength(password)) {
      return 'Password must be at least 8 characters';
    }
    if (!hasUppercase(password)) {
      return 'Include at least one uppercase letter';
    }
    if (!hasLowercase(password)) {
      return 'Include at least one lowercase letter';
    }
    if (!hasDigit(password)) {
      return 'Include at least one number';
    }
    if (!hasSpecial(password)) {
      return 'Include at least one special character';
    }
    return null;
  }

  static PasswordStrength strengthOf(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    var score = 0;
    if (hasMinLength(password)) score++;
    if (password.length >= 12) score++;
    if (hasUppercase(password)) score++;
    if (hasLowercase(password)) score++;
    if (hasDigit(password)) score++;
    if (hasSpecial(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.fair;
    if (score <= 5) return PasswordStrength.good;
    return PasswordStrength.strong;
  }
}
