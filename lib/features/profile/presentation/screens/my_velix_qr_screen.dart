import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../user/domain/entities/user_entity.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/services/velix_qr_payload.dart';
import '../widgets/my_velix_qr_actions.dart';
import '../widgets/my_velix_qr_card.dart';
import 'qr_scanner_screen.dart';

/// Full-screen digital identity QR for the authenticated Velix user.
///
/// Encodes only the user's Velix ID as `velix://user/@…`.
/// Does not handle payments.
class MyVelixQrScreen extends ConsumerWidget {
  const MyVelixQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Theme(
      data: AppTheme.darkTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Velix QR'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              actions: [
                PopupMenuButton<_QrMenuAction>(
                  tooltip: 'More',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    // Reserved for copy link / save image / etc.
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _QrMenuAction.copyLink,
                      enabled: false,
                      child: Text('Copy link'),
                    ),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              child: userAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to load your Velix profile.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                data: (user) {
                  if (user == null) {
                    return Center(
                      child: Text(
                        'Sign in to view your Velix QR.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }
                  return _MyVelixQrBody(user: user);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MyVelixQrBody extends StatelessWidget {
  const _MyVelixQrBody({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 600 ? 48.0 : 24.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  8,
                  horizontalPadding,
                  16,
                ),
                child: MyVelixQrCard(user: user),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                16,
              ),
              child: MyVelixQrActions(
                onShareQr: () => _onShareQr(context, user),
                onOpenScanner: () => _onOpenScanner(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Prepared for `share_plus` — share payload / QR image in a later pass.
  void _onShareQr(BuildContext context, UserEntity user) {
    final payload = VelixQrPayload.fromVelixId(user.velixId);
    if (payload.isEmpty) return;

    // share_plus is already a project dependency. Wire when product-ready:
    // await SharePlus.instance.share(ShareParams(text: payload));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share QR will be available soon'),
      ),
    );
  }

  void _onOpenScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const QrScannerScreen(),
      ),
    );
  }
}

enum _QrMenuAction { copyLink }
