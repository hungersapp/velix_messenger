import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/entities/story_owner_bucket.dart';
import '../providers/time_capsule_provider.dart';
import '../utils/story_time_formatter.dart';
import '../widgets/story_viewers_sheet.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.buckets,
    required this.initialOwnerId,
  });

  final List<StoryOwnerBucket> buckets;
  final String initialOwnerId;

  @override
  ConsumerState<StoryViewerScreen> createState() =>
      _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _ownerPageController;
  late int _ownerIndex;
  int _storyIndex = 0;

  AnimationController? _progressController;
  VideoPlayerController? _videoController;

  bool _isPaused = false;
  bool _isHolding = false;
  final Set<String> _markedSeen = {};

  String? _likeStoryId;
  int _likeCount = 0;
  bool _likedByMe = false;
  bool _likeBusy = false;
  bool _deleteBusy = false;
  bool _shareBusy = false;

  late List<StoryOwnerBucket> _buckets;

  StoryOwnerBucket get _currentBucket => _buckets[_ownerIndex];

  StoryEntity get _currentStory => _currentBucket.stories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _buckets = List<StoryOwnerBucket>.from(widget.buckets);
    final initial = _buckets.indexWhere(
      (b) => b.ownerId == widget.initialOwnerId,
    );
    _ownerIndex = initial >= 0 ? initial : 0;
    _ownerPageController = PageController(initialPage: _ownerIndex);

    _progressController = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goNext();
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentStory();
    });
  }

  @override
  void dispose() {
    _progressController?.dispose();
    _videoController?.dispose();
    _ownerPageController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentStory() async {
    if (!mounted) return;

    _progressController?.stop();
    _progressController?.reset();
    await _videoController?.dispose();
    _videoController = null;

    final story = _currentStory;
    _syncLikesFrom(story);
    await _markSeen(story);

    if (story.isVideo) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(story.mediaUrl),
      );
      _videoController = controller;
      try {
        await controller.initialize();
        if (!mounted) return;
        setState(() {});
        final duration = controller.value.duration;
        final ms = duration.inMilliseconds > 0
            ? duration.inMilliseconds
            : story.durationMs;
        _startProgress(Duration(milliseconds: ms));
        if (!_isPaused && !_isHolding) {
          await controller.play();
        }
      } catch (_) {
        if (!mounted) return;
        _startProgress(Duration(milliseconds: story.durationMs));
      }
    } else {
      if (!mounted) return;
      setState(() {});
      _startProgress(Duration(milliseconds: story.durationMs));
    }
  }

  void _startProgress(Duration duration) {
    final controller = _progressController;
    if (controller == null) return;

    controller.duration = duration;
    controller.reset();
    if (!_isPaused && !_isHolding) {
      controller.forward();
    }
  }

  Future<void> _markSeen(StoryEntity story) async {
    final viewerId = ref.read(currentUserProvider).value?.uid;
    if (viewerId == null) return;
    if (story.ownerId == viewerId) return;
    if (story.isSeenBy(viewerId)) return;
    if (_markedSeen.contains(story.id)) return;

    _markedSeen.add(story.id);
    try {
      await ref.read(markStorySeenUseCaseProvider)(
        storyId: story.id,
        viewerId: viewerId,
      );
    } catch (_) {
      _markedSeen.remove(story.id);
    }
  }

  void _goNext() {
    if (_storyIndex < _currentBucket.stories.length - 1) {
      setState(() => _storyIndex += 1);
      _loadCurrentStory();
      return;
    }

    if (_ownerIndex < _buckets.length - 1) {
      _ownerPageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _goPrevious() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex -= 1);
      _loadCurrentStory();
      return;
    }

    if (_ownerIndex > 0) {
      _ownerPageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    _progressController?.reset();
    _loadCurrentStory();
  }

  void _onOwnerPageChanged(int index) {
    setState(() {
      _ownerIndex = index;
      _storyIndex = 0;
    });
    _loadCurrentStory();
  }

  void _onHoldStart() {
    _isHolding = true;
    _isPaused = true;
    _progressController?.stop();
    _videoController?.pause();
  }

  void _onHoldEnd() {
    _isHolding = false;
    _isPaused = false;
    _progressController?.forward();
    _videoController?.play();
  }

  void _syncLikesFrom(StoryEntity story) {
    final uid = ref.read(currentUserProvider).value?.uid;
    _likeStoryId = story.id;
    _likeCount = story.likeCount;
    _likedByMe = uid != null && story.isLikedBy(uid);
  }

  Future<void> _toggleLike() async {
    final uid = ref.read(currentUserProvider).value?.uid;
    if (uid == null || _likeBusy) {
      return;
    }

    final storyId = _currentStory.id;
    final wasLiked = _likedByMe;
    final previousCount = _likeCount;

    setState(() {
      _likeBusy = true;
      _likedByMe = !wasLiked;
      _likeCount = wasLiked
          ? (previousCount > 0 ? previousCount - 1 : 0)
          : previousCount + 1;
    });

    try {
      final liked = await ref.read(toggleStoryLikeUseCaseProvider)(
        storyId: storyId,
        userId: uid,
      );
      if (!mounted || _likeStoryId != storyId) {
        return;
      }
      setState(() {
        _likedByMe = liked;
      });
    } catch (_) {
      if (!mounted || _likeStoryId != storyId) {
        return;
      }
      setState(() {
        _likedByMe = wasLiked;
        _likeCount = previousCount;
      });
    } finally {
      if (mounted) {
        setState(() {
          _likeBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_buckets.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No stories',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    ref.listen<AsyncValue<List<StoryEntity>>>(activeStoriesProvider, (
      previous,
      next,
    ) {
      if (_likeBusy) {
        return;
      }
      next.whenData((stories) {
        StoryEntity? updated;
        for (final story in stories) {
          if (story.id == _currentStory.id) {
            updated = story;
            break;
          }
        }
        if (updated == null || !mounted) {
          return;
        }
        final uid = ref.read(currentUserProvider).value?.uid ?? '';
        if (updated.likeCount == _likeCount &&
            updated.isLikedBy(uid) == _likedByMe) {
          return;
        }
        setState(() => _syncLikesFrom(updated!));
      });
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _ownerPageController,
        itemCount: _buckets.length,
        onPageChanged: _onOwnerPageChanged,
        itemBuilder: (context, ownerIndex) {
          final bucket = _buckets[ownerIndex];
          final isCurrentOwner = ownerIndex == _ownerIndex;
          final story = isCurrentOwner
              ? bucket.stories[_storyIndex.clamp(0, bucket.stories.length - 1)]
              : bucket.stories.first;

          return Stack(
            fit: StackFit.expand,
            children: [
              if (isCurrentOwner &&
                  story.isVideo &&
                  _videoController != null &&
                  _videoController!.value.isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                )
              else
                CachedNetworkImage(
                  imageUrl: story.isVideo
                      ? (story.thumbnailUrl ?? story.mediaUrl)
                      : story.mediaUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white),
                  ),
                ),

              // Tap zones + hold
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _goPrevious,
                      onLongPressStart: (_) => _onHoldStart(),
                      onLongPressEnd: (_) => _onHoldEnd(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _goNext,
                      onLongPressStart: (_) => _onHoldStart(),
                      onLongPressEnd: (_) => _onHoldEnd(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),

              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Row(
                        children: List.generate(bucket.stories.length, (i) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: _StoryProgressBar(
                                animation: isCurrentOwner &&
                                        i == _storyIndex
                                    ? _progressController
                                    : null,
                                filled: isCurrentOwner
                                    ? i < _storyIndex
                                    : false,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white24,
                            backgroundImage: bucket.ownerPhotoUrl != null
                                ? NetworkImage(bucket.ownerPhotoUrl!)
                                : null,
                            child: bucket.ownerPhotoUrl == null
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bucket.ownerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatStoryRelativeTime(story.createdAt),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _shareBusy
                                ? null
                                : () => _shareStory(story),
                            icon: const Icon(
                              Icons.ios_share,
                              color: Colors.white,
                            ),
                          ),
                          if (_isOwnerOf(story))
                            IconButton(
                              onPressed: _deleteBusy
                                  ? null
                                  : () => _confirmDeleteStory(story),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        story.caption != null &&
                                story.caption!.trim().isNotEmpty
                            ? 12
                            : 24,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _toggleLike,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _likedByMe
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _likedByMe
                                      ? const Color(0xFFE11D48)
                                      : Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_likeCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isOwnerOf(story)) ...[
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () => _openViewersSheet(story),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${story.seenCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (story.caption != null &&
                        story.caption!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Text(
                          story.caption!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isOwnerOf(StoryEntity story) {
    final uid = ref.read(currentUserProvider).value?.uid;
    if (uid == null) {
      return false;
    }
    return story.ownerId == uid;
  }

  Future<void> _shareStory(StoryEntity story) async {
    if (_shareBusy) {
      return;
    }

    setState(() => _shareBusy = true);
    _onHoldStart();

    try {
      await ref.read(timeCapsuleShareServiceProvider).shareStory(story);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to share this Time Capsule.'),
        ),
      );
    } finally {
      if (mounted) {
        _onHoldEnd();
        setState(() => _shareBusy = false);
      }
    }
  }

  Future<void> _openViewersSheet(StoryEntity story) async {
    if (!_isOwnerOf(story)) {
      return;
    }

    _onHoldStart();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return StoryViewersSheet(story: story);
        },
      );
    } finally {
      if (mounted) {
        _onHoldEnd();
      }
    }
  }

  Future<void> _confirmDeleteStory(StoryEntity story) async {
    if (!_isOwnerOf(story) || _deleteBusy) {
      return;
    }

    _onHoldStart();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Time Capsule?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE11D48),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (confirmed != true) {
      _onHoldEnd();
      return;
    }

    await _deleteStory(story);
  }

  Future<void> _deleteStory(StoryEntity story) async {
    final uid = ref.read(currentUserProvider).value?.uid;
    if (uid == null) {
      _onHoldEnd();
      return;
    }

    setState(() => _deleteBusy = true);

    try {
      await ref.read(deleteStoryUseCaseProvider)(
        story: story,
        requesterId: uid,
      );
      if (!mounted) {
        return;
      }
      _isHolding = false;
      _isPaused = false;
      _removeStoryLocally(story.id);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete story. Please try again.'),
        ),
      );
      _onHoldEnd();
    } finally {
      if (mounted) {
        setState(() => _deleteBusy = false);
      }
    }
  }

  void _removeStoryLocally(String storyId) {
    if (_buckets.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final bucket = _buckets[_ownerIndex];
    final remainingStories = bucket.stories
        .where((story) => story.id != storyId)
        .toList(growable: false);

    if (remainingStories.isEmpty) {
      final updatedBuckets = List<StoryOwnerBucket>.from(_buckets)
        ..removeAt(_ownerIndex);

      if (updatedBuckets.isEmpty) {
        Navigator.of(context).pop();
        return;
      }

      var nextOwnerIndex = _ownerIndex;
      if (nextOwnerIndex >= updatedBuckets.length) {
        nextOwnerIndex = updatedBuckets.length - 1;
      }

      setState(() {
        _buckets = updatedBuckets;
        _ownerIndex = nextOwnerIndex;
        _storyIndex = 0;
      });

      if (_ownerPageController.hasClients) {
        _ownerPageController.jumpToPage(_ownerIndex);
      }
      _loadCurrentStory();
      return;
    }

    var nextStoryIndex = _storyIndex;
    if (nextStoryIndex >= remainingStories.length) {
      nextStoryIndex = remainingStories.length - 1;
    }

    final updatedBucket = StoryOwnerBucket(
      ownerId: bucket.ownerId,
      ownerName: bucket.ownerName,
      ownerPhotoUrl: bucket.ownerPhotoUrl,
      stories: remainingStories,
    );

    final updatedBuckets = List<StoryOwnerBucket>.from(_buckets);
    updatedBuckets[_ownerIndex] = updatedBucket;

    setState(() {
      _buckets = updatedBuckets;
      _storyIndex = nextStoryIndex;
    });
    _loadCurrentStory();
  }
}

class _StoryProgressBar extends StatelessWidget {
  const _StoryProgressBar({
    required this.animation,
    required this.filled,
  });

  final AnimationController? animation;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 2.5,
        child: animation != null
            ? AnimatedBuilder(
                animation: animation!,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: animation!.value,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  );
                },
              )
            : LinearProgressIndicator(
                value: filled ? 1 : 0,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
              ),
      ),
    );
  }
}
