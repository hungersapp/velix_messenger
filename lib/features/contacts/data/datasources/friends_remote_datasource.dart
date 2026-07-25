import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/friend_model.dart';

abstract class FriendsRemoteDataSource {
  Future<List<FriendModel>> getFriends();

  Future<bool> isFriend(String friendUid);

  /// Creates a bidirectional friendship when missing. No-ops if already friends.
  Future<void> addFriend({
    required FriendModel friend,
    required FriendModel selfProfile,
  });
}

class FriendsRemoteDataSourceImpl implements FriendsRemoteDataSource {
  FriendsRemoteDataSourceImpl({
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

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _friendsOf(String uid) {
    return _users.doc(uid).collection('friends');
  }

  @override
  Future<List<FriendModel>> getFriends() async {
    final snapshot = await _friendsOf(_currentUid).get();
    if (snapshot.docs.isEmpty) return const [];

    final friends = await Future.wait(
      snapshot.docs.map((doc) async {
        final stored = FriendModel.fromFirestore(doc.data());
        if (stored.uid.isEmpty) return stored;

        final live = await _users.doc(stored.uid).get();
        if (!live.exists || live.data() == null) {
          return stored;
        }

        final data = live.data()!;
        return FriendModel(
          uid: stored.uid,
          displayName: data['displayName'] as String? ??
              data['name'] as String? ??
              stored.displayName,
          velixId: data['velixId'] as String? ?? stored.velixId,
          photoUrl: data['photoUrl'] as String? ?? stored.photoUrl,
          createdAt: stored.createdAt,
          isOnline: data['isOnline'] as bool? ?? false,
        );
      }),
    );

    friends.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return friends;
  }

  @override
  Future<bool> isFriend(String friendUid) async {
    if (friendUid.isEmpty) return false;
    final doc = await _friendsOf(_currentUid).doc(friendUid).get();
    return doc.exists;
  }

  @override
  Future<void> addFriend({
    required FriendModel friend,
    required FriendModel selfProfile,
  }) async {
    final currentUid = _currentUid;

    if (friend.uid.isEmpty || friend.uid == currentUid) {
      throw Exception('Cannot add yourself as a friend.');
    }

    final existing = await _friendsOf(currentUid).doc(friend.uid).get();
    if (existing.exists) {
      return;
    }

    final now = Timestamp.now();
    final batch = _firestore.batch();

    batch.set(
      _friendsOf(currentUid).doc(friend.uid),
      {
        ...friend.toFirestore(),
        'createdAt': now,
      },
    );

    batch.set(
      _friendsOf(friend.uid).doc(currentUid),
      {
        ...selfProfile.toFirestore(),
        'uid': currentUid,
        'createdAt': now,
      },
    );

    await batch.commit();
  }
}
