class MediaUploadResult {
  final String mediaUrl;
  final String? thumbnailUrl;

  const MediaUploadResult({
    required this.mediaUrl,
    this.thumbnailUrl,
  });

  bool get hasThumbnail =>
      thumbnailUrl != null &&
      thumbnailUrl!.isNotEmpty;

  MediaUploadResult copyWith({
    String? mediaUrl,
    String? thumbnailUrl,
  }) {
    return MediaUploadResult(
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}