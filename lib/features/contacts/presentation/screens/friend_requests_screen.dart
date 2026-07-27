import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/presentation/providers/conversation_provider.dart';
import '../../../profile/domain/services/velix_qr_payload.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/entities/friend_request_entity.dart';
import '../providers/contacts_provider.dart';

/// Incoming Velix friend requests — Accept creates friendship + chat.
class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  bool _loading = true;
  String? _error;
  List<FriendRequestEntity> _requests = const [];
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final requests =
          await ref.read(getIncomingFriendRequestsUseCaseProvider)();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load friend requests.';
      });
    }
  }

  Future<void> _accept(FriendRequestEntity request) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() => _busy.add(request.fromUid));

    try {
      await ref.read(acceptFriendRequestUseCaseProvider)(
        currentUser: currentUser,
        request: request,
      );

      ref.invalidate(friendsProvider);
      ref.invalidate(contactsProvider);
      ref.invalidate(syncContactsUseCaseProvider);
      ref.invalidate(chatConversationsProvider(currentUser.uid));

      if (!mounted) return;
      setState(() {
        _requests =
            _requests.where((r) => r.fromUid != request.fromUid).toList();
        _busy.remove(request.fromUid);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend added successfully')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy.remove(request.fromUid));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to accept request.')),
      );
    }
  }

  Future<void> _decline(FriendRequestEntity request) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() => _busy.add(request.fromUid));

    try {
      await ref.read(declineFriendRequestUseCaseProvider)(
        fromUid: request.fromUid,
        toUid: currentUser.uid,
      );

      if (!mounted) return;
      setState(() {
        _requests =
            _requests.where((r) => r.fromUid != request.fromUid).toList();
        _busy.remove(request.fromUid);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy.remove(request.fromUid));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to decline request.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading && _requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && _requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
          Center(child: Text(_error!)),
        ],
      );
    }

    if (_requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
          Center(
            child: Text(
              'No incoming requests',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Incoming Requests',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ..._requests.map((request) {
          final handle = VelixQrPayload.displayHandle(request.velixId);
          final busy = _busy.contains(request.fromUid);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: request.photoUrl.trim().isNotEmpty
                  ? NetworkImage(request.photoUrl)
                  : null,
              child: request.photoUrl.trim().isEmpty
                  ? Text(
                      _initials(request.displayName),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            title: Text(
              request.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(handle),
            trailing: busy
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => _decline(request),
                        child: const Text('Decline'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _accept(request),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
          );
        }),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
