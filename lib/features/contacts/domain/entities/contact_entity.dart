import 'package:equatable/equatable.dart';

/// Compatibility projection used by Time Capsule friend-id resolution.
///
/// The Contacts UI uses [FriendEntity]. This shape is retained so existing
/// Time Capsule providers keep compiling without modification.
class ContactEntity extends Equatable {
  const ContactEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.photoUrl,
    this.isVelixUser = false,
    this.uid,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? photoUrl;
  final bool isVelixUser;
  final String? uid;

  @override
  List<Object?> get props => [
        id,
        name,
        phoneNumber,
        email,
        photoUrl,
        isVelixUser,
        uid,
      ];
}
