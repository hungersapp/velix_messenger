import 'call_session.dart';

enum CallDirection { incoming, outgoing }

class CallHistoryEntry {
  const CallHistoryEntry({
    required this.id,
    required this.callId,
    required this.callerId,
    required this.receiverId,
    required this.peerId,
    required this.peerName,
    required this.direction,
    required this.status,
    required this.callType,
    required this.durationSeconds,
    required this.createdAt,
    this.peerPhotoUrl,
    this.startedAt,
    this.endedAt,
  });

  final String id;
  final String callId;
  final String callerId;
  final String receiverId;
  final String peerId;
  final String peerName;
  final String? peerPhotoUrl;
  final CallDirection direction;
  final CallStatus status;
  final CallType callType;
  final int durationSeconds;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  String get statusLabel {
    if (status == CallStatus.timeout) return 'No Answer';
    return status.value;
  }

  bool get isMissed =>
      status == CallStatus.timeout ||
      status == CallStatus.missed ||
      status == CallStatus.declined;

  factory CallHistoryEntry.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final statusRaw = (data['status'] as String?) ?? 'ended';
    final normalized = statusRaw.toLowerCase().replaceAll(' ', '_');
    final CallStatus status;
    if (normalized == 'no_answer' || statusRaw == 'No Answer') {
      status = CallStatus.timeout;
    } else {
      status = CallStatusX.fromString(statusRaw);
    }

    final directionRaw = (data['direction'] as String?) ?? 'outgoing';
    final direction = directionRaw == CallDirection.incoming.name
        ? CallDirection.incoming
        : CallDirection.outgoing;

    final typeRaw =
        (data['callType'] as String?) ?? (data['type'] as String?) ?? 'voice';

    return CallHistoryEntry(
      id: id,
      callId: data['callId'] as String? ?? id,
      callerId: data['callerId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      peerId: data['peerId'] as String? ?? '',
      peerName: data['peerName'] as String? ?? 'Velix User',
      peerPhotoUrl: data['peerPhotoUrl'] as String?,
      direction: direction,
      status: status,
      callType: CallTypeX.fromString(typeRaw),
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ??
          (data['duration'] as num?)?.toInt() ??
          0,
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      startedAt: _readDate(data['startTime']) ?? _readDate(data['startedAt']),
      endedAt: _readDate(data['endTime']) ?? _readDate(data['endedAt']),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      // cloud_firestore Timestamp
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }
}
