import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/tts_voice_helper.dart';

class KidsTTSService {
  final TtsService _ttsService;
  static const String _narrationKey = "is_kids_narration_enabled";

  KidsTTSService({TtsService? ttsService})
      : _ttsService = ttsService ?? di.sl<TtsService>();

  /// Reloads active voice calibration when user changes settings.
  Future<void> reloadVoice() async {
    try {
      await _ttsService.reloadVoice();
    } catch (e) {
      di.sl<AppLogger>().warning("Kids TTS Reload Error: $e", tag: 'KidsZone');
    }
  }

  Future<bool> isNarrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final globalEnabled = prefs.getBool('sound_enabled') ?? true;
    if (!globalEnabled) return false;
    return prefs.getBool(_narrationKey) ?? true;
  }

  Future<void> setNarrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_narrationKey, enabled);
  }

  Future<bool> speak(String text, {bool force = false}) async {
    if (text.isEmpty) return false;
    if (!force && !(await isNarrationEnabled())) return false;

    // Clean emojis and decorative symbols for pure phonetic speech output
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
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

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
