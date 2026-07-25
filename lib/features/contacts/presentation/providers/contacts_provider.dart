import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/presentation/providers/chat_provider.dart';
import '../../data/datasources/friend_requests_remote_datasource.dart';
import '../../data/datasources/friends_remote_datasource.dart';
import '../../data/datasources/user_discovery_remote_datasource.dart';
import '../../data/repositories/friends_repository_impl.dart';
import '../../domain/repositories/friends_repository.dart';
import '../../domain/usecases/accept_friend_request_usecase.dart';
import '../../domain/usecases/add_friend_usecase.dart';
import '../../domain/usecases/decline_friend_request_usecase.dart';
import '../../domain/usecases/get_friends_usecase.dart';
import '../../domain/usecases/get_incoming_friend_requests_usecase.dart';
import '../../domain/usecases/search_friends_usecase.dart';
import '../../domain/usecases/search_velix_users_usecase.dart';
import '../../domain/usecases/send_friend_request_usecase.dart';
import '../../domain/usecases/sync_contacts_usecase.dart';
import '../../domain/usecases/watch_incoming_friend_requests_usecase.dart';
import 'friends_state.dart';

/// ---------------------------------------------------------------------------
/// Data Sources
/// ---------------------------------------------------------------------------

final friendsRemoteDataSourceProvider =
    Provider<FriendsRemoteDataSource>(
  (ref) => FriendsRemoteDataSourceImpl(),
);

final friendRequestsRemoteDataSourceProvider =
    Provider<FriendRequestsRemoteDataSource>(
  (ref) => FriendRequestsRemoteDataSourceImpl(),
);

final userDiscoveryRemoteDataSourceProvider =
    Provider<UserDiscoveryRemoteDataSource>(
  (ref) => UserDiscoveryRemoteDataSourceImpl(),
);

/// ---------------------------------------------------------------------------
/// Repository
/// ---------------------------------------------------------------------------

final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => FriendsRepositoryImpl(
    remoteDataSource: ref.watch(friendsRemoteDataSourceProvider),
    requestsRemoteDataSource:
        ref.watch(friendRequestsRemoteDataSourceProvider),
    discoveryRemoteDataSource:
        ref.watch(userDiscoveryRemoteDataSourceProvider),
  ),
);

/// ---------------------------------------------------------------------------
/// UseCases
/// ---------------------------------------------------------------------------

final getFriendsUseCaseProvider = Provider<GetFriendsUseCase>(
  (ref) => GetFriendsUseCase(ref.watch(friendsRepositoryProvider)),
);

final searchFriendsUseCaseProvider = Provider<SearchFriendsUseCase>(
  (ref) => SearchFriendsUseCase(ref.watch(friendsRepositoryProvider)),
);

final addFriendUseCaseProvider = Provider<AddFriendUseCase>(
  (ref) => AddFriendUseCase(ref.watch(friendsRepositoryProvider)),
);

final searchVelixUsersUseCaseProvider = Provider<SearchVelixUsersUseCase>(
  (ref) => SearchVelixUsersUseCase(ref.watch(friendsRepositoryProvider)),
);

final sendFriendRequestUseCaseProvider = Provider<SendFriendRequestUseCase>(
  (ref) => SendFriendRequestUseCase(ref.watch(friendsRepositoryProvider)),
);

final getIncomingFriendRequestsUseCaseProvider =
    Provider<GetIncomingFriendRequestsUseCase>(
  (ref) => GetIncomingFriendRequestsUseCase(
    ref.watch(friendsRepositoryProvider),
  ),
);

final watchIncomingFriendRequestsUseCaseProvider =
    Provider<WatchIncomingFriendRequestsUseCase>(
  (ref) => WatchIncomingFriendRequestsUseCase(
    ref.watch(friendsRepositoryProvider),
  ),
);

final acceptFriendRequestUseCaseProvider =
    Provider<AcceptFriendRequestUseCase>(
  (ref) => AcceptFriendRequestUseCase(
    repository: ref.watch(friendsRepositoryProvider),
    addFriendUseCase: ref.watch(addFriendUseCaseProvider),
    openChatUseCase: ref.watch(openChatUseCaseProvider),
  ),
);

final declineFriendRequestUseCaseProvider =
    Provider<DeclineFriendRequestUseCase>(
  (ref) => DeclineFriendRequestUseCase(ref.watch(friendsRepositoryProvider)),
);

/// Kept for Time Capsule (`timeCapsuleFriendIdsProvider`) without changing it.
final syncContactsUseCaseProvider = Provider<SyncContactsUseCase>(
  (ref) => SyncContactsUseCase(ref.watch(friendsRepositoryProvider)),
);

/// ---------------------------------------------------------------------------
/// StateNotifier
/// ---------------------------------------------------------------------------

class FriendsNotifier extends StateNotifier<FriendsState> {
  FriendsNotifier({
    required this.getFriendsUseCase,
    required this.searchFriendsUseCase,
  }) : super(const FriendsState());

  final GetFriendsUseCase getFriendsUseCase;
  final SearchFriendsUseCase searchFriendsUseCase;

  Future<void> loadFriends() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final friends = state.searchQuery.trim().isEmpty
          ? await getFriendsUseCase()
          : await searchFriendsUseCase(state.searchQuery);

      state = state.copyWith(
        isLoading: false,
        friends: friends,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() => loadFriends();

  Future<void> search(String query) async {
    state = state.copyWith(
      searchQuery: query,
      isLoading: true,
      clearError: true,
    );

    try {
      final friends = await searchFriendsUseCase(query);
      state = state.copyWith(
        isLoading: false,
        friends: friends,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>(
  (ref) => FriendsNotifier(
    getFriendsUseCase: ref.watch(getFriendsUseCaseProvider),
    searchFriendsUseCase: ref.watch(searchFriendsUseCaseProvider),
  ),
);

/// Alias used by QR Connect refresh — same friends list provider.
final contactsProvider = friendsProvider;
