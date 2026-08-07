import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart';

abstract class AudioRecordingService {
  factory AudioRecordingService() = AudioRecordingServiceImpl;

  Future<bool> hasPermission();
  Future<bool> startRecording();
  Future<String?> stopRecording();
  Future<void> dispose();
  bool get isRecording;
}

class AudioRecordingServiceImpl implements AudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentPath;

  @override
  bool get isRecording => _isRecording;

  @override
  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  @override
  Future<bool> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory tempDir = await getTemporaryDirectory();
        final String path =
            '${tempDir.path}/vowl_accent_eval_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _currentPath = path;

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc, // High quality, low latency for speech
            sampleRate: 44100,
          ),
          path: path,
        );
        _isRecording = true;
        return true;
      }
    } catch (e) {
      sl<AppLogger>().error(
        'AudioRecordingService: Start recording error',
        error: e,
      );
    }
    return false;
  }

  @override
  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      return path ?? _currentPath;
    } catch (e) {
      sl<AppLogger>().error(
        'AudioRecordingService: Stop recording error',
        error: e,
      );
      _isRecording = false;
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    await _audioRecorder.dispose();
  }
}
