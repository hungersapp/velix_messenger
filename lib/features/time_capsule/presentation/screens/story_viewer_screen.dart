import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/entities/story_owner_bucket.dart';
import '../providers/time_capsule_provider.dart';

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

  List<StoryOwnerBucket> get _buckets => widget.buckets;

  StoryOwnerBucket get _currentBucket => _buckets[_ownerIndex];

  StoryEntity get _currentStory => _currentBucket.stories[_storyIndex];

  @override
  void initState() {
    super.initState();
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
                            child: Text(
                              bucket.ownerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
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
