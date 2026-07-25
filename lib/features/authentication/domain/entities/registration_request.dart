/// Input collected on the V1 registration screen.
class RegistrationRequest {
  const RegistrationRequest({
    required this.displayName,
    required this.username,
    required this.password,
    required this.ageConfirmed,
  });

  final String displayName;

  /// Handle with leading `@`, e.g. `@murali007`.
  final String username;

  final String password;
  final bool ageConfirmed;
}
