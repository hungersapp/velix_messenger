import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/firebase/firebase_error_guard.dart';
import '../../../authentication/domain/services/password_vault.dart';
import '../../domain/entities/settings_models.dart';

class SettingsRemoteDatasource {
  SettingsRemoteDatasource({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    TotpVerifier? totpVerifier,
    TotpSecretGenerator? totpSecretGenerator,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance,
        _totpVerifier = totpVerifier ?? const TotpVerifier(),
        _totpSecretGenerator = totpSecretGenerator ?? TotpSecretGenerator();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final TotpVerifier _totpVerifier;
  final TotpSecretGenerator _totpSecretGenerator;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _users.doc(uid);

  CollectionReference<Map<String, dynamic>> _blocked(String uid) =>
      _userDoc(uid).collection('blocked');

  CollectionReference<Map<String, dynamic>> _devices(String uid) =>
      _userDoc(uid).collection('devices');

  Future<PrivacySettings> getPrivacySettings(String userId) {
    return guardFirebase(() async {
      final snap = await _userDoc(userId).get();
      final data = snap.data() ?? {};
      return PrivacySettings(
        lastSeen: PrivacyVisibility.fromStorage(
          data['lastSeenPrivacy'] as String?,
        ),
        profilePhoto: PrivacyVisibility.fromStorage(
          data['profilePhotoPrivacy'] as String?,
        ),
        readReceipts: data['readReceiptsEnabled'] as bool? ?? true,
      );
    });
  }

  Future<void> updatePrivacySettings(
    String userId,
    PrivacySettings settings,
  ) {
    return guardFirebase(() async {
      await _userDoc(userId).set({
        'lastSeenPrivacy': settings.lastSeen.storageValue,
        'profilePhotoPrivacy': settings.profilePhoto.storageValue,
        'readReceiptsEnabled': settings.readReceipts,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Stream<List<BlockedUser>> watchBlockedUsers(String userId) {
    return guardFirebaseStream(
      _blocked(userId)
          .orderBy('blockedAt', descending: true)
          .snapshots()
          .map((snap) {
        return snap.docs.map((doc) {
          final data = doc.data();
          return BlockedUser(
            uid: doc.id,
            displayName: data['displayName'] as String? ?? 'Velix User',
            velixId: data['velixId'] as String? ?? '',
            photoUrl: data['photoUrl'] as String? ?? '',
            blockedAt: (data['blockedAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
          );
        }).toList();
      }),
    );
  }

  Future<void> blockUser({
    required String currentUserId,
    required BlockedUser user,
  }) {
    return guardFirebase(() async {
      await _blocked(currentUserId).doc(user.uid).set({
        'uid': user.uid,
        'displayName': user.displayName,
        'velixId': user.velixId,
        'photoUrl': user.photoUrl,
        'blockedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) {
    return guardFirebase(() async {
      await _blocked(currentUserId).doc(blockedUserId).delete();
    });
  }

  Future<bool> isBlockedEitherWay({
    required String userA,
    required String userB,
  }) {
    return guardFirebase(() async {
      final a = await _blocked(userA).doc(userB).get();
      if (a.exists) return true;
      final b = await _blocked(userB).doc(userA).get();
      return b.exists;
    });
  }

  Future<List<ActiveDevice>> getActiveDevices({
    required String userId,
    required String currentDeviceId,
  }) {
    return guardFirebase(() async {
      final snap =
          await _devices(userId).orderBy('lastActiveAt', descending: true).get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return ActiveDevice(
          id: doc.id,
          name: data['name'] as String? ?? 'Unknown device',
          platform: data['platform'] as String? ?? 'unknown',
          lastActiveAt:
              (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isCurrent: doc.id == currentDeviceId,
        );
      }).toList();
    });
  }

  Future<void> registerCurrentDevice({
    required String userId,
    required ActiveDevice device,
  }) {
    return guardFirebase(() async {
      // Soft-enforce one active mobile session (architecture requirement).
      final isMobile =
          device.platform == 'Android' || device.platform == 'iOS';
      if (isMobile) {
        final snap = await _devices(userId).get();
        for (final doc in snap.docs) {
          if (doc.id == device.id) continue;
          final data = doc.data();
          final platform = data['platform'] as String? ?? '';
          final alreadyRevoked = data['revoked'] as bool? ?? false;
          if (alreadyRevoked) continue;
          if (platform == 'Android' || platform == 'iOS') {
            await revokeDevice(userId: userId, deviceId: doc.id);
          }
        }
      }

      await _devices(userId).doc(device.id).set({
        'name': device.name,
        'platform': device.platform,
        'lastActiveAt': FieldValue.serverTimestamp(),
        'revoked': false,
      }, SetOptions(merge: true));
    });
  }

  Future<void> revokeDevice({
    required String userId,
    required String deviceId,
  }) {
    return guardFirebase(() async {
      await _devices(userId).doc(deviceId).set({
        'revoked': true,
        'revokedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<bool> isDeviceRevoked({
    required String userId,
    required String deviceId,
  }) {
    return guardFirebase(() async {
      final snap = await _devices(userId).doc(deviceId).get();
      if (!snap.exists) return false;
      return snap.data()?['revoked'] as bool? ?? false;
    });
  }

  Future<bool> isTwoFactorEnabled(String userId) {
    return guardFirebase(() async {
      final snap = await _userDoc(userId).get();
      return snap.data()?['twoStepVerificationEnabled'] as bool? ?? false;
    });
  }

  Future<String> generateTwoFactorSecret() {
    return Future.value(_totpSecretGenerator.generate());
  }

  Future<void> confirmTwoFactor({
    required String userId,
    required String secret,
    required String otp,
  }) {
    return guardFirebase(() async {
      final ok = _totpVerifier.verify(secretBase32: secret, otp: otp);
      if (!ok) {
        throw Exception('Invalid authenticator code');
      }
      await _writeTwoFactor(userId: userId, enabled: true, totpSecret: secret);
    });
  }

  Future<void> disableTwoFactor({
    required String userId,
    required String otp,
  }) {
    return guardFirebase(() async {
      final security = await _securityRef(userId).get();
      var secret = security.data()?['totpSecret'] as String? ?? '';
      if (secret.isEmpty) {
        final snap = await _userDoc(userId).get();
        secret = snap.data()?['totpSecret'] as String? ?? '';
      }
      if (secret.isEmpty) {
        throw Exception('Two-factor authentication is not configured');
      }
      final ok = _totpVerifier.verify(secretBase32: secret, otp: otp);
      if (!ok) {
        throw Exception('Invalid authenticator code');
      }
      await _writeTwoFactor(userId: userId, enabled: false, totpSecret: null);
    });
  }

  Future<bool> verifyCurrentUserTotp(String otp) {
    return guardFirebase(() async {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;
      final userSnap = await _userDoc(uid).get();
      final enabled =
          userSnap.data()?['twoStepVerificationEnabled'] as bool? ?? false;
      if (!enabled) return true;

      final security = await _securityRef(uid).get();
      var secret = security.data()?['totpSecret'] as String? ?? '';
      if (secret.isEmpty) {
        secret = userSnap.data()?['totpSecret'] as String? ?? '';
      }
      if (secret.isEmpty) return false;
      return _totpVerifier.verify(secretBase32: secret, otp: otp);
    });
  }

  DocumentReference<Map<String, dynamic>> _securityRef(String uid) =>
      _userDoc(uid).collection('security').doc('credentials');

  Future<void> _writeTwoFactor({
    required String userId,
    required bool enabled,
    required String? totpSecret,
  }) async {
    final userSnap = await _userDoc(userId).get();
    final data = userSnap.data() ?? {};
    final username = data['username'] as String? ?? '';
    final velixId = data['velixId'] as String? ?? '';

    final batch = _firestore.batch();
    batch.set(_userDoc(userId), {
      'twoStepVerificationEnabled': enabled,
      'totpSecret': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_securityRef(userId), {
      'totpSecret': enabled ? totpSecret : null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final lookup = {
      'uid': userId,
      'username': username,
      'velixId': velixId,
      'twoStepVerificationEnabled': enabled,
    };
    if (username.isNotEmpty) {
      batch.set(
        _firestore.collection('usernames').doc(username.trim().toLowerCase()),
        lookup,
        SetOptions(merge: true),
      );
    }
    if (velixId.isNotEmpty) {
      batch.set(
        _firestore.collection('velix_ids').doc(velixId.trim().toLowerCase()),
        lookup,
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> submitSupportRequest({
    required String userId,
    required String type,
    required String message,
  }) {
    return guardFirebase(() async {
      await _firestore.collection('support_requests').add({
        'userId': userId,
        'type': type,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
      });
    });
  }
}
