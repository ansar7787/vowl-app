import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:audioplayers/audioplayers.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Service providing sound effects and audio playback controls tailored for kids games.
class KidsAudioService {
  final AudioPlayer _sfxPlayer = AudioPlayer();

  static const String _sfxKey = "is_kids_sfx_enabled";

  /// Creates a [KidsAudioService] instance.
  KidsAudioService() {
    _initAudio();
  }

  Future<void> _initAudio() async {
    // SFX init if needed
  }

  /// Whether sound effects are currently enabled.
  Future<bool> isSfxEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final globalEnabled = prefs.getBool('sound_enabled') ?? true;
    final gameSoundsEnabled = prefs.getBool('game_sounds_enabled') ?? true;
    if (!globalEnabled || !gameSoundsEnabled) return false;
    return prefs.getBool(_sfxKey) ?? true;
  }

  /// Sets whether kids sound effects should be enabled.
  Future<void> setSfxEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, enabled);
  }

  /// Plays the celebration success sound effect with pitch scaling for combo step.
  Future<void> playSuccessSFX({int comboStep = 1}) async {
    if (!(await isSfxEnabled())) return;
    try {
      await _sfxPlayer.stop();
      final double rate = comboStep == 2 ? 1.12 : (comboStep >= 3 ? 1.25 : 1.0);
      await _sfxPlayer.setPlaybackRate(rate);
      await _sfxPlayer.play(AssetSource('sounds/correct.mp3'), volume: 0.85);
    } catch (e) {
      di.sl<AppLogger>().warning("Kids SFX Success Error: $e", tag: 'KidsZone');
    }
  }

  /// Plays the failure sound effect.
  Future<void> playFailureSFX() async {
    if (!(await isSfxEnabled())) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setPlaybackRate(1.0);
      await _sfxPlayer.play(AssetSource('sounds/wrong.mp3'), volume: 0.85);
    } catch (e) {
      di.sl<AppLogger>().warning("Kids SFX Failure Error: $e", tag: 'KidsZone');
    }
  }

  /// Plays the level completion fanfare sound effect.
  Future<void> playLevelCompleteSFX() async {
    if (!(await isSfxEnabled())) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(
        AssetSource('sounds/level_completed.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      di.sl<AppLogger>().warning(
        "Kids SFX Level Complete Error: $e",
        tag: 'KidsZone',
      );
      await playSuccessSFX();
    }
  }

  /// Disposes of the underlying audio player.
  void dispose() {
    _sfxPlayer.dispose();
  }
}
