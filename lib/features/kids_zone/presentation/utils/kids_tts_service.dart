import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:flutter_tts/flutter_tts.dart';

import 'package:shared_preferences/shared_preferences.dart';

class KidsTTSService {
  final FlutterTts _flutterTts = FlutterTts();
  static const String _narrationKey = "is_kids_narration_enabled";

  KidsTTSService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    // Slightly slower and higher pitch for a "friendly" teacher voice
    await _flutterTts.setSpeechRate(0.35);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.2);
    await _flutterTts.awaitSpeakCompletion(true);
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

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    if (!(await isNarrationEnabled())) return;

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      di.sl<AppLogger>().warning("Kids TTS Error: $e", tag: 'KidsZone');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      di.sl<AppLogger>().warning("Kids TTS Error: $e", tag: 'KidsZone');
    }
  }
}
