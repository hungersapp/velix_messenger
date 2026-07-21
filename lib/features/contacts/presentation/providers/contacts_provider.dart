import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/contacts_local_datasource.dart';
import '../../data/datasources/contacts_remote_datasource.dart';
import '../../data/repositories/contacts_repository_impl.dart';
import '../../domain/repositories/contacts_repository.dart';
import '../../domain/usecases/get_contacts_usecase.dart';
import '../../domain/usecases/search_contacts_usecase.dart';
import '../../domain/usecases/sync_contacts_usecase.dart';
import 'contacts_state.dart';

/// ---------------------------------------------------------------------------
/// Data Sources
/// ---------------------------------------------------------------------------

final contactsLocalDataSourceProvider =
    Provider<ContactsLocalDataSource>(
  (ref) => ContactsLocalDataSourceImpl(),
);

final contactsRemoteDataSourceProvider =
    Provider<ContactsRemoteDataSource>(
  (ref) => ContactsRemoteDataSourceImpl(),
);

/// ---------------------------------------------------------------------------
/// Repository
/// ---------------------------------------------------------------------------

final contactsRepositoryProvider =
    Provider<ContactsRepository>(
  (ref) => ContactsRepositoryImpl(
    localDataSource: ref.watch(
      contactsLocalDataSourceProvider,
    ),
    remoteDataSource: ref.watch(
      contactsRemoteDataSourceProvider,
    ),
  ),
);

/// ---------------------------------------------------------------------------
/// UseCases
/// ---------------------------------------------------------------------------

final getContactsUseCaseProvider =
    Provider<GetContactsUseCase>(
  (ref) => GetContactsUseCase(
    ref.watch(contactsRepositoryProvider),
  ),
);

final syncContactsUseCaseProvider =
    Provider<SyncContactsUseCase>(
  (ref) => SyncContactsUseCase(
    ref.watch(contactsRepositoryProvider),
  ),
);

final searchContactsUseCaseProvider =
    Provider<SearchContactsUseCase>(
  (ref) => SearchContactsUseCase(
    ref.watch(contactsRepositoryProvider),
  ),
);

/// ---------------------------------------------------------------------------
/// StateNotifier
/// ---------------------------------------------------------------------------

class ContactsNotifier extends StateNotifier<ContactsState> {
  final ContactsRepository repository;
  final GetContactsUseCase getContactsUseCase;
  final SyncContactsUseCase syncContactsUseCase;
  final SearchContactsUseCase searchContactsUseCase;

  ContactsNotifier({
    required this.repository,
    required this.getContactsUseCase,
    required this.syncContactsUseCase,
    required this.searchContactsUseCase,
  }) : super(const ContactsState());

  Future<void> loadContacts() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final hasPermission =
          await repository.requestPermission();

      if (!hasPermission) {
        state = state.copyWith(
          isLoading: false,
          hasPermission: false,
          errorMessage: 'Contacts permission denied.',
        );
        return;
      }

      final contacts = await getContactsUseCase();

      state = state.copyWith(
        isLoading: false,
        hasPermission: true,
        contacts: contacts,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> syncContacts() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final contacts =
          await syncContactsUseCase();

      state = state.copyWith(
        isLoading: false,
        contacts: contacts,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> searchContacts(String query) async {
    state = state.copyWith(
      searchQuery: query,
      isLoading: true,
      clearError: true,
    );

    try {
      final contacts =
          await searchContactsUseCase(query);

      state = state.copyWith(
        isLoading: false,
        hasPermission: true,
        contacts: contacts,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

/// ---------------------------------------------------------------------------
/// Provider
/// ---------------------------------------------------------------------------

final contactsProvider =
    StateNotifierProvider<
        ContactsNotifier,
        ContactsState>(
  (ref) => ContactsNotifier(
    repository: ref.watch(
      contactsRepositoryProvider,
    ),
    getContactsUseCase:
        ref.watch(getContactsUseCaseProvider),
    syncContactsUseCase:
        ref.watch(syncContactsUseCaseProvider),
    searchContactsUseCase:
        ref.watch(searchContactsUseCaseProvider),
  ),
);