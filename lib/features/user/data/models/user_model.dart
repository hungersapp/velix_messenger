import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.mobileNumber,
    required super.photoUrl,
    required super.about,
    required super.accountStatus,
    required super.appVersion,
    required super.isOnline,
    required super.lastActiveDevice,
    required super.lastSeen,
    required super.notificationToken,
    required super.profileCompleted,
    required super.storyPrivacy,
    required super.createdAt,
    required super.updatedAt,
    super.velixId,
  });

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;

    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? data['displayName'] ?? '',
      email: data['email'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      about: data['about'] ?? '',
      accountStatus: data['accountStatus'] ?? data['status'] ?? 'active',
      appVersion: data['appVersion'] ?? '1.0.0',
      isOnline: data['isOnline'] ?? false,
      lastActiveDevice: data['lastActiveDevice'] ?? '',
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      notificationToken: data['notificationToken'] ?? '',
      profileCompleted: data['profileCompleted'] ?? false,
      storyPrivacy: data['storyPrivacy'] ?? 'everyone',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      velixId: data['velixId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'mobileNumber': mobileNumber,
      'photoUrl': photoUrl,
      'about': about,
      'accountStatus': accountStatus,
      'appVersion': appVersion,
      'isOnline': isOnline,
      'lastActiveDevice': lastActiveDevice,
      'lastSeen':
          lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'notificationToken': notificationToken,
      'profileCompleted': profileCompleted,
      'storyPrivacy': storyPrivacy,
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt':
          updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      if (velixId.isNotEmpty) 'velixId': velixId,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      name: entity.name,
      email: entity.email,
      mobileNumber: entity.mobileNumber,
      photoUrl: entity.photoUrl,
      about: entity.about,
      accountStatus: entity.accountStatus,
      appVersion: entity.appVersion,
      isOnline: entity.isOnline,
      lastActiveDevice: entity.lastActiveDevice,
      lastSeen: entity.lastSeen,
      notificationToken: entity.notificationToken,
      profileCompleted: entity.profileCompleted,
      storyPrivacy: entity.storyPrivacy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      velixId: entity.velixId,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      name: name,
      email: email,
      mobileNumber: mobileNumber,
      photoUrl: photoUrl,
      about: about,
      accountStatus: accountStatus,
      appVersion: appVersion,
      isOnline: isOnline,
      lastActiveDevice: lastActiveDevice,
      lastSeen: lastSeen,
      notificationToken: notificationToken,
      profileCompleted: profileCompleted,
      storyPrivacy: storyPrivacy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      velixId: velixId,
    );
  }
}