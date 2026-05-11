import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint("Kids BGM Error: $e");
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint("Kids BGM Stop Error: $e");
    }
  }

  Future<void> playSuccessSFX() async {
    if (!(await isSfxEnabled())) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setSource(AssetSource('sounds/correct.mp3'));
      await _sfxPlayer.setVolume(0.8);
      await _sfxPlayer.resume();
    } catch (e) {
      debugPrint("Kids SFX Success Error: $e");
    }
  }

  Future<void> playFailureSFX() async {
    if (!(await isSfxEnabled())) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setSource(AssetSource('sounds/wrong.mp3'));
      await _sfxPlayer.setVolume(0.8);
      await _sfxPlayer.resume();
    } catch (e) {
      debugPrint("Kids SFX Failure Error: $e");
    }
  }

  Future<void> playLevelCompleteSFX() async {
    if (!(await isSfxEnabled())) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setSource(AssetSource('sounds/level_completed.mp3'));
      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.resume();
    } catch (e) {
      debugPrint("Kids SFX Level Complete Error: $e");
      await playSuccessSFX();
    }
  }

  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
