import 'story_entity.dart';

/// Group of active stories for one owner (Home rail + viewer).
class StoryOwnerBucket {
  const StoryOwnerBucket({
    required this.ownerId,
    required this.ownerName,
    this.ownerPhotoUrl,
    required this.stories,
  });

  final String ownerId;
  final String ownerName;
  final String? ownerPhotoUrl;

  /// Chronological (oldest → newest) for viewer playback.
  final List<StoryEntity> stories;

  bool hasUnseenFor(String viewerId) {
    return stories.any((story) => !story.isSeenBy(viewerId));
  }

  DateTime get latestCreatedAt {
    if (stories.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return stories
        .map((s) => s.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }
}
