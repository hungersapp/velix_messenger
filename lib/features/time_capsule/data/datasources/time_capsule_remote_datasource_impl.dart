import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/firebase_error_guard.dart';
import '../models/story_model.dart';
import 'time_capsule_remote_datasource.dart';

class TimeCapsuleRemoteDataSourceImpl
    implements TimeCapsuleRemoteDataSource {
  TimeCapsuleRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int pageSize = 50;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('time_capsules');

  /// Active capsules only. With a fixed 24h TTL, expiresAt desc ≈ newest first.
  Query<Map<String, dynamic>> _activeQuery(Timestamp now) {
    return _collection
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt', descending: true);
  }

  @override
  Stream<List<StoryModel>> watchActiveStories() {
    final now = Timestamp.now();

    return guardFirebaseStream(
      _activeQuery(now).limit(pageSize).snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
            .where((story) => story.expiresAt.toDate().isAfter(DateTime.now()))
            .toList();
      }),
    );
  }

  @override
  Future<List<StoryModel>> getOlderActiveStories({
    required String beforeStoryId,
    int limit = pageSize,
  }) {
    return guardFirebase(() async {
      if (beforeStoryId.isEmpty || limit <= 0) {
        return const [];
      }

      final cursor = await _collection.doc(beforeStoryId).get();
      if (!cursor.exists) {
        return const [];
      }

      final now = Timestamp.now();
      final snapshot = await _activeQuery(now)
          .startAfterDocument(cursor)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
          .where((story) => story.expiresAt.toDate().isAfter(DateTime.now()))
          .toList();
    });
  }

  @override
  Future<void> createStory(StoryModel story) {
    return guardFirebase(() async {
      await _collection.doc(story.id).set(story.toMap());
    });
  }

  @override
  Future<void> markStorySeen({
    required String storyId,
    required String viewerId,
  }) {
    return guardFirebase(() async {
      final docRef = _collection.doc(storyId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return;
        }

        final data = snapshot.data();
        if (data == null) {
          return;
        }

        final viewersRaw = data['viewers'];
        if (viewersRaw is Map && viewersRaw.containsKey(viewerId)) {
          return;
        }

        final seenBy = List<String>.from(data['seenBy'] ?? const []);
        if (seenBy.contains(viewerId)) {
          // Legacy doc: already counted in seenBy; backfill viewers map once.
          transaction.update(docRef, {
            'viewers.$viewerId': Timestamp.now(),
          });
          return;
        }

        transaction.update(docRef, {
          'viewers.$viewerId': Timestamp.now(),
          'seenBy': FieldValue.arrayUnion([viewerId]),
        });
      });
    });
  }

  @override
  Future<bool> toggleStoryLike({
    required String storyId,
    required String userId,
  }) {
    return guardFirebase(() async {
      final docRef = _collection.doc(storyId);

      return _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return false;
        }

        final data = snapshot.data();
        if (data == null) {
          return false;
        }

        final likesRaw = data['likes'];
        final alreadyLiked =
            likesRaw is Map && likesRaw.containsKey(userId);

        if (alreadyLiked) {
          transaction.update(docRef, {
            'likes.$userId': FieldValue.delete(),
          });
          return false;
        }

        transaction.update(docRef, {
          'likes.$userId': Timestamp.now(),
        });
        return true;
      });
    });
  }

  @override
  Future<void> deleteStory(String storyId) {
    return guardFirebase(() async {
      try {
        await _collection.doc(storyId).delete();
      } on FirebaseException catch (e) {
        if (e.code == 'not-found') {
          return;
        }
        rethrow;
      }
    });
  }
}
