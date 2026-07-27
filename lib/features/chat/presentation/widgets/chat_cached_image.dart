import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Shared cached network image helpers for chat media previews.
abstract final class ChatCachedImage {
  ChatCachedImage._();

  static const double previewSize = 220;

  /// Disk + memory cached [ImageProvider] for full-screen viewing.
  static ImageProvider provider(String imageUrl) =>
      CachedNetworkImageProvider(imageUrl);

  static int memCacheExtent(BuildContext context, double logicalSize) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return (logicalSize * ratio).round();
  }
}

/// 220×220 chat image preview with disk/memory caching.
class ChatImagePreview extends StatelessWidget {
  const ChatImagePreview({
    super.key,
    required this.imageUrl,
    this.width = ChatCachedImage.previewSize,
    this.height = ChatCachedImage.previewSize,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final memExtent = ChatCachedImage.memCacheExtent(context, width);

    return RepaintBoundary(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memExtent,
        memCacheHeight: memExtent,
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: const Duration(milliseconds: 80),
        placeholder: (context, url) => _ChatImagePlaceholder(
          width: width,
          height: height,
        ),
        errorWidget: (context, url, error) => _ChatImageError(
          width: width,
          height: height,
        ),
      ),
    );
  }
}

/// Video thumbnail preview in chat bubbles.
class ChatVideoThumbnailPreview extends StatelessWidget {
  const ChatVideoThumbnailPreview({
    super.key,
    required this.thumbnailUrl,
    this.width = ChatCachedImage.previewSize,
    this.height = ChatCachedImage.previewSize,
    this.fit = BoxFit.cover,
  });

  final String thumbnailUrl;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final memExtent = ChatCachedImage.memCacheExtent(context, width);

    return RepaintBoundary(
      child: CachedNetworkImage(
        imageUrl: thumbnailUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memExtent,
        memCacheHeight: memExtent,
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: const Duration(milliseconds: 80),
        placeholder: (context, url) => _ChatImagePlaceholder(
          width: width,
          height: height,
        ),
        errorWidget: (context, url, error) => _ChatVideoThumbnailError(
          width: width,
          height: height,
        ),
      ),
    );
  }
}

class _ChatImagePlaceholder extends StatelessWidget {
  const _ChatImagePlaceholder({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }
}

class _ChatImageError extends StatelessWidget {
  const _ChatImageError({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 50,
        ),
      ),
    );
  }
}

class _ChatVideoThumbnailError extends StatelessWidget {
  const _ChatVideoThumbnailError({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.black12,
      child: const Icon(
        Icons.videocam,
        size: 50,
      ),
    );
  }
}
