import 'package:flutter/foundation.dart' show debugPrint, VoidCallback;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// Abstract contract defining Text-To-Speech (TTS) and Speech-To-Text (STT) services.
///
/// Decouples voice components from calling speaking pages/BLoCs,
/// satisfying the Dependency Inversion Principle.
abstract class SpeechService {
  /// Factory mapping constructor supporting seamless backwards compatibility for callers.
  factory SpeechService() = SpeechServiceImpl;

  /// Gets current audio playback state.
  bool get isPlaying;

  /// Gets current microphone listening state.
  bool get isListening;

  /// Registers a word callback callback to track Karaoke progress.
  void setWordCallback(Function(String)? callback);

  /// Sets text-to-speech presentation rate speed.
  Future<void> setSpeechRate(double rate);

  /// Speaks a phrase aloud.
  Future<void> speak(
    String text, {
    double rate = 0.5,
    String locale = "en-US",
  });

  /// Stops all active audio outputs and listening sessions.
  Future<void> stop();

  /// Requests permissions and registers speech recognition listeners.
  Future<bool> initializeStt();

  /// Listens continuously for user speaking outputs.
  void listen({
    required Function(String) onResult,
    required VoidCallback onDone,
  });
}

/// Concrete implementation of [SpeechService] integrating with FlutterTts and SpeechToText.
class SpeechServiceImpl implements SpeechService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  
  bool _isSttInitialized = false;
  bool _isPlaying = false;
  VoidCallback? _onDoneCallback;
  Function(String)? _onWordCallback;

  SpeechServiceImpl() {
    _initTts();
  }

  void _initTts() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5); // Better default for learners
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Track playback states safely
      _tts.setStartHandler(() {
        _isPlaying = true;
      });
      _tts.setCompletionHandler(() {
        _isPlaying = false;
      });
      _tts.setErrorHandler((_) {
        _isPlaying = false;
      });
      _tts.setCancelHandler(() {
        _isPlaying = false;
      });

      // Karaoke Progress Tracking
      _tts.setProgressHandler((text, start, end, word) {
        _onWordCallback?.call(word);
      });
    } catch (e) {
      debugPrint('SpeechService: TTS configuration initialization error: $e');
    }
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  bool get isListening => _stt.isListening;

  @override
  void setWordCallback(Function(String)? callback) {
    _onWordCallback = callback;
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  @override
  Future<void> speak(
    String text, {
    double rate = 0.5,
    String locale = "en-US",
  }) async {
    try {
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(rate);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('SpeechService: TTS speech execution error: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
      await _stt.stop();
    } catch (e) {
      debugPrint('SpeechService: Speech stop execution error: $e');
    }
  }

  @override
  Future<bool> initializeStt() async {
    if (_isSttInitialized) return true;

    try {
      var status = await Permission.microphone.status;
      if (status.isDenied) {
        status = await Permission.microphone.request();
      }

      if (status.isPermanentlyDenied) {
        openAppSettings();
        return false;
      }

      if (!status.isGranted) return false;

      _isSttInitialized = await _stt.initialize(
        onError: (val) => debugPrint('SpeechService: STT Error: $val'),
        onStatus: (status) {
          debugPrint('SpeechService: STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            _onDoneCallback?.call();
            _onDoneCallback = null;
          }
        },
      );
      return _isSttInitialized;
    } catch (e) {
      debugPrint('SpeechService: STT initialization exception: $e');
      return false;
    }
  }

  @override
  void listen({
    required Function(String) onResult,
    required VoidCallback onDone,
  }) async {
    _onDoneCallback = onDone;
    if (!_isSttInitialized) {
      bool ok = await initializeStt();
      if (!ok) return;
    }

    try {
      await _stt.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 15), // Highly patient for learners
        // ignore: deprecated_member_use
        partialResults: true,
        // ignore: deprecated_member_use
        listenMode: ListenMode.dictation, // Continuous speech shadowing support
      );
    } catch (e) {
      debugPrint('SpeechService: STT listening exception: $e');
    }
  }
}
