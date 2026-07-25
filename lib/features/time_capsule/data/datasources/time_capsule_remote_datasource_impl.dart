import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/story_model.dart';
import 'time_capsule_remote_datasource.dart';

class TimeCapsuleRemoteDataSourceImpl
    implements TimeCapsuleRemoteDataSource {
  TimeCapsuleRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('time_capsules');

  @override
  Stream<List<StoryModel>> watchActiveStories() {
    final now = Timestamp.now();

    return _collection
        .where('expiresAt', isGreaterThan: now)
        .snapshots()
        .map((snapshot) {
      final stories = snapshot.docs
          .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
          .where((story) => story.expiresAt.toDate().isAfter(DateTime.now()))
          .toList();

      stories.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return stories;
    });
  }

  @override
  Future<void> createStory(StoryModel story) async {
    await _collection.doc(story.id).set(story.toMap());
  }

  @override
  Future<void> markStorySeen({
    required String storyId,
    required String viewerId,
  }) async {
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
  }

  @override
  Future<bool> toggleStoryLike({
    required String storyId,
    required String userId,
  }) async {
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
  }

  @override
  Future<void> deleteStory(String storyId) async {
    try {
      await _collection.doc(storyId).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        return;
      }
      rethrow;
    }
  }
}
