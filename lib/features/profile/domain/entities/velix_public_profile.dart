/// Public Velix profile subset used for QR preview and discovery.
class VelixPublicProfile {
  const VelixPublicProfile({
    required this.uid,
    required this.displayName,
    required this.velixId,
    required this.photoUrl,
    this.username = '',
  });

  final String uid;
  final String displayName;
  final String velixId;
  final String photoUrl;
  final String username;

  factory VelixPublicProfile.fromFirestore(Map<String, dynamic> data) {
    return VelixPublicProfile(
      uid: data['uid'] as String? ?? '',
      displayName:
          data['displayName'] as String? ?? data['name'] as String? ?? '',
      velixId: data['velixId'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      username: data['username'] as String? ?? '',
    );
  }
}
