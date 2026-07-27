import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/firebase_error_guard.dart';
import '../../domain/entities/call_history_entry.dart';
import '../../domain/entities/call_session.dart';
import '../models/call_session_model.dart';
import 'call_remote_datasource.dart';

class CallRemoteDataSourceImpl implements CallRemoteDataSource {
  CallRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _calls =>
      _firestore.collection('calls');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<CallSessionModel> createCall({
    required String conversationId,
    required String callerId,
    required String callerName,
    String? callerPhotoUrl,
    required String receiverId,
    required String receiverName,
    String? receiverPhotoUrl,
    CallType callType = CallType.voice,
  }) {
    return guardFirebase(() async {
      final doc = _calls.doc();
      final model = CallSessionModel(
        id: doc.id,
        conversationId: conversationId,
        callerId: callerId,
        callerName: callerName,
        callerPhotoUrl: callerPhotoUrl,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverPhotoUrl: receiverPhotoUrl,
        callType: callType,
        status: CallStatus.ringing,
        createdAt: DateTime.now(),
      );

      await doc.set(model.toCreateMap());
      final created = await doc.get();
      return CallSessionModel.fromFirestore(created);
    });
  }

  @override
  Future<CallSessionModel?> getCall(String callId) {
    return guardFirebase(() async {
      final doc = await _calls.doc(callId).get();
      if (!doc.exists) return null;
      return CallSessionModel.fromFirestore(doc);
    });
  }

  @override
  Stream<CallSessionModel?> watchCall(String callId) {
    return guardFirebaseStream(
      _calls.doc(callId).snapshots().map((doc) {
        if (!doc.exists) return null;
        return CallSessionModel.fromFirestore(doc);
      }),
    );
  }

  @override
  Stream<CallSessionModel?> watchIncomingRingingCall(String receiverId) {
    return guardFirebaseStream(
      _calls
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: CallStatus.ringing.value)
          .limit(5)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        final models = snapshot.docs
            .map(CallSessionModel.fromFirestore)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return models.first;
      }),
    );
  }

  @override
  Future<void> updateStatus({
    required String callId,
    required CallStatus status,
    String? endReason,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return guardFirebase(() async {
      final data = <String, dynamic>{
        'status': status.value,
      };
      if (endReason != null) data['endReason'] = endReason;
      if (startedAt != null) {
        data['startedAt'] = Timestamp.fromDate(startedAt);
      }
      if (endedAt != null) {
        data['endedAt'] = Timestamp.fromDate(endedAt);
      }
      await _calls.doc(callId).update(data);
    });
  }

  @override
  Future<void> setOffer({
    required String callId,
    required String sdp,
  }) {
    return guardFirebase(() async {
      await _calls.doc(callId).update({'offerSdp': sdp});
    });
  }

  @override
  Future<void> setAnswer({
    required String callId,
    required String sdp,
  }) {
    return guardFirebase(() async {
      await _calls.doc(callId).update({'answerSdp': sdp});
    });
  }

  @override
  Future<void> addIceCandidate({
    required String callId,
    required String fromUserId,
    required Map<String, dynamic> candidate,
  }) {
    return guardFirebase(() async {
      await _calls.doc(callId).collection('iceCandidates').add({
        'fromUserId': fromUserId,
        'candidate': candidate,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchIceCandidates({
    required String callId,
    required String forUserId,
  }) {
    // Deliver candidates authored by the peer.
    return guardFirebaseStream(
      _calls
          .doc(callId)
          .collection('iceCandidates')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => doc.data())
            .where((data) => data['fromUserId'] != forUserId)
            .map((data) {
              final candidate = data['candidate'];
              if (candidate is Map<String, dynamic>) return candidate;
              if (candidate is Map) {
                return candidate.map(
                  (key, value) => MapEntry(key.toString(), value),
                );
              }
              return <String, dynamic>{};
            })
            .where((candidate) => candidate.isNotEmpty)
            .toList();
      }),
    );
  }

  @override
  Future<bool> isUserOnline(String userId) {
    return guardFirebase(() async {
      final doc = await _users.doc(userId).get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data?['isOnline'] == true;
    });
  }

  @override
  Future<void> saveCallHistory({
    required String userId,
    required CallHistoryEntry entry,
  }) {
    return guardFirebase(() async {
      await _users.doc(userId).collection('call_history').doc(entry.id).set({
        'callId': entry.callId,
        'callerId': entry.callerId,
        'receiverId': entry.receiverId,
        'peerId': entry.peerId,
        'peerName': entry.peerName,
        'peerPhotoUrl': entry.peerPhotoUrl,
        'direction': entry.direction.name,
        'status': entry.status == CallStatus.timeout
            ? 'No Answer'
            : entry.status.value,
        'callType': entry.callType.value,
        'type': entry.callType.value,
        'durationSeconds': entry.durationSeconds,
        'duration': entry.durationSeconds,
        'startTime': entry.startedAt != null
            ? Timestamp.fromDate(entry.startedAt!)
            : Timestamp.fromDate(entry.createdAt),
        'endTime': entry.endedAt != null
            ? Timestamp.fromDate(entry.endedAt!)
            : FieldValue.serverTimestamp(),
        'createdAt': Timestamp.fromDate(entry.createdAt),
        'endedAt': entry.endedAt != null
            ? Timestamp.fromDate(entry.endedAt!)
            : FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Stream<List<CallHistoryEntry>> watchCallHistory(String userId) {
    return guardFirebaseStream(
      _users
          .doc(userId)
          .collection('call_history')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => CallHistoryEntry.fromMap(doc.id, doc.data()))
            .toList();
      }),
    );
  }
}
