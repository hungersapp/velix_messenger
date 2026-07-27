import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_dependency_provider.dart';
import '../../../contacts/presentation/providers/contacts_provider.dart';
import '../../../home/presentation/providers/peer_user_provider.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../../data/datasources/time_capsule_remote_datasource.dart';
import '../../data/datasources/time_capsule_remote_datasource_impl.dart';
import '../../data/datasources/time_capsule_storage_datasource.dart';
import '../../data/datasources/time_capsule_storage_datasource_impl.dart';
import '../../data/repositories/time_capsule_repository_impl.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/entities/story_owner_bucket.dart';
import '../../domain/repositories/time_capsule_repository.dart';
import '../../domain/usecases/create_story_usecase.dart';
import '../../domain/usecases/delete_story_usecase.dart';
import '../../domain/usecases/get_older_active_stories_usecase.dart';
import '../../domain/usecases/get_story_viewers_usecase.dart';
import '../../domain/usecases/mark_story_seen_usecase.dart';
import '../../domain/usecases/toggle_story_like_usecase.dart';
import '../../domain/usecases/watch_active_stories_usecase.dart';
import '../services/time_capsule_media_service.dart';
import '../services/time_capsule_share_service.dart';

/// Page size for live window + older Time Capsule fetches.
const int kTimeCapsulePageSize = 50;

final timeCapsuleRemoteDataSourceProvider =
    Provider<TimeCapsuleRemoteDataSource>(
  (ref) => TimeCapsuleRemoteDataSourceImpl(),
);

final timeCapsuleStorageDataSourceProvider =
    Provider<TimeCapsuleStorageDataSource>(
  (ref) => TimeCapsuleStorageDataSourceImpl(),
);

final timeCapsuleRepositoryProvider =
    Provider<TimeCapsuleRepository>(
  (ref) => TimeCapsuleRepositoryImpl(
    remoteDataSource: ref.watch(timeCapsuleRemoteDataSourceProvider),
    storageDataSource: ref.watch(timeCapsuleStorageDataSourceProvider),
  ),
);

final watchActiveStoriesUseCaseProvider =
    Provider<WatchActiveStoriesUseCase>(
  (ref) => WatchActiveStoriesUseCase(
    ref.watch(timeCapsuleRepositoryProvider),
  ),
);

final getOlderActiveStoriesUseCaseProvider =
    Provider<GetOlderActiveStoriesUseCase>(
  (ref) => GetOlderActiveStoriesUseCase(
    ref.watch(timeCapsuleRepositoryProvider),
  ),
);

final createStoryUseCaseProvider = Provider<CreateStoryUseCase>(
  (ref) => CreateStoryUseCase(
    ref.watch(timeCapsuleRepositoryProvider),
  ),
);

final markStorySeenUseCaseProvider = Provider<MarkStorySeenUseCase>(
  (ref) => MarkStorySeenUseCase(
    ref.watch(timeCapsuleRepositoryProvider),
  ),
);

final getStoryViewersUseCaseProvider = Provider<GetStoryViewersUseCase>(
  (ref) => GetStoryViewersUseCase(
    ref.watch(getUserUseCaseProvider),
  ),
);

final toggleStoryLikeUseCaseProvider = Provider<ToggleStoryLikeUseCase>(
  (ref) => ToggleStoryLikeUseCase(
    ref.watch(timeCapsuleRepositoryProvider),
  ),
);

final deleteStoryUseCaseProvider = Provider<DeleteStoryUseCase>(
  (ref) => DeleteStoryUseCase(
    ref.watch(timeCapsuleRepositoryProvider),
  ),
);

final timeCapsuleMediaServiceProvider =
    Provider<TimeCapsuleMediaService>(
  (ref) => TimeCapsuleMediaService(),
);

final timeCapsuleShareServiceProvider =
    Provider<TimeCapsuleShareService>(
  (ref) => TimeCapsuleShareService(),
);

/// Combined realtime latest page + paginated older active capsules.
class ActiveStoriesState {
  const ActiveStoriesState({
    this.stories = const [],
    this.isInitialLoading = true,
    this.isLoadingOlder = false,
    this.hasMore = true,
    this.error,
  });

  final List<StoryEntity> stories;
  final bool isInitialLoading;
  final bool isLoadingOlder;
  final bool hasMore;
  final Object? error;

