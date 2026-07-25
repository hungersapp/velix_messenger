/// Relative time formatter for Time Capsule stories (`createdAt`).
String formatStoryRelativeTime(
  DateTime dateTime, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(dateTime);

  if (diff.isNegative || diff.inSeconds < 60) {
    return 'Just now';
  }

  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m';
  }

  if (diff.inHours < 24) {
    return '${diff.inHours}h';
  }

  if (diff.inDays == 1) {
    return 'Yesterday';
  }

  return '${diff.inDays}d';
}
