import 'package:equatable/equatable.dart';

/// A Velix friend created by scanning a valid Velix QR code.
class FriendEntity extends Equatable {
  const FriendEntity({
    required this.uid,
    required this.displayName,
    required this.velixId,
    required this.photoUrl,
    required this.createdAt,
    this.isOnline = false,
  });

  final String uid;
  final String displayName;
  final String velixId;
  final String photoUrl;
  final DateTime createdAt;
  final bool isOnline;

  @override
  List<Object?> get props => [
        uid,
        displayName,
        velixId,
        photoUrl,
        createdAt,
        isOnline,
      ];
}
