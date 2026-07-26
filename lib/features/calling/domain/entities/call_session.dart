enum CallStatus {
  ringing,
  connecting,
  connected,
  declined,
  ended,
  missed,
  timeout,
  failed,
}

enum CallType {
  voice,
  video,
}

extension CallStatusX on CallStatus {
  String get value => name;

  static CallStatus fromString(String? raw) {
    return CallStatus.values.firstWhere(
      (status) => status.name == raw,
      orElse: () => CallStatus.failed,
    );
  }

  bool get isTerminal =>
      this == CallStatus.declined ||
      this == CallStatus.ended ||
      this == CallStatus.missed ||
      this == CallStatus.timeout ||
      this == CallStatus.failed;
}

extension CallTypeX on CallType {
  String get value => name;

  static CallType fromString(String? raw) {
    return CallType.values.firstWhere(
      (type) => type.name == raw,
      orElse: () => CallType.voice,
    );
  }
}

class CallSession {
  const CallSession({
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

  bool get isVideo => callType == CallType.video;

  bool isCaller(String userId) => callerId == userId;

  String peerIdFor(String userId) =>
      isCaller(userId) ? receiverId : callerId;

  String peerNameFor(String userId) =>
      isCaller(userId) ? receiverName : callerName;

  String? peerPhotoFor(String userId) =>
      isCaller(userId) ? receiverPhotoUrl : callerPhotoUrl;
}
