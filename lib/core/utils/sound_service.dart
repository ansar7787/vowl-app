import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

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

  /// Whether game-specific celebratory sounds are enabled.
  bool get isGameSoundsEnabled;

  /// Sets whether game-specific sounds are enabled.
  void setGameSoundsEnabled(bool enabled);

  /// Releases audio players, resources, and event listeners.
  Future<void> dispose();

  /// Plays success audio feedback with dynamic pitch scaling according to [comboStep].
  ///
  /// - Step 1: Base pitch (1.00x)
  /// - Step 2: Ascending major third (1.12x)
  /// - Step 3+: Peak fifth / frenzy (1.25x)
  Future<void> playCorrect({int comboStep = 1});

  /// Plays standard error/fail audio feedback effect.
  Future<void> playWrong();

  /// Plays gentle, non-punitive error feedback (soft wood clunk).
  Future<void> playSoftWrong();

  /// Plays general item clicking blip sound.
  Future<void> playClick();

  /// Plays hint retrieval blip sound.
  Future<void> playHint();

  /// Plays subtle greeting feedback for Mascot reactions.
  Future<void> playMascotInteraction();

  /// Plays level completion victory audio overlay.
  Future<void> playLevelComplete();

  /// Plays warm celebratory fanfare when daily streak mission is secured.
  Future<void> playStreakFlameIgnite();

  /// Plays rapid micro-ticker chimes synced with the victory coin/XP counter animation.
  Future<void> playCoinTally({int count = 10});

  /// Downloads and streams sound assets from internet endpoints.
  Future<void> playUrl(String url);

  /// Plays a local audio file from the device storage.
  Future<void> playFile(String filePath);

  /// Triggers synthesized speech generation using Text-to-Speech.
  Future<void> playTts(
    String text, {
    double speed = 0.4,
    String? locale,
    List<int>? pauseMarkers,
  });

  /// Speaks text with comparative dual-speed pronunciation (normal then slow).
  Future<void> playTtsComparison(
    String text, {
    double normalRate = 0.8,
    double slowRate = 0.32,
  });

  /// Aborts all active synthesized speech playback.
  Future<void> stopTts();

  /// Stops any currently playing audio track.
  Future<void> stopAudio();
}

/// Concrete implementation of [SoundService] utilizing `audioplayers` SDK.
class SoundServiceImpl implements SoundService {
  final TtsService _ttsService;

  /// Primary player for gameplay sounds (correct, wrong, hint, click)
  final AudioPlayer _player = AudioPlayer();

  /// Secondary player for overlay sounds (level complete, flame) that shouldn't cut off primary
  final AudioPlayer _overlayPlayer = AudioPlayer();

  bool _isMuted = false;
  bool _isGameSoundsEnabled = true;

  late final Future<void> _initFuture;

  // Compile-time static const paths to prevent magic string typo configurations
  static const String assetCorrect = 'sounds/correct.mp3';
  static const String assetWrong = 'sounds/wrong.mp3';
  static const String assetHint = 'sounds/hint.mp3';
  static const String assetLevelCompleted = 'sounds/level_completed.mp3';
  static const String assetFlame = 'sounds/flame.mp3';
  static const String assetCoin = 'sounds/coin.mp3';

  static const String _prefsKeySoundEnabled = 'sound_enabled';
  static const String _prefsKeyGameSoundsEnabled = 'game_sounds_enabled';

  void _logError(String message, {Object? error}) {
    if (di.sl.isRegistered<AppLogger>()) {
      _logError(message, error: error);
    }
  }

