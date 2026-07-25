import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  const StoryModel({
    required this.id,
    required this.ownerId,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.seenBy,
    this.viewers = const {},
    this.likes = const {},
    required this.visibility,
    required this.durationMs,
  });

  final String id;
  final String ownerId;
  final String mediaType;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final Timestamp createdAt;
  final Timestamp expiresAt;
  final List<String> seenBy;
  final Map<String, Timestamp> viewers;
  final Map<String, Timestamp> likes;
  final String visibility;
  final int durationMs;

  factory StoryModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return StoryModel(
      id: documentId,
      ownerId: map['ownerId'] as String? ?? '',
      mediaType: map['mediaType'] as String? ?? 'image',
      mediaUrl: map['mediaUrl'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String?,
      caption: map['caption'] as String?,
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      expiresAt: map['expiresAt'] as Timestamp? ?? Timestamp.now(),
      seenBy: List<String>.from(map['seenBy'] ?? const []),
      viewers: _parseTimestampMap(map['viewers']),
      likes: _parseTimestampMap(map['likes']),
      visibility: map['visibility'] as String? ?? 'friends',
      durationMs: map['durationMs'] as int? ?? 5000,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'seenBy': seenBy,
      'viewers': viewers,
      'likes': likes,
      'visibility': visibility,
      'durationMs': durationMs,
    };
  }

  static Map<String, Timestamp> _parseTimestampMap(dynamic raw) {
    if (raw is! Map) {
      return const {};
    }

    final result = <String, Timestamp>{};
    raw.forEach((key, value) {
      final userId = key?.toString();
      if (userId == null || userId.isEmpty) {
        return;
      }
      if (value is Timestamp) {
        result[userId] = value;
      }
    });
    return result;
  }
}
