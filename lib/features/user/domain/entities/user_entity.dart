class UserEntity {
  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.photoUrl,
    required this.about,
    required this.accountStatus,
    required this.appVersion,
    required this.isOnline,
    required this.lastActiveDevice,
    required this.lastSeen,
    required this.notificationToken,
    required this.profileCompleted,
    required this.storyPrivacy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String mobileNumber;
  final String photoUrl;
  final String about;
  final String accountStatus;
  final String appVersion;
  final bool isOnline;
  final String lastActiveDevice;
  final DateTime? lastSeen;
  final String notificationToken;
  final bool profileCompleted;
  final String storyPrivacy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}