import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/velix_user.dart';

class VelixUserModel extends VelixUser {
  const VelixUserModel({
    required super.uid,
    required super.displayName,
    required super.username,
    required super.velixId,
    required super.recoverySecurityKeyHash,
    required super.passwordVault,
    required super.twoStepVerificationEnabled,
    super.totpSecret,
    required super.photoUrl,
    required super.about,
    required super.status,
    required super.notificationToken,
    required super.profileCompleted,
    required super.storyPrivacy,
    required super.createdAt,
    required super.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      // Compatibility alias so existing Home user reads keep working.
      'name': displayName,
      'username': username,
      'velixId': velixId,
      'velixIdLower': velixId.toLowerCase(),
      'recoverySecurityKey': recoverySecurityKeyHash,
      'passwordVault': passwordVault,
      'twoStepVerificationEnabled': twoStepVerificationEnabled,
      'totpSecret': totpSecret,
      'photoUrl': photoUrl,
      'about': about,
      'status': status,
      'notificationToken': notificationToken,
      'profileCompleted': profileCompleted,
      'storyPrivacy': storyPrivacy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory VelixUserModel.fromEntity(VelixUser user) {
    return VelixUserModel(
      uid: user.uid,
      displayName: user.displayName,
      username: user.username,
      velixId: user.velixId,
      recoverySecurityKeyHash: user.recoverySecurityKeyHash,
      passwordVault: user.passwordVault,
      twoStepVerificationEnabled: user.twoStepVerificationEnabled,
      totpSecret: user.totpSecret,
      photoUrl: user.photoUrl,
      about: user.about,
      status: user.status,
      notificationToken: user.notificationToken,
      profileCompleted: user.profileCompleted,
      storyPrivacy: user.storyPrivacy,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }
}
