class UserEntity {
  final String uid;
  final String name;
  final String mobile;
  final String email;
  final String photoUrl;
  final DateTime? createdAt;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.mobile,
    required this.email,
    required this.photoUrl,
    this.createdAt,
  });

  UserEntity copyWith({
    String? uid,
    String? name,
    String? mobile,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}