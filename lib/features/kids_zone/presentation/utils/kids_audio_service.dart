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

  /// Plays the celebration success sound effect with dedicated harmonic ladder according to [comboStep].
  Future<void> playSuccessSFX({int comboStep = 1}) async {
    if (!(await isSfxEnabled())) return;
    try {
      await _sfxPlayer.stop();
      final String assetToPlay;
      if (comboStep <= 1) {
        assetToPlay = 'sounds/correct_1.mp3';
      } else if (comboStep == 2) {
        assetToPlay = 'sounds/correct_2.mp3';
      } else if (comboStep == 3) {
        assetToPlay = 'sounds/correct_3.mp3';
      } else {
        assetToPlay = 'sounds/correct_frenzy.mp3';
      }
      await _sfxPlayer.play(AssetSource(assetToPlay), volume: 0.85);
    } catch (e) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().warning(
          "Kids SFX Success Error: $e",
          tag: 'KidsZone',
        );
      }
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
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().warning(
          "Kids SFX Failure Error: $e",
          tag: 'KidsZone',
        );
      }
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
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().warning(
          "Kids SFX Level Complete Error: $e",
          tag: 'KidsZone',
        );
      }
      await playSuccessSFX();
    }
  }

  /// Plays the game over defeat sound effect.
  Future<void> playGameOverSFX() async {
    if (!(await isSfxEnabled())) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/game_over.mp3'), volume: 0.85);
    } catch (e) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().warning(
          "Kids SFX Game Over Error: $e",
          tag: 'KidsZone',
        );
      }
    }
  }

  /// Disposes of the underlying audio player.
  void dispose() {
    _sfxPlayer.dispose();
  }
}
