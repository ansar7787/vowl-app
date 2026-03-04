import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _isSttInitialized = false;
  bool _isPlaying = false;
  VoidCallback? _onDoneCallback;

  bool get isPlaying => _isPlaying;

  SpeechService() {
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5); // Better for learners
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Track playback state
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
  }

  Function(String)? _onWordCallback;

  void setWordCallback(Function(String)? callback) {
    _onWordCallback = callback;
  }

  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  Future<void> speak(
    String text, {
    double rate = 0.5,
    String locale = "en-US",
  }) async {
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(rate);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    await _stt.stop();
  }

  Future<bool> initializeStt() async {
    if (_isSttInitialized) return true;

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
      onError: (val) => debugPrint('STT Error: $val'),
      onStatus: (status) {
        debugPrint('STT Status: $status');
        if (status == 'done' || status == 'notListening') {
          _onDoneCallback?.call();
          _onDoneCallback = null;
        }
      },
    );
    return _isSttInitialized;
  }

  void listen({
    required Function(String) onResult,
    required VoidCallback onDone,
  }) async {
    _onDoneCallback = onDone;
    if (!_isSttInitialized) {
      bool ok = await initializeStt();
      if (!ok) return;
    }

    await _stt.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 15), // Highly patient for learners
      // ignore: deprecated_member_use
      partialResults: true,
      // ignore: deprecated_member_use
      listenMode:
          ListenMode.dictation, // Better for continuous speech/shadowing
    );
  }

  bool get isListening => _stt.isListening;
}

typedef VoidCallback = void Function();
