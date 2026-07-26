import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/entities/call_history_entry.dart';
import 'call_controller.dart';

/// Live call history for the signed-in user.
final callHistoryProvider = StreamProvider<List<CallHistoryEntry>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) {
    return Stream<List<CallHistoryEntry>>.value(const []);
  }
  return ref.watch(callRepositoryProvider).watchCallHistory(user.uid);
});
