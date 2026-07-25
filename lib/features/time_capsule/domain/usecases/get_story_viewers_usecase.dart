import '../../../auth/domain/usecases/get_user_usecase.dart';
import '../entities/story_viewer_entry.dart';

class GetStoryViewersUseCase {
  const GetStoryViewersUseCase(this._getUser);

  final GetUserUseCase _getUser;

  /// Loads viewer profiles on demand from existing [viewers] / [seenBy] data.
  Future<List<StoryViewerEntry>> call({
    required Map<String, DateTime> viewers,
    required List<String> seenBy,
  }) async {
    final viewerIds = <String>{...viewers.keys, ...seenBy};
    if (viewerIds.isEmpty) {
      return const [];
    }

    final entries = await Future.wait(
      viewerIds.map((userId) async {
        final user = await _getUser(userId);
        final photo = user?.photoUrl.trim();
        return StoryViewerEntry(
          userId: userId,
          name: (user?.name.trim().isNotEmpty ?? false)
              ? user!.name.trim()
              : 'Velix User',
          photoUrl: (photo != null && photo.isNotEmpty) ? photo : null,
          viewedAt: viewers[userId],
        );
      }),
    );

    entries.sort((a, b) {
      final aTime = a.viewedAt;
      final bTime = b.viewedAt;
      if (aTime == null && bTime == null) {
        return a.name.compareTo(b.name);
      }
      if (aTime == null) {
        return 1;
      }
      if (bTime == null) {
        return -1;
      }
      return bTime.compareTo(aTime);
    });

    return entries;
  }
}
