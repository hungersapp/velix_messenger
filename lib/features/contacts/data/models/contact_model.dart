import '../../domain/entities/contact_entity.dart';

class ContactModel extends ContactEntity {
  const ContactModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
    super.email,
    super.photoUrl,
    super.isVelixUser,
    super.uid,
  });

  /// Device Contact -> Model
  factory ContactModel.fromDevice({
    required String id,
    required String name,
    required String phoneNumber,
    String? email,
    String? photoUrl,
  }) {
    return ContactModel(
      id: id,
      name: name,
      phoneNumber: _normalizePhoneNumber(phoneNumber),
      email: email,
      photoUrl: photoUrl,
    );
  }

  /// Firestore JSON -> Model
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['uid'] ?? '',
      uid: json['uid'],
      name: json['name'] ?? '',
      phoneNumber: _normalizePhoneNumber(
        json['mobileNumber'] ?? '',
      ),
      email: json['email'],
      photoUrl: json['photoUrl'],
      isVelixUser: true,
    );
  }

  /// Model -> Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'mobileNumber': phoneNumber,
      'email': email,
      'photoUrl': photoUrl,
      'isVelixUser': isVelixUser,
    };
  }

  /// CopyWith
  ContactModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? photoUrl,
    bool? isVelixUser,
    String? uid,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isVelixUser: isVelixUser ?? this.isVelixUser,
      uid: uid ?? this.uid,
    );
  }

  /// Normalize Phone Number
  static String _normalizePhoneNumber(String phoneNumber) {
    var number = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    number = number.replaceAll('-', '');
    number = number.replaceAll('(', '');
    number = number.replaceAll(')', '');

    if (number.startsWith('+91')) {
      number = number.substring(3);
    }

    if (number.startsWith('91') && number.length == 12) {
      number = number.substring(2);
    }

    if (number.startsWith('0') && number.length == 11) {
      number = number.substring(1);
    }

    return number;
  }
}