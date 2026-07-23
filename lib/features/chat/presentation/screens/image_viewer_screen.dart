import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            loadingBuilder: (context, event) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 60,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}