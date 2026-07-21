import 'package:equatable/equatable.dart';

class ContactEntity extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? photoUrl;
  final bool isVelixUser;
  final String? uid;

  const ContactEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.photoUrl,
    this.isVelixUser = false,
    this.uid,
  });

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