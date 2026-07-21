import 'dart:async';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart';

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
  Future<void> speak(String text, {double rate = 0.5, String locale = "en-US"});

  /// Stops all active audio outputs and listening sessions.
  Future<void> stop();

  /// Requests permissions and registers speech recognition listeners.
  Future<bool> initializeStt();

  /// Listens continuously for user speaking outputs.
  ///
  /// FIX: previously declared `void` while having an `async` body (the
  /// `avoid_void_async` anti-pattern) - callers could only fire-and-forget
  /// this; they had no way to `await` its completion or catch any error it
  /// threw (any uncaught exception would become an unhandled Zone error
  /// instead of something the caller could react to). Returning
  /// `Future<void>` is non-breaking for every existing call site: calling
  /// an async function and not awaiting its result is always valid Dart,
  /// so this only adds capability, in line with the explicit "void async"
  /// production-readiness audit category.
  Future<void> listen({
    required Function(List<String>) onResult,
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

  /// RACE-CONDITION FIX: matches the same fix already applied to
  /// TtsServiceImpl and SoundServiceImpl elsewhere in this codebase.
  /// `_initTts()` configures language/rate/volume/pitch AND registers the
  /// playback-state handlers (`setStartHandler`, `setCompletionHandler`,
  /// `setErrorHandler`, `setCancelHandler`, `setProgressHandler`) that
  /// `isPlaying` and the karaoke word callback depend on entirely.
  /// Previously fired from the constructor as a `void async` method with
  /// nothing awaiting it, so a `speak()` (or `stop()`/`initializeStt()`)
  /// call made in the brief window before this completed could run before
  /// those handlers were registered - `_isPlaying` would then never flip
  /// to `true` for that utterance, silently breaking any UI bound to
  /// `isPlaying`, and the karaoke word-highlight callback would silently
  /// never fire for that call. Every public method now awaits this first.
  late final Future<void> _initFuture;

  SpeechServiceImpl() {
    _initFuture = _initTts();
  }

  Future<void> _initTts() async {
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
      sl<AppLogger>().error(
        'SpeechService: TTS configuration initialization error',
        error: e,
      );
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
    await _initFuture;
    await _tts.setSpeechRate(rate);
  }

  @override
  Future<void> speak(
    String text, {
    double rate = 0.5,
    String locale = "en-US",
  }) async {
    await _initFuture;
    try {
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(rate);
      await _tts.speak(text);
    } catch (e) {
      sl<AppLogger>().error(
        'SpeechService: TTS speech execution error',
        error: e,
      );
    }
  }

  @override
  Future<void> stop() async {
    await _initFuture;
    try {
      await _tts.stop();
      await _stt.stop();
    } catch (e) {
      sl<AppLogger>().error(
        'SpeechService: Speech stop execution error',
        error: e,
      );
    }
  }

  @override
  Future<bool> initializeStt() async {
    await _initFuture;
    if (_isSttInitialized) return true;

    try {
      var status = await Permission.microphone.status;
      if (status.isDenied) {
        status = await Permission.microphone.request();
      }

      if (status.isPermanentlyDenied) {
        // FIX (CODE CLEANLINESS): explicitly mark this fire-and-forget
        // Future as intentional (matches the `unawaited()` convention
        // already used elsewhere in this codebase, e.g. curriculum_
        // service.dart / review_service.dart) rather than leaving a bare
        // discarded Future that `flutter analyze`'s unawaited_futures
        // lint would flag.
        unawaited(openAppSettings());
        return false;
      }

      if (!status.isGranted) return false;

      _isSttInitialized = await _stt.initialize(
        onError: (val) =>
            sl<AppLogger>().error('SpeechService: STT Error', error: val),
        onStatus: (status) {
          sl<AppLogger>().debug('SpeechService: STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            _onDoneCallback?.call();
            _onDoneCallback = null;
          }
        },
      );
      return _isSttInitialized;
    } catch (e) {
      sl<AppLogger>().error(
        'SpeechService: STT initialization exception',
        error: e,
      );
      return false;
    }
  }

  @override
  Future<void> listen({
    required Function(List<String>) onResult,
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
          final Set<String> candidates = {result.recognizedWords};
          for (var alternate in result.alternates) {
            candidates.add(alternate.recognizedWords);
          }
          onResult(candidates.toList());
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 15), // Highly patient for learners
          partialResults: true,
          listenMode: ListenMode.dictation, // Continuous speech shadowing support
        ),
      );
    } catch (e) {
      sl<AppLogger>().error('SpeechService: STT listening exception', error: e);
    }
  }
}
