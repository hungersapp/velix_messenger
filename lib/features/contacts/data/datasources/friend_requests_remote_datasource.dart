import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/friend_request_model.dart';

abstract class FriendRequestsRemoteDataSource {
  Future<List<FriendRequestModel>> getIncomingRequests();

  Stream<List<FriendRequestModel>> watchIncomingRequests();

  Future<bool> hasOutgoingRequest(String toUid);

  Future<bool> hasIncomingRequestFrom(String fromUid);

  /// Creates a pending request for [toUid]. No-ops if already pending/friends.
  Future<void> sendRequest({
    required FriendRequestModel outgoingPayload,
    required FriendRequestModel incomingPayload,
  });

  Future<void> deleteRequest({
    required String fromUid,
    required String toUid,
  });
}

class FriendRequestsRemoteDataSourceImpl
    implements FriendRequestsRemoteDataSource {
  FriendRequestsRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  String get _currentUid {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('No authenticated user found.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _incoming(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('incomingFriendRequests');
  }

  CollectionReference<Map<String, dynamic>> _outgoing(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('outgoingFriendRequests');
  }

  @override
  Future<List<FriendRequestModel>> getIncomingRequests() async {
    final snapshot = await _incoming(_currentUid).get();

    final requests = snapshot.docs
        .map((doc) => FriendRequestModel.fromFirestore(doc.data()))
        .where((r) => r.fromUid.isNotEmpty)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return requests;
  }

  @override
  Stream<List<FriendRequestModel>> watchIncomingRequests() {
    return _incoming(_currentUid).snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => FriendRequestModel.fromFirestore(doc.data()))
          .where((r) => r.fromUid.isNotEmpty)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  @override
  Future<bool> hasOutgoingRequest(String toUid) async {
    if (toUid.isEmpty) return false;
    final doc = await _outgoing(_currentUid).doc(toUid).get();
    return doc.exists;
  }

  @override
  Future<bool> hasIncomingRequestFrom(String fromUid) async {
    if (fromUid.isEmpty) return false;
    final doc = await _incoming(_currentUid).doc(fromUid).get();
    return doc.exists;
  }

  @override
  Future<void> sendRequest({
    required FriendRequestModel outgoingPayload,
    required FriendRequestModel incomingPayload,
  }) async {
    final fromUid = outgoingPayload.fromUid;
    final toUid = outgoingPayload.toUid;

    if (fromUid.isEmpty || toUid.isEmpty || fromUid == toUid) {
      throw Exception('Invalid friend request.');
    }

    final existingOut = await _outgoing(fromUid).doc(toUid).get();
    if (existingOut.exists) return;

    final existingIn = await _incoming(toUid).doc(fromUid).get();
    if (existingIn.exists) return;

    final now = Timestamp.now();
    final batch = _firestore.batch();

    batch.set(
      _outgoing(fromUid).doc(toUid),
      {
        ...outgoingPayload.toFirestore(),
        'createdAt': now,
      },
    );

    batch.set(
      _incoming(toUid).doc(fromUid),
      {
        ...incomingPayload.toFirestore(),
        'createdAt': now,
      },
    );

    await batch.commit();
  }

  @override
  Future<void> deleteRequest({
    required String fromUid,
    required String toUid,
  }) async {
    final batch = _firestore.batch();
    batch.delete(_outgoing(fromUid).doc(toUid));
    batch.delete(_incoming(toUid).doc(fromUid));
    await batch.commit();
  }
}
