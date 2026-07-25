import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/app_routes.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../providers/time_capsule_provider.dart';
import '../services/time_capsule_media_service.dart';
import '../utils/story_time_formatter.dart';
import '../../domain/entities/story_owner_bucket.dart';

class TimeCapsuleRail extends ConsumerWidget {
  const TimeCapsuleRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bucketsAsync = ref.watch(storyBucketsProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final uploadState = ref.watch(storyUploadControllerProvider);

    ref.listen<StoryUploadState>(storyUploadControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.phase == next.phase) {
        return;
      }

      if (next.phase == StoryUploadPhase.success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your TC shared')),
          );
          ref.read(storyUploadControllerProvider.notifier).acknowledge();
        });
        return;
      }

      if (next.phase == StoryUploadPhase.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? 'Upload failed'),
          ),
        );
        ref.read(storyUploadControllerProvider.notifier).acknowledge();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            'Time Capsule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 118,
          child: bucketsAsync.when(
            loading: () => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Unable to load Time Capsule',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            data: (buckets) {
              if (currentUser == null) {
                return const SizedBox.shrink();
              }

              final yourBucket = buckets.isNotEmpty ? buckets.first : null;
              final friendBuckets = buckets.length > 1
                  ? buckets.sublist(1).where((b) => b.stories.isNotEmpty)
                  : const <StoryOwnerBucket>[];

              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (yourBucket != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _YourTimeCapsuleBubble(
                        bucket: yourBucket,
                        viewerId: currentUser.uid,
                        showUploadRing: uploadState.showUploadRing,
                        onAdd: uploadState.isInProgress
                            ? null
                            : () => _openCreateSheet(context, ref),
                        onView: yourBucket.stories.isEmpty ||
                                uploadState.isInProgress
                            ? null
                            : () => _openViewer(
                                  context,
                                  buckets: buckets
                                      .where(
                                        (b) =>
                                            b.ownerId == currentUser.uid ||
                                            b.stories.isNotEmpty,
                                      )
                                      .toList(),
                                  initialOwnerId: currentUser.uid,
                                ),
                      ),
                    ),
                  ...friendBuckets.map(
                    (bucket) => Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _FriendTimeCapsuleBubble(
                        bucket: bucket,
                        viewerId: currentUser.uid,
                        onTap: () => _openViewer(
                          context,
                          buckets: buckets
                              .where(
                                (b) =>
                                    b.ownerId == currentUser.uid ||
                                    b.stories.isNotEmpty,
                              )
                              .toList(),
                          initialOwnerId: bucket.ownerId,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _openViewer(
    BuildContext context, {
    required List<StoryOwnerBucket> buckets,
    required String initialOwnerId,
  }) {
    final viewable = buckets.where((b) => b.stories.isNotEmpty).toList();
    if (viewable.isEmpty) return;

    context.push(
      AppRoutes.timeCapsuleViewer,
      extra: {
        'buckets': viewable,
        'initialOwnerId': initialOwnerId,
      },
    );
  }

  Future<void> _openCreateSheet(BuildContext context, WidgetRef ref) async {
    if (ref.read(storyUploadControllerProvider).isInProgress) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Photo from gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUpload(
                    context,
                    ref,
                    image: true,
                    source: ImageSource.gallery,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUpload(
                    context,
                    ref,
                    image: true,
                    source: ImageSource.camera,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Video from gallery'),
                subtitle: const Text('Max 30 seconds'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUpload(
                    context,
                    ref,
                    image: false,
                    source: ImageSource.gallery,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Record video'),
                subtitle: const Text('Max 30 seconds'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUpload(
                    context,
                    ref,
                    image: false,
                    source: ImageSource.camera,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    WidgetRef ref, {
    required bool image,
    required ImageSource source,
  }) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    if (ref.read(storyUploadControllerProvider).isInProgress) {
      return;
    }

    final mediaService = ref.read(timeCapsuleMediaServiceProvider);

    try {
      final media = image
          ? await mediaService.pickImage(source: source)
          : await mediaService.pickVideo(source: source);

      if (media == null || !context.mounted) return;

      final caption = await _askCaption(context);
      if (!context.mounted) return;

      await ref.read(storyUploadControllerProvider.notifier).upload(
            ownerId: user.uid,
            media: media,
            caption: caption,
          );
    } on TimeCapsuleMediaException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<String?> _askCaption(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add caption'),
          content: TextField(
            controller: controller,
            maxLength: 120,
            decoration: const InputDecoration(
              hintText: 'Optional',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }
}

class _YourTimeCapsuleBubble extends StatelessWidget {
  const _YourTimeCapsuleBubble({
    required this.bucket,
    required this.viewerId,
    required this.showUploadRing,
    this.onAdd,
    this.onView,
  });

  final StoryOwnerBucket bucket;
  final String viewerId;
  final bool showUploadRing;
  final VoidCallback? onAdd;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    final hasStories = bucket.stories.isNotEmpty;
    final hasUnseen = bucket.hasUnseenFor(viewerId);
    final ringColor = !hasStories
        ? const Color(0xFF2563EB)
        : hasUnseen
            ? const Color(0xFF2563EB)
            : Colors.grey.shade400;

    return SizedBox(
      width: 74,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (showUploadRing)
                const SizedBox(
                  width: 68,
                  height: 68,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF2563EB),
                  ),
                )
              else
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 2),
                  ),
                ),
              GestureDetector(
                onTap: hasStories ? onView : onAdd,
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFF2F4F7),
                  backgroundImage: bucket.ownerPhotoUrl != null
                      ? NetworkImage(bucket.ownerPhotoUrl!)
                      : null,
                  child: bucket.ownerPhotoUrl == null
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
              ),
              if (!showUploadRing && onAdd != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            showUploadRing ? 'Uploading' : 'Your TC',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          if (!showUploadRing && hasStories)
            Text(
              formatStoryRelativeTime(bucket.latestCreatedAt),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }
}

class _FriendTimeCapsuleBubble extends StatelessWidget {
  const _FriendTimeCapsuleBubble({
    required this.bucket,
    required this.viewerId,
    required this.onTap,
  });

  final StoryOwnerBucket bucket;
  final String viewerId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnseen = bucket.hasUnseenFor(viewerId);
    final ringColor =
        hasUnseen ? const Color(0xFF2563EB) : Colors.grey.shade400;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 2),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFF2F4F7),
                backgroundImage: bucket.ownerPhotoUrl != null
                    ? NetworkImage(bucket.ownerPhotoUrl!)
                    : null,
                child: bucket.ownerPhotoUrl == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              bucket.ownerName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              formatStoryRelativeTime(bucket.latestCreatedAt),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
