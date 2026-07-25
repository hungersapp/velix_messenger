/// Presentation model for the My Profile digital identity screen.
/// Backend fields will replace this mock shape in a later sprint.
class ProfileIdentity {
  const ProfileIdentity({
    required this.displayName,
    required this.velixId,
    this.photoUrl,
  });

  final String displayName;

  /// Handle without the leading `@` (e.g. `murali_VX4A9D`).
  final String velixId;

  final String? photoUrl;

  String get handle => '@$velixId';
}
