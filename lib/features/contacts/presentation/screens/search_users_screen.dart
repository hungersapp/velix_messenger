import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/services/velix_qr_payload.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/entities/discoverable_user_entity.dart';
import '../../domain/exceptions/friend_request_exceptions.dart';
import '../providers/contacts_provider.dart';

/// Live search for registered Velix users (excludes self / friends / blocked).
class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  ConsumerState<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<DiscoverableUserEntity> _results = const [];
  final Set<String> _sending = {};
  final Set<String> _sentLocally = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(value);
    });
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results =
          await ref.read(searchVelixUsersUseCaseProvider)(trimmed);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to search users.';
        _results = const [];
      });
    }
  }

  Future<void> _addFriend(DiscoverableUserEntity user) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      _toast('Sign in to add friends.');
      return;
    }

    setState(() => _sending.add(user.uid));

    try {
      await ref.read(sendFriendRequestUseCaseProvider)(
        currentUser: currentUser,
        target: user,
      );
      if (!mounted) return;
      setState(() {
        _sentLocally.add(user.uid);
        _sending.remove(user.uid);
      });
      _toast('Friend request sent.');
    } on FriendRequestException catch (e) {
      if (!mounted) return;
      setState(() => _sending.remove(user.uid));
      _toast(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending.remove(user.uid));
      _toast('Unable to send friend request.');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Velix Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search by Velix ID, username, or name',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_controller.text.trim().isEmpty) {
      return Center(
        child: Text(
          'Search for people on Velix',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (!_loading && _results.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = _results[index];
        final handle = VelixQrPayload.displayHandle(user.velixId);
        final username = user.username.isNotEmpty
            ? VelixQrPayload.displayHandle(user.username)
            : '';
        final requestSent =
            user.hasOutgoingRequest || _sentLocally.contains(user.uid);
        final isSending = _sending.contains(user.uid);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: user.photoUrl.trim().isNotEmpty
                ? NetworkImage(user.photoUrl)
                : null,
            child: user.photoUrl.trim().isEmpty
                ? Text(
                    _initials(user.displayName),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          title: Text(
            user.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (handle.isNotEmpty) Text(handle),
              if (username.isNotEmpty && username != handle)
                Text(
                  username,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          isThreeLine: username.isNotEmpty && username != handle,
          trailing: user.isFriend
              ? Text(
                  'Friends',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                )
              : FilledButton(
                  onPressed: user.isFriend || requestSent || isSending
                      ? null
                      : () => _addFriend(user),
                  child: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(requestSent ? 'Sent' : 'Add Friend'),
                ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
