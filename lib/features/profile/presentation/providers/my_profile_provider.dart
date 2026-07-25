import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/entities/profile_identity.dart';
import '../../domain/services/velix_qr_payload.dart';

/// Maps the authenticated [UserEntity] into profile presentation identity.
/// Does not invent placeholder users.
final myProfileProvider = Provider<AsyncValue<ProfileIdentity?>>((ref) {
  return ref.watch(currentUserProvider).whenData((user) {
    if (user == null) return null;

    final handle = VelixQrPayload.displayHandle(user.velixId);
    final velixId = handle.startsWith('@') ? handle.substring(1) : handle;

    return ProfileIdentity(
      displayName: user.name,
      velixId: velixId,
      photoUrl: user.photoUrl.trim().isEmpty ? null : user.photoUrl,
    );
  });
});
