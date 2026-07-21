import '../entities/contact_entity.dart';

abstract class ContactsRepository {
  /// Request contacts permission
  Future<bool> requestPermission();

  /// Get all contacts from device
  Future<List<ContactEntity>> getDeviceContacts();

  /// Get only Velix users from Firestore
  Future<List<ContactEntity>> getVelixUsers(
    List<ContactEntity> contacts,
  );

  /// Sync device contacts with Firestore users
  Future<List<ContactEntity>> syncContacts();

  /// Search contacts
  Future<List<ContactEntity>> searchContacts(
    String query,
  );
}