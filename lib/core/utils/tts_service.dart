import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart';

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
}

/// Concrete high-performance implementation of [TtsService] integrating with the `flutter_tts` package.
class TtsServiceImpl implements TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  SharedPreferences? _prefs;

  /// RACE-CONDITION FIX: `_initTts()` caches `SharedPreferences` asynchronously
  /// from the constructor with nothing awaiting it. The previous `speak()`
  /// read `_prefs?.getBool(...)` directly - if called before this finished,
  /// `_prefs` was still null and the null-aware fallback (`?? true`) meant
  /// speech could play even for an already-muted user, for a brief window
  /// right after app startup. `speak()` now awaits this stored Future first.
  late final Future<void> _initFuture;

  TtsServiceImpl() {
    _initFuture = _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(true);

      // Cache SharedPreferences in memory to evaluate app mute state instantly without circular references
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      sl<AppLogger>().error(
        'TtsService: Configuration initialization error',
        error: e,
      );
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
      } else {
        await _flutterTts.setLanguage("en-US");
      }
      if (rate != null) {
        await _flutterTts.setSpeechRate(rate);
      } else {
        await _flutterTts.setSpeechRate(0.4); // Default speed for learners
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
    try {
      await _flutterTts.stop();
    } catch (e) {
      sl<AppLogger>().error('TtsService: Stop execution error', error: e);
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
