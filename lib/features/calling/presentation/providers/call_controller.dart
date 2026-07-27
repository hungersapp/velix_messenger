import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../chat/services/camera_permission_service.dart';
import '../../../chat/services/microphone_permission_service.dart';
import '../../../settings/presentation/providers/settings_feature_providers.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../../data/datasources/call_remote_datasource_impl.dart';
import '../../data/repositories/call_repository_impl.dart';
import '../../domain/entities/call_history_entry.dart';
import '../../domain/entities/call_session.dart';
import '../../domain/repositories/call_repository.dart';
import '../../services/network_availability_service.dart';
import '../../services/webrtc_voice_service.dart';

enum CallPhase {
  idle,
  dialing,
  ringingIncoming,
  connecting,
  connected,
  ended,
}

class CallUiState {
  const CallUiState({
    this.phase = CallPhase.idle,
    this.session,
    this.isOutgoing = false,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.isCameraEnabled = true,
    this.isReconnecting = false,
    this.mediaRevision = 0,
    this.elapsed = Duration.zero,
    this.statusLabel = '',
    this.errorMessage,
    this.historySaved = false,
  });

  final CallPhase phase;
  final CallSession? session;
  final bool isOutgoing;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraEnabled;
  final bool isReconnecting;
  final int mediaRevision;
  final Duration elapsed;
  final String statusLabel;
  final String? errorMessage;
  final bool historySaved;

  bool get isVideo => session?.isVideo ?? false;

  CallUiState copyWith({
    CallPhase? phase,
    CallSession? session,
    bool? isOutgoing,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isCameraEnabled,
    bool? isReconnecting,
    int? mediaRevision,
    Duration? elapsed,
    String? statusLabel,
    String? errorMessage,
    bool? historySaved,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return CallUiState(
      phase: phase ?? this.phase,
      session: clearSession ? null : (session ?? this.session),
      isOutgoing: isOutgoing ?? this.isOutgoing,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      mediaRevision: mediaRevision ?? this.mediaRevision,
      elapsed: elapsed ?? this.elapsed,
      statusLabel: statusLabel ?? this.statusLabel,
      errorMessage: errorMessage ?? (clearError ? null : this.errorMessage),
      historySaved: historySaved ?? this.historySaved,
    );
  }
}

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepositoryImpl(
    CallRemoteDataSourceImpl(
      firestore: ref.watch(firestoreProvider),
    ),
  );
});

final webrtcVoiceServiceProvider = Provider<WebrtcVoiceService>((ref) {
  final service = WebrtcVoiceService();
  ref.onDispose(service.dispose);
  return service;
});

final callControllerProvider =
    StateNotifierProvider<CallController, CallUiState>((ref) {
  return CallController(ref);
});

final incomingCallProvider = StreamProvider<CallSession?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) {
    return Stream<CallSession?>.value(null);
  }
  return ref.watch(callRepositoryProvider).watchIncomingRingingCall(user.uid);
});

class CallController extends StateNotifier<CallUiState> {
  CallController(this._ref) : super(const CallUiState());

  final Ref _ref;
  final MicrophonePermissionService _micPermission =
      const MicrophonePermissionService();
  final CameraPermissionService _cameraPermission =
      const CameraPermissionService();
  final NetworkAvailabilityService _network =
      const NetworkAvailabilityService();

  StreamSubscription<CallSession?>? _sessionSub;
  StreamSubscription<List<Map<String, dynamic>>>? _iceSub;
  Timer? _ringTimeout;
  Timer? _elapsedTimer;
  DateTime? _connectedAt;
  bool _ending = false;
  final Set<String> _appliedCandidates = {};

  CallRepository get _repository => _ref.read(callRepositoryProvider);
  WebrtcVoiceService get _webrtc => _ref.read(webrtcVoiceServiceProvider);

  RTCVideoRenderer? get localRenderer => _webrtc.localRenderer;
  RTCVideoRenderer? get remoteRenderer => _webrtc.remoteRenderer;

