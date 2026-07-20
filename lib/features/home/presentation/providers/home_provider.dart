import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home State
class HomeNotifier extends StateNotifier<int> {
  HomeNotifier() : super(0);

  /// Current Bottom Navigation Index
  int get currentIndex => state;

  /// Change Bottom Navigation
  void changeIndex(int index) {
    if (state == index) return;

    state = index;
  }
}

/// Provider
final homeProvider =
    StateNotifierProvider<HomeNotifier, int>(
  (ref) => HomeNotifier(),
);