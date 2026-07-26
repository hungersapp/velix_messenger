import '../../domain/entities/call_history_entry.dart';
import '../../domain/entities/call_session.dart';
import '../../domain/repositories/call_repository.dart';
import '../datasources/call_remote_datasource.dart';

class CallRepositoryImpl implements CallRepository {
  CallRepositoryImpl(this._remote);

  final CallRemoteDataSource _remote;

  @override
  Future<CallSession> createCall({
    required String conversationId,
    required String callerId,
    required String callerName,
    String? callerPhotoUrl,
    required String receiverId,
    required String receiverName,
    String? receiverPhotoUrl,
    CallType callType = CallType.voice,
  }) async {
    final model = await _remote.createCall(
      conversationId: conversationId,
      callerId: callerId,
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverPhotoUrl: receiverPhotoUrl,
      callType: callType,
    );
    return model.toEntity();
  }

  @override
  Future<CallSession?> getCall(String callId) async {
    final model = await _remote.getCall(callId);
    return model?.toEntity();
  }

  @override
  Stream<CallSession?> watchCall(String callId) {
    return _remote.watchCall(callId).map((model) => model?.toEntity());
  }

  @override
  Stream<CallSession?> watchIncomingRingingCall(String receiverId) {
    return _remote
        .watchIncomingRingingCall(receiverId)
        .map((model) => model?.toEntity());
  }

  @override
  Future<void> updateStatus({
    required String callId,
    required CallStatus status,
    String? endReason,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return _remote.updateStatus(
      callId: callId,
      status: status,
      endReason: endReason,
      startedAt: startedAt,
      endedAt: endedAt,
    );
  }

  @override
  Future<void> setOffer({
    required String callId,
    required String sdp,
  }) {
    return _remote.setOffer(callId: callId, sdp: sdp);
  }

  @override
  Future<void> setAnswer({
    required String callId,
    required String sdp,
  }) {
    return _remote.setAnswer(callId: callId, sdp: sdp);
  }

  @override
  Future<void> addIceCandidate({
    required String callId,
    required String fromUserId,
    required Map<String, dynamic> candidate,
  }) {
    return _remote.addIceCandidate(
      callId: callId,
      fromUserId: fromUserId,
      candidate: candidate,
    );
  }

  @override
  Stream<List<Map<String, dynamic>>> watchIceCandidates({
    required String callId,
    required String forUserId,
  }) {
    return _remote.watchIceCandidates(
      callId: callId,
      forUserId: forUserId,
    );
  }

  @override
  Future<bool> isUserOnline(String userId) {
    return _remote.isUserOnline(userId);
  }

  @override
  Future<void> saveCallHistory({
    required String userId,
    required CallHistoryEntry entry,
  }) {
    return _remote.saveCallHistory(userId: userId, entry: entry);
  }

  @override
  Stream<List<CallHistoryEntry>> watchCallHistory(String userId) {
    return _remote.watchCallHistory(userId);
  }
}
