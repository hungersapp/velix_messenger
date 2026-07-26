class FileUploadResult {
  const FileUploadResult({
    required this.mediaUrl,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
  });

  final String mediaUrl;
  final String fileName;
  final int fileSize;
  final String mimeType;
}
