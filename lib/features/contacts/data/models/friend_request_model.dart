import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/friend_request_entity.dart';

class FriendRequestModel extends FriendRequestEntity {
  const FriendRequestModel({
    required super.fromUid,
    required super.toUid,
    required super.displayName,
    required super.velixId,
    required super.photoUrl,
    required super.username,
    required super.createdAt,
    super.status,
  });

  factory FriendRequestModel.fromFirestore(Map<String, dynamic> data) {
    return FriendRequestModel(
      fromUid: data['fromUid'] as String? ?? '',
      toUid: data['toUid'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      velixId: data['velixId'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      username: data['username'] as String? ?? '',
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      status: FriendRequestStatus.pending,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUid': fromUid,
      'toUid': toUid,
      'displayName': displayName,
      'velixId': velixId,
      'photoUrl': photoUrl,
      'username': username,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': 'pending',
    };
  }

  FriendRequestEntity toEntity() {
    return FriendRequestEntity(
      fromUid: fromUid,
      toUid: toUid,
      displayName: displayName,
      velixId: velixId,
      photoUrl: photoUrl,
      username: username,
      createdAt: createdAt,
      status: status,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
