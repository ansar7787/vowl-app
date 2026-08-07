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

    // Clean emojis and symbols from text for pristine phonetic engine results.
    // BUG FIX: the original range list covered the main pictograph blocks
    // but missed several ranges that commonly appear as PART of composite
    // emoji: regional-indicator letter pairs (flag emoji, e.g. 🇺🇸 =
    // U+1F1FA U+1F1F8 - outside every range below), the zero-width joiner
    // used to combine emoji (e.g. family/profession emoji), skin-tone
    // modifiers, and variation selectors. Missing these left stray,
    // unpronounceable characters behind after stripping - the TTS engine
    // would then try to read out leftover regional-indicator letters or
    // modifier characters. Given this app ships 18 locales including
    // several with flag icons in-app (see LocaleService.supportedLocales),
    // and quest/UI copy elsewhere in this codebase routinely embeds emoji
    // in strings passed to TTS, this is a real, reachable gap, not a
    // theoretical one.
    final cleanText = text
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
        // Collapse whitespace left behind by the removals above (e.g.
        // "Great job 🎉 well done" -> "Great job  well done" would
        // otherwise read as an unnatural double pause).
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // DEFENSIVE FIX: if `text` was entirely emoji/symbols (e.g. a reaction
    // string like "🎉🎊"), `cleanText` can now legitimately end up empty.
    // Skip the platform call rather than asking the native TTS engine to
    // speak an empty string, whose behavior isn't guaranteed identical
    // across every Android/iOS TTS engine this app may run on.
    if (cleanText.isEmpty) return;

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
        throw Exception(
          "TTS Engine failed to speak (possibly unbound or crashed)",
        );
      }
    } catch (e) {
      sl<AppLogger>().error('TtsService: Speech execution error', error: e);
      rethrow;
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
