import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../chat/presentation/providers/conversation_provider.dart';
import '../../../contacts/presentation/providers/contacts_provider.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/entities/velix_public_profile.dart';
import '../../domain/exceptions/velix_qr_exceptions.dart';
import '../../domain/services/velix_qr_payload.dart';
import '../providers/velix_qr_connect_provider.dart';
import '../widgets/profile_avatar.dart';

/// Preview of a scanned Velix user — Connect creates friendship immediately.
class ProfilePreviewScreen extends ConsumerStatefulWidget {
  const ProfilePreviewScreen({
    super.key,
    required this.profile,
  });

  final VelixPublicProfile profile;

  @override
  ConsumerState<ProfilePreviewScreen> createState() =>
      _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends ConsumerState<ProfilePreviewScreen> {
  bool _connecting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final handle = VelixQrPayload.displayHandle(widget.profile.velixId);
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 600 ? 48.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _connecting
              ? null
              : () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            32,
            horizontalPadding,
            24,
          ),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ProfileAvatar(
                      displayName: widget.profile.displayName,
                      photoUrl: widget.profile.photoUrl.isEmpty
                          ? null
                          : widget.profile.photoUrl,
                      size: 112,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.profile.displayName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      handle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _connecting ? null : _onConnect,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _connecting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onConnect() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      _showMessage('Sign in to connect with this user.');
      return;
    }

    setState(() => _connecting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(connectVelixUserUseCaseProvider)(
        currentUser: currentUser,
        peer: widget.profile,
      );

      ref.invalidate(friendsProvider);
      ref.invalidate(contactsProvider);
      ref.invalidate(syncContactsUseCaseProvider);
      ref.invalidate(conversationProvider(currentUser.uid));

      if (!mounted) return;
      context.go(AppRoutes.home);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Friend added successfully')),
        );
    } on CannotConnectSelfException catch (e) {
      _showMessage(e.message);
    } on VelixUserNotFoundException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Unable to connect. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _connecting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