  SoundServiceImpl(this._ttsService) {
    _initFuture = _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = !(prefs.getBool(_prefsKeySoundEnabled) ?? true);
      _isGameSoundsEnabled = prefs.getBool(_prefsKeyGameSoundsEnabled) ?? true;
    } catch (e) {
      _logError(
        'SoundService: SharedPreferences loading error',
        error: e,
      );
    }
  }

  @override
  bool get isMuted => _isMuted;

  @override
  bool get isGameSoundsEnabled => _isGameSoundsEnabled;

  @override
  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      unawaited(stopAudio());
      unawaited(stopTts());
    }
    unawaited(_persistMuted(muted));
  }

  @override
  void setGameSoundsEnabled(bool enabled) {
    _isGameSoundsEnabled = enabled;
    if (!enabled) {
      unawaited(stopAudio());
    }
    unawaited(_persistGameSoundsEnabled(enabled));
  }

  Future<void> _persistMuted(bool muted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeySoundEnabled, !muted);
    } catch (e) {
      _logError(
        'SoundService: Failed to persist mute preference',
        error: e,
      );
    }
  }

  Future<void> _persistGameSoundsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyGameSoundsEnabled, enabled);
    } catch (e) {
      _logError(
        'SoundService: Failed to persist game sounds preference',
        error: e,
      );
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (e) {
      _logError(
        'SoundService: Error disposing primary AudioPlayer',
        error: e,
      );
    }
    try {
      await _overlayPlayer.dispose();
    } catch (e) {
      _logError(
        'SoundService: Error disposing overlay AudioPlayer',
        error: e,
      );
    }
  }

  @override
  Future<void> playCorrect({int comboStep = 1}) async {
    await _initFuture;
    if (_isMuted) return;
    try {
      await _player.stop();
      // Musical pitch ladder for 3-question levels:
      // Q1: 1.00x (base C5), Q2: 1.12x (ascending E5), Q3+: 1.25x (peak G5)
      final double rate = comboStep == 2 ? 1.12 : (comboStep >= 3 ? 1.25 : 1.0);
      await _player.setPlaybackRate(rate);

      // Audio ducking: if TTS is speaking, drop SFX volume to preserve voice clarity
      final double effectiveVolume = _ttsService.isSpeaking ? 0.35 : 0.85;
      await _player.setVolume(effectiveVolume);

      await _player.play(AssetSource(assetCorrect));
    } catch (e) {
      _logError(
        'SoundService: Error playing sound (correct)',
        error: e,
      );
    }
  }

  @override
  Future<void> playWrong() async {
    await _initFuture;
    if (_isMuted) return;
    try {
      await _player.stop();
      await _player.setPlaybackRate(1.0);

      final double effectiveVolume = _ttsService.isSpeaking ? 0.35 : 0.85;
      await _player.setVolume(effectiveVolume);

      await _player.play(AssetSource(assetWrong));
    } catch (e) {
      _logError(
        'SoundService: Error playing sound (wrong)',
        error: e,
      );
    }
  }

  @override
  Future<void> playSoftWrong() async {
    await playWrong();
  }

  @override
  Future<void> playClick() async {
    // Intentionally left empty.
    // We rely on HapticService for UI tap feedback rather than audio clicks
    // to prevent the app from becoming noisy and annoying.
  }

  @override
  Future<void> playHint() async {
    await _initFuture;
    if (_isMuted) return;
    try {
      await _player.stop();
      await _player.setPlaybackRate(1.0);
      await _player.play(AssetSource(assetHint));
    } catch (e) {
      _logError(
        'SoundService: Error playing sound (hint)',
        error: e,
      );
    }
  }

  @override
  Future<void> playMascotInteraction() async {
    await playHint();
  }

  @override
  Future<void> playLevelComplete() async {
    await _initFuture;
    if (_isMuted || !_isGameSoundsEnabled) return;
    try {
      await _overlayPlayer.stop();
      await _overlayPlayer.setPlaybackRate(1.0);
      await _overlayPlayer.play(AssetSource(assetLevelCompleted));
    } catch (e) {
      _logError(
        'SoundService: Error playing sound (level_completed); using fallback',
        error: e,
      );
      await playCorrect();
    }
  }

  @override
  Future<void> playStreakFlameIgnite() async {
    await _initFuture;
    if (_isMuted || !_isGameSoundsEnabled) return;
    try {
      await _overlayPlayer.stop();
      await _overlayPlayer.setPlaybackRate(1.0);
      await _overlayPlayer.play(AssetSource(assetFlame));
    } catch (e) {
      _logError(
        'SoundService: Error playing flame sound; using fallback',
        error: e,
      );
      await playLevelComplete();
    }
  }

  @override
  Future<void> playCoinTally({int count = 10}) async {
    await _initFuture;
    if (_isMuted || !_isGameSoundsEnabled) return;
    final int safeCount = count.clamp(1, 15);
    try {
      for (int i = 0; i < safeCount; i++) {
        // Micro-pitch ascent over the coin tally
        final double rate = 1.0 + (i * 0.025);
        await _player.stop();
        await _player.setPlaybackRate(rate.clamp(1.0, 1.35));
        await _player.play(AssetSource(assetCoin), volume: 0.6);
        await Future.delayed(const Duration(milliseconds: 65));
      }
    } catch (e) {
      _logError(
        'SoundService: Error playing coin tally sound',
        error: e,
      );
    }
  }

  @override
  Future<void> playUrl(String url) async {
    await _initFuture;
    if (_isMuted) return;
    if (di.sl.isRegistered<AudioRecordingService>() &&
        di.sl<AudioRecordingService>().isRecording) {
      return;
    }
    try {
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (e) {
      _logError(
        'SoundService: Error playing sound (url)',
        error: e,
      );
    }
  }

  @override
  Future<void> playFile(String filePath) async {
    await _initFuture;
    if (_isMuted) return;
    if (di.sl.isRegistered<AudioRecordingService>() &&
        di.sl<AudioRecordingService>().isRecording) {
      return;
    }
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(filePath));
    } catch (e) {
      _logError(
        'SoundService: Error playing sound (file)',
        error: e,
      );
    }
  }

  @override
  Future<void> playTts(
    String text, {
    double speed = 0.4,
    String? locale,
    List<int>? pauseMarkers,
  }) async {
    await _initFuture;
    if (_isMuted) return;
    if (di.sl.isRegistered<AudioRecordingService>() &&
        di.sl<AudioRecordingService>().isRecording) {
      return;
    }
    try {
      await _ttsService.speak(
        text,
        rate: speed,
        locale: locale,
        pauseMarkers: pauseMarkers,
      );
    } catch (e) {
      _logError('SoundService: Error playing TTS', error: e);
    }
  }

  @override
  Future<void> playTtsComparison(
    String text, {
    double normalRate = 0.8,
    double slowRate = 0.32,
  }) async {
    await _initFuture;
    if (_isMuted) return;
    if (di.sl.isRegistered<AudioRecordingService>() &&
        di.sl<AudioRecordingService>().isRecording) {
      return;
    }
    try {
      await _ttsService.speakComparison(
        text,
        normalRate: normalRate,
        slowRate: slowRate,
      );
    } catch (e) {
      _logError(
        'SoundService: Error playing TTS comparison',
        error: e,
      );
    }
  }

  @override
  Future<void> stopTts() async {
    try {
      await _ttsService.stop();
    } catch (e) {
      _logError('SoundService: Error stopping TTS', error: e);
    }
  }

  @override
  Future<void> stopAudio() async {
    try {
      await _player.stop();
      await _overlayPlayer.stop();
    } catch (e) {
      _logError('SoundService: Error stopping audio', error: e);
    }
  }
}
