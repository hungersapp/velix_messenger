import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/firebase_error_guard.dart';
import '../models/user_model.dart';

class FirestoreUserDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'users';

  /// Save User
  Future<void> saveUser(UserModel user) {
    return guardFirebase(() async {
      await _firestore
          .collection(_collection)
          .doc(user.uid)
          .set(user.toMap());
    });
  }

  /// Check User Exists
  Future<bool> userExists(String uid) {
    return guardFirebase(() async {
      final doc = await _firestore
          .collection(_collection)
          .doc(uid)
          .get();

      return doc.exists;
    });
  }

  /// Get User
  Future<UserModel?> getUser(String uid) {
    return guardFirebase(() async {
      final doc = await _firestore
          .collection(_collection)
          .doc(uid)
          .get();

      if (!doc.exists) {
        return null;
      }

      return UserModel.fromMap(doc.data()!);
    });
  }

  /// Check Mobile Number Exists
  Future<bool> isMobileExists(String mobile) {
    return guardFirebase(() async {
      final query = await _firestore
          .collection(_collection)
          .where('mobile', isEqualTo: mobile)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    });
  }
}
