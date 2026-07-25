/// Public account summary used during password recovery.
class RecoveryAccount {
  const RecoveryAccount({
    required this.uid,
    required this.velixId,
    required this.username,
    required this.twoStepVerificationEnabled,
  });

  final String uid;
  final String velixId;
  final String username;
  final bool twoStepVerificationEnabled;
}
