import '../../domain/entities/contact_entity.dart';

class ContactsState {
  final bool isLoading;
  final bool hasPermission;
  final List<ContactEntity> contacts;
  final String searchQuery;
  final String? errorMessage;

  const ContactsState({
    this.isLoading = false,
    this.hasPermission = false,
    this.contacts = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  ContactsState copyWith({
    bool? isLoading,
    bool? hasPermission,
    List<ContactEntity>? contacts,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ContactsState(
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      contacts: contacts ?? this.contacts,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}