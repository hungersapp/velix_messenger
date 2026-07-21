import '../entities/contact_entity.dart';
import '../repositories/contacts_repository.dart';

class SyncContactsUseCase {
  final ContactsRepository repository;

  SyncContactsUseCase(this.repository);

  Future<List<ContactEntity>> call() async {
    return await repository.syncContacts();
  }
}