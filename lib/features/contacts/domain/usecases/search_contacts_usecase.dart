import '../entities/contact_entity.dart';
import '../repositories/contacts_repository.dart';

class SearchContactsUseCase {
  final ContactsRepository repository;

  SearchContactsUseCase(this.repository);

  Future<List<ContactEntity>> call(String query) async {
    return await repository.searchContacts(query);
  }
}