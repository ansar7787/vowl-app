import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/core/utils/tts_error_notifier.dart';
import 'package:vowl/core/utils/tts_text_cleaner.dart';
import 'package:vowl/core/utils/tts_voice_helper.dart';

/// Status of the underlying TTS synthesis engine.
enum TtsEngineStatus {
  /// Engine initialized and ready to speak.
  ready,

  /// No TTS engine installed on device.
  noEngine,

  /// Engine exists but initialization failed.
  initFailed,

  /// Still initializing — not yet determined.
  initializing,
}

/// Abstract contract defining the Text-To-Speech (TTS) synthesis engine.
///
/// Decouples audio output speech integrations from the calling layouts and services, satisfying DIP.
abstract class TtsService {
  /// Factory mapping constructor supporting seamless backwards compatibility for callers.
  factory TtsService() = TtsServiceImpl;

  /// Synthesizes text aloud using native speech synthesis engines.
  Future<void> speak(
    String text, {
    double? rate,
    String? locale,
    List<int>? pauseMarkers,
    TtsVoicePreset? forcedPreset,
    bool isKids = false,
  });

  /// Aborts active audio speech outputs immediately.
  Future<void> stop();

  /// Releases the TTS engine and all associated platform resources.
  Future<void> dispose();

  /// Reloads active voice calibration according to saved user preferences.
  Future<void> reloadVoice();

  /// True if TTS is actively synthesizing or speaking.
  bool get isSpeaking;

  /// Listenable stream/notifier of active speaking status for UI components.
  ValueListenable<bool> get isSpeakingNotifier;

  /// Current engine readiness status.
  TtsEngineStatus get engineStatus;

  /// Speaks a voice sample for the given [preset] in a preview context.
  /// Handles engine calibration, utterance lifecycle tracking, and invokes
  /// [onStart], [onDone], and [onError] deterministically without UI heuristics.
  Future<void> previewPreset(
    TtsVoicePreset preset, {
    void Function()? onStart,
    void Function()? onDone,
    void Function(dynamic error)? onError,
  });

  /// Attaches a word-level progress handler (for phonics, karaoke, or speech highlighting).
  void setWordCallback(void Function(String word)? callback);

  /// Speaks [text] at normal conversational speed, pauses, and then repeats
  /// it at slow speed for comparative pronunciation and phoneme analysis.
  Future<void> speakComparison(
    String text, {
    double normalRate = 0.8,
    double slowRate = 0.32,
  });
}

