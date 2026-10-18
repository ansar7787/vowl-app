import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/tts_text_cleaner.dart';
import 'package:vowl/core/utils/tts_voice_helper.dart';

class KidsTTSService {
  final TtsService _ttsService;
  static const String _narrationKey = "is_kids_narration_enabled";

  SharedPreferences? _prefs;

  KidsTTSService({TtsService? ttsService})
      : _ttsService = ttsService ?? di.sl<TtsService>();

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Reloads active voice calibration when user changes settings.
  Future<void> reloadVoice() async {
    try {
      await _ttsService.reloadVoice();
    } catch (e) {
      di.sl<AppLogger>().warning("Kids TTS Reload Error: $e", tag: 'KidsZone');
    }
  }

  bool get isSpeaking => _ttsService.isSpeaking;

  Future<bool> isNarrationEnabled() async {
    final prefs = await _getPrefs();
    final globalEnabled = prefs.getBool('sound_enabled') ?? true;
    if (!globalEnabled) return false;
    return prefs.getBool(_narrationKey) ?? true;
  }

  Future<void> setNarrationEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_narrationKey, enabled);
  }

  Future<bool> speak(String text, {bool force = false}) async {
    if (text.isEmpty) return false;
    if (!force && !(await isNarrationEnabled())) return false;

    // Clean emojis and decorative symbols for pure phonetic speech output
    final cleanText = TtsTextCleaner.clean(text);

    if (cleanText.isEmpty) return false;

    try {
      // Kids Zone ALWAYS enforces Friendly Teacher voice preset with warm kid cadence
      await _ttsService.speak(
        cleanText,
        forcedPreset: TtsVoicePreset.friendlyTeacher,
        isKids: true,
      );
      return true;
    } catch (e) {
      di.sl<AppLogger>().warning("Kids TTS Error: $e", tag: 'KidsZone');
      return false;
    }
  }

  /// Speaks a word, pauses, spells it letter by letter slowly, pauses, and repeats the word.
  /// Ideal for alphabet and spelling quest learning.
  Future<bool> speakWithSpelling(String word, {bool force = false}) async {
    if (word.isEmpty) return false;
    if (!force && !(await isNarrationEnabled())) return false;

    final cleanWord = TtsTextCleaner.clean(word);
    if (cleanWord.isEmpty) return false;

    // e.g. "Cat, C, A, T, Cat"
    final letters = cleanWord
        .toUpperCase()
        .split('')
        .where((c) => RegExp(r'[A-Z]').hasMatch(c))
        .join(', ');
    final speechText = '$cleanWord, $letters, $cleanWord';

    try {
      await _ttsService.speak(
        speechText,
        forcedPreset: TtsVoicePreset.friendlyTeacher,
        isKids: true,
        rate: 0.38,
      );
      return true;
    } catch (e) {
      di.sl<AppLogger>().warning(
        "Kids TTS speakWithSpelling Error: $e",
        tag: 'KidsZone',
      );
      return false;
    }
  }

  /// Speaks a letter with phonics example (e.g., "B, as in Ball").
  Future<bool> speakPhonics(
    String letter,
    String exampleWord, {
    bool force = false,
  }) async {
    if (letter.isEmpty || exampleWord.isEmpty) return false;
    if (!force && !(await isNarrationEnabled())) return false;

    final cleanLetter = TtsTextCleaner.clean(letter).toUpperCase();
    final cleanWord = TtsTextCleaner.clean(exampleWord);
    if (cleanLetter.isEmpty || cleanWord.isEmpty) return false;

    final speechText = '$cleanLetter, as in $cleanWord';

    try {
      await _ttsService.speak(
        speechText,
        forcedPreset: TtsVoicePreset.friendlyTeacher,
        isKids: true,
        rate: 0.42,
      );
      return true;
    } catch (e) {
      di.sl<AppLogger>().warning(
        "Kids TTS speakPhonics Error: $e",
        tag: 'KidsZone',
      );
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _ttsService.stop();
    } catch (e) {
      di.sl<AppLogger>().warning("Kids TTS Error: $e", tag: 'KidsZone');
    }
  }

  Future<void> dispose() async {
    try {
      await _ttsService.stop();
    } catch (_) {}
  }
}
