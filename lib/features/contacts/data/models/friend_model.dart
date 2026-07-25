import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/friend_entity.dart';

class FriendModel extends FriendEntity {
  const FriendModel({
    required super.uid,
    required super.displayName,
    required super.velixId,
    required super.photoUrl,
    required super.createdAt,
    super.isOnline,
  });

  factory FriendModel.fromFirestore(
    Map<String, dynamic> data, {
    bool isOnline = false,
  }) {
    return FriendModel(
      uid: data['uid'] as String? ?? '',
      displayName:
          data['displayName'] as String? ?? data['name'] as String? ?? '',
      velixId: data['velixId'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      isOnline: isOnline,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'name': displayName,
      'velixId': velixId,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FriendEntity toEntity() {
    return FriendEntity(
      uid: uid,
      displayName: displayName,
      velixId: velixId,
      photoUrl: photoUrl,
      createdAt: createdAt,
      isOnline: isOnline,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
