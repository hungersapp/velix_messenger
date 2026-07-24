import '../../../chat/domain/entities/conversation.dart';

String formatLastMessagePreview(Conversation conversation) {
  switch (conversation.lastMessageType) {
    case 'image':
      return 'Photo';
    case 'video':
      return 'Video';
    default:
      return conversation.lastMessage;
  }
}

String formatConversationTime(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final dayDiff = today.difference(messageDay).inDays;

  if (dayDiff == 0) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  if (dayDiff == 1) {
    return 'Yesterday';
  }

  if (dayDiff < 7) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[dateTime.weekday - 1];
  }

  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  return '$day/$month/${dateTime.year}';
}

String otherParticipantId({
  required Conversation conversation,
  required String currentUserId,
}) {
  for (final participantId in conversation.participants) {
    if (participantId != currentUserId) {
      return participantId;
    }
  }

  return currentUserId;
}

bool matchesRecentChatSearch({
  required String query,
  required Conversation conversation,
  required String name,
  required String phone,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return true;
  }

  final preview = formatLastMessagePreview(conversation).toLowerCase();
  final rawMessage = conversation.lastMessage.toLowerCase();

  return name.toLowerCase().contains(normalizedQuery) ||
      phone.contains(query.trim()) ||
      phone.toLowerCase().contains(normalizedQuery) ||
      preview.contains(normalizedQuery) ||
      rawMessage.contains(normalizedQuery);
}
