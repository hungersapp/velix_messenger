import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/datasources/chat_remote_datasource_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/create_conversation_usecase.dart';
import '../../domain/usecases/get_conversation_by_id_usecase.dart';
import '../../domain/usecases/get_conversation_by_key_usecase.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/open_chat_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/update_conversation_usecase.dart';
import '../../domain/usecases/update_typing_status_usecase.dart';
import '../../domain/usecases/watch_conversation_by_id_usecase.dart';

/// Firestore
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// Remote Data Source
final chatRemoteDataSourceProvider =
    Provider<ChatRemoteDataSource>(
  (ref) => ChatRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
  ),
);

/// Repository
final chatRepositoryProvider =
    Provider<ChatRepository>(
  (ref) => ChatRepositoryImpl(
    remoteDataSource:
        ref.watch(chatRemoteDataSourceProvider),
  ),
);

final watchConversationByIdUseCaseProvider =
    Provider<WatchConversationByIdUseCase>(
  (ref) => WatchConversationByIdUseCase(
    repository: ref.watch(
      chatRepositoryProvider,
    ),
  ),
);

/// Create Conversation
final createConversationUseCaseProvider =
    Provider<CreateConversationUseCase>(
  (ref) => CreateConversationUseCase(
    repository: ref.watch(chatRepositoryProvider),
  ),
);

/// Get Conversation By Id
final getConversationByIdUseCaseProvider =
    Provider<GetConversationByIdUseCase>(
  (ref) => GetConversationByIdUseCase(
    repository: ref.watch(chatRepositoryProvider),
  ),
);

/// Get Conversation By Key
final getConversationByKeyUseCaseProvider =
    Provider<GetConversationByKeyUseCase>(
  (ref) => GetConversationByKeyUseCase(
    repository: ref.watch(chatRepositoryProvider),
  ),
);

/// Open Chat Workflow
final openChatUseCaseProvider =
    Provider<OpenChatUseCase>(
  (ref) => OpenChatUseCase(
    repository: ref.watch(chatRepositoryProvider),
  ),
);

/// Get Conversations
final getConversationsUseCaseProvider =
    Provider<GetConversationsUseCase>(
  (ref) => GetConversationsUseCase(
    repository: ref.watch(chatRepositoryProvider),
  ),
);

/// Get Messages
final getMessagesUseCaseProvider =
    Provider<GetMessagesUseCase>(
  (ref) => GetMessagesUseCase(
    repository: ref.watch(chatRepositoryProvider),
  ),
);

/// Send Message
final sendMessageUseCaseProvider =
    Provider<SendMessageUseCase>(
  (ref) => SendMessageUseCase(
    repository: ref.watch(chatRepositoryProvider),
  ),
);

/// Update Conversation
final updateConversationUseCaseProvider =
    Provider<UpdateConversationUseCase>(
  (ref) => UpdateConversationUseCase(
    repository: ref.watch(chatRepositoryProvider),
  ),
);

/// Update Typing Status
final updateTypingStatusUseCaseProvider =
    Provider<UpdateTypingStatusUseCase>(
  (ref) => UpdateTypingStatusUseCase(
    repository: ref.watch(chatRepositoryProvider),
  ),
);