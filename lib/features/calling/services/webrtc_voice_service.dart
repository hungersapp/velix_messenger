import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef IceCandidateHandler = FutureOr<void> Function(
  Map<String, dynamic> candidate,
);

/// Shared WebRTC media stack for voice and video calls.
class WebrtcVoiceService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  bool _muted = false;
  bool _speakerOn = true;
  bool _cameraEnabled = true;
  bool _enableVideo = false;
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];
  bool _remoteDescriptionSet = false;
  Timer? _disconnectGraceTimer;
  VoidCallback? _onConnected;
  VoidCallback? _onReconnecting;
  void Function(String message)? _onConnectionFailed;
  VoidCallback? _onMediaChanged;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  RTCVideoRenderer? get localRenderer => _localRenderer;
  RTCVideoRenderer? get remoteRenderer => _remoteRenderer;
  bool get isMuted => _muted;
  bool get isSpeakerOn => _speakerOn;
  bool get isCameraEnabled => _cameraEnabled;
  bool get isVideoEnabled => _enableVideo;

  Future<void> initialize({
    required IceCandidateHandler onIceCandidate,
    required VoidCallback onConnected,
    required void Function(String message) onConnectionFailed,
    VoidCallback? onReconnecting,
    VoidCallback? onMediaChanged,
    bool enableVideo = false,
  }) async {
    await dispose();

    _enableVideo = enableVideo;
    _cameraEnabled = enableVideo;
    _onConnected = onConnected;
    _onReconnecting = onReconnecting;
    _onConnectionFailed = onConnectionFailed;
    _onMediaChanged = onMediaChanged;

    if (enableVideo) {
      _localRenderer = RTCVideoRenderer();
      _remoteRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();
      await _remoteRenderer!.initialize();
    }

    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': enableVideo
          ? {
              'facingMode': 'user',
              'width': 640,
              'height': 480,
            }
          : false,
    });

    if (enableVideo) {
      _localRenderer!.srcObject = _localStream;
    }

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    _peerConnection!.onIceCandidate = (candidate) async {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) {
        return;
      }
      await onIceCandidate({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        if (_enableVideo && _remoteRenderer != null) {
          _remoteRenderer!.srcObject = _remoteStream;
        }
        _onMediaChanged?.call();
      }
    };

    _peerConnection!.onConnectionState = (state) {
      debugPrint('WebRTC connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _disconnectGraceTimer?.cancel();
        _onConnected?.call();
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _onReconnecting?.call();
        _disconnectGraceTimer?.cancel();
        _disconnectGraceTimer = Timer(const Duration(seconds: 8), () {
          final current = _peerConnection?.connectionState;
          if (current ==
                  RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
              current == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
            _onConnectionFailed?.call(
              'Network interruption. Unable to restore the call.',
            );
          }
        });
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _disconnectGraceTimer?.cancel();
        _onConnectionFailed?.call('Network failure during the call.');
      }
    };

    await Helper.setSpeakerphoneOn(_speakerOn);
    _onMediaChanged?.call();
  }

  Future<String> createOffer() async {
    final pc = _peerConnection;
    if (pc == null) {
      throw StateError('Peer connection is not initialized.');
    }

    final offer = await pc.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': _enableVideo ? 1 : 0,
    });
    await pc.setLocalDescription(offer);
    return offer.sdp ?? '';
  }

  Future<void> setRemoteOffer(String sdp) async {
    final pc = _peerConnection;
    if (pc == null) {
      throw StateError('Peer connection is not initialized.');
    }

    await pc.setRemoteDescription(
      RTCSessionDescription(sdp, 'offer'),
    );
    _remoteDescriptionSet = true;
    await _flushPendingRemoteCandidates();
  }

  Future<String> createAnswer() async {
    final pc = _peerConnection;
    if (pc == null) {
      throw StateError('Peer connection is not initialized.');
    }

    final answer = await pc.createAnswer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': _enableVideo ? 1 : 0,
    });
    await pc.setLocalDescription(answer);
    return answer.sdp ?? '';
  }

  Future<void> setRemoteAnswer(String sdp) async {
    final pc = _peerConnection;
    if (pc == null) {
      throw StateError('Peer connection is not initialized.');
    }

    await pc.setRemoteDescription(
      RTCSessionDescription(sdp, 'answer'),
    );
    _remoteDescriptionSet = true;
    await _flushPendingRemoteCandidates();
  }

  Future<void> addRemoteCandidate(Map<String, dynamic> data) async {
    final candidate = RTCIceCandidate(
      data['candidate'] as String?,
      data['sdpMid'] as String?,
      (data['sdpMLineIndex'] as num?)?.toInt(),
    );

    if (!_remoteDescriptionSet) {
      _pendingRemoteCandidates.add(candidate);
      return;
    }

    await _peerConnection?.addCandidate(candidate);
  }

  Future<void> setMuted(bool muted) async {
    _muted = muted;
    final tracks = _localStream?.getAudioTracks() ?? [];
    for (final track in tracks) {
      track.enabled = !muted;
    }
  }

  Future<void> setSpeaker(bool enabled) async {
    _speakerOn = enabled;
    await Helper.setSpeakerphoneOn(enabled);
  }

  Future<void> setCameraEnabled(bool enabled) async {
    if (!_enableVideo) return;
    _cameraEnabled = enabled;
    final tracks = _localStream?.getVideoTracks() ?? [];
    for (final track in tracks) {
      track.enabled = enabled;
    }
    _onMediaChanged?.call();
  }

  Future<void> switchCamera() async {
    if (!_enableVideo || !_cameraEnabled) return;
    final tracks = _localStream?.getVideoTracks() ?? [];
    if (tracks.isEmpty) return;
    await Helper.switchCamera(tracks.first);
    _onMediaChanged?.call();
  }

  Future<void> _flushPendingRemoteCandidates() async {
    for (final candidate in _pendingRemoteCandidates) {
      await _peerConnection?.addCandidate(candidate);
    }
    _pendingRemoteCandidates.clear();
  }

  Future<void> dispose() async {
    _disconnectGraceTimer?.cancel();
    _disconnectGraceTimer = null;

    try {
      final tracks = _localStream?.getTracks() ?? [];
      for (final track in tracks) {
        await track.stop();
      }
      await _localStream?.dispose();
    } catch (_) {}

    try {
      await _peerConnection?.close();
    } catch (_) {}

    try {
      await _localRenderer?.dispose();
    } catch (_) {}
    try {
      await _remoteRenderer?.dispose();
    } catch (_) {}

    _localStream = null;
    _remoteStream = null;
    _localRenderer = null;
    _remoteRenderer = null;
    _peerConnection = null;
    _pendingRemoteCandidates.clear();
    _remoteDescriptionSet = false;
    _muted = false;
    _speakerOn = true;
    _cameraEnabled = true;
    _enableVideo = false;
    _onConnected = null;
    _onReconnecting = null;
    _onConnectionFailed = null;
    _onMediaChanged = null;
  }
}
