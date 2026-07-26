import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/call_session.dart';

class CallSessionModel {
  const CallSessionModel({
    required this.id,
    required this.conversationId,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.receiverName,
    required this.status,
    required this.createdAt,
    this.callType = CallType.voice,
    this.callerPhotoUrl,
    this.receiverPhotoUrl,
    this.offerSdp,
    this.answerSdp,
    this.startedAt,
    this.endedAt,
    this.endReason,
  });

  final String id;
  final String conversationId;
  final String callerId;
  final String callerName;
  final String? callerPhotoUrl;
  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;
  final CallType callType;
  final CallStatus status;
  final DateTime createdAt;
  final String? offerSdp;
  final String? answerSdp;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? endReason;

  factory CallSessionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CallSessionModel(
      id: doc.id,
      conversationId: data['conversationId'] as String? ?? '',
      callerId: data['callerId'] as String? ?? '',
      callerName: data['callerName'] as String? ?? '',
      callerPhotoUrl: data['callerPhotoUrl'] as String?,
      receiverId: data['receiverId'] as String? ?? '',
      receiverName: data['receiverName'] as String? ?? '',
      receiverPhotoUrl: data['receiverPhotoUrl'] as String?,
      callType: CallTypeX.fromString(data['type'] as String?),
      status: CallStatusX.fromString(data['status'] as String?),
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      offerSdp: data['offerSdp'] as String?,
      answerSdp: data['answerSdp'] as String?,
      startedAt: _readDate(data['startedAt']),
      endedAt: _readDate(data['endedAt']),
      endReason: data['endReason'] as String?,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'conversationId': conversationId,
      'callerId': callerId,
      'callerName': callerName,
      'callerPhotoUrl': callerPhotoUrl,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhotoUrl': receiverPhotoUrl,
      'status': status.value,
      'createdAt': FieldValue.serverTimestamp(),
      'offerSdp': offerSdp,
      'answerSdp': answerSdp,
      'startedAt': null,
      'endedAt': null,
      'endReason': endReason,
      'type': callType.value,
    };
  }

  CallSession toEntity() {
    return CallSession(
      id: id,
      conversationId: conversationId,
      callerId: callerId,
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverPhotoUrl: receiverPhotoUrl,
      callType: callType,
      status: status,
      createdAt: createdAt,
      offerSdp: offerSdp,
      answerSdp: answerSdp,
      startedAt: startedAt,
      endedAt: endedAt,
      endReason: endReason,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
