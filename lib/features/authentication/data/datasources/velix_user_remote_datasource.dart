import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/firebase_error_guard.dart';
import '../models/velix_user_model.dart';

/// Firestore access for Velix user profiles, public lookup indexes, and
/// private security credentials.
class VelixUserRemoteDatasource {
  VelixUserRemoteDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';
  static const String _usernamesCollection = 'usernames';
  static const String _velixIdsCollection = 'velix_ids';
  static const String _securityDocId = 'credentials';

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(_usersCollection);

  CollectionReference<Map<String, dynamic>> get _usernames =>
      _firestore.collection(_usernamesCollection);

  CollectionReference<Map<String, dynamic>> get _velixIds =>
      _firestore.collection(_velixIdsCollection);

  DocumentReference<Map<String, dynamic>> _securityRef(String uid) =>
      _users.doc(uid).collection('security').doc(_securityDocId);

  String _usernameKey(String username) => username.trim().toLowerCase();

  String _velixIdKey(String velixId) => velixId.trim().toLowerCase();

  Future<bool> isUsernameTaken(String username) {
    return guardFirebase(() async {
      final snap = await _usernames.doc(_usernameKey(username)).get();
      if (snap.exists) return true;

      // Legacy fallback while indexes backfill.
      final query = await _users
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    });
  }

