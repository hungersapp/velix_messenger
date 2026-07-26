import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VoicePlaybackStatus {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

class VoicePlaybackState {
  const VoicePlaybackState({
    this.activeMessageId,
    this.status = VoicePlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  final String? activeMessageId;
  final VoicePlaybackStatus status;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  bool isActive(String messageId) => activeMessageId == messageId;

  VoicePlaybackState copyWith({
    String? activeMessageId,
    VoicePlaybackStatus? status,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    bool clearError = false,
    bool clearActive = false,
  }) {
    return VoicePlaybackState(
      activeMessageId:
          clearActive ? null : (activeMessageId ?? this.activeMessageId),
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class VoicePlaybackController extends StateNotifier<VoicePlaybackState> {
  VoicePlaybackController() : super(const VoicePlaybackState()) {
    _positionSub = _player.onPositionChanged.listen((position) {
      if (!mounted) return;
      state = state.copyWith(position: position);
    });
    _durationSub = _player.onDurationChanged.listen((duration) {
      if (!mounted) return;
      if (duration > Duration.zero) {
        state = state.copyWith(duration: duration);
      }
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      state = state.copyWith(
        status: VoicePlaybackStatus.completed,
        position: state.duration,
      );
    });
    _stateSub = _player.onPlayerStateChanged.listen((playerState) {
      if (!mounted) return;
      switch (playerState) {
        case PlayerState.playing:
          state = state.copyWith(
            status: VoicePlaybackStatus.playing,
            clearError: true,
          );
        case PlayerState.paused:
          if (state.status != VoicePlaybackStatus.completed) {
            state = state.copyWith(status: VoicePlaybackStatus.paused);
          }
        case PlayerState.stopped:
          break;
        case PlayerState.completed:
          state = state.copyWith(status: VoicePlaybackStatus.completed);
        case PlayerState.disposed:
          break;
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<void>? _completeSub;
  StreamSubscription<PlayerState>? _stateSub;

  Future<void> toggle({
    required String messageId,
    required String mediaUrl,
    Duration? knownDuration,
  }) async {
    try {
      if (state.activeMessageId == messageId) {
        switch (state.status) {
          case VoicePlaybackStatus.playing:
            await _player.pause();
            return;
          case VoicePlaybackStatus.paused:
            await _player.resume();
            return;
          case VoicePlaybackStatus.completed:
            await _player.seek(Duration.zero);
            await _player.resume();
            return;
          case VoicePlaybackStatus.loading:
            return;
          case VoicePlaybackStatus.idle:
          case VoicePlaybackStatus.error:
            break;
        }
      }

      state = VoicePlaybackState(
        activeMessageId: messageId,
        status: VoicePlaybackStatus.loading,
        position: Duration.zero,
        duration: knownDuration ?? Duration.zero,
      );

      await _player.stop();
      await _player.play(UrlSource(mediaUrl));
    } catch (e) {
      state = state.copyWith(
        status: VoicePlaybackStatus.error,
        errorMessage: 'Unable to play this voice message.',
      );
    }
  }

  Future<void> seek(Duration position) async {
    if (state.activeMessageId == null) return;
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _player.stop();
    state = const VoicePlaybackState();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

final voicePlaybackProvider =
    StateNotifierProvider<VoicePlaybackController, VoicePlaybackState>(
  (ref) => VoicePlaybackController(),
);
