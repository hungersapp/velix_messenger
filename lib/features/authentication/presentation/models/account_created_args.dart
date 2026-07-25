class AccountCreatedArgs {
  const AccountCreatedArgs({
    required this.displayName,
    required this.username,
    required this.velixId,
    required this.recoverySecurityKey,
  });

  final String displayName;
  final String username;
  final String velixId;
  final String recoverySecurityKey;
}
