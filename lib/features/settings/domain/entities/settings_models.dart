/// Who can see a privacy-sensitive profile field.
enum PrivacyVisibility {
  everyone,
  contacts,
  nobody;

  String get label => switch (this) {
        PrivacyVisibility.everyone => 'Everyone',
        PrivacyVisibility.contacts => 'My Contacts',
        PrivacyVisibility.nobody => 'Nobody',
      };

  String get storageValue => name;

  static PrivacyVisibility fromStorage(String? raw) {
    return PrivacyVisibility.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => PrivacyVisibility.everyone,
    );
  }
}

enum ChatFontSizeOption {
  small,
  medium,
  large;

  String get label => switch (this) {
        ChatFontSizeOption.small => 'Small',
        ChatFontSizeOption.medium => 'Medium',
        ChatFontSizeOption.large => 'Large',
      };

  /// Multiplier applied to chat message body text.
  double get scale => switch (this) {
        ChatFontSizeOption.small => 0.9,
        ChatFontSizeOption.medium => 1.0,
        ChatFontSizeOption.large => 1.2,
      };

  static ChatFontSizeOption fromStorage(String? raw) {
    return ChatFontSizeOption.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => ChatFontSizeOption.medium,
    );
  }
}

class AutoDownloadSettings {
  const AutoDownloadSettings({
    this.photos = true,
    this.videos = false,
    this.documents = false,
    this.voiceMessages = true,
  });

  final bool photos;
  final bool videos;
  final bool documents;
  final bool voiceMessages;

  AutoDownloadSettings copyWith({
    bool? photos,
    bool? videos,
    bool? documents,
    bool? voiceMessages,
  }) {
    return AutoDownloadSettings(
      photos: photos ?? this.photos,
      videos: videos ?? this.videos,
      documents: documents ?? this.documents,
      voiceMessages: voiceMessages ?? this.voiceMessages,
    );
  }
}

class BlockedUser {
  const BlockedUser({
    required this.uid,
    required this.displayName,
    required this.velixId,
    required this.photoUrl,
    required this.blockedAt,
  });

  final String uid;
  final String displayName;
  final String velixId;
  final String photoUrl;
  final DateTime blockedAt;
}

class ActiveDevice {
  const ActiveDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.lastActiveAt,
    required this.isCurrent,
  });

  final String id;
  final String name;
  final String platform;
  final DateTime lastActiveAt;
  final bool isCurrent;
}

class PrivacySettings {
  const PrivacySettings({
    this.lastSeen = PrivacyVisibility.everyone,
    this.profilePhoto = PrivacyVisibility.everyone,
    this.readReceipts = true,
  });

  final PrivacyVisibility lastSeen;
  final PrivacyVisibility profilePhoto;
  final bool readReceipts;

  PrivacySettings copyWith({
    PrivacyVisibility? lastSeen,
    PrivacyVisibility? profilePhoto,
    bool? readReceipts,
  }) {
    return PrivacySettings(
      lastSeen: lastSeen ?? this.lastSeen,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      readReceipts: readReceipts ?? this.readReceipts,
    );
  }
}
