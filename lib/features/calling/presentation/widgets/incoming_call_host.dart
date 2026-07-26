import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/call_session.dart';
import '../providers/call_controller.dart';
import '../screens/incoming_call_screen.dart';

/// Listens for ringing calls and presents the incoming call UI once.
class IncomingCallHost extends ConsumerStatefulWidget {
  const IncomingCallHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<IncomingCallHost> createState() => _IncomingCallHostState();
}

class _IncomingCallHostState extends ConsumerState<IncomingCallHost> {
  String? _presentedCallId;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CallSession?>>(incomingCallProvider,
        (previous, next) {
      final session = next.asData?.value;
      if (session == null) {
        _presentedCallId = null;
        return;
      }

      final callState = ref.read(callControllerProvider);
      if (callState.phase != CallPhase.idle &&
          callState.phase != CallPhase.ended &&
          callState.phase != CallPhase.ringingIncoming) {
        return;
      }

      if (_presentedCallId == session.id) return;
      _presentedCallId = session.id;

      ref.read(callControllerProvider.notifier).presentIncoming(session);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => IncomingCallScreen(session: session),
          ),
        );
      });
    });

    return widget.child;
  }
}
