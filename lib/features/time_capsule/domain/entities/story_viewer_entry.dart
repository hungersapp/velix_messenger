class StoryViewerEntry {
  const StoryViewerEntry({
    required this.userId,
    required this.name,
    this.photoUrl,
    this.viewedAt,
  });

  final String userId;
  final String name;
  final String? photoUrl;
  final DateTime? viewedAt;
}
