import 'package:flutter/material.dart';

import 'dart:io';
//import 'package:uuid/uuid.dart';

import '../../services/media_picker_service.dart';
import '../providers/media_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/media_upload_result.dart';
//import '../../../../core/services/native_thumbnail_service.dart';
//import '../providers/pending_media_provider.dart';

class MessageInput extends ConsumerStatefulWidget {
  final String conversationId;
  final String senderId;

  final TextEditingController controller;
  final VoidCallback? onEmojiPressed;
  final VoidCallback? onVelixPressed;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSend;
  final VoidCallback? onVoice;
  final Future<void> Function(String imageUrl)? onImageSelected;
  final Future<void> Function(MediaUploadResult result)? onVideoSelected;

  const MessageInput({
    super.key,
    required this.conversationId,
    required this.senderId,
    required this.controller,
    this.onEmojiPressed,
    this.onVelixPressed,
    this.onChanged,
    this.onSend,
    this.onVoice,
    this.onImageSelected,
    this.onVideoSelected,
  });

  @override
  ConsumerState<MessageInput> createState() =>
      _MessageInputState();
      
}

class _MessageInputState
    extends ConsumerState<MessageInput> {

      final MediaPickerService _picker = MediaPickerService();

      
        Future<void> _pickImage() async {
  final File? image =
    await _picker.pickImageFromGallery();

  if (image == null) return;

debugPrint("1. Gallery selected");
  final File uploadFile =
    await _picker.compressImage(image) ?? image;
debugPrint("2. Image compressed");

  final imageUrl =
      await ref
          .read(mediaControllerProvider.notifier)
          .uploadImage(
          conversationId: widget.conversationId,
           senderId: widget.senderId,
          filePath: uploadFile.path,
        );

  if (widget.onImageSelected != null) {

debugPrint("3. Upload completed: $imageUrl");
  await widget.onImageSelected!(imageUrl);
  debugPrint("4. Message created");
}
}

Future<void> _pickVideo() async {
  final File? video =
    await _picker.pickVideo();

  if (video == null) return;

  debugPrint("1. Video selected");

  final result = await ref
    .read(mediaControllerProvider.notifier)
    .uploadVideo(
      conversationId: widget.conversationId,
      senderId: widget.senderId,
      filePath: video.path,
    );

debugPrint("Video URL: ${result.mediaUrl}");
debugPrint("Thumbnail: ${result.thumbnailUrl}");

if (widget.onVideoSelected != null) {
  await widget.onVideoSelected!(result);
}

debugPrint("3. Video message created");
}

void _showAttachmentSheet() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              onTap: () async {
              Navigator.pop(context);
              await _pickVideo();
               },
               ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}
  bool get _hasText =>
      widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          12,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [

            /// Emoji
            IconButton(
              onPressed: widget.onEmojiPressed,
              icon: const Icon(
                Icons.emoji_emotions_outlined,
              ),
            ),

            /// Text Field
            Expanded(
              child: TextField(
                controller: widget.controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: widget.onChanged,
              ),
            ),

            const SizedBox(width: 8),

            /// Velix Button
            Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder:
                    const CircleBorder(),
                onTap: _showAttachmentSheet,
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Center(
                    child: Text(
                      "Ⓥ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            /// Send / Voice
            Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder:
                    const CircleBorder(),
                onTap: _hasText
                    ? widget.onSend
                    : widget.onVoice,
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    _hasText
                        ? Icons.send_rounded
                        : Icons.mic_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}