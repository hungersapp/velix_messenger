import '../../domain/entities/contact_entity.dart';
import '../../domain/repositories/contacts_repository.dart';
import '../datasources/contacts_local_datasource.dart';
import '../datasources/contacts_remote_datasource.dart';
import '../models/contact_model.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  final ContactsLocalDataSource localDataSource;
  final ContactsRemoteDataSource remoteDataSource;

  ContactsRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<bool> requestPermission() async {
    return await localDataSource.requestPermission();
  }

  @override
  Future<List<ContactEntity>> getDeviceContacts() async {
    return await localDataSource.getContacts();
  }

  @override
  Future<List<ContactEntity>> getVelixUsers(
    List<ContactEntity> contacts,
  ) async {
    final contactModels = contacts
        .map(
          (contact) => ContactModel(
            id: contact.id,
            name: contact.name,
            phoneNumber: contact.phoneNumber,
            email: contact.email,
            photoUrl: contact.photoUrl,
            isVelixUser: contact.isVelixUser,
            uid: contact.uid,
          ),
        )
        .toList();

    return await remoteDataSource.matchVelixUsers(contactModels);
  }

  @override
  Future<List<ContactEntity>> syncContacts() async {
    final contacts = await localDataSource.getContacts();

    return await remoteDataSource.matchVelixUsers(
      contacts,
    );
  }

  @override
  Future<List<ContactEntity>> searchContacts(
    String query,
  ) async {
    final contacts = await syncContacts();

    if (query.trim().isEmpty) {
      return contacts;
    }

    final search = query.toLowerCase();

    return contacts.where((contact) {
      return contact.name.toLowerCase().contains(search) ||
          contact.phoneNumber.contains(query);
    }).toList();
  }
}