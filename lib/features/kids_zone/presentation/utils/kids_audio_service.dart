import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:audioplayers/audioplayers.dart';

import 'package:shared_preferences/shared_preferences.dart';

class KidsAudioService {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  static const String _bgmKey = "is_kids_bgm_enabled";
  static const String _sfxKey = "is_kids_sfx_enabled";

  KidsAudioService() {
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<bool> isBgmEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final globalEnabled = prefs.getBool('sound_enabled') ?? true;
    if (!globalEnabled) return false;
    return prefs.getBool(_bgmKey) ?? true;
  }

  Future<bool> isSfxEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final globalEnabled = prefs.getBool('sound_enabled') ?? true;
    if (!globalEnabled) return false;
    return prefs.getBool(_sfxKey) ?? true;
  }

  Future<void> setBgmEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bgmKey, enabled);
    if (!enabled) {
      await stopBgm();
    }
  }

  Future<void> setSfxEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, enabled);
  }

  Future<void> startBgm() async {
    if (!(await isBgmEnabled())) return;
    try {
      if (_bgmPlayer.state == PlayerState.playing) return;
      await _bgmPlayer.setSource(AssetSource('sounds/kids_bgm.mp3'));
      await _bgmPlayer.setVolume(0.3); // Low volume for BGM
      await _bgmPlayer.resume();
    } catch (e) {
      di.sl<AppLogger>().warning("Kids BGM Error: $e", tag: 'KidsZone');
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      di.sl<AppLogger>().warning("Kids BGM Stop Error: $e", tag: 'KidsZone');
    }
  }

  Future<void> playSuccessSFX() async {
    if (!(await isSfxEnabled())) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/correct.mp3'), volume: 0.8);
    } catch (e) {
      di.sl<AppLogger>().warning("Kids SFX Success Error: $e", tag: 'KidsZone');
    }
  }

  Future<void> playFailureSFX() async {
    if (!(await isSfxEnabled())) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/wrong.mp3'), volume: 0.8);
    } catch (e) {
      di.sl<AppLogger>().warning("Kids SFX Failure Error: $e", tag: 'KidsZone');
    }
  }

  Future<void> playLevelCompleteSFX() async {
    if (!(await isSfxEnabled())) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(
        AssetSource('sounds/level_completed.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      di.sl<AppLogger>().warning("Kids SFX Level Complete Error: $e", tag: 'KidsZone');
      await playSuccessSFX();
    }
  }

  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}

