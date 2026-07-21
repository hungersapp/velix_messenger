import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/contact_model.dart';

abstract class ContactsLocalDataSource {
  Future<bool> requestPermission();

  Future<List<ContactModel>> getContacts();
}

class ContactsLocalDataSourceImpl
    implements ContactsLocalDataSource {

  @override
  Future<bool> requestPermission() async {
    debugPrint("========== PERMISSION HANDLER ==========");

    final status = await Permission.contacts.request();

    debugPrint("Permission Handler Status : $status");

    return status.isGranted;
  }

  @override
  Future<List<ContactModel>> getContacts() async {
    final permission = await requestPermission();

    debugPrint("Permission inside getContacts : $permission");

    if (!permission) {
      debugPrint("Permission denied.");
      return [];
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
    );

    debugPrint("========================================");
    debugPrint("Total Contacts : ${contacts.length}");
    debugPrint("========================================");

    final List<ContactModel> contactModels = [];

    for (final contact in contacts) {
      final phoneNumbers =
          contact.phones.map((e) => e.number).toList();

      debugPrint("----------------------------------------");
      debugPrint("Name        : ${contact.displayName}");
      debugPrint("Contact ID  : ${contact.id}");
      debugPrint("Phone Count : ${contact.phones.length}");
      debugPrint("Phones      : $phoneNumbers");
      debugPrint("Email Count : ${contact.emails.length}");
      debugPrint("----------------------------------------");

      contactModels.add(
        ContactModel.fromDevice(
          id: contact.id,
          name: contact.displayName,
          phoneNumber: phoneNumbers.isNotEmpty
              ? phoneNumbers.first
              : '',
          email: contact.emails.isNotEmpty
              ? contact.emails.first.address
              : null,
          photoUrl: null,
        ),
      );
    }

    debugPrint(
      "Mapped Contact Models : ${contactModels.length}",
    );

    return contactModels;
  }
}