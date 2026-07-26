class VoiceUploadResult {
  const VoiceUploadResult({
    required this.mediaUrl,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.durationMs,
  });

  final String mediaUrl;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final int durationMs;
}