  ActiveStoriesState copyWith({
    List<StoryEntity>? stories,
    bool? isInitialLoading,
    bool? isLoadingOlder,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return ActiveStoriesState(
      stories: stories ?? this.stories,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ActiveStoriesNotifier extends StateNotifier<ActiveStoriesState> {
  ActiveStoriesNotifier(this.ref) : super(const ActiveStoriesState()) {
    _subscribeLive();
  }

  final Ref ref;
  StreamSubscription<List<StoryEntity>>? _liveSub;
  List<StoryEntity> _live = const [];
  List<StoryEntity> _older = const [];
  bool _loadInFlight = false;
  final Completer<void> _ready = Completer<void>();

  Future<void> get ready => _ready.future;

  void _subscribeLive() {
    _liveSub?.cancel();
    _liveSub = ref.read(watchActiveStoriesUseCaseProvider)().listen(
      _applyLiveUpdate,
      onError: (Object e, StackTrace st) {
        if (!_ready.isCompleted) {
          _ready.complete();
        }
        if (state.stories.isEmpty) {
          state = state.copyWith(
            isInitialLoading: false,
            error: e,
          );
        }
      },
    );
  }

  void _applyLiveUpdate(List<StoryEntity> live) {
    final now = DateTime.now();
    final liveIds = live.map((s) => s.id).where((id) => id.isNotEmpty).toSet();

    final demoted = <StoryEntity>[];
    for (final prev in _live) {
      if (prev.id.isEmpty || liveIds.contains(prev.id)) continue;
      if (!prev.isActive(now)) continue;
      final alreadyOlder = _older.any((s) => s.id == prev.id);
      if (!alreadyOlder) {
        demoted.add(prev);
      }
    }

    _older = [
      ...demoted,
      ..._older.where(
        (s) => s.isActive(now) && !liveIds.contains(s.id),
      ),
    ];
    _live = live.where((s) => s.isActive(now)).toList();

    final hadFirstPage = !state.isInitialLoading;
    state = state.copyWith(
      stories: _mergeForDisplay(),
      isInitialLoading: false,
      clearError: true,
      hasMore: hadFirstPage
          ? state.hasMore
          : live.length >= kTimeCapsulePageSize,
    );

    if (!_ready.isCompleted) {
      _ready.complete();
    }
  }

  List<StoryEntity> _queryOrdered(Iterable<StoryEntity> stories) {
    final list = stories.toList()
      ..sort((a, b) {
        final byExp = b.expiresAt.compareTo(a.expiresAt);
        if (byExp != 0) return byExp;
        return a.id.compareTo(b.id);
      });
    return list;
  }

  List<StoryEntity> _mergeForDisplay() {
    final byId = <String, StoryEntity>{};
    for (final story in _older) {
      if (story.id.isEmpty) continue;
      byId[story.id] = story;
    }
    for (final story in _live) {
      if (story.id.isEmpty) continue;
      byId[story.id] = story;
    }

    final merged = byId.values.toList()
      ..sort((a, b) {
        final byCreated = b.createdAt.compareTo(a.createdAt);
        if (byCreated != 0) return byCreated;
        return a.id.compareTo(b.id);
      });
    return merged;
  }

  Future<void> loadOlder() async {
    if (_loadInFlight ||
        state.isLoadingOlder ||
        !state.hasMore ||
        state.isInitialLoading) {
      return;
    }

    final ordered = _queryOrdered([..._live, ..._older]);
    if (ordered.isEmpty) {
      state = state.copyWith(hasMore: false);
      return;
    }

    final cursorId = ordered.last.id;
    if (cursorId.isEmpty) {
      state = state.copyWith(hasMore: false);
      return;
    }

    _loadInFlight = true;
    state = state.copyWith(isLoadingOlder: true, clearError: true);

    try {
      final page = await ref.read(getOlderActiveStoriesUseCaseProvider)(
        beforeStoryId: cursorId,
        limit: kTimeCapsulePageSize,
      );

      final existingIds = <String>{
        ..._older.map((s) => s.id),
        ..._live.map((s) => s.id),
      };
      final now = DateTime.now();
      final fresh = page
          .where(
            (s) =>
                s.id.isNotEmpty &&
                !existingIds.contains(s.id) &&
                s.isActive(now),
          )
          .toList();

      if (fresh.isNotEmpty) {
        _older = [..._older, ...fresh];
      }

      state = state.copyWith(
        stories: _mergeForDisplay(),
        isLoadingOlder: false,
        hasMore: page.length >= kTimeCapsulePageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingOlder: false,
        error: e,
      );
    } finally {
      _loadInFlight = false;
    }
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    _liveSub = null;
    super.dispose();
  }
}

/// Keep briefly after leaving Home so returning does not re-query immediately.
final activeStoriesControllerProvider = StateNotifierProvider.autoDispose<
    ActiveStoriesNotifier, ActiveStoriesState>((ref) {
  final link = ref.keepAlive();
  Timer? disposeTimer;
  ref.onCancel(() {
    disposeTimer?.cancel();
    disposeTimer = Timer(const Duration(minutes: 2), link.close);
  });
  ref.onResume(() {
    disposeTimer?.cancel();
  });
  ref.onDispose(() {
    disposeTimer?.cancel();
  });
  return ActiveStoriesNotifier(ref);
});

/// Compatibility AsyncValue view (viewer likes + buckets).
final activeStoriesProvider =
    Provider.autoDispose<AsyncValue<List<StoryEntity>>>((ref) {
  final state = ref.watch(activeStoriesControllerProvider);

  if (state.isInitialLoading && state.stories.isEmpty) {
    return const AsyncValue.loading();
  }
  if (state.error != null && state.stories.isEmpty) {
    return AsyncValue.error(state.error!, StackTrace.current);
  }
  return AsyncValue.data(state.stories);
});

/// Friend UIDs via existing Contacts sync (Contacts files untouched).
final timeCapsuleFriendIdsProvider =
    FutureProvider<Set<String>>((ref) async {
  final contacts = await ref.watch(syncContactsUseCaseProvider)();
  return contacts
      .where((c) => c.isVelixUser && c.uid != null && c.uid!.isNotEmpty)
      .map((c) => c.uid!)
      .toSet();
});

/// Home rail + viewer buckets. Your TC first; friends newest / unseen first.
final storyBucketsProvider =
    FutureProvider.autoDispose<List<StoryOwnerBucket>>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    return const [];
  }

  await ref.watch(activeStoriesControllerProvider.notifier).ready;
  final stories = ref.watch(activeStoriesControllerProvider).stories;
  final friendIds = await ref.watch(timeCapsuleFriendIdsProvider.future);
  final now = DateTime.now();

  final visible = stories.where((story) {
    if (!story.isActive(now)) return false;
    if (story.visibility != 'friends') return false;
    if (story.ownerId == currentUser.uid) return true;
    return friendIds.contains(story.ownerId);
  }).toList();

  final byOwner = <String, List<StoryEntity>>{};
  for (final story in visible) {
    byOwner.putIfAbsent(story.ownerId, () => []).add(story);
  }

  for (final list in byOwner.values) {
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<StoryOwnerBucket> buildBucket(String ownerId) async {
    final ownerStories = byOwner[ownerId] ?? const <StoryEntity>[];
    if (ownerId == currentUser.uid) {
      return StoryOwnerBucket(
        ownerId: ownerId,
        ownerName: currentUser.name.isNotEmpty ? currentUser.name : 'You',
        ownerPhotoUrl: currentUser.photoUrl.trim().isEmpty
            ? null
            : currentUser.photoUrl,
        stories: ownerStories,
      );
    }

    final peer = await ref.watch(peerUserProvider(ownerId).future);
    return StoryOwnerBucket(
      ownerId: ownerId,
      ownerName: peer?.name.isNotEmpty == true ? peer!.name : 'Velix User',
      ownerPhotoUrl: (peer?.photoUrl.trim().isNotEmpty ?? false)
          ? peer!.photoUrl
          : null,
      stories: ownerStories,
    );
  }

  final buckets = <StoryOwnerBucket>[
    await buildBucket(currentUser.uid),
  ];

  final friendOwnerIds =
      byOwner.keys.where((id) => id != currentUser.uid).toList();

  final friendBuckets = await Future.wait(
    friendOwnerIds.map(buildBucket),
  );

  friendBuckets.sort((a, b) {
    final aUnseen = a.hasUnseenFor(currentUser.uid);
    final bUnseen = b.hasUnseenFor(currentUser.uid);
    if (aUnseen != bUnseen) {
      return aUnseen ? -1 : 1;
    }
    return b.latestCreatedAt.compareTo(a.latestCreatedAt);
  });

  buckets.addAll(friendBuckets);
  return buckets;
});

enum StoryUploadPhase {
  idle,
  preparing,
  uploading,
  success,
  error,
}

@immutable
class StoryUploadState {
  const StoryUploadState({
    required this.phase,
    this.message,
  });

  const StoryUploadState.idle()
      : phase = StoryUploadPhase.idle,
        message = null;

  const StoryUploadState.preparing()
      : phase = StoryUploadPhase.preparing,
        message = null;

  const StoryUploadState.uploading()
      : phase = StoryUploadPhase.uploading,
        message = null;

  const StoryUploadState.success()
      : phase = StoryUploadPhase.success,
        message = null;

  const StoryUploadState.error(this.message)
      : phase = StoryUploadPhase.error;

  final StoryUploadPhase phase;
  final String? message;

  bool get isInProgress =>
      phase == StoryUploadPhase.preparing ||
      phase == StoryUploadPhase.uploading;

  bool get showUploadRing => isInProgress;
}

final storyUploadControllerProvider =
    StateNotifierProvider<StoryUploadController, StoryUploadState>(
  (ref) => StoryUploadController(ref),
);

class StoryUploadController extends StateNotifier<StoryUploadState> {
  StoryUploadController(this._ref) : super(const StoryUploadState.idle());

  final Ref _ref;

  Future<void> upload({
    required String ownerId,
    required TimeCapsulePickedMedia media,
    String? caption,
  }) async {
    if (state.isInProgress) {
      return;
    }

    state = const StoryUploadState.preparing();

    try {
      state = const StoryUploadState.uploading();

      await _ref.read(createStoryUseCaseProvider)(
        ownerId: ownerId,
        mediaType: media.mediaType,
        localFilePath: media.file.path,
        thumbnailPath: media.thumbnailPath,
        caption: caption,
        durationMs: media.durationMs,
      );

      state = const StoryUploadState.success();
    } catch (e) {
      state = StoryUploadState.error(e.toString());
    }
  }

  void acknowledge() {
    if (state.phase == StoryUploadPhase.success ||
        state.phase == StoryUploadPhase.error) {
      state = const StoryUploadState.idle();
    }
  }
}
