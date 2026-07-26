import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecordingResult {
  const VoiceRecordingResult({
    required this.file,
    required this.duration,
  });

  final File file;
  final Duration duration;
}

class VoiceRecorderService {
  VoiceRecorderService({
    AudioRecorder? recorder,
  }) : _recorder = recorder ?? AudioRecorder();

  static const Duration maxDuration = Duration(minutes: 5);

  final AudioRecorder _recorder;

  Timer? _maxDurationTimer;
  DateTime? _startedAt;
  String? _outputPath;

  bool get isRecording => _startedAt != null;

  Duration get elapsed {
    final startedAt = _startedAt;
    if (startedAt == null) return Duration.zero;
    return DateTime.now().difference(startedAt);
  }

  Future<void> start() async {
    if (await _recorder.isRecording()) {
      await cancel();
    }

    final directory = await getTemporaryDirectory();
    final fileName =
        'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _outputPath = path.join(directory.path, fileName);

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _outputPath!,
    );

    _startedAt = DateTime.now();
    _maxDurationTimer?.cancel();
    _maxDurationTimer = Timer(maxDuration, () {
      // Caller observes elapsed and stops; timer is a safety backstop.
    });
  }

  Future<VoiceRecordingResult?> stop() async {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;

    final startedAt = _startedAt;
    final outputPath = _outputPath;
    _startedAt = null;
    _outputPath = null;

    final stoppedPath = await _recorder.stop();
    final filePath = stoppedPath ?? outputPath;
    if (filePath == null || startedAt == null) return null;

    final file = File(filePath);
    if (!await file.exists()) return null;

    var duration = DateTime.now().difference(startedAt);
    if (duration > maxDuration) {
      duration = maxDuration;
    }
    if (duration < const Duration(milliseconds: 400)) {
      await _deleteQuietly(file);
      return null;
    }

    return VoiceRecordingResult(file: file, duration: duration);
  }

  Future<void> cancel() async {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;

    final outputPath = _outputPath;
    _startedAt = null;
    _outputPath = null;

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {
      // Ignore stop errors during cancel.
    }

    if (outputPath != null) {
      await _deleteQuietly(File(outputPath));
    }
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup.
    }
  }
}
