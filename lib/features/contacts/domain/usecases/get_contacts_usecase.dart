import '../entities/contact_entity.dart';
import '../repositories/contacts_repository.dart';

class GetContactsUseCase {
  final ContactsRepository repository;

  GetContactsUseCase(this.repository);

  Future<List<ContactEntity>> call() async {
    return await repository.getDeviceContacts();
  }
}