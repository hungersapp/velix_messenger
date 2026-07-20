import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'user_remote_datasource.dart';

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  String get _currentUid {
    final uid = _firebaseAuth.currentUser?.uid;

    if (uid == null) {
      throw Exception('No authenticated user found.');
    }

    return uid;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final document = await _usersCollection.doc(_currentUid).get();

    if (!document.exists) {
      return null;
    }

    return UserModel.fromFirestore(document);
  }

  @override
  Future<void> updateCurrentUser(UserModel user) async {
    await _usersCollection.doc(_currentUid).update(
          user.toFirestore(),
        );
  }

  @override
  Future<void> updateOnlineStatus({
    required bool isOnline,
    required DateTime lastSeen,
  }) async {
    await _usersCollection.doc(_currentUid).update({
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateNotificationToken(String token) async {
    await _usersCollection.doc(_currentUid).update({
      'notificationToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}