import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../contacts/presentation/providers/contacts_provider.dart';
import '../../domain/usecases/connect_velix_user_usecase.dart';
import '../../domain/usecases/resolve_velix_qr_usecase.dart';

final resolveVelixQrUseCaseProvider =
    Provider<ResolveVelixQrUseCase>((ref) {
  return ResolveVelixQrUseCase(
    ref.watch(velixUserRemoteDatasourceProvider),
  );
});

final connectVelixUserUseCaseProvider =
    Provider<ConnectVelixUserUseCase>((ref) {
  return ConnectVelixUserUseCase(
    userDatasource: ref.watch(velixUserRemoteDatasourceProvider),
    addFriendUseCase: ref.watch(addFriendUseCaseProvider),
    openChatUseCase: ref.watch(openChatUseCaseProvider),
  );
});
