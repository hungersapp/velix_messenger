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
    this.velixId = '',
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

  /// Permanent Velix User ID, e.g. `@murali_VX82A7`.
  final String velixId;

  UserEntity copyWith({
    String? uid,
    String? name,
    String? email,
    String? mobileNumber,
    String? photoUrl,
    String? about,
    String? accountStatus,
    String? appVersion,
    bool? isOnline,
    String? lastActiveDevice,
    DateTime? lastSeen,
    String? notificationToken,
    bool? profileCompleted,
    String? storyPrivacy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? velixId,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      about: about ?? this.about,
      accountStatus: accountStatus ?? this.accountStatus,
      appVersion: appVersion ?? this.appVersion,
      isOnline: isOnline ?? this.isOnline,
      lastActiveDevice: lastActiveDevice ?? this.lastActiveDevice,
      lastSeen: lastSeen ?? this.lastSeen,
      notificationToken: notificationToken ?? this.notificationToken,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      storyPrivacy: storyPrivacy ?? this.storyPrivacy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      velixId: velixId ?? this.velixId,
    );
  }
}
