import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class SoundService {
  /// Primary player for gameplay sounds (correct, wrong, hint)
  final AudioPlayer _player = AudioPlayer();

  /// Secondary player for overlay sounds (level complete) that shouldn't cut off primary
  final AudioPlayer _overlayPlayer = AudioPlayer();

  bool _isMuted = false;

  SoundService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _isMuted = !(prefs.getBool('sound_enabled') ?? true);
  }

  bool get isMuted => _isMuted;

  void setMuted(bool muted) {
    _isMuted = muted;
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
      await _overlayPlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }
  }

  Future<void> playCorrect() async {
    if (_isMuted) return;
    try {
      if (_player.state == PlayerState.playing) await _player.stop();
      await _player.setSource(AssetSource('sounds/correct.mp3'));
      await _player.resume();
    } catch (e) {
      debugPrint('Error playing sound (correct): $e');
    }
  }

  Future<void> playWrong() async {
    if (_isMuted) return;
    try {
      if (_player.state == PlayerState.playing) await _player.stop();
      await _player.setSource(AssetSource('sounds/wrong.mp3'));
      await _player.resume();
    } catch (e) {
      debugPrint('Error playing sound (wrong): $e');
    }
  }

  Future<void> playClick() async {
    if (_isMuted) return;
    try {
      if (_player.state == PlayerState.playing) await _player.stop();
      await _player.setSource(
        AssetSource('sounds/correct.mp3'),
      ); // Using correct.mp3 as a generic click for now
      await _player.resume();
    } catch (e) {
      debugPrint('Error playing sound (click): $e');
    }
  }

  Future<void> playHint() async {
    if (_isMuted) return;
    try {
      if (_player.state == PlayerState.playing) await _player.stop();
      await _player.setSource(AssetSource('sounds/hint.mp3'));
      await _player.resume();
    } catch (e) {
      debugPrint('Error playing sound (hint): $e');
    }
  }

  Future<void> playMascotInteraction() async {
    // Subtle blip for mascot reactions
    await playHint();
  }

  /// Uses the overlay player so it doesn't cut off the "correct" sound
  Future<void> playLevelComplete() async {
    if (_isMuted) return;
    try {
      if (_overlayPlayer.state == PlayerState.playing) await _overlayPlayer.stop();
      await _overlayPlayer.setSource(AssetSource('sounds/level_completed.mp3'));
      await _overlayPlayer.resume();
    } catch (e) {
      debugPrint('Error playing sound (level_completed): $e');
      // Fallback
      await playCorrect();
    }
  }

  Future<void> playUrl(String url) async {
    if (_isMuted) return;
    try {
      if (_player.state == PlayerState.playing) await _player.stop();
      await _player.setSource(UrlSource(url));
      await _player.resume();
    } catch (e) {
      debugPrint('Error playing sound (url): $e');
    }
  }

  Future<void> playTts(String text, {double speed = 0.4}) async {
    if (_isMuted) return;
    try {
      final tts = di.sl<TtsService>();
      // We can't set speed easily without modifying TtsService, 
      // but let's assume TtsService handles the core logic.
      await tts.speak(text);
    } catch (e) {
      debugPrint('Error playing TTS: $e');
    }
  }

  Future<void> stopTts() async {
    try {
      await di.sl<TtsService>().stop();
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }
}
