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
  Future<void> speak(String text, {double? rate, String? locale});

  /// Aborts active audio speech outputs immediately.
  Future<void> stop();
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
  Future<void> speak(String text, {double? rate, String? locale}) async {
    if (text.isEmpty) return;

    await _initFuture;

    // Evaluate if the application is muted dynamically from local cache (zero circular dependency on SoundService)
    final bool isMuted = !(_prefs?.getBool('sound_enabled') ?? true);
    if (isMuted) return;

    // Clean emojis and symbols from text for pristine phonetic engine results
    final cleanText = text.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
        unicode: true,
      ),
      '',
    );

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
      await _flutterTts.speak(cleanText);
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
}
