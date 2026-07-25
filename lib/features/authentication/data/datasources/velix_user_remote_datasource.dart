import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/velix_user_model.dart';

class VelixUserRemoteDatasource {
  VelixUserRemoteDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'users';

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(_collection);

  Future<bool> isUsernameTaken(String username) async {
    final query = await _users
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<Map<String, dynamic>?> findByUsername(String username) async {
    final query = await _users
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.data();
  }

  Future<bool> isVelixIdTaken(String velixId) async {
    final query = await _users
        .where('velixId', isEqualTo: velixId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> saveUser(VelixUserModel user) async {
    await _users.doc(user.uid).set(user.toFirestore());
  }

  Future<void> updatePasswordVault({
    required String uid,
    required String passwordVault,
  }) async {
    await _users.doc(uid).update({
      'passwordVault': passwordVault,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> findByVelixId(String velixId) async {
    final trimmed = velixId.trim();
    final exact = await _users
        .where('velixId', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (exact.docs.isNotEmpty) {
      return exact.docs.first.data();
    }

    final lower = await _users
        .where('velixIdLower', isEqualTo: trimmed.toLowerCase())
        .limit(1)
        .get();

    if (lower.docs.isEmpty) return null;
    return lower.docs.first.data();
  }

  Future<Map<String, dynamic>?> findByIdentifier(String identifier) async {
    final normalized = identifier.trim().startsWith('@')
        ? identifier.trim()
        : '@${identifier.trim()}';

    final byVelix = await findByVelixId(normalized);
    if (byVelix != null) return byVelix;

    final looksLikeVelixId =
        RegExp(r'_VX[A-Z0-9]+$', caseSensitive: false).hasMatch(normalized);
    if (looksLikeVelixId) return null;

    return findByUsername(normalized);
  }
}