  Future<bool> startOutgoingCall({
    required String conversationId,
    required String receiverId,
    required String receiverName,
    String? receiverPhotoUrl,
    CallType callType = CallType.voice,
  }) async {
    if (state.phase != CallPhase.idle && state.phase != CallPhase.ended) {
      return false;
    }

    final hasNetwork = await _network.hasNetworkConnection();
    if (!hasNetwork) {
      state = state.copyWith(
        errorMessage: 'No network connection. Check your internet and try again.',
      );
      return false;
    }

    final micOk = await _ensureMicPermission(forVideo: callType == CallType.video);
    if (!micOk) return false;

    if (callType == CallType.video) {
      final cameraOk = await _ensureCameraPermission();
      if (!cameraOk) return false;
    }

    final currentUser = _ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      state = state.copyWith(errorMessage: 'You must be signed in to call.');
      return false;
    }

    // Blocked-user guard (settings block list).
    try {
      final settingsRepo = _ref.read(settingsRepositoryProvider);
      final blocked = await settingsRepo.isBlockedEitherWay(
        userA: currentUser.uid,
        userB: receiverId,
      );
      if (blocked) {
        state = state.copyWith(
          errorMessage: 'Calling is unavailable with this user.',
        );
        return false;
      }
    } catch (_) {
      // Continue if settings lookup fails.
    }

