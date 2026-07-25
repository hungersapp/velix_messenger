import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/story_entity.dart';
import '../../domain/entities/story_viewer_entry.dart';
import '../providers/time_capsule_provider.dart';
import '../utils/story_time_formatter.dart';

class StoryViewersSheet extends ConsumerStatefulWidget {
  const StoryViewersSheet({
    super.key,
    required this.story,
  });

  final StoryEntity story;

  @override
  ConsumerState<StoryViewersSheet> createState() =>
      _StoryViewersSheetState();
}

class _StoryViewersSheetState extends ConsumerState<StoryViewersSheet> {
  late final Future<List<StoryViewerEntry>> _viewersFuture;

  @override
  void initState() {
    super.initState();
    _viewersFuture = ref.read(getStoryViewersUseCaseProvider)(
      viewers: widget.story.viewers,
      seenBy: widget.story.seenBy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.5;

    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Viewers · ${widget.story.seenCount}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<StoryViewerEntry>>(
                  future: _viewersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    final viewers =
                        snapshot.data ?? const <StoryViewerEntry>[];
                    if (viewers.isEmpty) {
                      return const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.remove_red_eye_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'No views yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: viewers.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final viewer = viewers[index];
                        final timeLabel = viewer.viewedAt != null
                            ? formatStoryRelativeTime(viewer.viewedAt!)
                            : 'Seen';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFF2F4F7),
                            backgroundImage: viewer.photoUrl != null
                                ? NetworkImage(viewer.photoUrl!)
                                : null,
                            child: viewer.photoUrl == null
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          title: Text(
                            viewer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
