import 'dart:async';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart';

/// Callback signature for speech recognition result events.
///
/// [candidates] contains alternative hypotheses for the entire spoken utterance,
/// ordered by confidence. The primary, highest-confidence transcription is ALWAYS [candidates.first].
///
/// NOTE: [candidates] is NOT a list of individual words in a sentence; it contains
/// alternative hypotheses for the entire spoken utterance (an N-best list).
/// Callers who want the transcribed speech should use `candidates.first`,
/// and MUST NOT do `candidates.join(' ')`.
typedef SpeechResultCallback =
    void Function(List<String> candidates, bool isFinal);

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
  ///
  /// Deprecated: Pass speech rate directly to [speak(..., rate: ...)].
  @Deprecated('Pass speech rate directly to speak(..., rate: ...)')
  Future<void> setSpeechRate(double rate);

  /// Speaks a phrase aloud.
  Future<void> speak(String text, {double rate = 0.5, String locale = "en-US"});

  /// Stops all active audio outputs and listening sessions, processing the final result.
  Future<void> stop();

  /// Immediately cancels the current listening session and forcefully releases
  /// mic resources without waiting for a final result. Critical for cleanup during long sessions.
  Future<void> cancel();

  /// Releases all platform resources held by this service.
  ///
  /// Must be called when the service is no longer needed to prevent
  /// microphone resource leaks and orphaned speech engine handles.
  Future<void> dispose();

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
    required SpeechResultCallback onResult,
    required VoidCallback onDone,
    Function(double)? onSoundLevelChange,
    String? localeId,
    Duration? pauseFor,
    ListenMode listenMode = ListenMode.dictation,
  });
}

/// Concrete implementation of [SpeechService] integrating with TtsService and SpeechToText.
class SpeechServiceImpl implements SpeechService {
  final TtsService _ttsService;
  final SpeechToText _stt = SpeechToText();

  bool _isSttInitialized = false;
  VoidCallback? _onDoneCallback;
  List<LocaleName> _availableLocales = [];

  SpeechServiceImpl({TtsService? ttsService})
    : _ttsService = ttsService ?? sl<TtsService>();

  @override
  bool get isPlaying => _ttsService.isSpeaking;

  @override
  bool get isListening => _stt.isListening;

  @override
  void setWordCallback(Function(String)? callback) {
    _ttsService.setWordCallback(
      callback != null ? (word) => callback(word) : null,
    );
  }

  @override
  @Deprecated('Pass speech rate directly to speak(..., rate: ...)')
  Future<void> setSpeechRate(double rate) async {
    // Deprecated no-op: speech rate is handled dynamically per speak call
  }

  @override
  Future<void> speak(
    String text, {
    double rate = 0.5,
    String locale = "en-US",
  }) async {
    try {
      await _ttsService.speak(text, rate: rate, locale: locale);
    } catch (e) {
      sl<AppLogger>().error(
        'SpeechService: TTS speech execution error',
        error: e,
      );
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _ttsService.stop();
      await _stt.stop();
    } catch (e) {
      sl<AppLogger>().error(
        'SpeechService: Speech stop execution error',
        error: e,
      );
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _ttsService.stop();
      await _stt.cancel(); // Force-release mic resources immediately
    } catch (e) {
      sl<AppLogger>().error(
        'SpeechService: Speech cancel execution error',
        error: e,
      );
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
      if (_isSttInitialized) {
        try {
          _availableLocales = await _stt.locales();
        } catch (_) {}
      }
      return _isSttInitialized;
    } catch (e) {
      sl<AppLogger>().error(
        'SpeechService: STT initialization exception',
        error: e,
      );
      return false;
    }
  }

  String? _resolveLocale(String? requestedLocale) {
    if (requestedLocale == null || _availableLocales.isEmpty) {
      return requestedLocale;
    }
    final reqClean = requestedLocale.trim().toLowerCase();
    final reqNormalized = reqClean.replaceAll('-', '_');

    // 1. Exact match (e.g. 'ar_SA' == 'ar_SA')
    for (final loc in _availableLocales) {
      final locId = loc.localeId.toLowerCase().replaceAll('-', '_');
      if (locId == reqNormalized) {
        return loc.localeId;
      }
    }

    // 2. Prefix / language tag match (e.g. 'ar' matches 'ar_SA', 'kn' matches 'kn_IN')
    for (final loc in _availableLocales) {
      final locId = loc.localeId.toLowerCase().replaceAll('-', '_');
      if (locId.startsWith('${reqNormalized}_') || locId == reqNormalized) {
        return loc.localeId;
      }
    }

    return requestedLocale;
  }

  @override
  Future<void> listen({
    required SpeechResultCallback onResult,
    required VoidCallback onDone,
    Function(double)? onSoundLevelChange,
    String? localeId,
    Duration? pauseFor,
    ListenMode listenMode = ListenMode.dictation,
  }) async {
    // Guard: if a previous session's callback is pending, invoke it before
    // replacing — prevents the previous caller from hanging indefinitely.
    if (_onDoneCallback != null && _stt.isListening) {
      _onDoneCallback?.call();
    }
    _onDoneCallback = onDone;
    if (!_isSttInitialized) {
      bool ok = await initializeStt();
      if (!ok) return;
    }

    // CRITICAL: Stop any active TTS before starting STT — otherwise TTS audio
    // bleeds into the microphone and corrupts speech recognition results.
    try {
      await _ttsService.stop();
    } catch (_) {}

    try {
      // Aggressively cancel any lingering zombie sessions before starting a new one
      if (_stt.isListening) {
        await _stt.cancel();
      }

      final resolvedLocale = _resolveLocale(localeId);

      await _stt.listen(
        onResult: (result) {
          final primary = result.recognizedWords.trim();
          final Set<String> candidates = {};
          if (primary.isNotEmpty) {
            candidates.add(primary);
          }
          for (final alternate in result.alternates) {
            final alt = alternate.recognizedWords.trim();
            if (alt.isNotEmpty) {
              candidates.add(alt);
            }
          }
          if (candidates.isEmpty && result.recognizedWords.isNotEmpty) {
            candidates.add(result.recognizedWords);
          }
          onResult(candidates.toList(), result.finalResult);
        },
        onSoundLevelChange: onSoundLevelChange,
        listenOptions: SpeechListenOptions(
          localeId: resolvedLocale,
          listenFor: const Duration(seconds: 45),
          pauseFor:
              pauseFor ??
              const Duration(seconds: 15), // Highly patient for learners
          partialResults: true,
          listenMode: listenMode, // Continuous speech shadowing support
        ),
      );
    } catch (e) {
      sl<AppLogger>().error('SpeechService: STT listening exception', error: e);
    }
  }

  /// Releases STT platform resources and stops any active TTS/STT sessions.
  ///
  /// Must be called when the service is no longer needed to prevent
  /// microphone resource leaks and orphaned speech engine handles.
  @override
  Future<void> dispose() async {
    try {
      _onDoneCallback = null;
      if (_stt.isListening) {
        await _stt.cancel();
      }
      await _ttsService.stop();
    } catch (e) {
      sl<AppLogger>().error('SpeechService: Error during disposal', error: e);
    }
  }
}
