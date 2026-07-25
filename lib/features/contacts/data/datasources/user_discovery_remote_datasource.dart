import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/discoverable_user_entity.dart';

abstract class UserDiscoveryRemoteDataSource {
  /// Searches registered Velix users by Velix ID, username, or display name.
  Future<List<DiscoverableUserEntity>> searchUsers(String query);
}

class UserDiscoveryRemoteDataSourceImpl
    implements UserDiscoveryRemoteDataSource {
  UserDiscoveryRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<List<DiscoverableUserEntity>> searchUsers(String query) async {
    final raw = query.trim();
    if (raw.isEmpty) return const [];

    final currentUid = _firebaseAuth.currentUser?.uid ?? '';
    final normalized = raw.startsWith('@') ? raw : '@$raw';
    final lower = normalized.toLowerCase();
    final body = lower.startsWith('@') ? lower.substring(1) : lower;

    final results = <String, DiscoverableUserEntity>{};

    Future<void> addDocs(QuerySnapshot<Map<String, dynamic>> snap) async {
      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = data['uid'] as String? ?? doc.id;
        if (uid.isEmpty || uid == currentUid) continue;
        results.putIfAbsent(uid, () => _mapUser(uid, data));
      }
    }

    // Exact / lower Velix ID
    await addDocs(
      await _users.where('velixId', isEqualTo: normalized).limit(5).get(),
    );
    await addDocs(
      await _users.where('velixIdLower', isEqualTo: lower).limit(5).get(),
    );

    // Username exact
    await addDocs(
      await _users.where('username', isEqualTo: normalized).limit(5).get(),
    );
    await addDocs(
      await _users.where('username', isEqualTo: lower).limit(5).get(),
    );

    // Prefix-ish: username / displayName / name contains body (limited scans)
    if (body.length >= 2) {
      await addDocs(
        await _users
            .where('velixIdLower', isGreaterThanOrEqualTo: lower)
            .where('velixIdLower', isLessThan: '$lower\uf8ff')
            .limit(15)
            .get(),
      );

      await addDocs(
        await _users
            .where('username', isGreaterThanOrEqualTo: lower)
            .where('username', isLessThan: '$lower\uf8ff')
            .limit(15)
            .get(),
      );

      // Display name (optional) — case-sensitive prefix on stored fields
      final nameQuery = raw.toLowerCase();
      await addDocs(
        await _users
            .where('name', isGreaterThanOrEqualTo: nameQuery)
            .where('name', isLessThan: '$nameQuery\uf8ff')
            .limit(15)
            .get(),
      );
      await addDocs(
        await _users
            .where('displayName', isGreaterThanOrEqualTo: raw)
            .where('displayName', isLessThan: '$raw\uf8ff')
            .limit(15)
            .get(),
      );
    }

    // Client-side contains filter for display name / username / velixId
    final filtered = results.values.where((user) {
      final q = body.toLowerCase();
      return user.displayName.toLowerCase().contains(q) ||
          user.velixId.toLowerCase().contains(q) ||
          user.username.toLowerCase().contains(q);
    }).toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );

    return filtered;
  }

  DiscoverableUserEntity _mapUser(String uid, Map<String, dynamic> data) {
    return DiscoverableUserEntity(
      uid: uid,
      displayName:
          data['displayName'] as String? ?? data['name'] as String? ?? '',
      velixId: data['velixId'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      username: data['username'] as String? ?? '',
    );
  }
}
