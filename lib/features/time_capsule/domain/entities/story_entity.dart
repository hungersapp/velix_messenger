class StoryEntity {
  const StoryEntity({
    required this.id,
    required this.ownerId,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.seenBy,
    this.viewers = const {},
    this.likes = const {},
    required this.visibility,
    required this.durationMs,
  });

  final String id;
  final String ownerId;
  final String mediaType; // image | video
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// Legacy + compatibility list of viewer UIDs.
  final List<String> seenBy;

  /// userId → viewedAt (preferred source for seen count).
  final Map<String, DateTime> viewers;

  /// userId → likedAt
  final Map<String, DateTime> likes;

  final String visibility; // friends
  final int durationMs;

  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';

  /// Unique viewers from [viewers] map and legacy [seenBy].
  int get seenCount {
    final ids = <String>{...viewers.keys, ...seenBy};
    return ids.length;
  }

  int get likeCount => likes.length;

  bool isExpired([DateTime? now]) {
    return (now ?? DateTime.now()).isAfter(expiresAt);
  }

  bool isActive([DateTime? now]) => !isExpired(now);

  bool isSeenBy(String userId) =>
      viewers.containsKey(userId) || seenBy.contains(userId);

  bool isLikedBy(String userId) => likes.containsKey(userId);

  StoryEntity copyWith({
    String? id,
    String? ownerId,
    String? mediaType,
    String? mediaUrl,
    String? thumbnailUrl,
    String? caption,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? seenBy,
    Map<String, DateTime>? viewers,
    Map<String, DateTime>? likes,
    String? visibility,
    int? durationMs,
  }) {
    return StoryEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      mediaType: mediaType ?? this.mediaType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      seenBy: seenBy ?? this.seenBy,
      viewers: viewers ?? this.viewers,
      likes: likes ?? this.likes,
      visibility: visibility ?? this.visibility,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}