/// Concrete high-performance implementation of [TtsService] integrating with the `flutter_tts` package.
class TtsServiceImpl implements TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  SharedPreferences? _prefs;
  late final Future<void> _initFuture;

  bool _isSpeaking = false;
  int _activeSessionId = 0;
  void Function(String word)? _wordCallback;
  Timer? _watchdogTimer;
  TtsVoicePreset? _activeEnginePreset;
  TtsEngineStatus _engineStatus = TtsEngineStatus.initializing;

  final ValueNotifier<bool> _isSpeakingNotifier = ValueNotifier<bool>(false);

  TtsServiceImpl() {
    _initFuture = _initTts();
  }

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  ValueListenable<bool> get isSpeakingNotifier => _isSpeakingNotifier;

  @override
  TtsEngineStatus get engineStatus => _engineStatus;

  void _updateSpeakingState(bool speaking) {
    _isSpeaking = speaking;
    if (_isSpeakingNotifier.value != speaking) {
      _isSpeakingNotifier.value = speaking;
    }
  }

  @override
  void setWordCallback(void Function(String word)? callback) {
    _wordCallback = callback;
  }

  Future<void> _initTts() async {
    try {
      // Check if a TTS engine is actually installed on the device
      final dynamic isAvailable = await _flutterTts.isLanguageAvailable(
        'en-US',
      );
      if (isAvailable == false || isAvailable == 0) {
        _engineStatus = TtsEngineStatus.noEngine;
        TtsErrorNotifier.instance.report(TtsErrorType.noEngine);
        sl<AppLogger>().warning(
          'TtsService: No TTS engine available on this device',
          tag: 'TTS',
        );
        return;
      }

      // Warm up voices cache immediately to avoid any initial preview delay
      await TtsVoiceHelper.warmUpVoices(_flutterTts);

      final preset = await TtsVoiceHelper.getSavedPreset();
      _activeEnginePreset = preset;
      await TtsVoiceHelper.applyPresetToTts(
        _flutterTts,
        preset: preset,
        isKids: false,
      );

      _setupDefaultHandlers();

      // Cache SharedPreferences in memory to evaluate app mute state instantly without circular references
      _prefs = await SharedPreferences.getInstance();
      _engineStatus = TtsEngineStatus.ready;
    } catch (e) {
      _engineStatus = TtsEngineStatus.initFailed;
      TtsErrorNotifier.instance.report(TtsErrorType.initFailed);
      sl<AppLogger>().error(
        'TtsService: Configuration initialization error',
        error: e,
      );
    }
  }

  void _setupDefaultHandlers() {
    _flutterTts.setStartHandler(() {
      _updateSpeakingState(true);
    });

    _flutterTts.setCompletionHandler(() {
      _watchdogTimer?.cancel();
      _updateSpeakingState(false);
    });

    _flutterTts.setCancelHandler(() {
      _watchdogTimer?.cancel();
      _updateSpeakingState(false);
    });

    _flutterTts.setErrorHandler((dynamic msg) {
      _watchdogTimer?.cancel();
      _updateSpeakingState(false);
      sl<AppLogger>().warning('TtsService native error: $msg', tag: 'TTS');
    });

    _flutterTts.setProgressHandler((text, start, end, word) {
      _wordCallback?.call(word);
    });
  }

  @override
  Future<void> reloadVoice() async {
    await _initFuture;
    _watchdogTimer?.cancel();
    _activeSessionId++;
    _setupDefaultHandlers();
    try {
      final preset = await TtsVoiceHelper.getSavedPreset();
      _activeEnginePreset = preset;
      await TtsVoiceHelper.applyPresetToTts(
        _flutterTts,
        preset: preset,
        isKids: false,
      );
    } catch (e) {
      sl<AppLogger>().error(
        'TtsService: Error reloading voice preset',
        error: e,
      );
    }
  }

  @override
  Future<void> previewPreset(
    TtsVoicePreset preset, {
    void Function()? onStart,
    void Function()? onDone,
    void Function(dynamic error)? onError,
  }) async {
    await _initFuture;
    _watchdogTimer?.cancel();
    final sessionId = ++_activeSessionId;

    try {
      await _flutterTts.stop();
    } catch (_) {}

    if (sessionId != _activeSessionId) return;

    try {
      _activeEnginePreset = null;
      await TtsVoiceHelper.applyPresetToTts(
        _flutterTts,
        preset: preset,
        isKids: preset == TtsVoicePreset.friendlyTeacher,
      );

      if (sessionId != _activeSessionId) return;

      final sample = TtsVoiceHelper.getSampleSentence(preset);

      _flutterTts.setStartHandler(() {
        if (sessionId == _activeSessionId) {
          _updateSpeakingState(true);
          onStart?.call();
        }
      });

      void handleDone() {
        if (sessionId == _activeSessionId) {
          _watchdogTimer?.cancel();
          _updateSpeakingState(false);
          _activeEnginePreset = null;
          _setupDefaultHandlers();
          onDone?.call();
        }
      }

      _flutterTts.setCompletionHandler(handleDone);
      _flutterTts.setCancelHandler(handleDone);
      _flutterTts.setErrorHandler((dynamic err) {
        if (sessionId == _activeSessionId) {
          _watchdogTimer?.cancel();
          _updateSpeakingState(false);
          _activeEnginePreset = null;
          _setupDefaultHandlers();
          onError?.call(err);
          onDone?.call();
        }
      });

      // Defensive hardware watchdog: fires ONLY if Android OEM drops onDone event completely
      _watchdogTimer = Timer(const Duration(seconds: 10), () {
        if (sessionId == _activeSessionId && _isSpeaking) {
          sl<AppLogger>().debug(
            'TtsService: Watchdog auto-cleared preview state',
          );
          handleDone();
        }
      });

      await _flutterTts.speak(sample);
    } catch (e) {
      if (sessionId == _activeSessionId) {
        _watchdogTimer?.cancel();
        _updateSpeakingState(false);
        _activeEnginePreset = null;
        _setupDefaultHandlers();
        onError?.call(e);
        onDone?.call();
      }
    }
  }

  @override
  Future<void> speak(
    String text, {
    double? rate,
    String? locale,
    List<int>? pauseMarkers,
    TtsVoicePreset? forcedPreset,
    bool isKids = false,
  }) async {
    if (text.isEmpty) return;

    await _initFuture;

    if (_engineStatus != TtsEngineStatus.ready) {
      sl<AppLogger>().warning(
        'TtsService: Cannot speak — engine status: $_engineStatus',
        tag: 'TTS',
      );
      return;
    }

    // Evaluate if the application is muted dynamically from local cache (zero circular dependency on SoundService)
    final bool isMuted = !(_prefs?.getBool('sound_enabled') ?? true);
    if (isMuted) return;

    // Clean emojis and symbols from text for pristine phonetic engine results.
    String cleanText = TtsTextCleaner.clean(text);

    if (cleanText.isEmpty) return;

    // Apply pause markers using natural punctuation (commas) instead of SSML
    // tags, because many device TTS engines don't support SSML and would
    // read literal "<speak>" and "<break>" tags aloud.
    if (pauseMarkers != null && pauseMarkers.isNotEmpty) {
      final words = cleanText.split(' ');
      final StringBuffer builder = StringBuffer();
      for (int i = 0; i < words.length; i++) {
        builder.write(words[i]);
        if (pauseMarkers.contains(i) && i != words.length - 1) {
          // Natural comma pause — universally supported by all TTS engines
          builder.write(', ');
        } else if (i != words.length - 1) {
          builder.write(' ');
        }
      }
      cleanText = builder.toString();
    }

    try {
      final targetPreset =
          forcedPreset ?? await TtsVoiceHelper.getSavedPreset();
      if (_activeEnginePreset != targetPreset || isKids || locale != null) {
        await TtsVoiceHelper.applyPresetToTts(
          _flutterTts,
          preset: targetPreset,
          isKids: isKids,
          explicitLocale: locale,
        );
        // Invalidate cache if a custom foreign locale was applied, ensuring subsequent
        // English calls restore the saved voice preset seamlessly.
        _activeEnginePreset = (isKids || locale != null) ? null : targetPreset;
      }

      if (locale != null) {
        final dynamic isAvailable = await _flutterTts.isLanguageAvailable(
          locale,
        );
        final bool canSpeakLocale = isAvailable == 1 || isAvailable == true;
        if (canSpeakLocale) {
          await _flutterTts.setLanguage(locale);
        } else {
          sl<AppLogger>().warning(
            'TTS locale "$locale" not supported on this device engine, using default voice.',
            tag: 'TTS',
          );
        }
      }
      if (rate != null) {
        await _flutterTts.setSpeechRate(rate);
      }
      final estimatedSeconds = (cleanText.length / 5).ceil() + 3;
      final timeoutDuration = Duration(seconds: estimatedSeconds.clamp(3, 45));

      final result = await _flutterTts
          .speak(cleanText)
          .timeout(
            timeoutDuration,
            onTimeout: () {
              sl<AppLogger>().error(
                'TtsService: TTS Engine timed out (crashed/unbound)',
              );
              // CRITICAL: Actually stop the engine on timeout — previously
              // the timeout returned 0 but left the engine running silently.
              _updateSpeakingState(false);
              _watchdogTimer?.cancel();
              _flutterTts.stop();
              TtsErrorNotifier.instance.report(TtsErrorType.timeout);
              return 0;
            },
          );
      if (result == 0) {
        // Android TTS returns 0 (TextToSpeech.ERROR) when an utterance is interrupted
        // by stop(), replaced by a new utterance, or preempted by navigation.
        if (_isSpeaking) {
          sl<AppLogger>().warning(
            'TtsService: Utterance was interrupted, stopped, or skipped by the engine.',
            tag: 'TTS',
          );
        }
        return;
      }
    } catch (e) {
      sl<AppLogger>().error('TtsService: Speech execution error', error: e);
      TtsErrorNotifier.instance.report(TtsErrorType.speakFailed);
    }
  }

  @override
  Future<void> speakComparison(
    String text, {
    double normalRate = 0.8,
    double slowRate = 0.32,
  }) async {
    final clean = TtsTextCleaner.clean(text);
    if (clean.isEmpty) return;

    await stop();
    final sessionId = _activeSessionId;

    final firstCompleter = Completer<void>();
    _flutterTts.setCompletionHandler(() {
      if (!firstCompleter.isCompleted) firstCompleter.complete();
    });
    _flutterTts.setErrorHandler((_) {
      if (!firstCompleter.isCompleted) firstCompleter.complete();
    });

    await speak(clean, rate: normalRate);

    // Wait for first utterance to finish or safety timeout
    await firstCompleter.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );

    if (sessionId != _activeSessionId) return;

    // Natural inter-utterance pause
    await Future.delayed(const Duration(milliseconds: 500));
    if (sessionId != _activeSessionId) return;

    _setupDefaultHandlers();
    await speak(clean, rate: slowRate);
  }

  @override
  Future<void> stop() async {
    _watchdogTimer?.cancel();
    _activeSessionId++;
    _updateSpeakingState(false);
    _setupDefaultHandlers();
    try {
      await _flutterTts.stop();
    } catch (e) {
      sl<AppLogger>().error('TtsService: Stop execution error', error: e);
    }
  }

  @override
  Future<void> dispose() async {
    _watchdogTimer?.cancel();
    _activeSessionId++;
    _updateSpeakingState(false);
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
