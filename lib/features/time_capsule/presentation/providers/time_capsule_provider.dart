import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_dependency_provider.dart';
import '../../../contacts/presentation/providers/contacts_provider.dart';
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
import '../../domain/usecases/mark_story_seen_usecase.dart';
import '../../domain/usecases/watch_active_stories_usecase.dart';
import '../services/time_capsule_media_service.dart';

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

final timeCapsuleMediaServiceProvider =
    Provider<TimeCapsuleMediaService>(
  (ref) => TimeCapsuleMediaService(),
);

/// Active stories from Firestore (expiresAt > now).
final activeStoriesProvider = StreamProvider<List<StoryEntity>>((ref) {
  return ref.watch(watchActiveStoriesUseCaseProvider)();
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
    FutureProvider<List<StoryOwnerBucket>>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    return const [];
  }

  final stories = await ref.watch(activeStoriesProvider.future);
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

  final getUser = ref.read(getUserUseCaseProvider);

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

    final peer = await getUser(ownerId);
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

  final friendOwnerIds = byOwner.keys
      .where((id) => id != currentUser.uid)
      .toList();

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

final storyUploadControllerProvider =
    StateNotifierProvider<StoryUploadController, AsyncValue<void>>(
  (ref) => StoryUploadController(ref),
);

class StoryUploadController extends StateNotifier<AsyncValue<void>> {
  StoryUploadController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> upload({
    required String ownerId,
    required TimeCapsulePickedMedia media,
    String? caption,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _ref.read(createStoryUseCaseProvider)(
        ownerId: ownerId,
        mediaType: media.mediaType,
        localFilePath: media.file.path,
        thumbnailPath: media.thumbnailPath,
        caption: caption,
        durationMs: media.durationMs,
      );
    });
  }
}
