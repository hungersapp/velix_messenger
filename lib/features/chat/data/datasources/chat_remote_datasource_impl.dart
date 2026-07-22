import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'chat_remote_datasource.dart';

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;

  ChatRemoteDataSourceImpl({
    required this.firestore,
  });

  CollectionReference<Map<String, dynamic>> get _conversationCollection =>
      firestore.collection('conversations');

  @override
  Future<String> createConversation(
    ConversationModel conversation,
  ) async {
    final docRef = await _conversationCollection.add(
      conversation.toMap(),
    );

    return docRef.id;
  }

  @override
Future<ConversationModel?> getConversationById(
  String conversationId,
) async {
  final doc = await _conversationCollection
      .doc(conversationId)
      .get();

  if (!doc.exists) {
    return null;
  }

  return ConversationModel.fromMap(
    doc.data()!,
    doc.id,
  );
}

@override
Future<ConversationModel?> getConversationByKey(
  String conversationKey,
) async {
  final snapshot = await _conversationCollection
      .where(
        'conversationKey',
        isEqualTo: conversationKey,
      )
      .limit(1)
      .get();

  if (snapshot.docs.isEmpty) {
    return null;
  }

  final doc = snapshot.docs.first;

  return ConversationModel.fromMap(
    doc.data(),
    doc.id,
  );
}

@override
Stream<ConversationModel?> watchConversationById(
  String conversationId,
) {
  return _conversationCollection
      .doc(conversationId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) {
      return null;
    }

    return ConversationModel.fromMap(
      doc.data()!,
      doc.id,
    );
  });
}

  @override
  Stream<List<ConversationModel>> getConversations(
    String userId,
  ) {
    return _conversationCollection
        .where(
          'participants',
          arrayContains: userId,
        )
        .orderBy(
          'lastMessageAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ConversationModel.fromMap(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  @override
   Future<void> sendMessage(
    MessageModel message,
  ) async {
   final messageRef = _conversationCollection
      .doc(message.conversationId)
      .collection('messages')
      .doc();

    final newMessage = message.copyWith(
    id: messageRef.id,
  );

    await messageRef.set(
    newMessage.toMap(),
  );
}

  @override
  Stream<List<MessageModel>> getMessages(
    String conversationId,
  ) {
    return _conversationCollection
        .doc(conversationId)
        .collection('messages')
        .orderBy(
          'sentAt',
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => MessageModel.fromMap(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

    @override
  Future<void> updateConversation({
    required String conversationId,
    required String lastMessage,
    required String lastMessageSenderId,
    required String lastMessageType,
  }) async {
    await _conversationCollection
        .doc(conversationId)
        .update({
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageType': lastMessageType,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }
  
  @override
  Future<void> updateTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    await _conversationCollection
        .doc(conversationId)
        .update({
      'typingStatus.$userId': isTyping,
    });
  }
  @override
Future<void> updateMessageStatus({
  required String conversationId,
  required String messageId,
  required String status,
}) async {
  await _conversationCollection
      .doc(conversationId)
      .collection('messages')
      .doc(messageId)
      .update({
    'status': status,
  });
}

@override
Future<void> markMessageAsDelivered({
  required String conversationId,
  required String messageId,
}) async {
  await _conversationCollection
      .doc(conversationId)
      .collection('messages')
      .doc(messageId)
      .update({
    'status': 'delivered',
    'deliveredAt': FieldValue.serverTimestamp(),
  });
}

@override
Future<void> markMessageAsRead({
  required String conversationId,
  required String messageId,
}) async {
  await _conversationCollection
      .doc(conversationId)
      .collection('messages')
      .doc(messageId)
      .update({
    'status': 'read',
    'readAt': FieldValue.serverTimestamp(),
  });
}
}