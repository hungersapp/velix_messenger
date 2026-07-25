import '../../domain/entities/friend_entity.dart';

class FriendsState {
  const FriendsState({
    this.isLoading = false,
    this.friends = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  final bool isLoading;
  final List<FriendEntity> friends;
  final String searchQuery;
  final String? errorMessage;

  FriendsState copyWith({
    bool? isLoading,
    List<FriendEntity>? friends,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FriendsState(
      isLoading: isLoading ?? this.isLoading,
      friends: friends ?? this.friends,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
