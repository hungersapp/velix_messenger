import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/firebase/firebase_error_guard.dart';
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
  Future<UserModel?> getCurrentUser() {
    return guardFirebase(() async {
      final document = await _usersCollection.doc(_currentUid).get();

      if (!document.exists) {
        return null;
      }

      await _migrateLegacySecretsIfNeeded(_currentUid, document.data());

      return UserModel.fromFirestore(document);
    });
  }

  Future<void> _migrateLegacySecretsIfNeeded(
    String uid,
    Map<String, dynamic>? data,
  ) async {
    if (data == null) return;
    final hasLegacy = data.containsKey('passwordVault') ||
        data.containsKey('recoverySecurityKey') ||
        data.containsKey('totpSecret');

    final username = data['username'] as String? ?? '';
    final velixId = data['velixId'] as String? ?? '';

    final batch = _firestore.batch();
    var dirty = false;

    if (hasLegacy) {
      final securityRef =
          _usersCollection.doc(uid).collection('security').doc('credentials');
      final existing = await securityRef.get();
      final securityData = <String, dynamic>{
        if (existing.data() != null) ...existing.data()!,
      };
      if (data['recoverySecurityKey'] != null &&
          securityData['recoverySecurityKey'] == null) {
        securityData['recoverySecurityKey'] = data['recoverySecurityKey'];
      }
      if (data['passwordVault'] != null &&
          securityData['passwordVault'] == null) {
        securityData['passwordVault'] = data['passwordVault'];
      }
      if (data['totpSecret'] != null && securityData['totpSecret'] == null) {
        securityData['totpSecret'] = data['totpSecret'];
      }
      securityData['updatedAt'] = FieldValue.serverTimestamp();
      batch.set(securityRef, securityData, SetOptions(merge: true));
      batch.set(_usersCollection.doc(uid), {
        'passwordVault': FieldValue.delete(),
        'recoverySecurityKey': FieldValue.delete(),
        'totpSecret': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      dirty = true;
    }

    if (username.isNotEmpty && velixId.isNotEmpty) {
      final lookup = {
        'uid': uid,
        'username': username,
        'velixId': velixId,
        'twoStepVerificationEnabled':
            data['twoStepVerificationEnabled'] as bool? ?? false,
      };
      batch.set(
        _firestore.collection('usernames').doc(username.trim().toLowerCase()),
        lookup,
        SetOptions(merge: true),
      );
      batch.set(
        _firestore.collection('velix_ids').doc(velixId.trim().toLowerCase()),
        lookup,
        SetOptions(merge: true),
      );
      dirty = true;
    }

    if (dirty) {
      await batch.commit();
    }
  }

  @override
  Future<void> updateCurrentUser(UserModel user) {
    return guardFirebase(() async {
      await _usersCollection.doc(_currentUid).update(
            user.toFirestore(),
          );
    });
  }

  @override
  Future<void> updateOnlineStatus({
    required bool isOnline,
    required DateTime lastSeen,
  }) {
    return guardFirebase(() async {
      await _usersCollection.doc(_currentUid).update({
        'isOnline': isOnline,
        'lastSeen': Timestamp.fromDate(lastSeen),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> updateNotificationToken(String token) {
    return guardFirebase(() async {
      await _usersCollection.doc(_currentUid).update({
        'notificationToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
