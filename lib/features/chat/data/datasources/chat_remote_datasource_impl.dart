import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/firebase/firebase_error_guard.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'chat_remote_datasource.dart';

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth _firebaseAuth;

  ChatRemoteDataSourceImpl({
    required this.firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _conversationCollection =>
      firestore.collection('conversations');

  @override
  Future<String> createConversation(
    ConversationModel conversation,
  ) {
    return guardFirebase(() async {
      final docRef = await _conversationCollection.add(
        conversation.toMap(),
      );

      return docRef.id;
    });
  }

  @override
  Future<ConversationModel?> getConversationById(
    String conversationId,
  ) {
    return guardFirebase(() async {
      final doc = await _conversationCollection.doc(conversationId).get();

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
  Future<ConversationModel?> getConversationByKey(
    String conversationKey,
  ) {
    return guardFirebase(() async {
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid == null || uid.isEmpty) return null;

      // Must constrain by participants so the query satisfies security rules.
      final snapshot = await _conversationCollection
          .where('participants', arrayContains: uid)
          .where('conversationKey', isEqualTo: conversationKey)
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
    });
  }

  @override
  Stream<ConversationModel?> watchConversationById(
    String conversationId,
  ) {
    return guardFirebaseStream(
      _conversationCollection.doc(conversationId).snapshots().map((doc) {
        if (!doc.exists) {
          return null;
        }

        return ConversationModel.fromMap(
          doc.data()!,
          doc.id,
        );
      }),
    );
  }

  @override
  Stream<List<ConversationModel>> getConversations(
    String userId,
  ) {
    return guardFirebaseStream(
      _conversationCollection
          .where(
            'participants',
            arrayContains: userId,
          )
          .orderBy(
            'lastMessageAt',
            descending: true,
          )
          .limit(30)
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
          ),
    );
  }

  @override
  Future<List<ConversationModel>> getOlderConversations({
    required String userId,
    required String beforeConversationId,
    int limit = 30,
  }) {
    return guardFirebase(() async {
      if (userId.isEmpty || beforeConversationId.isEmpty || limit <= 0) {
        return const [];
      }

      final cursor =
          await _conversationCollection.doc(beforeConversationId).get();
      if (!cursor.exists) {
        return const [];
      }

      final snapshot = await _conversationCollection
          .where(
            'participants',
            arrayContains: userId,
          )
          .orderBy(
            'lastMessageAt',
            descending: true,
          )
          .startAfterDocument(cursor)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => ConversationModel.fromMap(
              doc.data(),
              doc.id,
            ),
          )
          .toList();
    });
  }

  @override
  Future<void> sendMessage(
    MessageModel message,
  ) {
    return guardFirebase(() async {
      final mediaUrl = message.mediaUrl?.trim() ?? '';
      final isMedia = message.messageType != 'text';

      debugPrint(
        '[FirestoreWrite] sendMessage start '
        'conversationId=${message.conversationId} '
        'type=${message.messageType} senderId=${message.senderId} '
        'mediaUrl=${mediaUrl.isEmpty ? '(none)' : mediaUrl}',
      );

      if (isMedia && mediaUrl.isEmpty) {
        throw Exception(
          'Refusing Firestore write: media message missing download URL '
          '(type=${message.messageType}, conversationId=${message.conversationId}).',
        );
      }

      final messageRef = _conversationCollection
          .doc(message.conversationId)
          .collection('messages')
          .doc();

      final newMessage = message.copyWith(
        id: messageRef.id,
      );

      try {
        await messageRef.set(
          newMessage.toMap(),
        );
        debugPrint(
          '[FirestoreWrite] sendMessage success id=${messageRef.id} '
          'type=${message.messageType}',
        );
      } catch (e, st) {
        debugPrint(
          '[FirestoreWrite] sendMessage failed '
          'conversationId=${message.conversationId} '
          'type=${message.messageType} error=$e\n$st',
        );
        rethrow;
      }
    }, context: 'FirestoreWrite.sendMessage');
  }

  @override
  Stream<List<MessageModel>> getMessages(
    String conversationId,
  ) {
    // Latest page first — reverse to chronological ascending for MessageList.
    return guardFirebaseStream(
      _messagesCollection(conversationId)
          .orderBy('sentAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
        final messages = snapshot.docs
            .map(
              (doc) => MessageModel.fromMap(
                doc.data(),
                doc.id,
              ),
            )
            .toList();
        return messages.reversed.toList();
      }),
    );
  }

  @override
  Future<List<MessageModel>> getOlderMessages({
    required String conversationId,
    required String beforeMessageId,
    int limit = 50,
  }) {
    return guardFirebase(() async {
      if (beforeMessageId.isEmpty || limit <= 0) {
        return const [];
      }

      final collection = _messagesCollection(conversationId);
      final cursor = await collection.doc(beforeMessageId).get();
      if (!cursor.exists) {
        return const [];
      }

      final snapshot = await collection
          .orderBy('sentAt', descending: true)
          .startAfterDocument(cursor)
          .limit(limit)
          .get();

      final messages = snapshot.docs
          .map(
            (doc) => MessageModel.fromMap(
              doc.data(),
              doc.id,
            ),
          )
          .toList();

      // Chronological ascending (oldest → newest within the page).
      return messages.reversed.toList();
    });
  }

  CollectionReference<Map<String, dynamic>> _messagesCollection(
    String conversationId,
  ) {
    return _conversationCollection.doc(conversationId).collection('messages');
  }

  @override
  Future<void> updateConversation({
    required String conversationId,
    required String lastMessage,
    required String lastMessageSenderId,
    required String lastMessageType,
  }) {
    return guardFirebase(() async {
      final docRef = _conversationCollection.doc(conversationId);

      // One read for participants, then a single summary write:
      // last message fields + FieldValue.increment for every other participant.
      // Never scans the messages subcollection for unread badges.
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final participants = List<String>.from(
        snapshot.data()?['participants'] ?? const <String>[],
      );

      final updates = <String, dynamic>{
        'lastMessage': lastMessage,
        'lastMessageSenderId': lastMessageSenderId,
        'lastMessageType': lastMessageType,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
      };

      for (final participantId in participants) {
        if (participantId.isEmpty || participantId == lastMessageSenderId) {
          continue;
        }
        updates['unreadCount.$participantId'] = FieldValue.increment(1);
      }

      await docRef.update(updates);
    });
  }

  @override
  Future<void> clearConversationUnread({
    required String conversationId,
    required String userId,
  }) {
    return guardFirebase(() async {
      if (conversationId.isEmpty || userId.isEmpty) return;

      await _conversationCollection.doc(conversationId).update({
        'unreadCount.$userId': 0,
        'lastReadAt.$userId': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> updateTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) {
    return guardFirebase(() async {
      await _conversationCollection.doc(conversationId).update({
        'typingStatus.$userId': isTyping,
      });
    });
  }

  @override
  Future<void> updateMessageStatus({
    required String conversationId,
    required String messageId,
    required String status,
  }) {
    return guardFirebase(() async {
      await _conversationCollection
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'status': status,
      });
    });
  }

  @override
  Future<void> markMessageAsDelivered({
    required String conversationId,
    required String messageId,
  }) {
    return guardFirebase(() async {
      final docRef = _conversationCollection
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);

      // Monotonic: never overwrite an advanced read status with delivered.
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;
        final status = snapshot.data()?['status'] as String?;
        if (status == 'read' || status == 'delivered') return;
        transaction.update(docRef, {
          'status': 'delivered',
          'deliveredAt': FieldValue.serverTimestamp(),
        });
      });
    });
  }

  @override
  Future<void> markMessageAsRead({
    required String conversationId,
    required String messageId,
  }) {
    return guardFirebase(() async {
      final docRef = _conversationCollection
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;
        final status = snapshot.data()?['status'] as String?;
        if (status == 'read') return;
        transaction.update(docRef, {
          'status': 'read',
          'readAt': FieldValue.serverTimestamp(),
        });
      });
    });
  }
}
