import '../entities/call_history_entry.dart';
import '../entities/call_session.dart';

abstract class CallRepository {
  Future<CallSession> createCall({
    required String conversationId,
    required String callerId,
    required String callerName,
    String? callerPhotoUrl,
    required String receiverId,
    required String receiverName,
    String? receiverPhotoUrl,
    CallType callType = CallType.voice,
  });

  Future<CallSession?> getCall(String callId);

  Stream<CallSession?> watchCall(String callId);

  Stream<CallSession?> watchIncomingRingingCall(String receiverId);

  Future<void> updateStatus({
    required String callId,
    required CallStatus status,
    String? endReason,
    DateTime? startedAt,
    DateTime? endedAt,
  });

  Future<void> setOffer({
    required String callId,
    required String sdp,
  });

  Future<void> setAnswer({
    required String callId,
    required String sdp,
  });

  Future<void> addIceCandidate({
    required String callId,
    required String fromUserId,
    required Map<String, dynamic> candidate,
  });

  Stream<List<Map<String, dynamic>>> watchIceCandidates({
    required String callId,
    required String forUserId,
  });

  Future<bool> isUserOnline(String userId);

  Future<void> saveCallHistory({
    required String userId,
    required CallHistoryEntry entry,
  });

  Stream<List<CallHistoryEntry>> watchCallHistory(String userId);
}
