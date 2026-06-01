import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/tts_service.dart';

/// Abstract contract defining standard audio effects and Text-to-Speech triggers.
///
/// Decouples audio player configurations from the application features, satisfying DIP.
abstract class SoundService {
  /// Factory mapping constructor supporting seamless backwards compatibility for callers.
  factory SoundService(TtsService ttsService) = SoundServiceImpl;

  /// Gets if the sound system is currently muted by user preferences.
  bool get isMuted;

  /// Sets the system mute state toggled by user configuration settings.
  void setMuted(bool muted);

  /// Releases audio players, resources, and event listeners.
  Future<void> dispose();

  /// Plays standard success audio feedback effect.
  Future<void> playCorrect();

  /// Plays standard error/fail audio feedback effect.
  Future<void> playWrong();

  /// Plays general item clicking blip sound.
  Future<void> playClick();

  /// Plays hint retrieval blip sound.
  Future<void> playHint();

  /// Plays subtle greeting feedback for Mascot reactions.
  Future<void> playMascotInteraction();

  /// Plays level completion victory audio overlay.
  Future<void> playLevelComplete();

  /// Downloads and streams sound assets from internet endpoints.
  Future<void> playUrl(String url);

  /// Triggers synthesized speech generation using Text-to-Speech.
  Future<void> playTts(String text, {double speed = 0.4, String? locale});

  /// Aborts all active synthesized speech playback.
  Future<void> stopTts();
}

/// Concrete implementation of [SoundService] utilizing `audioplayers` SDK.
class SoundServiceImpl implements SoundService {
  final TtsService _ttsService;

  /// Primary player for gameplay sounds (correct, wrong, hint)
  final AudioPlayer _player = AudioPlayer();

  /// Secondary player for overlay sounds (level complete) that shouldn't cut off primary
  final AudioPlayer _overlayPlayer = AudioPlayer();

  bool _isMuted = false;

  // Compile-time static const paths to prevent magic string typo configurations
  static const String assetCorrect = 'sounds/correct.mp3';
  static const String assetWrong = 'sounds/wrong.mp3';
  static const String assetHint = 'sounds/hint.mp3';
  static const String assetLevelCompleted = 'sounds/level_completed.mp3';

  SoundServiceImpl(this._ttsService) {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = !(prefs.getBool('sound_enabled') ?? true);
    } catch (e) {
      debugPrint('SoundService: SharedPreferences loading error: $e');
    }
  }

  @override
  bool get isMuted => _isMuted;

  @override
  void setMuted(bool muted) {
    _isMuted = muted;
  }

  @override
  Future<void> dispose() async {
    try {
      await _player.dispose();
      await _overlayPlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing AudioPlayers: $e');
    }
  }

  @override
  Future<void> playCorrect() async {
    if (_isMuted) return;
    try {
      if (_player.state == PlayerState.playing) await _player.stop();
      await _player.setSource(AssetSource(assetCorrect));
      await _player.resume();
    } catch (e) {
      debugPrint('Error playing sound (correct): $e');
    }
  }

  @override
  Future<void> playWrong() async {
    if (_isMuted) return;
    try {
      if (_player.state == PlayerState.playing) await _player.stop();
      await _player.setSource(AssetSource(assetWrong));
      await _player.resume();
    } catch (e) {
      debugPrint('Error playing sound (wrong): $e');
    }
  }

  @override
  Future<void> playClick() async {
    if (_isMuted) return;
    try {
      if (_player.state == PlayerState.playing) await _player.stop();
      // Using correct.mp3 as a generic click for now
      await _player.setSource(AssetSource(assetCorrect));
      await _player.resume();
    } catch (e) {
      debugPrint('Error playing sound (click): $e');
    }
  }

  @override
  Future<void> playHint() async {
    if (_isMuted) return;
    try {
      if (_player.state == PlayerState.playing) await _player.stop();
      await _player.setSource(AssetSource(assetHint));
      await _player.resume();
    } catch (e) {
      debugPrint('Error playing sound (hint): $e');
    }
  }

  @override
  Future<void> playMascotInteraction() async {
    await playHint();
  }

  @override
  Future<void> playLevelComplete() async {
    if (_isMuted) return;
    try {
      if (_overlayPlayer.state == PlayerState.playing) await _overlayPlayer.stop();
      await _overlayPlayer.setSource(AssetSource(assetLevelCompleted));
      await _overlayPlayer.resume();
    } catch (e) {
      debugPrint('Error playing sound (level_completed): $e. Using fallback.');
      await playCorrect();
    }
  }

  @override
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

  @override
  Future<void> playTts(String text, {double speed = 0.4, String? locale}) async {
    if (_isMuted) return;
    try {
      await _ttsService.speak(text, rate: speed, locale: locale);
    } catch (e) {
      debugPrint('Error playing TTS: $e');
    }
  }

  @override
  Future<void> stopTts() async {
    try {
      await _ttsService.stop();
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }
}
