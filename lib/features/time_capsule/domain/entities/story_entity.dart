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
  final List<String> seenBy;
  final String visibility; // friends
  final int durationMs;

  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';

  bool isExpired([DateTime? now]) {
    return (now ?? DateTime.now()).isAfter(expiresAt);
  }

  bool isActive([DateTime? now]) => !isExpired(now);

  bool isSeenBy(String userId) => seenBy.contains(userId);

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
      visibility: visibility ?? this.visibility,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}
