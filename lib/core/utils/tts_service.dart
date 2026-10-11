import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/core/utils/tts_voice_helper.dart';

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
  });

  /// Aborts active audio speech outputs immediately.
  Future<void> stop();

  /// Releases the TTS engine and all associated platform resources.
  Future<void> dispose();

  /// Reloads active voice calibration according to saved user preferences.
  Future<void> reloadVoice();

  /// True if TTS is actively synthesizing or speaking.
  bool get isSpeaking;

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

  TtsServiceImpl() {
    _initFuture = _initTts();
  }

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  void setWordCallback(void Function(String word)? callback) {
    _wordCallback = callback;
  }

  Future<void> _initTts() async {
    try {
      // Warm up voices cache immediately to avoid any initial preview delay
      await TtsVoiceHelper.warmUpVoices(_flutterTts);

      final preset = await TtsVoiceHelper.getSavedPreset();
      await TtsVoiceHelper.applyPresetToTts(
        _flutterTts,
        preset: preset,
        isKids: false,
      );

      _setupDefaultHandlers();

      // Cache SharedPreferences in memory to evaluate app mute state instantly without circular references
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      sl<AppLogger>().error(
        'TtsService: Configuration initialization error',
        error: e,
      );
    }
  }

  void _setupDefaultHandlers() {
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _watchdogTimer?.cancel();
      _isSpeaking = false;
    });

    _flutterTts.setCancelHandler(() {
      _watchdogTimer?.cancel();
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler((dynamic msg) {
      _watchdogTimer?.cancel();
      _isSpeaking = false;
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
      await TtsVoiceHelper.applyPresetToTts(
        _flutterTts,
        preset: preset,
        isKids: preset == TtsVoicePreset.friendlyTeacher,
      );

      if (sessionId != _activeSessionId) return;

      final sample = TtsVoiceHelper.getSampleSentence(preset);

      _flutterTts.setStartHandler(() {
        if (sessionId == _activeSessionId) {
          _isSpeaking = true;
          onStart?.call();
        }
      });

      void handleDone() {
        if (sessionId == _activeSessionId) {
          _watchdogTimer?.cancel();
          _isSpeaking = false;
          _setupDefaultHandlers();
          onDone?.call();
        }
      }

      _flutterTts.setCompletionHandler(handleDone);
      _flutterTts.setCancelHandler(handleDone);
      _flutterTts.setErrorHandler((dynamic err) {
        if (sessionId == _activeSessionId) {
          _watchdogTimer?.cancel();
          _isSpeaking = false;
          _setupDefaultHandlers();
          onError?.call(err);
          onDone?.call();
        }
      });

      // Defensive hardware watchdog: fires ONLY if Android OEM drops onDone event completely
      _watchdogTimer = Timer(const Duration(seconds: 10), () {
        if (sessionId == _activeSessionId && _isSpeaking) {
          sl<AppLogger>().debug('TtsService: Watchdog auto-cleared preview state');
          handleDone();
        }
      });

      await _flutterTts.speak(sample);
    } catch (e) {
      if (sessionId == _activeSessionId) {
        _watchdogTimer?.cancel();
        _isSpeaking = false;
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
  }) async {
    if (text.isEmpty) return;

    await _initFuture;

    // Evaluate if the application is muted dynamically from local cache (zero circular dependency on SoundService)
    final bool isMuted = !(_prefs?.getBool('sound_enabled') ?? true);
    if (isMuted) return;

    // Clean emojis and symbols from text for pristine phonetic engine results.
    String cleanText = text
        .replaceAll(
          RegExp(
            r'[\u{1F1E6}-\u{1F1FF}\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}'
            r'\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}'
            r'\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}'
            r'\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}'
            r'\u{FE0F}\u{200D}\u{1F3FB}-\u{1F3FF}]',
            unicode: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleanText.isEmpty) return;

    // Inject native SSML tags if pause markers are provided
    if (pauseMarkers != null && pauseMarkers.isNotEmpty) {
      final words = cleanText.split(' ');
      final StringBuffer ssmlBuilder = StringBuffer('<speak>');
      for (int i = 0; i < words.length; i++) {
        ssmlBuilder.write(words[i]);
        if (pauseMarkers.contains(i) && i != words.length - 1) {
          ssmlBuilder.write(' <break time="400ms"/> ');
        } else if (i != words.length - 1) {
          ssmlBuilder.write(' ');
        }
      }
      ssmlBuilder.write('</speak>');
      cleanText = ssmlBuilder.toString();
    }

    try {
      if (locale != null) {
        await _flutterTts.setLanguage(locale);
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
              return 0;
            },
          );
      if (result == 0) {
        sl<AppLogger>().error(
          "TTS Engine failed to speak (possibly unbound or crashed)",
        );
        return;
      }
    } catch (e) {
      sl<AppLogger>().error('TtsService: Speech execution error', error: e);
    }
  }

  @override
  Future<void> stop() async {
    _watchdogTimer?.cancel();
    _activeSessionId++;
    _isSpeaking = false;
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
    _isSpeaking = false;
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
