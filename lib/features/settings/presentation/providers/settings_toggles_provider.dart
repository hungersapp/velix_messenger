import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local UI toggles only — no backend sync yet.
final messageNotificationsEnabledProvider =
    StateProvider<bool>((ref) => true);

final callNotificationsEnabledProvider =
    StateProvider<bool>((ref) => true);

final readReceiptsEnabledProvider = StateProvider<bool>((ref) => true);