    try {
      final online = await _repository.isUserOnline(receiverId);

      _resetTransientState();
      state = state.copyWith(
        phase: CallPhase.dialing,
        isOutgoing: true,
        isCameraEnabled: callType == CallType.video,
        isReconnecting: false,
        statusLabel: 'Calling...',
        clearError: true,
        historySaved: false,
        elapsed: Duration.zero,
        errorMessage: online
            ? null
            : 'Receiver appears offline. Waiting for an answer...',
      );

      final session = await _repository.createCall(
        conversationId: conversationId,
        callerId: currentUser.uid,
        callerName: currentUser.name,
        callerPhotoUrl:
            currentUser.photoUrl.isEmpty ? null : currentUser.photoUrl,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverPhotoUrl: receiverPhotoUrl,
        callType: callType,
      );

      state = state.copyWith(session: session, phase: CallPhase.dialing);

      await _initializeMedia(
        callId: session.id,
        localUserId: currentUser.uid,
        enableVideo: callType == CallType.video,
      );

      final offer = await _webrtc.createOffer();
      await _repository.setOffer(callId: session.id, sdp: offer);

      _listenToSession(session.id, currentUser.uid);
      _listenToIce(session.id, currentUser.uid);
      _startRingTimeout(session.id);

      return true;
    } catch (e, st) {
      debugPrint('startOutgoingCall failed: $e\n$st');
      await _webrtc.dispose();
      state = state.copyWith(
        phase: CallPhase.ended,
        errorMessage: 'Unable to start the call. Check your network.',
        statusLabel: 'Failed',
      );
      return false;
    }
  }

  Future<void> acceptIncomingCall(CallSession session) async {
    final micOk = await _ensureMicPermission(forVideo: session.isVideo);
    if (!micOk) {
      await declineIncomingCall(session);
      return;
    }

    if (session.isVideo) {
      final cameraOk = await _ensureCameraPermission();
      if (!cameraOk) {
        await declineIncomingCall(session);
        return;
      }
    }

    final currentUser = _ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    try {
      _resetTransientState();
      state = state.copyWith(
        session: session,
        phase: CallPhase.connecting,
        isOutgoing: false,
        isCameraEnabled: session.isVideo,
        isReconnecting: false,
        statusLabel: 'Connecting...',
        clearError: true,
        historySaved: false,
        elapsed: Duration.zero,
      );

      await _repository.updateStatus(
        callId: session.id,
        status: CallStatus.connecting,
      );

      await _initializeMedia(
        callId: session.id,
        localUserId: currentUser.uid,
        enableVideo: session.isVideo,
      );

      final latest = await _repository.getCall(session.id);
      final offer = latest?.offerSdp;
      if (offer == null || offer.isEmpty) {
        throw StateError('Missing call offer.');
      }

      await _webrtc.setRemoteOffer(offer);
      final answer = await _webrtc.createAnswer();
      await _repository.setAnswer(callId: session.id, sdp: answer);

      _listenToSession(session.id, currentUser.uid);
      _listenToIce(session.id, currentUser.uid);
    } catch (e, st) {
      debugPrint('acceptIncomingCall failed: $e\n$st');
      await endCall(reason: 'accept_failed');
      state = state.copyWith(
        errorMessage: 'Unable to accept the call. Check your network.',
      );
    }
  }

  Future<void> declineIncomingCall(CallSession session) async {
    await _repository.updateStatus(
      callId: session.id,
      status: CallStatus.declined,
      endedAt: DateTime.now(),
      endReason: 'declined',
    );
    await _saveHistoryForSession(
      session.copyWithStatus(
        CallStatus.declined,
        endedAt: DateTime.now(),
        endReason: 'declined',
      ),
    );
    state = state.copyWith(
      phase: CallPhase.ended,
      session: session,
      statusLabel: 'Declined',
    );
  }

  Future<void> endCall({String reason = 'ended'}) async {
    if (_ending) return;
    _ending = true;

    final session = state.session;
    _ringTimeout?.cancel();
    _elapsedTimer?.cancel();

    try {
      if (session != null && !session.status.isTerminal) {
        await _repository.updateStatus(
          callId: session.id,
          status: CallStatus.ended,
          endedAt: DateTime.now(),
          endReason: reason,
        );
      }
    } catch (e) {
      debugPrint('endCall status update failed: $e');
    }

    await _webrtc.dispose();
    await _sessionSub?.cancel();
    await _iceSub?.cancel();

    final latest = session == null
        ? null
        : await _repository.getCall(session.id) ?? session;

    if (latest != null) {
      await _saveHistoryForSession(
        latest.copyWithStatus(
          CallStatus.ended,
          endedAt: latest.endedAt ?? DateTime.now(),
          endReason: reason,
        ),
      );
    }

    state = state.copyWith(
      phase: CallPhase.ended,
      statusLabel: 'Call ended',
      session: latest,
      isReconnecting: false,
    );
    _ending = false;
  }

  Future<void> toggleMute() async {
    final next = !state.isMuted;
    await _webrtc.setMuted(next);
    state = state.copyWith(isMuted: next);
  }

  Future<void> toggleSpeaker() async {
    final next = !state.isSpeakerOn;
    await _webrtc.setSpeaker(next);
    state = state.copyWith(isSpeakerOn: next);
  }

  Future<void> toggleCamera() async {
    if (!state.isVideo) return;
    final next = !state.isCameraEnabled;
    await _webrtc.setCameraEnabled(next);
    state = state.copyWith(
      isCameraEnabled: next,
      mediaRevision: state.mediaRevision + 1,
    );
  }

  Future<void> switchCamera() async {
    if (!state.isVideo || !state.isCameraEnabled) return;
    await _webrtc.switchCamera();
    state = state.copyWith(mediaRevision: state.mediaRevision + 1);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void resetToIdle() {
    state = const CallUiState();
  }

  void presentIncoming(CallSession session) {
    if (state.phase != CallPhase.idle && state.phase != CallPhase.ended) {
      return;
    }
    state = state.copyWith(
      phase: CallPhase.ringingIncoming,
      session: session,
      isOutgoing: false,
      statusLabel: session.isVideo ? 'Incoming video call' : 'Incoming call',
      clearError: true,
    );
  }

  Future<bool> _ensureMicPermission({required bool forVideo}) async {
    final permission = await _micPermission.ensureGranted();
    if (permission == MicrophonePermissionResult.granted) return true;
    state = state.copyWith(
      errorMessage: permission == MicrophonePermissionResult.permanentlyDenied
          ? 'Microphone permission is permanently denied. Enable it in Settings.'
          : forVideo
              ? 'Microphone permission is required for video calls.'
              : 'Microphone permission is required for voice calls.',
    );
    return false;
  }

  Future<bool> _ensureCameraPermission() async {
    final permission = await _cameraPermission.ensureGranted();
    if (permission == CameraPermissionResult.granted) return true;
    state = state.copyWith(
      errorMessage: permission == CameraPermissionResult.permanentlyDenied
          ? 'Camera permission is permanently denied. Enable it in Settings.'
          : 'Camera permission is required for video calls.',
    );
    return false;
  }

  Future<void> _initializeMedia({
    required String callId,
    required String localUserId,
    required bool enableVideo,
  }) {
    return _webrtc.initialize(
      enableVideo: enableVideo,
      onIceCandidate: (candidate) {
        return _repository.addIceCandidate(
          callId: callId,
          fromUserId: localUserId,
          candidate: candidate,
        );
      },
      onConnected: _onMediaConnected,
      onReconnecting: _onMediaReconnecting,
      onConnectionFailed: _onMediaFailed,
      onMediaChanged: () {
        if (!mounted) return;
        state = state.copyWith(mediaRevision: state.mediaRevision + 1);
      },
    );
  }

  void _listenToSession(String callId, String localUserId) {
    _sessionSub?.cancel();
    _sessionSub = _repository.watchCall(callId).listen((session) async {
      if (session == null) return;

      state = state.copyWith(session: session);

      if (session.status == CallStatus.declined ||
          session.status == CallStatus.missed ||
          session.status == CallStatus.timeout ||
          session.status == CallStatus.failed) {
        await _webrtc.dispose();
        _ringTimeout?.cancel();
        _elapsedTimer?.cancel();
        await _saveHistoryForSession(session);
        state = state.copyWith(
          phase: CallPhase.ended,
          statusLabel: _labelForStatus(session.status),
          isReconnecting: false,
        );
        return;
      }

      if (session.status == CallStatus.ended) {
        await _webrtc.dispose();
        _ringTimeout?.cancel();
        _elapsedTimer?.cancel();
        await _saveHistoryForSession(session);
        state = state.copyWith(
          phase: CallPhase.ended,
          statusLabel: 'Call ended',
          isReconnecting: false,
        );
        return;
      }

      if (session.isCaller(localUserId) &&
          session.answerSdp != null &&
          session.answerSdp!.isNotEmpty &&
          state.phase == CallPhase.dialing) {
        state = state.copyWith(
          phase: CallPhase.connecting,
          statusLabel: 'Connecting...',
        );
        try {
          await _webrtc.setRemoteAnswer(session.answerSdp!);
          await _repository.updateStatus(
            callId: callId,
            status: CallStatus.connecting,
          );
        } catch (e, st) {
          debugPrint('setRemoteAnswer failed: $e\n$st');
          await endCall(reason: 'network_failure');
          state = state.copyWith(
            errorMessage: 'Network failure while connecting the call.',
          );
        }
      }
    }, onError: (Object error, StackTrace stackTrace) {
      debugPrint('watchCall stream error: $error\n$stackTrace');
      state = state.copyWith(
        errorMessage: 'Call connection interrupted. Please try again.',
        statusLabel: 'Connection error',
      );
    });
  }

  void _listenToIce(String callId, String localUserId) {
    _iceSub?.cancel();
    _iceSub = _repository
        .watchIceCandidates(callId: callId, forUserId: localUserId)
        .listen((candidates) async {
      for (final candidate in candidates) {
        final key =
            '${candidate['candidate']}_${candidate['sdpMid']}_${candidate['sdpMLineIndex']}';
        if (_appliedCandidates.contains(key)) continue;
        _appliedCandidates.add(key);
        try {
          await _webrtc.addRemoteCandidate(candidate);
        } catch (e) {
          debugPrint('addRemoteCandidate failed: $e');
        }
      }
    }, onError: (Object error, StackTrace stackTrace) {
      debugPrint('watchIceCandidates stream error: $error\n$stackTrace');
    });
  }

  void _startRingTimeout(String callId) {
    _ringTimeout?.cancel();
    _ringTimeout = Timer(const Duration(seconds: 30), () async {
      final session = state.session;
      if (session == null || session.id != callId) return;
      if (state.phase == CallPhase.connected ||
          state.phase == CallPhase.connecting) {
        return;
      }
      if (session.status.isTerminal) return;

      await _repository.updateStatus(
        callId: callId,
        status: CallStatus.timeout,
        endedAt: DateTime.now(),
        endReason: 'no_answer',
      );
      await _webrtc.dispose();
      final latest = await _repository.getCall(callId);
      if (latest != null) {
        await _saveHistoryForSession(latest);
      }
      state = state.copyWith(
        phase: CallPhase.ended,
        statusLabel: 'No Answer',
        session: latest,
        errorMessage: 'No Answer. The receiver did not pick up.',
      );
    });
  }

  void _onMediaConnected() {
    _ringTimeout?.cancel();
    final wasConnected = state.phase == CallPhase.connected;
    if (!wasConnected) {
      _connectedAt ??= DateTime.now();
    }
    state = state.copyWith(
      phase: CallPhase.connected,
      statusLabel: wasConnected || state.isReconnecting
          ? 'Reconnected'
          : 'Connected',
      isReconnecting: false,
      elapsed: wasConnected
          ? state.elapsed
          : Duration.zero,
    );

    final callId = state.session?.id;
    if (callId != null && !wasConnected) {
      unawaited(
        _repository.updateStatus(
          callId: callId,
          status: CallStatus.connected,
          startedAt: _connectedAt,
        ),
      );
    }

    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final started = _connectedAt;
      if (started == null) return;
      state = state.copyWith(elapsed: DateTime.now().difference(started));
    });
  }

  void _onMediaReconnecting() {
    if (state.phase != CallPhase.connected &&
        state.phase != CallPhase.connecting) {
      return;
    }
    state = state.copyWith(
      isReconnecting: true,
      statusLabel: 'Reconnecting...',
    );
  }

  void _onMediaFailed(String message) {
    unawaited(endCall(reason: 'network_failure'));
    state = state.copyWith(errorMessage: message, isReconnecting: false);
  }

  Future<void> _saveHistoryForSession(CallSession session) async {
    if (state.historySaved) return;
    final currentUser = _ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    final isCaller = session.isCaller(currentUser.uid);
    final startedAt = session.startedAt ?? session.createdAt;
    final endedAt = session.endedAt ?? DateTime.now();
    final durationSeconds = session.startedAt != null && session.endedAt != null
        ? session.endedAt!.difference(session.startedAt!).inSeconds
        : state.elapsed.inSeconds;

    final entry = CallHistoryEntry(
      id: session.id,
      callId: session.id,
      callerId: session.callerId,
      receiverId: session.receiverId,
      peerId: session.peerIdFor(currentUser.uid),
      peerName: session.peerNameFor(currentUser.uid),
      peerPhotoUrl: session.peerPhotoFor(currentUser.uid),
      direction: isCaller ? CallDirection.outgoing : CallDirection.incoming,
      status: session.status,
      callType: session.callType,
      durationSeconds: durationSeconds.clamp(0, 24 * 60 * 60),
      createdAt: session.createdAt,
      startedAt: startedAt,
      endedAt: endedAt,
    );

    try {
      await _repository.saveCallHistory(
        userId: currentUser.uid,
        entry: entry,
      );

      final peerEntry = CallHistoryEntry(
        id: session.id,
        callId: session.id,
        callerId: session.callerId,
        receiverId: session.receiverId,
        peerId: currentUser.uid,
        peerName: currentUser.name,
        peerPhotoUrl:
            currentUser.photoUrl.isEmpty ? null : currentUser.photoUrl,
        direction: isCaller ? CallDirection.incoming : CallDirection.outgoing,
        status: session.status,
        callType: session.callType,
        durationSeconds: entry.durationSeconds,
        createdAt: session.createdAt,
        startedAt: startedAt,
        endedAt: endedAt,
      );
      await _repository.saveCallHistory(
        userId: session.peerIdFor(currentUser.uid),
        entry: peerEntry,
      );

      state = state.copyWith(historySaved: true);
    } catch (e) {
      debugPrint('saveCallHistory failed: $e');
    }
  }

  String _labelForStatus(CallStatus status) {
    switch (status) {
      case CallStatus.declined:
        return 'Declined';
      case CallStatus.missed:
        return 'Missed';
      case CallStatus.timeout:
        return 'No Answer';
      case CallStatus.failed:
        return 'Failed';
      case CallStatus.ended:
        return 'Call ended';
      default:
        return status.value;
    }
  }

  void _resetTransientState() {
    _ending = false;
    _appliedCandidates.clear();
    _connectedAt = null;
    _ringTimeout?.cancel();
    _elapsedTimer?.cancel();
    unawaited(_sessionSub?.cancel() ?? Future<void>.value());
    unawaited(_iceSub?.cancel() ?? Future<void>.value());
  }

  @override
  void dispose() {
    _ringTimeout?.cancel();
    _elapsedTimer?.cancel();
    _sessionSub?.cancel();
    _iceSub?.cancel();
    unawaited(_webrtc.dispose());
    super.dispose();
  }
}

extension on CallSession {
  CallSession copyWithStatus(
    CallStatus status, {
    DateTime? endedAt,
    String? endReason,
  }) {
    return CallSession(
      id: id,
      conversationId: conversationId,
      callerId: callerId,
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverPhotoUrl: receiverPhotoUrl,
      callType: callType,
      status: status,
      createdAt: createdAt,
      offerSdp: offerSdp,
      answerSdp: answerSdp,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      endReason: endReason ?? this.endReason,
    );
  }
}
