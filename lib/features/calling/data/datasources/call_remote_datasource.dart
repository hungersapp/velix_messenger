import '../../domain/entities/call_history_entry.dart';
import '../../domain/entities/call_session.dart';
import '../models/call_session_model.dart';

abstract class CallRemoteDataSource {
  Future<CallSessionModel> createCall({
    required String conversationId,
    required String callerId,
    required String callerName,
    String? callerPhotoUrl,
    required String receiverId,
    required String receiverName,
    String? receiverPhotoUrl,
    CallType callType = CallType.voice,
  });

  Future<CallSessionModel?> getCall(String callId);

  Stream<CallSessionModel?> watchCall(String callId);

  Stream<CallSessionModel?> watchIncomingRingingCall(String receiverId);

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