  Future<bool> isVelixIdTaken(String velixId) {
    return guardFirebase(() async {
      final snap = await _velixIds.doc(_velixIdKey(velixId)).get();
      if (snap.exists) return true;

      final query = await _users
          .where('velixId', isEqualTo: velixId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    });
  }

  /// Public lookup for login / recovery (no secrets).
  Future<Map<String, dynamic>?> findByUsername(String username) {
    return guardFirebase(() async {
      final index = await _usernames.doc(_usernameKey(username)).get();
      if (index.exists && index.data() != null) {
        return Map<String, dynamic>.from(index.data()!);
      }

      // Legacy fallback for accounts not yet indexed.
      final query = await _users
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return _publicProjection(query.docs.first.data());
    });
  }

  Future<Map<String, dynamic>?> findByVelixId(String velixId) {
    return guardFirebase(() async {
      final trimmed = velixId.trim();
      final index = await _velixIds.doc(_velixIdKey(trimmed)).get();
      if (index.exists && index.data() != null) {
        final data = Map<String, dynamic>.from(index.data()!);
        // Authenticated callers (QR / connect) need live public profile fields.
        final uid = data['uid'] as String? ?? '';
        if (uid.isNotEmpty) {
          final live = await _users.doc(uid).get();
          if (live.exists && live.data() != null) {
            return {
              ..._publicProjection(live.data()!),
              ...data,
            };
          }
        }
        return data;
      }

      final exact = await _users
          .where('velixId', isEqualTo: trimmed)
          .limit(1)
          .get();

      if (exact.docs.isNotEmpty) {
        return _publicProjection(exact.docs.first.data());
      }

      final lower = await _users
          .where('velixIdLower', isEqualTo: trimmed.toLowerCase())
          .limit(1)
          .get();

      if (lower.docs.isEmpty) return null;
      return _publicProjection(lower.docs.first.data());
    });
  }

  Future<Map<String, dynamic>?> findByIdentifier(String identifier) {
    return guardFirebase(() async {
      final normalized = identifier.trim().startsWith('@')
          ? identifier.trim()
          : '@${identifier.trim()}';

      final byVelix = await findByVelixId(normalized);
      if (byVelix != null) return byVelix;

      final looksLikeVelixId =
          RegExp(r'_VX[A-Z0-9]+$', caseSensitive: false).hasMatch(normalized);
      if (looksLikeVelixId) return null;

      return findByUsername(normalized);
    });
  }

  /// Public profile + security credentials for recovery / vault operations.
  Future<Map<String, dynamic>?> findProfileWithSecurity(String velixId) {
    return guardFirebase(() async {
      final public = await findByVelixId(velixId);
      if (public == null) return null;
      final uid = public['uid'] as String? ?? '';
      if (uid.isEmpty) return public;

      final security = await getSecurityCredentials(uid);
      return {
        ...public,
        ...?security,
      };
    });
  }

  Future<Map<String, dynamic>?> getSecurityCredentials(String uid) {
    return guardFirebase(() async {
      final snap = await _securityRef(uid).get();
      if (snap.exists && snap.data() != null) {
        return Map<String, dynamic>.from(snap.data()!);
      }

      // Legacy: secrets still on the user document.
      final user = await _users.doc(uid).get();
      if (!user.exists || user.data() == null) return null;
      final data = user.data()!;
      final legacy = <String, dynamic>{};
      for (final key in [
        'recoverySecurityKey',
        'passwordVault',
        'totpSecret',
      ]) {
        if (data[key] != null) legacy[key] = data[key];
      }
      return legacy.isEmpty ? null : legacy;
    });
  }

  Future<void> saveUser(VelixUserModel user) {
    return guardFirebase(() async {
      final batch = _firestore.batch();
      final userRef = _users.doc(user.uid);

      batch.set(userRef, user.toFirestore());
      batch.set(_securityRef(user.uid), user.toSecurityCredentials());
      batch.set(
        _usernames.doc(_usernameKey(user.username)),
        user.toLookupIndex(),
      );
      batch.set(
        _velixIds.doc(_velixIdKey(user.velixId)),
        user.toLookupIndex(),
      );

      await batch.commit();
    });
  }

  Future<void> updatePasswordVault({
    required String uid,
    required String passwordVault,
  }) {
    return guardFirebase(() async {
      await _securityRef(uid).set({
        'passwordVault': passwordVault,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Clear legacy field if present.
      await _users.doc(uid).set({
        'passwordVault': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> updateTwoFactor({
    required String uid,
    required bool enabled,
    String? totpSecret,
  }) {
    return guardFirebase(() async {
      final batch = _firestore.batch();
      batch.set(userRef(uid), {
        'twoStepVerificationEnabled': enabled,
        'totpSecret': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(_securityRef(uid), {
        'totpSecret': enabled ? totpSecret : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final userSnap = await _users.doc(uid).get();
      final data = userSnap.data();
      if (data != null) {
        final username = data['username'] as String? ?? '';
        final velixId = data['velixId'] as String? ?? '';
        if (username.isNotEmpty) {
          batch.set(_usernames.doc(_usernameKey(username)), {
            'uid': uid,
            'username': username,
            'velixId': velixId,
            'twoStepVerificationEnabled': enabled,
          }, SetOptions(merge: true));
        }
        if (velixId.isNotEmpty) {
          batch.set(_velixIds.doc(_velixIdKey(velixId)), {
            'uid': uid,
            'username': username,
            'velixId': velixId,
            'twoStepVerificationEnabled': enabled,
          }, SetOptions(merge: true));
        }
      }

      await batch.commit();
    });
  }

  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _users.doc(uid);

  /// Moves legacy secrets off the public user document (owner session only).
  Future<void> migrateLegacySecretsIfNeeded(String uid) {
    return guardFirebase(() async {
      final userSnap = await _users.doc(uid).get();
      if (!userSnap.exists || userSnap.data() == null) return;
      final data = userSnap.data()!;

      final hasLegacy = data.containsKey('passwordVault') ||
          data.containsKey('recoverySecurityKey') ||
          data.containsKey('totpSecret');
      if (!hasLegacy) {
        // Still ensure lookup indexes exist.
        await _ensureLookupIndexes(uid, data);
        return;
      }

      final existingSecurity = await _securityRef(uid).get();
      final securityData = <String, dynamic>{
        if (existingSecurity.data() != null) ...existingSecurity.data()!,
      };

      if (data['recoverySecurityKey'] != null &&
          securityData['recoverySecurityKey'] == null) {
        securityData['recoverySecurityKey'] = data['recoverySecurityKey'];
      }
      if (data['passwordVault'] != null && securityData['passwordVault'] == null) {
        securityData['passwordVault'] = data['passwordVault'];
      }
      if (data['totpSecret'] != null && securityData['totpSecret'] == null) {
        securityData['totpSecret'] = data['totpSecret'];
      }
      securityData['updatedAt'] = FieldValue.serverTimestamp();

      final batch = _firestore.batch();
      batch.set(_securityRef(uid), securityData, SetOptions(merge: true));
      batch.set(userRef(uid), {
        'passwordVault': FieldValue.delete(),
        'recoverySecurityKey': FieldValue.delete(),
        'totpSecret': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();

      await _ensureLookupIndexes(uid, data);
    });
  }

  Future<void> _ensureLookupIndexes(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final username = data['username'] as String? ?? '';
    final velixId = data['velixId'] as String? ?? '';
    if (username.isEmpty || velixId.isEmpty) return;

    final payload = {
      'uid': uid,
      'username': username,
      'velixId': velixId,
      'twoStepVerificationEnabled':
          data['twoStepVerificationEnabled'] as bool? ?? false,
    };

    final batch = _firestore.batch();
    batch.set(_usernames.doc(_usernameKey(username)), payload, SetOptions(merge: true));
    batch.set(_velixIds.doc(_velixIdKey(velixId)), payload, SetOptions(merge: true));
    await batch.commit();
  }

  Map<String, dynamic> _publicProjection(Map<String, dynamic> data) {
    final copy = Map<String, dynamic>.from(data);
    copy.remove('passwordVault');
    copy.remove('recoverySecurityKey');
    copy.remove('recoverySecurityKeyHash');
    copy.remove('totpSecret');
    return copy;
  }
}
