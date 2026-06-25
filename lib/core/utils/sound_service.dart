import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/app_logger.dart';

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

  /// Primary player for gameplay sounds (correct, wrong, hint, click)
  final AudioPlayer _player = AudioPlayer();

  /// Secondary player for overlay sounds (level complete) that shouldn't cut off primary
  final AudioPlayer _overlayPlayer = AudioPlayer();

  bool _isMuted = false;

  /// RACE-CONDITION FIX: `_init()` loads the persisted mute preference
  /// asynchronously. The previous code fired it from the constructor and
  /// never awaited it anywhere, so any `play*()` call made in the brief
  /// window before it completed would see the default `_isMuted = false`
  /// regardless of what the user had actually saved - i.e. a muted user
  /// could briefly hear sound right at app startup. Every `play*()` method
  /// now awaits this stored Future first, with zero impact on the public
  /// API (callers never see this Future directly).
  late final Future<void> _initFuture;

  // Compile-time static const paths to prevent magic string typo configurations
  static const String assetCorrect = 'sounds/correct.mp3';
  static const String assetWrong = 'sounds/wrong.mp3';
  static const String assetHint = 'sounds/hint.mp3';
  static const String assetClick = 'sounds/click.mp3';
  static const String assetLevelCompleted = 'sounds/level_completed.mp3';

  static const String _prefsKeySoundEnabled = 'sound_enabled';

  SoundServiceImpl(this._ttsService) {
    _initFuture = _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = !(prefs.getBool(_prefsKeySoundEnabled) ?? true);
    } catch (e) {
      AppLogger.warning(
        'SoundService: SharedPreferences loading error',
        error: e,
      );
    }
  }

  @override
  bool get isMuted => _isMuted;

  @override
  void setMuted(bool muted) {
    _isMuted = muted;
    // PERSISTENCE BUG FIX: this previously only updated the in-memory
    // flag and never wrote the new value back to SharedPreferences, so a
    // user's mute choice did not survive an app restart (it would silently
    // revert to whatever was last persisted - or the default - the next
    // time the app launched). This service owns reading the preference in
    // `_init()`, so it should also own writing it, regardless of whether
    // some other layer happens to also persist it.
    unawaited(_persistMuted(muted));
  }

  Future<void> _persistMuted(bool muted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeySoundEnabled, !muted);
    } catch (e) {
      AppLogger.warning(
        'SoundService: Failed to persist mute preference',
        error: e,
      );
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _player.dispose();
      await _overlayPlayer.dispose();
    } catch (e) {
      AppLogger.warning('SoundService: Error disposing AudioPlayers', error: e);
    }
  }

  @override
  Future<void> playCorrect() async {
    await _initFuture;
    if (_isMuted) return;
    try {
      if (_player.state == PlayerState.playing) await _player.stop();
      await _player.setSource(AssetSource(assetCorrect));
      await _player.resume();
    } catch (e) {
      AppLogger.warning(
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
      if (_player.state == PlayerState.playing) await _player.stop();
      await _player.setSource(AssetSource(assetWrong));
      await _player.resume();
    } catch (e) {
      AppLogger.warning('SoundService: Error playing sound (wrong)', error: e);
    }
  }

  @override
  Future<void> playClick() async {
    await _initFuture;
    if (_isMuted) return;
    try {
      if (_player.state == PlayerState.playing) await _player.stop();
      // BUG FIX: this previously played `assetCorrect` (the "correct
      // answer" chime) for every single UI tap, per a comment literally
      // reading "Using correct.mp3 as a generic click for now". That
      // meant ordinary button taps sounded identical to getting a
      // question right, which both confuses the feedback semantics and
      // dilutes how rewarding the real "correct" chime feels. Now points
      // at its own dedicated asset.
      //
      // ACTION REQUIRED: add an actual `assets/sounds/click.mp3` file to
      // the project and register it in pubspec.yaml's assets list - this
      // is a real audio asset that has to be supplied by you; I can't
      // fabricate a binary file. Until it's added, this will safely no-op
      // (caught below) rather than crash.
      await _player.setSource(AssetSource(assetClick));
      await _player.resume();
    } catch (e) {
      AppLogger.warning('SoundService: Error playing sound (click)', error: e);
    }
  }

  @override
  Future<void> playHint() async {
    await _initFuture;
    if (_isMuted) return;
    try {
      if (_player.state == PlayerState.playing) await _player.stop();
      await _player.setSource(AssetSource(assetHint));
      await _player.resume();
    } catch (e) {
      AppLogger.warning('SoundService: Error playing sound (hint)', error: e);
    }
  }

  @override
  Future<void> playMascotInteraction() async {
    await playHint();
  }

  @override
  Future<void> playLevelComplete() async {
    await _initFuture;
    if (_isMuted) return;
    try {
      if (_overlayPlayer.state == PlayerState.playing)
        await _overlayPlayer.stop();
      await _overlayPlayer.setSource(AssetSource(assetLevelCompleted));
      await _overlayPlayer.resume();
    } catch (e) {
      AppLogger.warning(
        'SoundService: Error playing sound (level_completed); using fallback',
        error: e,
      );
      await playCorrect();
    }
  }

  @override
  Future<void> playUrl(String url) async {
    await _initFuture;
    if (_isMuted) return;
    try {
      if (_player.state == PlayerState.playing) await _player.stop();
      await _player.setSource(UrlSource(url));
      await _player.resume();
    } catch (e) {
      AppLogger.warning('SoundService: Error playing sound (url)', error: e);
    }
  }

  @override
  Future<void> playTts(
    String text, {
    double speed = 0.4,
    String? locale,
  }) async {
    await _initFuture;
    if (_isMuted) return;
    try {
      await _ttsService.speak(text, rate: speed, locale: locale);
    } catch (e) {
      AppLogger.warning('SoundService: Error playing TTS', error: e);
    }
  }

  @override
  Future<void> stopTts() async {
    try {
      await _ttsService.stop();
    } catch (e) {
      AppLogger.warning('SoundService: Error stopping TTS', error: e);
    }
  }
}
