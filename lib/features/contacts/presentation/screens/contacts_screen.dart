import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/contact_entity.dart';
import '../providers/contacts_provider.dart';
import '../providers/contacts_state.dart';
import '../widgets/contact_tile.dart';
import '../widgets/invite_tile.dart';
import '../widgets/search_bar.dart';

//import 'package:go_router/go_router.dart';
//import '../../../../app/routes/app_routes.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() =>
      _ContactsScreenState();
}

class _ContactsScreenState
    extends ConsumerState<ContactsScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(contactsProvider.notifier).loadContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ContactsState state =
        ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(contactsProvider.notifier)
              .syncContacts();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ContactsSearchBar(
              controller: _searchController,
              onChanged: (value) {
             ref
                .read(contactsProvider.notifier)
               .searchContacts(value);
              },
             ),
            ),

            Expanded(
              child: _buildBody(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ContactsState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!state.hasPermission) {
      return const Center(
        child: Text(
          "Please allow Contacts permission.",
        ),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (state.contacts.isEmpty) {
      return const Center(
        child: Text(
          "No contacts found.",
        ),
      );
    }

    return ListView.separated(
  physics: const AlwaysScrollableScrollPhysics(),
  itemCount: state.contacts.length,
  separatorBuilder: (_, _) => const Divider(height: 1),
  itemBuilder: (context, index) {
    final ContactEntity contact = state.contacts[index];

        if (contact.isVelixUser) {
          return ContactTile(
            name: contact.name,
            subtitle: contact.phoneNumber,
            photoUrl: contact.photoUrl,
            isOnline: false,
            onTap: () {
              // TODO:
              // Conversation Create
              // Navigate Chat Screen
            },
          );
        }

        return InviteTile(
          name: contact.name,
          phoneNumber: contact.phoneNumber,
          photoUrl: contact.photoUrl,
          onInvite: () {
            // TODO:
            // Share Invite Link
          },
        );
      },
    );
  }
}