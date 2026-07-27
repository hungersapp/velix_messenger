import 'dart:async';
import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/native_thumbnail_service.dart';
import '../../domain/entities/file_upload_result.dart';
import '../../domain/entities/media_upload_result.dart';
import '../../domain/entities/voice_upload_result.dart';
import '../../services/camera_permission_service.dart';
import '../../services/media_picker_service.dart';
import '../../services/microphone_permission_service.dart';
import '../../services/voice_recorder_service.dart';
import '../providers/media_provider.dart';
import '../providers/pending_media_provider.dart';
import '../screens/camera_capture_preview_screen.dart';

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
  final Future<void> Function(FileUploadResult result)? onFileSelected;
  final Future<void> Function(VoiceUploadResult result)? onVoiceSelected;

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
    this.onFileSelected,
    this.onVoiceSelected,
  });

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final MediaPickerService _picker = MediaPickerService();
  final CameraPermissionService _cameraPermission =
      const CameraPermissionService();
  final MicrophonePermissionService _microphonePermission =
      const MicrophonePermissionService();
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();
  final FocusNode _focusNode = FocusNode();

  bool _showEmojiPicker = false;
  bool _isRecordingVoice = false;
  bool _isSendingVoice = false;
  Duration _recordingElapsed = Duration.zero;
  Timer? _recordingTicker;

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _recordingTicker?.cancel();
    unawaited(_voiceRecorder.dispose());
    widget.controller.removeListener(_refresh);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
    }
  }

  Future<void> _toggleEmojiPicker() async {
    widget.onEmojiPressed?.call();

    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      _focusNode.requestFocus();
      return;
    }

    _focusNode.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _showEmojiPicker = true);
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    // Package inserts into [controller] at the cursor when provided.
    widget.onChanged?.call(widget.controller.text);
    _refresh();
  }

  void _showSnackBar(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), action: action),
    );
  }

  Future<bool> _ensureMicrophonePermission() async {
    final result = await _microphonePermission.ensureGranted();
    switch (result) {
      case MicrophonePermissionResult.granted:
        return true;
      case MicrophonePermissionResult.denied:
        _showSnackBar('Microphone permission is required to record voice.');
        return false;
      case MicrophonePermissionResult.permanentlyDenied:
        _showSnackBar(
          'Microphone permission is permanently denied. Enable it in Settings.',
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              _microphonePermission.openSettings();
            },
          ),
        );
        return false;
    }
  }

  String _formatRecordingDuration(Duration duration) {
    final minutes = duration.inMinutes.clamp(0, 99);
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startRecordingTicker() {
    _recordingTicker?.cancel();
    _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_isRecordingVoice || !mounted) return;
      final elapsed = _voiceRecorder.elapsed;
      setState(() => _recordingElapsed = elapsed);
      if (elapsed >= VoiceRecorderService.maxDuration) {
        await _sendVoiceRecording();
      }
    });
  }

  Future<void> _startVoiceRecording() async {
    if (_isRecordingVoice || _isSendingVoice) return;

    widget.onVoice?.call();

    final allowed = await _ensureMicrophonePermission();
    if (!allowed) return;

    try {
      _focusNode.unfocus();
      if (_showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }

      await _voiceRecorder.start();
      if (!mounted) return;
      setState(() {
        _isRecordingVoice = true;
        _recordingElapsed = Duration.zero;
      });
      _startRecordingTicker();
    } catch (e, st) {
      debugPrint('Voice recording start failed: $e\n$st');
      _showSnackBar('Unable to start recording. Please try again.');
      await _voiceRecorder.cancel();
    }
  }

  Future<void> _cancelVoiceRecording() async {
    _recordingTicker?.cancel();
    _recordingTicker = null;
    await _voiceRecorder.cancel();
    if (!mounted) return;
    setState(() {
      _isRecordingVoice = false;
      _recordingElapsed = Duration.zero;
    });
  }

  Future<void> _sendVoiceRecording() async {
    if (!_isRecordingVoice || _isSendingVoice) return;

    _recordingTicker?.cancel();
    _recordingTicker = null;

    setState(() {
      _isRecordingVoice = false;
      _isSendingVoice = true;
    });

    try {
      final recording = await _voiceRecorder.stop();
      if (recording == null) {
        _showSnackBar('Recording was too short.');
        return;
      }

      final fileName =
          'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final fileSize = await recording.file.length();
      final durationMs = recording.duration.inMilliseconds;

      final pendingId = ref.read(pendingMediaProvider.notifier).add(
            conversationId: widget.conversationId,
            mediaType: PendingMediaType.voice,
            localPath: recording.file.path,
            fileName: fileName,
            fileSize: fileSize,
            durationMs: durationMs,
          );

      try {
        debugPrint(
          '[MediaFlow] voice upload start conversationId=${widget.conversationId} '
          'senderId=${widget.senderId} file=$fileName',
        );
        final downloadUrl =
            await ref.read(mediaControllerProvider.notifier).uploadFile(
                  conversationId: widget.conversationId,
                  senderId: widget.senderId,
                  filePath: recording.file.path,
                  fileName: fileName,
                );

        if (downloadUrl.trim().isEmpty) {
          throw Exception(
            'Voice upload returned empty download URL; skipping Firestore write.',
          );
        }

        debugPrint('[MediaFlow] voice upload ok url=$downloadUrl');
        if (widget.onVoiceSelected != null) {
          await widget.onVoiceSelected!(
            VoiceUploadResult(
              mediaUrl: downloadUrl,
              fileName: fileName,
              fileSize: fileSize,
              mimeType: 'audio/mp4',
              durationMs: durationMs,
            ),
          );
          debugPrint('[MediaFlow] voice Firestore write requested');
        }
      } catch (e, st) {
        debugPrint('Voice upload/send failed: $e\n$st');
        _showSnackBar('Failed to upload voice message. Please try again.');
      } finally {
        ref.read(pendingMediaProvider.notifier).remove(pendingId);
      }
    } catch (e, st) {
      debugPrint('Voice recording stop failed: $e\n$st');
      _showSnackBar('Unable to save recording. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingVoice = false;
          _recordingElapsed = Duration.zero;
        });
      }
    }
  }

  Future<bool> _ensureCameraPermission() async {
    final result = await _cameraPermission.ensureGranted();
    switch (result) {
      case CameraPermissionResult.granted:
        return true;
      case CameraPermissionResult.denied:
        _showSnackBar('Camera permission is required to take a photo.');
        return false;
      case CameraPermissionResult.permanentlyDenied:
        _showSnackBar(
          'Camera permission is permanently denied. Enable it in Settings.',
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              _cameraPermission.openSettings();
            },
          ),
        );
        return false;
    }
  }

  /// Shared compress → pending bubble → Firebase upload → send image message.
  Future<void> _uploadAndSendImage(File image) async {
    debugPrint('1. Image selected');
    final File uploadFile = await _picker.compressImage(image) ?? image;
    debugPrint('2. Image compressed');

    final pendingId = ref.read(pendingMediaProvider.notifier).add(
          conversationId: widget.conversationId,
          mediaType: PendingMediaType.image,
          localPath: uploadFile.path,
        );

    try {
      debugPrint(
        '[MediaFlow] image upload start conversationId=${widget.conversationId} '
        'senderId=${widget.senderId}',
      );
      final imageUrl =
          await ref.read(mediaControllerProvider.notifier).uploadImage(
                conversationId: widget.conversationId,
                senderId: widget.senderId,
                filePath: uploadFile.path,
              );

      if (imageUrl.trim().isEmpty) {
        throw Exception(
          'Image upload returned empty download URL; skipping Firestore write.',
        );
      }

      if (widget.onImageSelected != null) {
        debugPrint('3. Upload completed: $imageUrl');
        await widget.onImageSelected!(imageUrl);
        debugPrint('4. Message created');
      }
    } catch (e, st) {
      debugPrint('Image upload/send failed: $e\n$st');
      _showSnackBar('Failed to upload image. Please try again.');
    } finally {
      ref.read(pendingMediaProvider.notifier).remove(pendingId);
    }
  }

  Future<void> _pickImage() async {
    try {
      final File? image = await _picker.pickImageFromGallery();
      if (image == null) return;
      await _uploadAndSendImage(image);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('$e');
    }
  }

  Future<void> _captureFromCamera() async {
    while (mounted) {
      final allowed = await _ensureCameraPermission();
      if (!allowed) return;

      final File? captured;
      try {
        captured = await _picker.pickImageFromCamera();
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('$e');
        return;
      }
      if (captured == null) return;
      final imageFile = captured;

      if (!mounted) return;
      final action = await Navigator.of(context).push<CameraCapturePreviewAction>(
        MaterialPageRoute(
          builder: (_) => CameraCapturePreviewScreen(imageFile: imageFile),
          fullscreenDialog: true,
        ),
      );

      switch (action) {
        case CameraCapturePreviewAction.send:
          await _uploadAndSendImage(imageFile);
          return;
        case CameraCapturePreviewAction.retake:
          continue;
        case CameraCapturePreviewAction.cancel:
        case null:
          return;
      }
    }
  }

  Future<void> _pickVideo() async {
    final File? video;
    try {
      video = await _picker.pickVideo();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('$e');
      return;
    }

    if (video == null) return;

    debugPrint('1. Video selected');

    String? localThumbnailPath;
    try {
      localThumbnailPath = await NativeThumbnailService.generateThumbnail(
        videoPath: video.path,
      );
    } catch (e) {
      debugPrint('Local video thumbnail failed: $e');
    }

    final pendingId = ref.read(pendingMediaProvider.notifier).add(
          conversationId: widget.conversationId,
          mediaType: PendingMediaType.video,
          localPath: video.path,
          localThumbnailPath: localThumbnailPath,
        );

    try {
      debugPrint(
        '[MediaFlow] video upload start conversationId=${widget.conversationId} '
        'senderId=${widget.senderId}',
      );
      final result =
          await ref.read(mediaControllerProvider.notifier).uploadVideo(
                conversationId: widget.conversationId,
                senderId: widget.senderId,
                filePath: video.path,
              );

      debugPrint('Video URL: ${result.mediaUrl}');
      debugPrint('Thumbnail: ${result.thumbnailUrl}');

      if (result.mediaUrl.trim().isEmpty) {
        throw Exception(
          'Video upload returned empty download URL; skipping Firestore write.',
        );
      }

      if (widget.onVideoSelected != null) {
        await widget.onVideoSelected!(result);
      }

      debugPrint('3. Video message created');
    } catch (e, st) {
      debugPrint('Video upload/send failed: $e\n$st');
      if (mounted) {
        _showSnackBar('Failed to upload video. Please try again.');
      }
    } finally {
      ref.read(pendingMediaProvider.notifier).remove(pendingId);
    }
  }

  Future<void> _pickDocument() async {
    final PickedDocument? document;
    try {
      document = await _picker.pickDocument();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('$e');
      return;
    }
    if (document == null) return;

    if (document.fileSize > MediaPickerService.maxDocumentBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document must be 25 MB or smaller.'),
        ),
      );
      return;
    }

    final storageFileName =
        '${DateTime.now().millisecondsSinceEpoch}_${document.fileName}';

    final pendingId = ref.read(pendingMediaProvider.notifier).add(
          conversationId: widget.conversationId,
          mediaType: PendingMediaType.file,
          localPath: document.file.path,
          fileName: document.fileName,
          fileSize: document.fileSize,
        );

    try {
      debugPrint(
        '[MediaFlow] document upload start conversationId=${widget.conversationId} '
        'senderId=${widget.senderId} file=$storageFileName',
      );
      final downloadUrl =
          await ref.read(mediaControllerProvider.notifier).uploadFile(
                conversationId: widget.conversationId,
                senderId: widget.senderId,
                filePath: document.file.path,
                fileName: storageFileName,
              );

      if (downloadUrl.trim().isEmpty) {
        throw Exception(
          'Document upload returned empty download URL; skipping Firestore write.',
        );
      }

      if (widget.onFileSelected != null) {
        await widget.onFileSelected!(
          FileUploadResult(
            mediaUrl: downloadUrl,
            fileName: document.fileName,
            fileSize: document.fileSize,
            mimeType: document.mimeType,
          ),
        );
        debugPrint('[MediaFlow] document Firestore write requested');
      }
    } catch (e, st) {
      debugPrint('Document upload/send failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload document. Please try again.'),
          ),
        );
      }
    } finally {
      ref.read(pendingMediaProvider.notifier).remove(pendingId);
    }
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
                onTap: () async {
                  Navigator.pop(context);
                  await _captureFromCamera();
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
                onTap: () async {
                  Navigator.pop(context);
                  await _pickDocument();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeArea(
          top: false,
          bottom: !_showEmojiPicker,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: _isRecordingVoice
                ? _buildRecordingBar(theme)
                : _buildComposerRow(theme),
          ),
        ),
        if (_showEmojiPicker && !_isRecordingVoice)
          SizedBox(
            height: 256,
            child: EmojiPicker(
              textEditingController: widget.controller,
              onEmojiSelected: _onEmojiSelected,
              config: Config(
                height: 256,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 28 *
                      (foundation.defaultTargetPlatform ==
                              TargetPlatform.iOS
                          ? 1.20
                          : 1.0),
                  backgroundColor: theme.colorScheme.surface,
                ),
                skinToneConfig: const SkinToneConfig(),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: theme.colorScheme.surface,
                  indicatorColor: theme.colorScheme.primary,
                  iconColorSelected: theme.colorScheme.primary,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor: theme.colorScheme.surface,
                  buttonColor: theme.colorScheme.primary,
                  buttonIconColor: theme.colorScheme.onPrimary,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: theme.colorScheme.surface,
                  buttonIconColor: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecordingBar(ThemeData theme) {
    return Row(
      children: [
        IconButton(
          onPressed: _isSendingVoice ? null : _cancelVoiceRecording,
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
        ),
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Recording',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _formatRecordingDuration(_recordingElapsed),
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        Material(
          color: theme.colorScheme.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _isSendingVoice ? null : _sendVoiceRecording,
            child: SizedBox(
              width: 46,
              height: 46,
              child: _isSendingVoice
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: theme.colorScheme.onPrimary,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComposerRow(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton(
          onPressed: _toggleEmojiPicker,
          icon: Icon(
            _showEmojiPicker
                ? Icons.keyboard_outlined
                : Icons.emoji_emotions_outlined,
          ),
        ),
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            minLines: 1,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Type a message...',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: widget.onChanged,
            onTap: () {
              if (_showEmojiPicker) {
                setState(() => _showEmojiPicker = false);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: theme.colorScheme.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _showAttachmentSheet,
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Center(
                child: Text(
                  'Ⓥ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: theme.colorScheme.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _hasText
                ? widget.onSend
                : (_isSendingVoice ? null : _startVoiceRecording),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                _hasText ? Icons.send_rounded : Icons.mic_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
