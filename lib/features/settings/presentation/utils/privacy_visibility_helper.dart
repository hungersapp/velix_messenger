import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../contacts/presentation/providers/contacts_provider.dart';
import '../../domain/entities/settings_models.dart';
import '../providers/settings_feature_providers.dart';

/// Resolves whether [viewerId] can see a privacy-gated field of [ownerId].
Future<bool> canViewerSeePrivacyField({
  required WidgetRef ref,
  required String ownerId,
  required String viewerId,
  required PrivacyVisibility visibility,
}) async {
  if (ownerId == viewerId) return true;
  switch (visibility) {
    case PrivacyVisibility.everyone:
      return true;
    case PrivacyVisibility.nobody:
      return false;
    case PrivacyVisibility.contacts:
      final blocked =
          await ref.read(settingsRepositoryProvider).isBlockedEitherWay(
                userA: ownerId,
                userB: viewerId,
              );
      if (blocked) return false;
      return ref.read(friendsRepositoryProvider).isFriend(ownerId);
  }
}
