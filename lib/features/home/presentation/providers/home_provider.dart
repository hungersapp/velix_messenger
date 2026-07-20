import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home Screen State
class HomeState {
  const HomeState({
    this.isLoading = false,
    this.hasChats = true,
    this.searchQuery = '',
  });

  final bool isLoading;
  final bool hasChats;
  final String searchQuery;

  HomeState copyWith({
    bool? isLoading,
    bool? hasChats,
    String? searchQuery,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      hasChats: hasChats ?? this.hasChats,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Home Notifier
class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState());

  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setHasChats(bool value) {
    state = state.copyWith(hasChats: value);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}

/// Provider
final homeProvider =
    StateNotifierProvider<HomeNotifier, HomeState>(
  (ref) => HomeNotifier(),
);