import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home Screen State
class HomeState {
  const HomeState({
    this.isLoading = false,
    this.hasChats = true,
    this.searchQuery = '',
    this.isSearchActive = false,
  });

  final bool isLoading;
  final bool hasChats;
  final String searchQuery;
  final bool isSearchActive;

  HomeState copyWith({
    bool? isLoading,
    bool? hasChats,
    String? searchQuery,
    bool? isSearchActive,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      hasChats: hasChats ?? this.hasChats,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearchActive: isSearchActive ?? this.isSearchActive,
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

  void openSearch() {
    state = state.copyWith(isSearchActive: true);
  }

  void closeSearch() {
    state = state.copyWith(
      isSearchActive: false,
      searchQuery: '',
    );
  }

  void toggleSearch() {
    if (state.isSearchActive) {
      closeSearch();
    } else {
      openSearch();
    }
  }
}

/// Provider
final homeProvider =
    StateNotifierProvider<HomeNotifier, HomeState>(
  (ref) => HomeNotifier(),
);
