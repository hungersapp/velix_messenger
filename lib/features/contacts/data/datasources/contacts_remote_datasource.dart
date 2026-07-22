import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/contact_model.dart';


abstract class ContactsRemoteDataSource {
  Future<List<ContactModel>> matchVelixUsers(
    List<ContactModel> contacts,
  );
}

class ContactsRemoteDataSourceImpl
    implements ContactsRemoteDataSource {
  ContactsRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<List<ContactModel>> matchVelixUsers(
    List<ContactModel> contacts,
  ) async {
    final snapshot = await _usersCollection.get();

    final users = snapshot.docs;

    return contacts.map((contact) {
      ContactModel updatedContact = contact;

      for (final user in users) {
        final data = user.data();

       final firestoreNumber = _normalizePhoneNumber(
  data['mobileNumber'] ?? '',
);

final contactNumber = _normalizePhoneNumber(
  contact.phoneNumber,
);


if (firestoreNumber == contactNumber) {
          updatedContact = contact.copyWith(
            isVelixUser: true,
            uid: data['uid'],
          );

          break;
        }
      }

      return updatedContact;
    }).toList();
  }

  String _normalizePhoneNumber(String phoneNumber) {
    var number = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (number.startsWith('91') && number.length == 12) {
      number = number.substring(2);
    }

    if (number.startsWith('0') && number.length == 11) {
      number = number.substring(1);
    }

    return number;
  }
}