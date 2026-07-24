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
    await _collection.doc(storyId).update({
      'seenBy': FieldValue.arrayUnion([viewerId]),
    });
  }
}
