/// Relative time formatter for Time Capsule (stories + future seen times).
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
    final mins = diff.inMinutes;
    return mins == 1 ? '1 min ago' : '$mins mins ago';
  }

  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return hours == 1 ? '1 hour ago' : '$hours hours ago';
  }

  return 'Yesterday';
}
